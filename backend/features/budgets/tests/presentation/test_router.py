"""
Integration tests for budgets API endpoints.

Uses FastAPI TestClient with dependency_overrides to mock dependencies.
Tests endpoint routing, authentication, request validation, response shape,
and HTTP status codes.
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
from features.auth.presentation.router import get_current_user
from features.budgets.business.pace_service import BudgetsPaceService
from features.budgets.presentation.router import router, get_pace_service
from features.budgets.presentation.schemas import (
    BudgetsStatusResponse,
    CategoryStatus,
)
from features.categories.data.repository import CategoriesRepository
from features.transactions.data.repository import TransactionsRepository


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
def mock_categories_repository():
    """Provide a mock categories repository."""
    repo = Mock(spec=CategoriesRepository)
    return repo


@pytest.fixture
def mock_transactions_repository():
    """Provide a mock transactions repository."""
    repo = Mock(spec=TransactionsRepository)
    return repo


@pytest.fixture
def mock_pace_service(mock_categories_repository, mock_transactions_repository):
    """Provide a mock pace service that returns sample data."""
    service = Mock(spec=BudgetsPaceService)

    def mock_get_all_category_statuses(user_id, month_id):
        """Return sample category status data."""
        return [
            {
                "category_code": "food",
                "display_name": "Food & Groceries",
                "budget": Decimal("6000"),
                "spent": Decimal("2000"),
                "remaining": Decimal("4000"),
                "days_left": 16,
                "allowance_per_day": Decimal("250"),
                "burn_rate_per_day": Decimal("133.33"),
                "projected_runout_date": None,
            },
            {
                "category_code": "rent",
                "display_name": "Rent",
                "budget": Decimal("17000"),
                "spent": Decimal("0"),
                "remaining": Decimal("17000"),
                "days_left": 16,
                "allowance_per_day": Decimal("1062.50"),
                "burn_rate_per_day": Decimal("0"),
                "projected_runout_date": None,
            },
        ]

    service.get_all_category_statuses.side_effect = mock_get_all_category_statuses
    return service


@pytest.fixture
def app_with_mocks(mock_token_service, mock_pace_service):
    """Create a test FastAPI app with real router and mocked dependencies."""
    app = FastAPI()
    # Mount with the real prefix used in main.py so a route-path regression
    # (e.g. frontend calling the wrong URL) would be caught here.
    app.include_router(router, prefix="/budgets")

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

    def mock_get_pace_service():
        """Return mocked pace service."""
        return mock_pace_service

    app.dependency_overrides[get_current_user] = mock_get_current_user
    app.dependency_overrides[get_pace_service] = mock_get_pace_service

    return app


@pytest.fixture
def client(app_with_mocks):
    """Create a FastAPI TestClient."""
    return TestClient(app_with_mocks)


# ============================================================================
# Tests for GET /status (Authentication)
# ============================================================================


class TestBudgetStatusAuthentication:
    """Test authentication requirements on GET /status endpoint."""

    def test_status_without_token_returns_401(self, client):
        """GET /status without Authorization header should return 401."""
        response = client.get("/budgets/status")
        assert response.status_code == 401
        assert "Missing authorization header" in response.json()["detail"]

    def test_status_with_invalid_bearer_format_returns_401(self, client):
        """GET /status with malformed Bearer header should return 401."""
        response = client.get("/budgets/status", headers={"Authorization": "InvalidBearer sometoken"})
        assert response.status_code == 401
        assert "authorization header format" in response.json()["detail"].lower()

    def test_status_with_invalid_token_returns_401(self, client):
        """GET /status with invalid token should return 401."""
        response = client.get(
            "/budgets/status", headers={"Authorization": "Bearer invalid.token.here"}
        )
        assert response.status_code == 401
        assert "Invalid or expired token" in response.json()["detail"]

    def test_status_with_valid_token_returns_200(self, client, mock_token_service):
        """GET /status with valid token should return 200 OK."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200

    def test_status_bearer_token_required_format(self, client):
        """Authorization header must use Bearer token format, not Basic."""
        response = client.get(
            "/budgets/status", headers={"Authorization": "Basic username:password"}
        )
        assert response.status_code == 401


# ============================================================================
# Tests for GET /status (Response Shape and Content)
# ============================================================================


class TestBudgetStatusResponseShape:
    """Test response shape and structure of GET /status."""

    def test_status_response_is_json(self, client, mock_token_service):
        """Response should be valid JSON."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        assert response.status_code == 200
        assert response.headers["content-type"] == "application/json"

    def test_status_response_has_categories_field(self, client, mock_token_service):
        """Response should have a 'categories' field."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        assert "categories" in data

    def test_status_categories_is_list(self, client, mock_token_service):
        """The 'categories' field should be a list."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        assert isinstance(data["categories"], list)

    def test_status_categories_not_empty(self, client, mock_token_service):
        """The categories list should not be empty (with mock data)."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        assert len(data["categories"]) > 0

    def test_status_response_matches_budgets_status_response_schema(
        self, client, mock_token_service
    ):
        """Response should match BudgetsStatusResponse schema."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        # Should be parseable as BudgetsStatusResponse
        try:
            parsed = BudgetsStatusResponse(**data)
            assert parsed is not None
        except Exception as e:
            pytest.fail(f"Response does not match schema: {e}")


# ============================================================================
# Tests for GET /status (Category Data)
# ============================================================================


class TestBudgetStatusCategoryData:
    """Test category data in GET /status response."""

    def test_status_category_includes_all_required_fields(
        self, client, mock_token_service
    ):
        """Each category should include all required fields."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        category = data["categories"][0]

        required_fields = [
            "category_code",
            "display_name",
            "budget",
            "spent",
            "remaining",
            "days_left",
            "allowance_per_day",
            "burn_rate_per_day",
            "projected_runout_date",
        ]

        for field in required_fields:
            assert field in category, f"Missing field: {field}"

    def test_status_category_code_is_string(self, client, mock_token_service):
        """category_code should be a string."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        category = data["categories"][0]
        assert isinstance(category["category_code"], str)
        assert len(category["category_code"]) > 0

    def test_status_display_name_is_string(self, client, mock_token_service):
        """display_name should be a string."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        category = data["categories"][0]
        assert isinstance(category["display_name"], str)
        assert len(category["display_name"]) > 0

    def test_status_budget_is_numeric(self, client, mock_token_service):
        """budget should be numeric (int or float)."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        category = data["categories"][0]
        assert isinstance(category["budget"], (int, float))
        assert category["budget"] > 0

    def test_status_spent_is_numeric(self, client, mock_token_service):
        """spent should be numeric."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        category = data["categories"][0]
        assert isinstance(category["spent"], (int, float))
        assert category["spent"] >= 0

    def test_status_remaining_is_numeric(self, client, mock_token_service):
        """remaining should be numeric."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        category = data["categories"][0]
        assert isinstance(category["remaining"], (int, float))
        assert category["remaining"] >= 0

    def test_status_days_left_is_integer(self, client, mock_token_service):
        """days_left should be an integer."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        category = data["categories"][0]
        assert isinstance(category["days_left"], int)
        assert category["days_left"] > 0

    def test_status_allowance_per_day_is_numeric(self, client, mock_token_service):
        """allowance_per_day should be numeric."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        category = data["categories"][0]
        assert isinstance(category["allowance_per_day"], (int, float))
        assert category["allowance_per_day"] >= 0

    def test_status_burn_rate_per_day_is_numeric(self, client, mock_token_service):
        """burn_rate_per_day should be numeric."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        category = data["categories"][0]
        assert isinstance(category["burn_rate_per_day"], (int, float))
        assert category["burn_rate_per_day"] >= 0

    def test_status_projected_runout_date_is_date_or_null(self, client, mock_token_service):
        """projected_runout_date should be date string or null."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        category = data["categories"][0]
        # Should be None (null in JSON) or a date string
        assert category["projected_runout_date"] is None or isinstance(
            category["projected_runout_date"], str
        )

    def test_status_includes_food_category(self, client, mock_token_service):
        """Response should include the food category."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        codes = [c["category_code"] for c in data["categories"]]
        assert "food" in codes

    def test_status_includes_rent_category(self, client, mock_token_service):
        """Response should include the rent category."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        codes = [c["category_code"] for c in data["categories"]]
        assert "rent" in codes

    def test_status_food_has_correct_budget(self, client, mock_token_service):
        """Food category should have budget of 6000."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        food = next(c for c in data["categories"] if c["category_code"] == "food")
        assert food["budget"] == 6000

    def test_status_rent_has_correct_budget(self, client, mock_token_service):
        """Rent category should have budget of 17000."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        rent = next(c for c in data["categories"] if c["category_code"] == "rent")
        assert rent["budget"] == 17000

    def test_status_food_has_some_spend(self, client, mock_token_service):
        """Food category should show some spend."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        food = next(c for c in data["categories"] if c["category_code"] == "food")
        assert food["spent"] > 0

    def test_status_rent_has_no_spend(self, client, mock_token_service):
        """Rent category should show no spend."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        rent = next(c for c in data["categories"] if c["category_code"] == "rent")
        assert rent["spent"] == 0

    def test_status_remaining_equals_budget_minus_spent(
        self, client, mock_token_service
    ):
        """remaining should equal budget - spent."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        for category in data["categories"]:
            # Allow small floating point error
            expected_remaining = category["budget"] - category["spent"]
            assert abs(category["remaining"] - expected_remaining) < 0.01


# ============================================================================
# Tests: Multiple Users/Sessions
# ============================================================================


class TestMultipleUsersAndSessions:
    """Test endpoint behavior with different user tokens."""

    def test_different_users_have_different_tokens(
        self, client, mock_token_service
    ):
        """Different user IDs should produce different tokens."""
        token1 = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        token2 = mock_token_service.create_access_token(user_id=2, expires_in_minutes=30)

        assert token1 != token2

    def test_both_users_can_access_status_endpoint(
        self, client, mock_token_service
    ):
        """Both users should be able to access the endpoint."""
        token1 = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        token2 = mock_token_service.create_access_token(user_id=2, expires_in_minutes=30)

        response1 = client.get("/budgets/status", headers={"Authorization": f"Bearer {token1}"})
        response2 = client.get("/budgets/status", headers={"Authorization": f"Bearer {token2}"})

        assert response1.status_code == 200
        assert response2.status_code == 200

    def test_expired_token_returns_401(self, client, mock_token_service):
        """An expired token should return 401."""
        # Create a token that expired in the past
        past_time = mock_token_service.clock.now() - timedelta(hours=1)
        token_service_past = MockTokenService(
            settings.JWT_SECRET, settings.JWT_ALGORITHM,
            type('FakeClock', (), {'now': lambda: past_time})()
        )

        # Create token with past time (it will have exp in the past too)
        payload = {
            "sub": "1",
            "exp": past_time + timedelta(minutes=30),  # Still in the past
            "iat": past_time,
            "token_type": "access",
        }
        expired_token = jwt.encode(
            payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM
        )

        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {expired_token}"})
        assert response.status_code == 401


# ============================================================================
# Tests: Endpoint Routing
# ============================================================================


class TestEndpointRouting:
    """Test that the endpoint is properly configured."""

    def test_status_endpoint_exists(self, client, mock_token_service):
        """GET /status should exist and respond."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        # Should not return 404 (not found for route)
        assert response.status_code != 404

    def test_wrong_method_returns_405(self, client, mock_token_service):
        """POST /status should return 405 Method Not Allowed."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.post("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        assert response.status_code == 405

    def test_wrong_path_returns_404(self, client, mock_token_service):
        """GET /nonexistent should return 404."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/nonexistent", headers={"Authorization": f"Bearer {token}"})

        assert response.status_code == 404


# ============================================================================
# Tests: Edge Cases
# ============================================================================


class TestEdgeCases:
    """Test edge cases and error conditions."""

    def test_empty_authorization_header_returns_401(self, client):
        """Authorization header with no value should return 401."""
        response = client.get("/budgets/status", headers={"Authorization": ""})
        assert response.status_code == 401

    def test_authorization_header_with_only_bearer_returns_401(self, client):
        """Authorization: Bearer (with no token) should return 401."""
        response = client.get("/budgets/status", headers={"Authorization": "Bearer "})
        assert response.status_code == 401

    def test_status_response_content_type_is_json(self, client, mock_token_service):
        """Response content type should be application/json."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        assert "application/json" in response.headers["content-type"]

    def test_status_response_no_html_injection(self, client, mock_token_service):
        """Response should be JSON, not HTML (no injection)."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/budgets/status", headers={"Authorization": f"Bearer {token}"})

        # Should be able to parse as JSON without error
        data = response.json()
        assert isinstance(data, dict)
