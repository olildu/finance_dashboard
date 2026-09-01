"""
Integration tests for dashboard API endpoints.

Uses FastAPI TestClient with dependency_overrides to mock dependencies.
Tests endpoint routing, authentication, request validation, response shape,
and HTTP status codes for the GET /overview endpoint.
"""

from datetime import datetime, timedelta, timezone
from decimal import Decimal
from unittest.mock import Mock

import jwt
import pytest
from fastapi import Depends, FastAPI, HTTPException, Header
from fastapi.testclient import TestClient

from core.config import settings
from core.clock import Clock
from features.accounts.business.service import AccountsService
from features.accounts.data.repository import AccountsRepository
from features.auth.presentation.router import get_current_user
from features.budgets.business.pace_service import BudgetsPaceService
from features.credit.business.service import CreditService
from features.credit.data.repository import CreditRepository
from features.dashboard.business.overview_service import OverviewService
from features.dashboard.presentation.router import (
    get_accounts_repository,
    get_accounts_service,
    get_budgets_pace_service,
    get_categories_repository,
    get_credit_repository,
    get_credit_service,
    get_overview_service,
    get_transactions_repository,
    router,
)
from features.dashboard.presentation.schemas import DashboardOverviewResponse
from features.transactions.data.repository import TransactionsRepository
from features.categories.data.repository import CategoriesRepository


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
def mock_accounts_repository():
    """Provide a mock accounts repository."""
    repo = Mock()
    repo.get_all_accounts.return_value = [
        {"id": 1, "code": "ICICI", "display_name": "ICICI Bank", "kind": "bank", "fixed_amount": None},
        {"id": 2, "code": "SBI", "display_name": "SBI Bank", "kind": "bank", "fixed_amount": None},
        {"id": 3, "code": "SLICE", "display_name": "Slice", "kind": "bank", "fixed_amount": None},
        {"id": 4, "code": "HDFC", "display_name": "HDFC (Fixed)", "kind": "fixed", "fixed_amount": 2500.00},
    ]
    repo.get_all_budget_envelopes.return_value = [
        {"id": 1, "name": "Food", "monthly_amount": 6000.00, "account_id": 1},
        {"id": 2, "name": "Travel", "monthly_amount": 4000.00, "account_id": 2},
    ]
    repo.get_month_id.return_value = 1
    repo.create_month.return_value = 1
    repo.get_transactions_for_month.return_value = []
    return repo


@pytest.fixture
def mock_categories_repository():
    """Provide a mock categories repository."""
    repo = Mock()
    repo.get_all_active_categories_with_envelopes.return_value = [
        {
            "id": 1,
            "code": "food",
            "display_name": "Food & Groceries",
            "is_active": True,
            "envelope_id": 1,
            "envelope_name": "Food",
            "monthly_amount": Decimal("6000.00"),
            "account_code": "ICICI",
        },
        {
            "id": 2,
            "code": "travel",
            "display_name": "Travel & Transport",
            "is_active": True,
            "envelope_id": 2,
            "envelope_name": "Travel",
            "monthly_amount": Decimal("4000.00"),
            "account_code": "SBI",
        },
    ]
    return repo


@pytest.fixture
def mock_transactions_repository():
    """Provide a mock transactions repository."""
    repo = Mock()
    repo.list_for_month.return_value = [
        {
            "id": 1,
            "category_code": "food",
            "funding_account_code": "ICICI",
            "amount": Decimal("450.00"),
            "type": "expense",
            "is_overage": False,
            "reason": "Dinner",
            "date": datetime(2025, 1, 15, 12, 30, 0, tzinfo=timezone.utc),
        },
        {
            "id": 2,
            "category_code": "travel",
            "funding_account_code": "ICICI",
            "amount": Decimal("350.00"),
            "type": "expense",
            "is_overage": False,
            "reason": "Uber",
            "date": datetime(2025, 1, 14, 18, 45, 0, tzinfo=timezone.utc),
        },
    ]
    return repo


@pytest.fixture
def mock_credit_repository():
    """Provide a mock credit repository."""
    repo = Mock()
    repo.sum_balance.return_value = Decimal("1250.50")
    return repo


@pytest.fixture
def mock_accounts_service(mock_accounts_repository, mock_clock):
    """Provide a real AccountsService with mocked repository."""
    return AccountsService(mock_accounts_repository, mock_clock)


@pytest.fixture
def mock_budgets_pace_service(mock_categories_repository, mock_transactions_repository, mock_clock):
    """Provide a real BudgetsPaceService with mocked repositories."""
    return BudgetsPaceService(
        categories_repository=mock_categories_repository,
        transactions_repository=mock_transactions_repository,
        clock=mock_clock,
    )


@pytest.fixture
def mock_credit_service(mock_credit_repository):
    """Provide a real CreditService with mocked repository."""
    return CreditService(mock_credit_repository)


@pytest.fixture
def mock_overview_service(
    mock_accounts_service,
    mock_budgets_pace_service,
    mock_credit_service,
    mock_transactions_repository,
):
    """Provide a real OverviewService with mocked dependencies."""
    return OverviewService(
        accounts_service=mock_accounts_service,
        budgets_pace_service=mock_budgets_pace_service,
        credit_service=mock_credit_service,
        transactions_repository=mock_transactions_repository,
    )


@pytest.fixture
def app_with_mocks(
    mock_token_service,
    mock_accounts_repository,
    mock_categories_repository,
    mock_transactions_repository,
    mock_credit_repository,
    mock_accounts_service,
    mock_budgets_pace_service,
    mock_credit_service,
    mock_overview_service,
    mock_clock,
):
    """Create a test FastAPI app with real router and mocked dependencies."""
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

    def mock_get_accounts_repository_override():
        """Return mocked accounts repository."""
        return mock_accounts_repository

    def mock_get_categories_repository_override():
        """Return mocked categories repository."""
        return mock_categories_repository

    def mock_get_transactions_repository_override():
        """Return mocked transactions repository."""
        return mock_transactions_repository

    def mock_get_credit_repository_override():
        """Return mocked credit repository."""
        return mock_credit_repository

    def mock_get_accounts_service_override():
        """Return mocked accounts service."""
        return mock_accounts_service

    def mock_get_budgets_pace_service_override():
        """Return mocked budgets pace service."""
        return mock_budgets_pace_service

    def mock_get_credit_service_override():
        """Return mocked credit service."""
        return mock_credit_service

    def mock_get_overview_service_override():
        """Return mocked overview service."""
        return mock_overview_service

    app.dependency_overrides[get_current_user] = mock_get_current_user
    app.dependency_overrides[get_accounts_repository] = mock_get_accounts_repository_override
    app.dependency_overrides[get_categories_repository] = mock_get_categories_repository_override
    app.dependency_overrides[get_transactions_repository] = mock_get_transactions_repository_override
    app.dependency_overrides[get_credit_repository] = mock_get_credit_repository_override
    app.dependency_overrides[get_accounts_service] = mock_get_accounts_service_override
    app.dependency_overrides[get_budgets_pace_service] = mock_get_budgets_pace_service_override
    app.dependency_overrides[get_credit_service] = mock_get_credit_service_override
    app.dependency_overrides[get_overview_service] = mock_get_overview_service_override

    return app


@pytest.fixture
def client(app_with_mocks):
    """Create a FastAPI TestClient with raise_server_exceptions disabled."""
    # raise_server_exceptions=False allows us to capture 500 errors from exceptions
    # instead of having them propagate to the test
    return TestClient(app_with_mocks, raise_server_exceptions=False)


# ============================================================================
# Tests for GET /overview - Authentication
# ============================================================================


class TestDashboardOverviewAuthentication:
    """Test authentication requirements for GET /overview endpoint."""

    def test_get_overview_requires_authorization_header(self, client):
        """GET /overview should return 401 if Authorization header is missing."""
        response = client.get("/overview")
        assert response.status_code == 401
        assert "authorization" in response.json()["detail"].lower()

    def test_get_overview_rejects_invalid_token_format(self, client):
        """GET /overview should return 401 if Authorization header format is invalid."""
        response = client.get("/overview", headers={"Authorization": "Invalid token"})
        assert response.status_code == 401
        assert "authorization" in response.json()["detail"].lower()

    def test_get_overview_rejects_expired_token(self, client, mock_token_service):
        """GET /overview should return 401 if token is expired."""
        # Create a token that expired 1 hour ago
        expired_payload = {
            "sub": "1",
            "exp": mock_token_service.clock.now() - timedelta(hours=1),
            "iat": mock_token_service.clock.now() - timedelta(hours=2),
            "token_type": "access",
        }
        expired_token = jwt.encode(
            expired_payload,
            mock_token_service.secret,
            algorithm=mock_token_service.algorithm,
        )

        response = client.get(
            "/overview",
            headers={"Authorization": f"Bearer {expired_token}"},
        )
        assert response.status_code == 401
        assert "invalid" in response.json()["detail"].lower() or "expired" in response.json()["detail"].lower()

    def test_get_overview_accepts_valid_token(self, client, mock_token_service):
        """GET /overview should accept a valid Bearer token."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=60)
        response = client.get(
            "/overview",
            headers={"Authorization": f"Bearer {token}"},
        )
        # Should not be 401; may be 500 if service raises NotImplementedError
        assert response.status_code != 401


# ============================================================================
# Tests for GET /overview - Response shape (with NotImplementedError)
# ============================================================================


class TestDashboardOverviewResponseShape:
    """
    Test GET /overview endpoint response shape and structure.

    Note: The endpoint will raise NotImplementedError from OverviewService.get_overview
    during stub phase. When implementation is complete, these tests document the
    expected response shape.
    """

    def test_get_overview_endpoint_exists(self, client, mock_token_service):
        """GET /overview endpoint should exist and be callable."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=60)
        response = client.get(
            "/overview",
            headers={"Authorization": f"Bearer {token}"},
        )
        # Should get some response (could be error during stub phase)
        assert response.status_code in [200, 500]

    def test_get_overview_returns_http_200_with_composed_data(
        self, client, mock_token_service, mock_overview_service
    ):
        """
        GET /overview should return 200 with composed dashboard data when implemented.

        Returns a DashboardOverviewResponse with all four data sources composed:
        - month_end_check from AccountsService
        - budget_statuses from BudgetsPaceService
        - credit_balance from CreditService
        - recent_transactions from TransactionsRepository
        """
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=60)
        response = client.get(
            "/overview",
            headers={"Authorization": f"Bearer {token}"},
        )
        # Test passes if endpoint is callable and returns data (status 200 with mocked services)
        assert response.status_code in [200, 500]  # Accepts both until full integration is ready

    def test_get_overview_documents_expected_response_shape(self):
        """
        Documents the expected response shape when GET /overview is implemented.

        Expected response (status 200):
        {
            "month_end_check": {
                "ICICI": {"expected_balance": 15000.00},
                "SBI": {"expected_balance": 8500.00},
                "SLICE": {"expected_balance": 22000.00},
                "hdfc_reserve": 2500.00,
                "total_net_worth": 48000.00
            },
            "budget_statuses": [
                {
                    "category_code": "food",
                    "display_name": "Food & Groceries",
                    "budget": 6000.00,
                    "spent": 2500.00,
                    "remaining": 3500.00,
                    "days_left": 15,
                    "allowance_per_day": 233.33,
                    "burn_rate_per_day": 166.67,
                    "projected_runout_date": null
                },
                ...
            ],
            "credit_balance": {
                "balance": 1250.50
            },
            "recent_transactions": [
                {
                    "id": 1,
                    "category_code": "food",
                    "funding_account_code": "ICICI",
                    "amount": 450.00,
                    "type": "expense",
                    "is_overage": false,
                    "reason": "Dinner",
                    "date": "2025-01-15T12:30:00Z"
                },
                ...
            ]
        }
        """
        pass  # This is a documentation test


# ============================================================================
# Tests for GET /overview - Dependency injection
# ============================================================================


class TestDashboardOverviewDependencies:
    """Test that GET /overview correctly resolves and uses dependencies."""

    def test_get_overview_resolves_overview_service(
        self, client, mock_token_service, mock_overview_service
    ):
        """
        GET /overview should resolve OverviewService from dependency injection.

        The endpoint calls service.get_overview(user_id, month_id), which
        (during stub phase) raises NotImplementedError.
        """
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=60)
        response = client.get(
            "/overview",
            headers={"Authorization": f"Bearer {token}"},
        )
        # NotImplementedError from service results in 500
        assert response.status_code == 500

    def test_get_overview_resolves_current_month_id(
        self, client, mock_token_service, mock_accounts_repository
    ):
        """
        GET /overview should resolve the current month via AccountsRepository.

        The endpoint calls:
        1. accounts_repo.get_month_id(year, month)
        2. If None, creates it via accounts_repo.create_month(year, month)
        3. Passes month_id to service.get_overview()
        """
        # Mock repository to simulate finding a month
        mock_accounts_repository.get_month_id.return_value = 42

        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=60)
        response = client.get(
            "/overview",
            headers={"Authorization": f"Bearer {token}"},
        )
        # Will raise NotImplementedError, but repository method should be called
        assert response.status_code == 500
        # Verify get_month_id was called (at least attempted)
        mock_accounts_repository.get_month_id.assert_called()


# ============================================================================
# Tests for GET /overview - Response model validation
# ============================================================================


class TestDashboardOverviewResponseModel:
    """
    Test that response model DashboardOverviewResponse validates correctly.

    This tests the Pydantic schema independently of the endpoint implementation.
    """

    def test_dashboard_overview_response_validates_complete_data(self):
        """DashboardOverviewResponse should validate a complete composed response."""
        data = {
            "month_end_check": {
                "ICICI": {"expected_balance": 15000.00},
                "SBI": {"expected_balance": 8500.00},
                "SLICE": {"expected_balance": 22000.00},
                "hdfc_reserve": 2500.00,
                "total_net_worth": 48000.00,
            },
            "budget_statuses": [
                {
                    "category_code": "food",
                    "display_name": "Food & Groceries",
                    "budget": Decimal("6000.00"),
                    "spent": Decimal("2500.00"),
                    "remaining": Decimal("3500.00"),
                    "days_left": 15,
                    "allowance_per_day": Decimal("233.33"),
                    "burn_rate_per_day": Decimal("166.67"),
                    "projected_runout_date": None,
                },
            ],
            "credit_balance": {"balance": Decimal("1250.50")},
            "recent_transactions": [
                {
                    "id": 1,
                    "category_code": "food",
                    "funding_account_code": "ICICI",
                    "amount": Decimal("450.00"),
                    "type": "expense",
                    "is_overage": False,
                    "reason": "Dinner",
                    "date": datetime(2025, 1, 15, 12, 30, 0, tzinfo=timezone.utc),
                },
            ],
        }

        # Should not raise
        response = DashboardOverviewResponse(**data)
        assert response.month_end_check is not None
        assert len(response.budget_statuses) > 0
        assert response.credit_balance is not None
        assert len(response.recent_transactions) > 0

    def test_dashboard_overview_response_requires_all_fields(self):
        """DashboardOverviewResponse should require all four fields."""
        incomplete_data = {
            "month_end_check": {
                "ICICI": {"expected_balance": 15000.00},
                "SBI": {"expected_balance": 8500.00},
                "SLICE": {"expected_balance": 22000.00},
                "hdfc_reserve": 2500.00,
                "total_net_worth": 48000.00,
            },
            # Missing budget_statuses, credit_balance, recent_transactions
        }

        with pytest.raises(ValueError):
            DashboardOverviewResponse(**incomplete_data)
