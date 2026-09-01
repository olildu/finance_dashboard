"""
Integration tests for categories API endpoints.

Uses FastAPI TestClient with dependency_overrides to mock dependencies.
Tests GET /categories endpoint: authentication, response shape, budget_envelope joins,
and verification that travel and party_outside share the same envelope.
"""

from datetime import datetime, timedelta, timezone
from decimal import Decimal

import jwt
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from core.clock import Clock
from core.config import settings
from features.auth.business.security import TokenService
from features.auth.presentation.router import get_current_user
from features.categories.data.repository import CategoriesRepository
from features.categories.presentation.router import (
    router,
    get_categories_repository,
)


# ============================================================================
# Mock Clock for testing
# ============================================================================


class FrozenClock(Clock):
    """A mock Clock that returns a fixed time."""

    def __init__(self, frozen_time: datetime):
        self.frozen_time = frozen_time

    def now(self) -> datetime:
        return self.frozen_time


# ============================================================================
# Mock classes for testing
# ============================================================================


class MockCategoriesRepository:
    """Mock categories repository for testing."""

    def __init__(self):
        # Seeded data: 7 categories with their envelopes
        # Note: travel (id=5) and party_outside (id=6) both point to envelope_id=2 (PartyOutsideTravel)
        self.categories = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "envelope_id": 1,
                "is_active": True,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000.00"),
                "account_code": "ICICI",
            },
            {
                "id": 2,
                "code": "rent",
                "display_name": "Rent",
                "envelope_id": 3,
                "is_active": True,
                "envelope_name": "Rent",
                "monthly_amount": Decimal("17000.00"),
                "account_code": "SLICE",
            },
            {
                "id": 3,
                "code": "electricity",
                "display_name": "Electricity",
                "envelope_id": 4,
                "is_active": True,
                "envelope_name": "Electricity",
                "monthly_amount": Decimal("100.00"),
                "account_code": "SLICE",
            },
            {
                "id": 4,
                "code": "phone_internet",
                "display_name": "Phone & Internet",
                "envelope_id": 5,
                "is_active": True,
                "envelope_name": "PhoneInternet",
                "monthly_amount": Decimal("300.00"),
                "account_code": "SLICE",
            },
            {
                "id": 5,
                "code": "travel",
                "display_name": "Travel",
                "envelope_id": 2,
                "is_active": True,
                "envelope_name": "PartyOutsideTravel",
                "monthly_amount": Decimal("4000.00"),
                "account_code": "SBI",
            },
            {
                "id": 6,
                "code": "party_outside",
                "display_name": "Party/Dining Out",
                "envelope_id": 2,
                "is_active": True,
                "envelope_name": "PartyOutsideTravel",
                "monthly_amount": Decimal("4000.00"),
                "account_code": "SBI",
            },
            {
                "id": 7,
                "code": "misc",
                "display_name": "Miscellaneous",
                "envelope_id": 6,
                "is_active": True,
                "envelope_name": "Misc",
                "monthly_amount": Decimal("5000.00"),
                "account_code": "ICICI",
            },
        ]

    def get_all_active_categories_with_envelopes(self) -> list:
        """Get all active categories with their envelope and funding account info."""
        return self.categories


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def mock_categories_repository():
    """Provide a mock categories repository."""
    return MockCategoriesRepository()


@pytest.fixture
def mock_token_service():
    """Provide a TokenService for creating valid test tokens."""
    # Use current time for token creation to avoid expiry/iat issues
    # jwt.decode uses the actual system time, so we must align our token's
    # iat (issued at) and exp (expiry) claims with the real time
    current_time = datetime.now(timezone.utc)
    clock = FrozenClock(current_time)
    return TokenService(
        secret=settings.JWT_SECRET,
        algorithm=settings.JWT_ALGORITHM,
        clock=clock,
    )


@pytest.fixture
def client(mock_categories_repository, mock_token_service):
    """Create a FastAPI TestClient with overridden dependencies."""
    from fastapi import Header, HTTPException

    app = FastAPI()
    app.include_router(router)

    # Override repository dependency with mock
    app.dependency_overrides[get_categories_repository] = lambda: mock_categories_repository

    # Override token service dependency to use our mock token service
    # This ensures tokens created in tests can be validated
    from features.auth.presentation.router import get_token_service
    app.dependency_overrides[get_token_service] = lambda: mock_token_service

    # Override get_current_user to use our mock token service
    def mock_get_current_user_impl(authorization: str = Header(None)):
        """Extract and validate user_id from Bearer token using mock token service."""
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

    app.dependency_overrides[get_current_user] = mock_get_current_user_impl

    yield TestClient(app)

    # Clean up overrides
    app.dependency_overrides.clear()


# ============================================================================
# Tests for GET /categories
# ============================================================================


class TestListCategoriesEndpoint:
    """Test GET /categories endpoint."""

    def test_list_categories_without_token_returns_401(self, client):
        """GET /categories without Authorization header should return 401."""
        response = client.get("/categories")
        assert response.status_code == 401
        assert "Missing authorization header" in response.json()["detail"]

    def test_list_categories_with_invalid_bearer_format_returns_401(self, client):
        """GET /categories with malformed Bearer header should return 401."""
        response = client.get("/categories", headers={"Authorization": "InvalidBearer sometoken"})
        assert response.status_code == 401

    def test_list_categories_with_invalid_token_returns_401(self, client):
        """GET /categories with invalid token should return 401."""
        response = client.get("/categories", headers={"Authorization": "Bearer invalid.token.here"})
        assert response.status_code == 401

    def test_list_categories_with_valid_token_returns_200(self, client, mock_token_service):
        """GET /categories with valid token should return 200 OK."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 200

    def test_list_categories_returns_all_seven_categories(self, client, mock_token_service):
        """GET /categories should return all 7 seeded categories."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        assert len(data["categories"]) == 7

    def test_list_categories_returns_correct_category_fields(self, client, mock_token_service):
        """Each category should include code, display_name, and envelope."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        assert len(data["categories"]) > 0

        category = data["categories"][0]
        assert "code" in category
        assert "display_name" in category
        assert "envelope" in category

    def test_list_categories_envelope_has_required_fields(self, client, mock_token_service):
        """Each category's envelope should include name, monthly_amount, and account_code."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        category = data["categories"][0]
        envelope = category["envelope"]

        assert "name" in envelope
        assert "monthly_amount" in envelope
        assert "account_code" in envelope

    def test_list_categories_includes_food(self, client, mock_token_service):
        """Response should include food category."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        codes = [cat["code"] for cat in data["categories"]]
        assert "food" in codes

    def test_list_categories_includes_rent(self, client, mock_token_service):
        """Response should include rent category."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        codes = [cat["code"] for cat in data["categories"]]
        assert "rent" in codes

    def test_list_categories_includes_electricity(self, client, mock_token_service):
        """Response should include electricity category."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        codes = [cat["code"] for cat in data["categories"]]
        assert "electricity" in codes

    def test_list_categories_includes_phone_internet(self, client, mock_token_service):
        """Response should include phone_internet category."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        codes = [cat["code"] for cat in data["categories"]]
        assert "phone_internet" in codes

    def test_list_categories_includes_travel(self, client, mock_token_service):
        """Response should include travel category."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        codes = [cat["code"] for cat in data["categories"]]
        assert "travel" in codes

    def test_list_categories_includes_party_outside(self, client, mock_token_service):
        """Response should include party_outside category."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        codes = [cat["code"] for cat in data["categories"]]
        assert "party_outside" in codes

    def test_list_categories_includes_misc(self, client, mock_token_service):
        """Response should include misc category."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        codes = [cat["code"] for cat in data["categories"]]
        assert "misc" in codes

    def test_list_categories_food_has_correct_envelope(self, client, mock_token_service):
        """Food category should be mapped to Food envelope (6000, ICICI)."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        food = next(cat for cat in data["categories"] if cat["code"] == "food")

        assert food["envelope"]["name"] == "Food"
        assert food["envelope"]["monthly_amount"] == 6000.00
        assert food["envelope"]["account_code"] == "ICICI"

    def test_list_categories_rent_has_correct_envelope(self, client, mock_token_service):
        """Rent category should be mapped to Rent envelope (17000, SLICE)."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        rent = next(cat for cat in data["categories"] if cat["code"] == "rent")

        assert rent["envelope"]["name"] == "Rent"
        assert rent["envelope"]["monthly_amount"] == 17000.00
        assert rent["envelope"]["account_code"] == "SLICE"

    def test_list_categories_electricity_has_correct_envelope(self, client, mock_token_service):
        """Electricity category should be mapped to Electricity envelope (100, SLICE)."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        electricity = next(cat for cat in data["categories"] if cat["code"] == "electricity")

        assert electricity["envelope"]["name"] == "Electricity"
        assert electricity["envelope"]["monthly_amount"] == 100.00
        assert electricity["envelope"]["account_code"] == "SLICE"

    def test_list_categories_phone_internet_has_correct_envelope(self, client, mock_token_service):
        """Phone & Internet category should be mapped to PhoneInternet envelope (300, SLICE)."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        phone = next(cat for cat in data["categories"] if cat["code"] == "phone_internet")

        assert phone["envelope"]["name"] == "PhoneInternet"
        assert phone["envelope"]["monthly_amount"] == 300.00
        assert phone["envelope"]["account_code"] == "SLICE"

    def test_list_categories_misc_has_correct_envelope(self, client, mock_token_service):
        """Misc category should be mapped to Misc envelope (5000, ICICI)."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        misc = next(cat for cat in data["categories"] if cat["code"] == "misc")

        assert misc["envelope"]["name"] == "Misc"
        assert misc["envelope"]["monthly_amount"] == 5000.00
        assert misc["envelope"]["account_code"] == "ICICI"

    def test_list_categories_travel_and_party_outside_share_same_envelope(self, client, mock_token_service):
        """Travel and party_outside should both map to PartyOutsideTravel envelope."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        travel = next(cat for cat in data["categories"] if cat["code"] == "travel")
        party = next(cat for cat in data["categories"] if cat["code"] == "party_outside")

        # Both should have identical envelope data
        assert travel["envelope"]["name"] == party["envelope"]["name"] == "PartyOutsideTravel"
        assert travel["envelope"]["monthly_amount"] == party["envelope"]["monthly_amount"] == 4000.00
        assert travel["envelope"]["account_code"] == party["envelope"]["account_code"] == "SBI"

    def test_list_categories_travel_has_correct_envelope(self, client, mock_token_service):
        """Travel category should be mapped to PartyOutsideTravel envelope (4000, SBI)."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        travel = next(cat for cat in data["categories"] if cat["code"] == "travel")

        assert travel["envelope"]["name"] == "PartyOutsideTravel"
        assert travel["envelope"]["monthly_amount"] == 4000.00
        assert travel["envelope"]["account_code"] == "SBI"

    def test_list_categories_party_outside_has_correct_envelope(self, client, mock_token_service):
        """Party/Dining Out category should be mapped to PartyOutsideTravel envelope (4000, SBI)."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        party = next(cat for cat in data["categories"] if cat["code"] == "party_outside")

        assert party["envelope"]["name"] == "PartyOutsideTravel"
        assert party["envelope"]["monthly_amount"] == 4000.00
        assert party["envelope"]["account_code"] == "SBI"

    def test_list_categories_response_is_json(self, client, mock_token_service):
        """Response should be JSON with categories array."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        assert response.headers["content-type"] == "application/json"
        data = response.json()
        assert isinstance(data, dict)
        assert "categories" in data
        assert isinstance(data["categories"], list)

    def test_list_categories_envelope_monetary_values_are_floats(self, client, mock_token_service):
        """All monetary values (monthly_amount) should be floats."""
        token = mock_token_service.create_access_token(user_id=1, expires_in_minutes=30)
        response = client.get("/categories", headers={"Authorization": f"Bearer {token}"})

        data = response.json()
        for cat in data["categories"]:
            assert isinstance(cat["envelope"]["monthly_amount"], (int, float))
