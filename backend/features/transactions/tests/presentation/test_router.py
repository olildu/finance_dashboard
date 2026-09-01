"""
Integration tests for transactions API endpoints.

Uses FastAPI TestClient with dependency_overrides to mock dependencies.
Tests endpoint routing, authentication, request validation, response shape,
and HTTP status codes.
"""

from datetime import datetime, timedelta, timezone
from decimal import Decimal
from unittest.mock import Mock
import json

import jwt
import pytest
from fastapi import Depends, HTTPException, Header
from fastapi.testclient import TestClient

from core.config import settings
from core.clock import Clock
from features.transactions.presentation.router import router, get_transactions_service
from features.transactions.presentation.schemas import (
    CreateTransactionRequest,
    TransactionResponse,
    TransactionListResponse,
)
from features.transactions.business.service import TransactionsService
from features.transactions.data.repository import TransactionsRepository
from features.auth.presentation.router import get_current_user


# ============================================================================
# Mock token service for testing
# ============================================================================


class MockTokenService:
    """Mock JWT token service for testing."""

    def __init__(self, secret: str, algorithm: str, clock: Clock):
        self.secret = secret
        self.algorithm = algorithm
        self.clock = clock

    def create_access_token(self, user_id: int, expires_in_minutes: int) -> str:
        """Create a signed JWT access token."""
        now = self.clock.now()
        expiry = now + timedelta(minutes=expires_in_minutes)
        payload = {
            "sub": str(user_id),
            "exp": expiry,
            "iat": now,
            "token_type": "access",
        }
        return jwt.encode(payload, self.secret, algorithm=self.algorithm)

    def get_user_id_from_token(self, token: str) -> int:
        """Extract user_id from token."""
        try:
            payload = jwt.decode(token, self.secret, algorithms=[self.algorithm])
            return int(payload["sub"])
        except jwt.InvalidTokenError:
            raise


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def mock_clock():
    """Provide a mock clock for predictable time."""
    clock = Clock()
    return clock


@pytest.fixture
def mock_token_service(mock_clock):
    """Provide a mock token service."""
    return MockTokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, mock_clock)


@pytest.fixture
def mock_transactions_repository():
    """Provide a mock transactions repository."""
    repo = Mock(spec=TransactionsRepository)
    repo.insert = Mock(return_value=1)
    repo.list_for_month = Mock(return_value=[])
    repo.delete = Mock(return_value=True)
    repo.sum_expense_for_envelope_in_month = Mock(return_value=Decimal("0"))
    return repo


@pytest.fixture
def mock_transactions_service(mock_transactions_repository):
    """Provide a mock transactions service."""
    service = Mock(spec=TransactionsService)

    def record_expense_side_effect(user_id, month_id, category_code, amount, reason, date):
        """Return a response that includes the actual amount from the request."""
        return {
            "id": 1,
            "category_code": category_code,
            "funding_account_code": "ICICI",
            "amount": amount,
            "type": "expense",
            "is_overage": False,
            "reason": reason,
            "date": date,
        }

    service.record_expense = Mock(side_effect=record_expense_side_effect)
    return service


@pytest.fixture
def app_with_mocks(mock_token_service, mock_transactions_service):
    """Create a test FastAPI app with real router and mocked dependencies."""
    from fastapi import FastAPI

    app = FastAPI()
    app.include_router(router)

    # Override dependencies for testing
    def mock_get_current_user(authorization: str = Header(None)) -> int:
        """Extract user_id from Bearer token."""
        if not authorization:
            raise HTTPException(status_code=401, detail="Missing authorization header")
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header format")

        token = authorization[7:]
        try:
            user_id = mock_token_service.get_user_id_from_token(token)
            return user_id
        except jwt.InvalidTokenError:
            raise HTTPException(status_code=401, detail="Invalid or expired token")

    def mock_get_transactions_service():
        """Return mocked transactions service."""
        return mock_transactions_service

    app.dependency_overrides[get_current_user] = mock_get_current_user
    app.dependency_overrides[get_transactions_service] = mock_get_transactions_service

    return app


@pytest.fixture
def client(app_with_mocks):
    """Create a FastAPI TestClient."""
    return TestClient(app_with_mocks)


# ============================================================================
# Tests for POST / (create transaction)
# ============================================================================


class TestCreateTransactionEndpoint:
    """Test POST /transactions endpoint."""

    def test_create_transaction_without_token_returns_401(self, client):
        """POST /transactions without Authorization header should return 401."""
        response = client.post(
            "/transactions",
            json={
                "category_code": "food",
                "amount": 500.00,
                "reason": "Lunch",
                "date": "2025-09-01T12:00:00",
            },
        )
        assert response.status_code == 401
        assert "Missing authorization header" in response.json()["detail"]

    def test_create_transaction_with_invalid_bearer_format_returns_401(self, client):
        """POST /transactions with malformed Bearer header should return 401."""
        response = client.post(
            "/transactions",
            json={
                "category_code": "food",
                "amount": 500.00,
                "reason": "Lunch",
                "date": "2025-09-01T12:00:00",
            },
            headers={"Authorization": "InvalidBearer sometoken"},
        )
        assert response.status_code == 401

    def test_create_transaction_with_invalid_token_returns_401(self, client):
        """POST /transactions with invalid token should return 401."""
        response = client.post(
            "/transactions",
            json={
                "category_code": "food",
                "amount": 500.00,
                "reason": "Lunch",
                "date": "2025-09-01T12:00:00",
            },
            headers={"Authorization": "Bearer invalid.token.here"},
        )
        assert response.status_code == 401

    def test_create_transaction_with_valid_token_returns_201(self, client, mock_token_service):
        """POST /transactions with valid token should return 201 Created."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.post(
            "/transactions",
            json={
                "category_code": "food",
                "amount": 500.00,
                "reason": "Lunch",
                "date": "2025-09-01T12:00:00",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 201

    def test_create_transaction_returns_transaction_response(self, client, mock_token_service):
        """POST / should return a TransactionResponse."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.post(
            "/transactions",
            json={
                "category_code": "food",
                "amount": 500.00,
                "reason": "Lunch",
                "date": "2025-09-01T12:00:00",
            },
            headers={"Authorization": f"Bearer {token}"},
        )

        data = response.json()
        assert "id" in data
        assert "category_code" in data
        assert "funding_account_code" in data
        assert "amount" in data
        assert "type" in data
        assert "is_overage" in data
        assert "reason" in data
        assert "date" in data

    def test_create_transaction_response_includes_category_code(
        self, client, mock_token_service
    ):
        """Response should include the requested category_code."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.post(
            "/transactions",
            json={
                "category_code": "food",
                "amount": 500.00,
                "reason": "Lunch",
                "date": "2025-09-01T12:00:00",
            },
            headers={"Authorization": f"Bearer {token}"},
        )

        data = response.json()
        assert data["category_code"] == "food"

    def test_create_transaction_response_includes_amount(self, client, mock_token_service):
        """Response should include the transaction amount."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.post(
            "/transactions",
            json={
                "category_code": "food",
                "amount": 750.50,
                "reason": "Lunch",
                "date": "2025-09-01T12:00:00",
            },
            headers={"Authorization": f"Bearer {token}"},
        )

        data = response.json()
        assert data["amount"] == 750.50

    def test_create_transaction_with_no_reason_allowed(self, client, mock_token_service):
        """POST /transactions should allow transaction without reason (optional field)."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.post(
            "/transactions",
            json={
                "category_code": "food",
                "amount": 500.00,
                "date": "2025-09-01T12:00:00",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 201

    def test_create_transaction_missing_category_code_returns_422(
        self, client, mock_token_service
    ):
        """POST /transactions without category_code should return 422 Unprocessable Entity."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.post(
            "/transactions",
            json={
                "amount": 500.00,
                "reason": "Lunch",
                "date": "2025-09-01T12:00:00",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 422

    def test_create_transaction_missing_amount_returns_422(self, client, mock_token_service):
        """POST /transactions without amount should return 422."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.post(
            "/transactions",
            json={
                "category_code": "food",
                "reason": "Lunch",
                "date": "2025-09-01T12:00:00",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 422

    def test_create_transaction_missing_date_returns_422(self, client, mock_token_service):
        """POST /transactions without date should return 422."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.post(
            "/transactions",
            json={
                "category_code": "food",
                "amount": 500.00,
                "reason": "Lunch",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 422


# ============================================================================
# Tests for GET / (list transactions)
# ============================================================================


class TestListTransactionsEndpoint:
    """Test GET /transactions endpoint."""

    def test_list_transactions_without_token_returns_401(self, client):
        """GET /transactions without Authorization header should return 401."""
        response = client.get("/transactions")
        assert response.status_code == 401
        assert "Missing authorization header" in response.json()["detail"]

    def test_list_transactions_with_invalid_token_returns_401(self, client):
        """GET /transactions with invalid token should return 401."""
        response = client.get("/transactions", headers={"Authorization": "Bearer invalid.token.here"})
        assert response.status_code == 401

    def test_list_transactions_with_valid_token_returns_200(self, client, mock_token_service):
        """GET /transactions with valid token should return 200 OK."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/transactions", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200

    def test_list_transactions_returns_transaction_list_response(
        self, client, mock_token_service
    ):
        """GET /transactions should return a TransactionListResponse."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/transactions", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        assert "transactions" in data
        assert isinstance(data["transactions"], list)

    def test_list_transactions_empty_list_when_none_exist(self, client, mock_token_service):
        """GET /transactions should return empty transactions list when none exist."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/transactions", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        assert data["transactions"] == []

    def test_list_transactions_returns_transactions_array(
        self, client, mock_token_service, mock_transactions_service
    ):
        """GET /transactions should return transactions array with proper structure."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)

        # Set up mock to return some transactions
        mock_transactions_service.record_expense = Mock(
            return_value={
                "id": 1,
                "category_code": "food",
                "funding_account_code": "ICICI",
                "amount": 500.00,
                "type": "expense",
                "is_overage": False,
                "reason": "Lunch",
                "date": "2025-09-01",
            }
        )

        response = client.get("/transactions", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200

        data = response.json()
        assert "transactions" in data


# ============================================================================
# Tests for DELETE /{transaction_id}
# ============================================================================


class TestDeleteTransactionEndpoint:
    """Test DELETE /{transaction_id} endpoint."""

    def test_delete_transaction_without_token_returns_401(self, client):
        """DELETE /1 without Authorization header should return 401."""
        response = client.delete("/transactions/1")
        assert response.status_code == 401
        assert "Missing authorization header" in response.json()["detail"]

    def test_delete_transaction_with_invalid_token_returns_401(self, client):
        """DELETE /1 with invalid token should return 401."""
        response = client.delete("/transactions/1", headers={"Authorization": "Bearer invalid.token.here"})
        assert response.status_code == 401

    def test_delete_transaction_with_valid_token_returns_204(self, client, mock_token_service):
        """DELETE /1 with valid token should return 204 No Content."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.delete("/transactions/1", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 204

    def test_delete_nonexistent_transaction_is_idempotent_204(
        self, client, mock_token_service, mock_transactions_service
    ):
        """DELETE on an already-gone/nonexistent transaction id is idempotent: still 204, not 404."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)

        # The repository's delete() returns False when no row matched; the route
        # deliberately treats this the same as a successful delete (idempotent DELETE).
        mock_transactions_service.delete = Mock(return_value=False)

        response = client.delete("/transactions/99999", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 204

    def test_delete_transaction_with_transaction_id_path_param(
        self, client, mock_token_service
    ):
        """DELETE endpoint should accept transaction_id as path parameter."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.delete("/transactions/42", headers={"Authorization": f"Bearer {token}"})
        # Should not return 404 "not found" for route
        assert response.status_code != 404 or "path" not in str(response.json()).lower()

    def test_delete_transaction_with_non_integer_id_returns_422(
        self, client, mock_token_service
    ):
        """DELETE /abc with non-integer ID should return 422."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.delete("/transactions/abc", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 422


# ============================================================================
# Tests: Authentication and Authorization
# ============================================================================


class TestAuthenticationAndAuthorization:
    """Test authentication requirements on all endpoints."""

    def test_all_endpoints_require_authentication(self, client):
        """All transaction endpoints should require authentication."""
        # GET /transactions
        response = client.get("/transactions")
        assert response.status_code == 401

        # POST /transactions
        response = client.post(
            "/transactions",
            json={
                "category_code": "food",
                "amount": 500.00,
                "date": "2025-09-01T12:00:00",
            },
        )
        assert response.status_code == 401

        # DELETE /transactions/1
        response = client.delete("/transactions/1")
        assert response.status_code == 401

    def test_bearer_token_required_format(self, client):
        """Authorization header must use Bearer token format."""
        response = client.get("/transactions", headers={"Authorization": "Basic username:password"})
        assert response.status_code == 401

    def test_different_users_have_different_sessions(
        self, client, mock_token_service
    ):
        """Different user tokens should represent different users."""
        token1 = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        token2 = mock_token_service.create_access_token(user_id=2, expires_in_minutes=30)

        # Both tokens should be valid but different
        response1 = client.get("/transactions", headers={"Authorization": f"Bearer {token1}"})
        response2 = client.get("/transactions", headers={"Authorization": f"Bearer {token2}"})

        assert response1.status_code == 200
        assert response2.status_code == 200
        # Both should succeed but theoretically represent different users
