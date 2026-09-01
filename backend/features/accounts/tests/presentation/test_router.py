"""
Integration tests for accounts API endpoints.

Uses FastAPI TestClient with dependency_overrides to mock dependencies.
Tests endpoint routing, authentication, request validation, response shape,
and HTTP status codes.
"""

from datetime import datetime, timedelta, timezone
from unittest.mock import Mock
from decimal import Decimal

import jwt
import pytest
from fastapi import Depends, HTTPException, Header
from fastapi.testclient import TestClient

from core.config import settings
from core.clock import Clock
from features.accounts.presentation.router import router, get_accounts_service
from features.accounts.presentation.schemas import AccountSchema, MonthEndCheckResponse
from features.accounts.business.service import AccountsService
from features.accounts.data.repository import AccountsRepository
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
def mock_accounts_repository():
    """Provide a mock accounts repository."""
    repo = Mock(spec=AccountsRepository)
    repo.get_all_accounts.return_value = [
        {"id": 1, "code": "ICICI", "display_name": "ICICI Bank", "kind": "bank", "fixed_amount": None},
        {"id": 2, "code": "SBI", "display_name": "SBI Bank", "kind": "bank", "fixed_amount": None},
        {"id": 3, "code": "SLICE", "display_name": "Slice", "kind": "bank", "fixed_amount": None},
        {"id": 4, "code": "HDFC", "display_name": "HDFC (Fixed)", "kind": "fixed", "fixed_amount": 2500.00},
        {"id": 5, "code": "CREDIT", "display_name": "Credit Ledger", "kind": "pseudo_credit", "fixed_amount": None},
    ]
    repo.get_all_budget_envelopes.return_value = [
        {"id": 1, "name": "Food", "monthly_amount": 6000.00, "account_id": 1},
        {"id": 2, "name": "PartyOutsideTravel", "monthly_amount": 4000.00, "account_id": 2},
        {"id": 3, "name": "Rent", "monthly_amount": 17000.00, "account_id": 3},
        {"id": 4, "name": "Electricity", "monthly_amount": 100.00, "account_id": 3},
        {"id": 5, "name": "PhoneInternet", "monthly_amount": 300.00, "account_id": 3},
        {"id": 6, "name": "Misc", "monthly_amount": 5000.00, "account_id": 1},
    ]
    repo.get_month_id.return_value = 1
    repo.create_month.return_value = 1
    repo.get_transactions_for_month.return_value = []
    return repo


@pytest.fixture
def mock_accounts_service(mock_accounts_repository, mock_clock):
    """Provide a real AccountsService with mocked repository."""
    return AccountsService(mock_accounts_repository, mock_clock)


@pytest.fixture
def app_with_mocks(mock_token_service, mock_accounts_service):
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

    def mock_get_accounts_service():
        """Return mocked accounts service."""
        return mock_accounts_service

    app.dependency_overrides[get_current_user] = mock_get_current_user
    app.dependency_overrides[get_accounts_service] = mock_get_accounts_service

    return app


@pytest.fixture
def client(app_with_mocks):
    """Create a FastAPI TestClient."""
    return TestClient(app_with_mocks)


# ============================================================================
# Tests for GET /accounts
# ============================================================================


class TestListAccountsEndpoint:
    """Test GET /accounts endpoint."""

    def test_list_accounts_without_token_returns_401(self, client):
        """GET /accounts without Authorization header should return 401."""
        response = client.get("/accounts")
        assert response.status_code == 401
        assert "Missing authorization header" in response.json()["detail"]

    def test_list_accounts_with_invalid_bearer_format_returns_401(self, client):
        """GET /accounts with malformed Bearer header should return 401."""
        response = client.get("/accounts", headers={"Authorization": "InvalidBearer sometoken"})
        assert response.status_code == 401

    def test_list_accounts_with_invalid_token_returns_401(self, client):
        """GET /accounts with invalid token should return 401."""
        response = client.get("/accounts", headers={"Authorization": "Bearer invalid.token.here"})
        assert response.status_code == 401

    def test_list_accounts_with_valid_token_returns_200(self, client, mock_token_service):
        """GET /accounts with valid token should return 200 OK."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/accounts", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200

    def test_list_accounts_returns_all_accounts(self, client, mock_token_service):
        """GET /accounts should return all 5 seeded accounts."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/accounts", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        assert len(data) == 5

    def test_list_accounts_returns_correct_account_fields(self, client, mock_token_service):
        """GET /accounts response should include id, code, display_name, kind, fixed_amount."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/accounts", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        assert len(data) > 0

        account = data[0]
        assert "id" in account
        assert "code" in account
        assert "display_name" in account
        assert "kind" in account
        assert "fixed_amount" in account

    def test_list_accounts_includes_icici(self, client, mock_token_service):
        """Response should include ICICI account."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/accounts", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        codes = [acc["code"] for acc in data]
        assert "ICICI" in codes

    def test_list_accounts_includes_sbi(self, client, mock_token_service):
        """Response should include SBI account."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/accounts", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        codes = [acc["code"] for acc in data]
        assert "SBI" in codes

    def test_list_accounts_includes_slice(self, client, mock_token_service):
        """Response should include SLICE account."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/accounts", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        codes = [acc["code"] for acc in data]
        assert "SLICE" in codes

    def test_list_accounts_icici_account_has_correct_kind(self, client, mock_token_service):
        """ICICI should have kind='bank'."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/accounts", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        icici = next(acc for acc in data if acc["code"] == "ICICI")
        assert icici["kind"] == "bank"
        assert icici["fixed_amount"] is None

    def test_list_accounts_hdfc_account_has_fixed_amount(self, client, mock_token_service):
        """HDFC should have kind='fixed' and fixed_amount=2500."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/accounts", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        hdfc = next(acc for acc in data if acc["code"] == "HDFC")
        assert hdfc["kind"] == "fixed"
        assert hdfc["fixed_amount"] == 2500.0

    def test_list_accounts_response_is_json_array(self, client, mock_token_service):
        """Response should be a JSON array."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/accounts", headers={"Authorization": f"Bearer {token}"})

        assert response.headers["content-type"] == "application/json"
        assert isinstance(response.json(), list)


# ============================================================================
# Tests for GET /accounts/month-end-check
# ============================================================================


class TestMonthEndCheckEndpoint:
    """Test GET /accounts/month-end-check endpoint."""

    def test_month_end_check_without_token_returns_401(self, client):
        """GET /accounts/month-end-check without token should return 401."""
        response = client.get("/accounts/month-end-check")
        assert response.status_code == 401

    def test_month_end_check_with_invalid_token_returns_401(self, client):
        """GET /accounts/month-end-check with invalid token should return 401."""
        response = client.get(
            "/accounts/month-end-check",
            headers={"Authorization": "Bearer invalid.token.here"},
        )
        assert response.status_code == 401

    def test_month_end_check_with_valid_token_returns_200(self, client, mock_token_service):
        """GET /accounts/month-end-check with valid token should return 200."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get(
            "/accounts/month-end-check",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200

    def test_month_end_check_returns_icici_balance(self, client, mock_token_service):
        """Response should include ICICI expected_balance."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get(
            "/accounts/month-end-check",
            headers={"Authorization": f"Bearer {token}"},
        )

        data = response.json()
        assert "ICICI" in data
        assert "expected_balance" in data["ICICI"]

    def test_month_end_check_returns_sbi_balance(self, client, mock_token_service):
        """Response should include SBI expected_balance."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get(
            "/accounts/month-end-check",
            headers={"Authorization": f"Bearer {token}"},
        )

        data = response.json()
        assert "SBI" in data
        assert "expected_balance" in data["SBI"]

    def test_month_end_check_returns_slice_balance(self, client, mock_token_service):
        """Response should include SLICE expected_balance."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get(
            "/accounts/month-end-check",
            headers={"Authorization": f"Bearer {token}"},
        )

        data = response.json()
        assert "SLICE" in data
        assert "expected_balance" in data["SLICE"]

    def test_month_end_check_returns_hdfc_reserve(self, client, mock_token_service):
        """Response should include hdfc_reserve field."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get(
            "/accounts/month-end-check",
            headers={"Authorization": f"Bearer {token}"},
        )

        data = response.json()
        assert "hdfc_reserve" in data
        assert isinstance(data["hdfc_reserve"], (int, float))
        assert data["hdfc_reserve"] == 2500.0

    def test_month_end_check_returns_total_net_worth(self, client, mock_token_service):
        """Response should include total_net_worth field."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get(
            "/accounts/month-end-check",
            headers={"Authorization": f"Bearer {token}"},
        )

        data = response.json()
        assert "total_net_worth" in data
        assert isinstance(data["total_net_worth"], (int, float))

    def test_month_end_check_total_equals_sum_of_balances(self, client, mock_token_service):
        """total_net_worth should equal sum of all balances."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get(
            "/accounts/month-end-check",
            headers={"Authorization": f"Bearer {token}"},
        )

        data = response.json()
        calculated_total = (
            data["ICICI"]["expected_balance"]
            + data["SBI"]["expected_balance"]
            + data["SLICE"]["expected_balance"]
            + data["hdfc_reserve"]
        )
        assert abs(data["total_net_worth"] - calculated_total) < 0.01

    def test_month_end_check_response_shape(self, client, mock_token_service):
        """Response should have expected structure."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get(
            "/accounts/month-end-check",
            headers={"Authorization": f"Bearer {token}"},
        )

        data = response.json()

        # Verify structure
        assert isinstance(data["ICICI"], dict)
        assert isinstance(data["SBI"], dict)
        assert isinstance(data["SLICE"], dict)
        assert isinstance(data["hdfc_reserve"], (int, float))
        assert isinstance(data["total_net_worth"], (int, float))

        # Verify numeric values
        assert isinstance(data["ICICI"]["expected_balance"], (int, float))
        assert isinstance(data["SBI"]["expected_balance"], (int, float))
        assert isinstance(data["SLICE"]["expected_balance"], (int, float))

    def test_month_end_check_hdfc_not_in_per_account_list(self, client, mock_token_service):
        """HDFC should only appear as hdfc_reserve, not as account entry."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get(
            "/accounts/month-end-check",
            headers={"Authorization": f"Bearer {token}"},
        )

        data = response.json()
        # Should not have per-account balance for HDFC
        assert "HDFC" not in data or "expected_balance" not in data.get("HDFC", {})

    def test_month_end_check_credit_not_in_response(self, client, mock_token_service):
        """CREDIT pseudo-account should not appear in month-end check."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get(
            "/accounts/month-end-check",
            headers={"Authorization": f"Bearer {token}"},
        )

        data = response.json()
        # Should not have CREDIT in response
        account_keys = [k for k in data.keys() if k in ["ICICI", "SBI", "SLICE", "CREDIT"]]
        assert "CREDIT" not in account_keys
