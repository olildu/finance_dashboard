"""
Integration tests for categories data layer (repository).

Tests database access patterns against real seeded data using db_conn fixture.
Verifies categories list query with budget_envelope and account joins.
"""

from decimal import Decimal

import pytest

from features.categories.data.repository import CategoriesRepository


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def repository(db_conn):
    """Provide a CategoriesRepository with a database connection."""
    return CategoriesRepository(db_conn)


# ============================================================================
# Tests: Get all active categories with envelopes
# ============================================================================


class TestGetAllActiveCategoriesWithEnvelopes:
    """Test get_all_active_categories_with_envelopes query against seeded data."""

    def test_get_all_active_categories_returns_list(self, repository):
        """get_all_active_categories_with_envelopes should return a list."""
        categories = repository.get_all_active_categories_with_envelopes()
        assert isinstance(categories, list)

    def test_get_all_active_categories_returns_seven_categories(self, repository):
        """Seeded data includes 7 active categories."""
        categories = repository.get_all_active_categories_with_envelopes()
        assert len(categories) == 7

    def test_get_all_active_categories_includes_food(self, repository):
        """Seeded categories include food."""
        categories = repository.get_all_active_categories_with_envelopes()
        codes = [cat["code"] for cat in categories]
        assert "food" in codes

    def test_get_all_active_categories_includes_rent(self, repository):
        """Seeded categories include rent."""
        categories = repository.get_all_active_categories_with_envelopes()
        codes = [cat["code"] for cat in categories]
        assert "rent" in codes

    def test_get_all_active_categories_includes_electricity(self, repository):
        """Seeded categories include electricity."""
        categories = repository.get_all_active_categories_with_envelopes()
        codes = [cat["code"] for cat in categories]
        assert "electricity" in codes

    def test_get_all_active_categories_includes_phone_internet(self, repository):
        """Seeded categories include phone_internet."""
        categories = repository.get_all_active_categories_with_envelopes()
        codes = [cat["code"] for cat in categories]
        assert "phone_internet" in codes

    def test_get_all_active_categories_includes_travel(self, repository):
        """Seeded categories include travel."""
        categories = repository.get_all_active_categories_with_envelopes()
        codes = [cat["code"] for cat in categories]
        assert "travel" in codes

    def test_get_all_active_categories_includes_party_outside(self, repository):
        """Seeded categories include party_outside."""
        categories = repository.get_all_active_categories_with_envelopes()
        codes = [cat["code"] for cat in categories]
        assert "party_outside" in codes

    def test_get_all_active_categories_includes_misc(self, repository):
        """Seeded categories include misc."""
        categories = repository.get_all_active_categories_with_envelopes()
        codes = [cat["code"] for cat in categories]
        assert "misc" in codes

    def test_get_all_active_categories_has_required_fields(self, repository):
        """Each category should have id, code, display_name, envelope info, account info."""
        categories = repository.get_all_active_categories_with_envelopes()
        for cat in categories:
            # Category fields
            assert "id" in cat
            assert "code" in cat
            assert "display_name" in cat
            assert "is_active" in cat
            # Envelope fields
            assert "envelope_id" in cat
            assert "envelope_name" in cat
            assert "monthly_amount" in cat
            # Account fields
            assert "account_code" in cat

    def test_get_all_active_categories_ordered_by_id(self, repository):
        """Categories should be returned in order by id."""
        categories = repository.get_all_active_categories_with_envelopes()
        ids = [cat["id"] for cat in categories]
        assert ids == sorted(ids)

    def test_get_all_active_categories_food_has_correct_envelope(self, repository):
        """Food category should be mapped to Food envelope."""
        categories = repository.get_all_active_categories_with_envelopes()
        food = next(cat for cat in categories if cat["code"] == "food")

        assert food["envelope_name"] == "Food"
        assert food["monthly_amount"] == Decimal("6000.00")
        assert food["account_code"] == "ICICI"

    def test_get_all_active_categories_rent_has_correct_envelope(self, repository):
        """Rent category should be mapped to Rent envelope."""
        categories = repository.get_all_active_categories_with_envelopes()
        rent = next(cat for cat in categories if cat["code"] == "rent")

        assert rent["envelope_name"] == "Rent"
        assert rent["monthly_amount"] == Decimal("17000.00")
        assert rent["account_code"] == "SLICE"

    def test_get_all_active_categories_electricity_has_correct_envelope(self, repository):
        """Electricity category should be mapped to Electricity envelope."""
        categories = repository.get_all_active_categories_with_envelopes()
        electricity = next(cat for cat in categories if cat["code"] == "electricity")

        assert electricity["envelope_name"] == "Electricity"
        assert electricity["monthly_amount"] == Decimal("100.00")
        assert electricity["account_code"] == "SLICE"

    def test_get_all_active_categories_phone_internet_has_correct_envelope(self, repository):
        """Phone & Internet category should be mapped to PhoneInternet envelope."""
        categories = repository.get_all_active_categories_with_envelopes()
        phone = next(cat for cat in categories if cat["code"] == "phone_internet")

        assert phone["envelope_name"] == "PhoneInternet"
        assert phone["monthly_amount"] == Decimal("300.00")
        assert phone["account_code"] == "SLICE"

    def test_get_all_active_categories_misc_has_correct_envelope(self, repository):
        """Misc category should be mapped to Misc envelope."""
        categories = repository.get_all_active_categories_with_envelopes()
        misc = next(cat for cat in categories if cat["code"] == "misc")

        assert misc["envelope_name"] == "Misc"
        assert misc["monthly_amount"] == Decimal("5000.00")
        assert misc["account_code"] == "ICICI"

    def test_get_all_active_categories_travel_has_correct_envelope(self, repository):
        """Travel category should be mapped to PartyOutsideTravel envelope."""
        categories = repository.get_all_active_categories_with_envelopes()
        travel = next(cat for cat in categories if cat["code"] == "travel")

        assert travel["envelope_name"] == "PartyOutsideTravel"
        assert travel["monthly_amount"] == Decimal("4000.00")
        assert travel["account_code"] == "SBI"

    def test_get_all_active_categories_party_outside_has_correct_envelope(self, repository):
        """Party/Dining Out category should be mapped to PartyOutsideTravel envelope."""
        categories = repository.get_all_active_categories_with_envelopes()
        party = next(cat for cat in categories if cat["code"] == "party_outside")

        assert party["envelope_name"] == "PartyOutsideTravel"
        assert party["monthly_amount"] == Decimal("4000.00")
        assert party["account_code"] == "SBI"

    def test_get_all_active_categories_travel_and_party_outside_share_same_envelope(self, repository):
        """Travel and party_outside categories should both map to PartyOutsideTravel envelope."""
        categories = repository.get_all_active_categories_with_envelopes()
        travel = next(cat for cat in categories if cat["code"] == "travel")
        party = next(cat for cat in categories if cat["code"] == "party_outside")

        # Both should have identical envelope and account info
        assert travel["envelope_id"] == party["envelope_id"]
        assert travel["envelope_name"] == party["envelope_name"] == "PartyOutsideTravel"
        assert travel["monthly_amount"] == party["monthly_amount"] == Decimal("4000.00")
        assert travel["account_code"] == party["account_code"] == "SBI"

    def test_get_all_active_categories_envelope_monthly_amounts_are_decimal(self, repository):
        """All monthly_amount values should be Decimal."""
        categories = repository.get_all_active_categories_with_envelopes()
        for cat in categories:
            assert isinstance(cat["monthly_amount"], Decimal)


# ============================================================================
# Tests: Get category by code
# ============================================================================


class TestGetCategoryByCode:
    """Test get_category_by_code query against seeded data."""

    def test_get_category_by_code_returns_dict_or_none(self, repository):
        """get_category_by_code should return dict or None."""
        result = repository.get_category_by_code("food")
        assert result is None or isinstance(result, dict)

    def test_get_category_by_code_finds_food(self, repository):
        """Should find food category."""
        cat = repository.get_category_by_code("food")
        assert cat is not None
        assert cat["code"] == "food"

    def test_get_category_by_code_returns_none_for_nonexistent(self, repository):
        """Should return None for nonexistent category."""
        cat = repository.get_category_by_code("nonexistent")
        assert cat is None

    def test_get_category_by_code_food_has_correct_envelope(self, repository):
        """Food category query should include envelope info."""
        cat = repository.get_category_by_code("food")
        assert cat["envelope_name"] == "Food"
        assert cat["monthly_amount"] == Decimal("6000.00")
        assert cat["account_code"] == "ICICI"

    def test_get_category_by_code_rent_has_correct_envelope(self, repository):
        """Rent category query should include envelope info."""
        cat = repository.get_category_by_code("rent")
        assert cat["envelope_name"] == "Rent"
        assert cat["monthly_amount"] == Decimal("17000.00")
        assert cat["account_code"] == "SLICE"

    def test_get_category_by_code_travel_has_correct_envelope(self, repository):
        """Travel category query should include envelope info."""
        cat = repository.get_category_by_code("travel")
        assert cat["envelope_name"] == "PartyOutsideTravel"
        assert cat["monthly_amount"] == Decimal("4000.00")
        assert cat["account_code"] == "SBI"

    def test_get_category_by_code_party_outside_has_correct_envelope(self, repository):
        """Party/Dining Out category query should include envelope info."""
        cat = repository.get_category_by_code("party_outside")
        assert cat["envelope_name"] == "PartyOutsideTravel"
        assert cat["monthly_amount"] == Decimal("4000.00")
        assert cat["account_code"] == "SBI"


# ============================================================================
# Tests: Get categories by envelope
# ============================================================================


class TestGetCategoriesByEnvelopeId:
    """Test get_categories_by_envelope_id query against seeded data."""

    def test_get_categories_by_envelope_returns_list(self, repository):
        """get_categories_by_envelope_id should return a list."""
        # Food envelope_id is 1
        result = repository.get_categories_by_envelope_id(1)
        assert isinstance(result, list)

    def test_get_categories_by_envelope_food_returns_one(self, repository):
        """Food envelope (id=1) should have 1 category."""
        # Food envelope_id is 1
        categories = repository.get_categories_by_envelope_id(1)
        assert len(categories) == 1
        assert categories[0]["code"] == "food"

    def test_get_categories_by_envelope_party_outside_travel_returns_two(self, repository):
        """PartyOutsideTravel envelope (id=2) should have 2 categories (travel, party_outside)."""
        # PartyOutsideTravel envelope_id is 2
        categories = repository.get_categories_by_envelope_id(2)
        assert len(categories) == 2

        codes = [cat["code"] for cat in categories]
        assert "travel" in codes
        assert "party_outside" in codes

    def test_get_categories_by_envelope_party_outside_travel_both_map_correctly(self, repository):
        """Travel and party_outside both should map to PartyOutsideTravel envelope with correct values."""
        # PartyOutsideTravel envelope_id is 2
        categories = repository.get_categories_by_envelope_id(2)

        for cat in categories:
            assert cat["envelope_name"] == "PartyOutsideTravel"
            assert cat["monthly_amount"] == Decimal("4000.00")
            assert cat["account_code"] == "SBI"

    def test_get_categories_by_envelope_rent_returns_one(self, repository):
        """Rent envelope (id=3) should have 1 category."""
        # Rent envelope_id is 3
        categories = repository.get_categories_by_envelope_id(3)
        assert len(categories) == 1
        assert categories[0]["code"] == "rent"

    def test_get_categories_by_envelope_electricity_returns_one(self, repository):
        """Electricity envelope (id=4) should have 1 category."""
        # Electricity envelope_id is 4
        categories = repository.get_categories_by_envelope_id(4)
        assert len(categories) == 1
        assert categories[0]["code"] == "electricity"

    def test_get_categories_by_envelope_phone_internet_returns_one(self, repository):
        """PhoneInternet envelope (id=5) should have 1 category."""
        # PhoneInternet envelope_id is 5
        categories = repository.get_categories_by_envelope_id(5)
        assert len(categories) == 1
        assert categories[0]["code"] == "phone_internet"

    def test_get_categories_by_envelope_misc_returns_one(self, repository):
        """Misc envelope (id=6) should have 1 category."""
        # Misc envelope_id is 6
        categories = repository.get_categories_by_envelope_id(6)
        assert len(categories) == 1
        assert categories[0]["code"] == "misc"

    def test_get_categories_by_envelope_nonexistent_returns_empty(self, repository):
        """Non-existent envelope should return empty list."""
        categories = repository.get_categories_by_envelope_id(999)
        assert len(categories) == 0

    def test_get_categories_by_envelope_ordered_by_id(self, repository):
        """Categories should be returned in order by id."""
        # PartyOutsideTravel envelope (id=2) has 2 categories
        categories = repository.get_categories_by_envelope_id(2)
        if len(categories) > 1:
            ids = [cat["id"] for cat in categories]
            assert ids == sorted(ids)
