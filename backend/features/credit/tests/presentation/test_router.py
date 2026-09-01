"""
Integration tests for credit API endpoints.

Uses FastAPI TestClient with dependency_overrides to mock dependencies.
Tests endpoint routing, authentication, request validation, response shape,
and HTTP status codes.

Endpoints tested:
- GET /balance: requires auth, returns {"balance": Decimal}
- GET /history: requires auth, returns {"entries": [CreditHistoryEntry]}
"""

from datetime import datetime, timedelta, timezone
from decimal import Decimal
from unittest.mock import Mock

import jwt
import pytest
from fastapi import Depends, HTTPException, Header
from fastapi.testclient import TestClient

from core.config import settings
from core.clock import Clock
from features.auth.presentation.router import get_current_user
from features.credit.data.repository import CreditRepository
from features.credit.presentation.router import router, get_credit_repository
from features.credit.presentation.schemas import (
    CreditBalanceResponse,
    CreditHistoryResponse,
    CreditHistoryEntry,
)


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
    return Clock()


@pytest.fixture
def mock_token_service(mock_clock):
    """Provide a mock token service."""
    return MockTokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, mock_clock)


@pytest.fixture
def mock_credit_repository():
    """Provide a mock credit repository."""
    repo = Mock(spec=CreditRepository)
    return repo


@pytest.fixture
def app_with_mocks(mock_token_service, mock_credit_repository):
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

    def mock_get_credit_repository(db=None) -> CreditRepository:
        """Return mocked credit repository."""
        return mock_credit_repository

    app.dependency_overrides[get_current_user] = mock_get_current_user
    app.dependency_overrides[get_credit_repository] = mock_get_credit_repository

    return app


@pytest.fixture
def client(app_with_mocks):
    """Create a FastAPI TestClient."""
    return TestClient(app_with_mocks)


# ============================================================================
# Tests for GET /balance
# ============================================================================


class TestGetBalanceEndpoint:
    """Test GET /balance endpoint."""

    def test_get_balance_without_token_returns_401(self, client):
        """GET /balance without Authorization header should return 401."""
        response = client.get("/balance")
        assert response.status_code == 401
        assert "Missing authorization header" in response.json()["detail"]

    def test_get_balance_with_invalid_bearer_format_returns_401(self, client):
        """GET /balance with malformed Bearer header should return 401."""
        response = client.get("/balance", headers={"Authorization": "InvalidBearer sometoken"})
        assert response.status_code == 401

    def test_get_balance_with_invalid_token_returns_401(self, client):
        """GET /balance with invalid token should return 401."""
        response = client.get("/balance", headers={"Authorization": "Bearer invalid.token.here"})
        assert response.status_code == 401

    def test_get_balance_with_valid_token_calls_handler(self, client, mock_token_service, mock_credit_repository):
        """
        GET /balance with valid token should call endpoint handler.

        Expected behavior (when implemented):
        - With valid auth, should return 200 OK
        - Response body: {"balance": Decimal}
        """
        mock_credit_repository.sum_balance.return_value = Decimal("500.00")
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)

        response = client.get("/balance", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        data = response.json()
        assert "balance" in data
        assert data["balance"] == "500.00"

    def test_get_balance_response_shape(self, client, mock_token_service, mock_credit_repository):
        """
        GET /balance response should include 'balance' field.

        Expected behavior (when implemented):
        - Response model: CreditBalanceResponse
        - Fields: balance (Decimal)
        """
        # Mock repository to return a balance
        mock_credit_repository.sum_balance.return_value = Decimal("500.00")

        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/balance", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        data = response.json()
        assert "balance" in data

    def test_get_balance_extracts_user_id_from_token(self, client, mock_token_service, mock_credit_repository):
        """
        GET /balance should extract user_id from Bearer token.

        Expected behavior (when implemented):
        - Token claims sub=123
        - Endpoint should call repository.sum_balance(user_id=123)
        """
        mock_credit_repository.sum_balance.return_value = Decimal("100.00")
        token = mock_token_service.create_access_token(user_id=123, expires_in_minutes=30)

        response = client.get("/balance", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        # Verify the repository was called with the correct user_id
        mock_credit_repository.sum_balance.assert_called_with(123)

    def test_get_balance_with_zero_balance(self, client, mock_token_service, mock_credit_repository):
        """
        GET /balance should handle zero balance correctly.

        Expected behavior (when implemented):
        - User with no credit ledger entries
        - Should return {"balance": 0}
        """
        mock_credit_repository.sum_balance.return_value = Decimal("0.00")

        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/balance", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        data = response.json()
        assert data["balance"] == "0.00"

    def test_get_balance_with_positive_balance(self, client, mock_token_service, mock_credit_repository):
        """
        GET /balance should handle positive balance (debt).

        Expected behavior (when implemented):
        - User with overage entries
        - Should return {"balance": positive_decimal}
        """
        mock_credit_repository.sum_balance.return_value = Decimal("750.50")

        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/balance", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        data = response.json()
        assert data["balance"] == "750.50"

    def test_get_balance_requires_auth(self, client, mock_token_service, mock_credit_repository):
        """GET /balance requires valid auth to reach handler."""
        # Without token, should get 401 before hitting handler
        response = client.get("/balance")
        assert response.status_code == 401

        # With valid token, should reach handler and get response
        mock_credit_repository.sum_balance.return_value = Decimal("100.00")
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/balance", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200


# ============================================================================
# Tests for GET /history
# ============================================================================


class TestGetHistoryEndpoint:
    """Test GET /history endpoint."""

    def test_get_history_without_token_returns_401(self, client):
        """GET /history without Authorization header should return 401."""
        response = client.get("/history")
        assert response.status_code == 401
        assert "Missing authorization header" in response.json()["detail"]

    def test_get_history_with_invalid_bearer_format_returns_401(self, client):
        """GET /history with malformed Bearer header should return 401."""
        response = client.get("/history", headers={"Authorization": "InvalidBearer sometoken"})
        assert response.status_code == 401

    def test_get_history_with_invalid_token_returns_401(self, client):
        """GET /history with invalid token should return 401."""
        response = client.get("/history", headers={"Authorization": "Bearer invalid.token.here"})
        assert response.status_code == 401

    def test_get_history_with_valid_token_calls_handler(self, client, mock_token_service, mock_credit_repository):
        """
        GET /history with valid token should call endpoint handler.

        Expected behavior (when implemented):
        - With valid auth, should return 200 OK
        - Response body: {"entries": [...]}
        """
        mock_credit_repository.get_history.return_value = []
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)

        response = client.get("/history", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        data = response.json()
        assert "entries" in data

    def test_get_history_response_shape(self, client, mock_token_service, mock_credit_repository):
        """
        GET /history response should include 'entries' field.

        Expected behavior (when implemented):
        - Response model: CreditHistoryResponse
        - Fields: entries (list of CreditHistoryEntry)
        """
        mock_credit_repository.get_history.return_value = []

        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/history", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        data = response.json()
        assert "entries" in data
        assert isinstance(data["entries"], list)

    def test_get_history_empty_entries(self, client, mock_token_service, mock_credit_repository):
        """
        GET /history should handle empty history.

        Expected behavior (when implemented):
        - User with no credit ledger entries
        - Should return {"entries": []}
        """
        mock_credit_repository.get_history.return_value = []

        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/history", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        data = response.json()
        assert data["entries"] == []

    def test_get_history_with_single_entry(self, client, mock_token_service, mock_credit_repository):
        """
        GET /history should return single entry correctly.

        Expected behavior (when implemented):
        - User with one overage entry
        - Should return {"entries": [entry]}
        """
        entry = {
            "id": 1,
            "month": 1,
            "category_code": "food",
            "amount": Decimal("100.00"),
            "entry_type": "overage",
            "created_at": datetime(2025, 9, 1, 12, 0, 0, tzinfo=timezone.utc),
        }
        mock_credit_repository.get_history.return_value = [entry]

        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/history", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        data = response.json()
        assert len(data["entries"]) == 1
        assert data["entries"][0]["id"] == 1

    def test_get_history_with_multiple_entries(self, client, mock_token_service, mock_credit_repository):
        """
        GET /history should return multiple entries.

        Expected behavior (when implemented):
        - User with multiple ledger entries
        - Should return all entries in order
        """
        entries = [
            {
                "id": 1,
                "month": 1,
                "category_code": "food",
                "amount": Decimal("100.00"),
                "entry_type": "overage",
                "created_at": datetime(2025, 9, 1, 12, 0, 0, tzinfo=timezone.utc),
            },
            {
                "id": 2,
                "month": 1,
                "category_code": "food",
                "amount": Decimal("-50.00"),
                "entry_type": "payoff",
                "created_at": datetime(2025, 9, 2, 12, 0, 0, tzinfo=timezone.utc),
            },
        ]
        mock_credit_repository.get_history.return_value = entries

        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/history", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        data = response.json()
        assert len(data["entries"]) == 2

    def test_get_history_entry_fields(self, client, mock_token_service, mock_credit_repository):
        """
        GET /history entries should include all required fields.

        Expected behavior (when implemented):
        - Each entry should have: id, month, category_code, amount, entry_type, created_at
        """
        entry = {
            "id": 1,
            "month": 1,
            "category_code": "rent",
            "amount": Decimal("200.00"),
            "entry_type": "overage",
            "created_at": datetime(2025, 9, 1, 12, 0, 0, tzinfo=timezone.utc),
        }
        mock_credit_repository.get_history.return_value = [entry]

        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/history", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        data = response.json()
        entry_data = data["entries"][0]
        assert "id" in entry_data
        assert "month" in entry_data
        assert "category_code" in entry_data
        assert "amount" in entry_data
        assert "entry_type" in entry_data
        assert "created_at" in entry_data

    def test_get_history_extracts_user_id_from_token(self, client, mock_token_service, mock_credit_repository):
        """
        GET /history should extract user_id from Bearer token.

        Expected behavior (when implemented):
        - Token claims sub=456
        - Endpoint should call repository.get_history(user_id=456)
        """
        mock_credit_repository.get_history.return_value = []

        token = mock_token_service.create_access_token(user_id=456, expires_in_minutes=30)
        response = client.get("/history", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        # Verify the repository was called with the correct user_id
        mock_credit_repository.get_history.assert_called_with(456)

    def test_get_history_requires_auth(self, client, mock_token_service, mock_credit_repository):
        """GET /history requires valid auth to reach handler."""
        # Without token, should get 401 before hitting handler
        response = client.get("/history")
        assert response.status_code == 401

        # With valid token, should reach handler and get response
        mock_credit_repository.get_history.return_value = []
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/history", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200

    def test_get_history_with_mixed_entry_types(self, client, mock_token_service, mock_credit_repository):
        """
        GET /history should return both overage and payoff entries.

        Expected behavior (when implemented):
        - User with mixed entry types
        - Should return both types in history
        """
        entries = [
            {
                "id": 1,
                "month": 1,
                "category_code": "food",
                "amount": Decimal("300.00"),
                "entry_type": "overage",
                "created_at": datetime(2025, 9, 1, 10, 0, 0, tzinfo=timezone.utc),
            },
            {
                "id": 2,
                "month": 1,
                "category_code": "rent",
                "amount": Decimal("150.00"),
                "entry_type": "overage",
                "created_at": datetime(2025, 9, 1, 11, 0, 0, tzinfo=timezone.utc),
            },
            {
                "id": 3,
                "month": 1,
                "category_code": "food",
                "amount": Decimal("-100.00"),
                "entry_type": "payoff",
                "created_at": datetime(2025, 9, 2, 10, 0, 0, tzinfo=timezone.utc),
            },
        ]
        mock_credit_repository.get_history.return_value = entries

        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/history", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200
        data = response.json()
        assert len(data["entries"]) == 3
        # Verify we have both entry types
        entry_types = {entry["entry_type"] for entry in data["entries"]}
        assert "overage" in entry_types
        assert "payoff" in entry_types
