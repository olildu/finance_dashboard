"""
Tests for BudgetsPaceService.

Tests the core business logic for computing budget pace metrics, burn rates,
and projected runout dates.
"""

import calendar
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from unittest.mock import Mock

import pytest

from features.budgets.business.pace_service import BudgetsPaceService
from features.categories.data.repository import CategoriesRepository
from features.transactions.data.repository import TransactionsRepository


# ============================================================================
# Test Fixtures
# ============================================================================


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
def pace_service(
    mock_categories_repository, mock_transactions_repository, frozen_clock
):
    """Provide a real BudgetsPaceService with mocked dependencies."""
    # Use frozen clock at Sept 15, 2025 (middle of 30-day month)
    clock = frozen_clock(datetime(2025, 9, 15, 12, 0, 0, tzinfo=timezone.utc))
    return BudgetsPaceService(
        mock_categories_repository, mock_transactions_repository, clock
    )


# ============================================================================
# Test: No Spend Yet (Balanced Budget)
# ============================================================================


class TestNoSpendYet:
    """Test category status when no spend has occurred."""

    def test_no_spend_returns_full_remaining_budget(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """When no spend, remaining should equal full budget."""
        # Set up mocks
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("0")
        )

        # Call the service
        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)

        # Verify structure
        assert isinstance(result, list)
        assert len(result) == 1

        category = result[0]
        assert category["spent"] == Decimal("0")
        assert category["remaining"] == Decimal("6000")

    def test_no_spend_allowance_equals_full_budget_divided_by_days_left(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """When no spend, allowance_per_day = budget / days_left."""
        # Sept 15 in 30-day month: days_left = 30 - 15 + 1 = 16
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("0")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        # Sept 15: days_left = 16
        assert category["days_left"] == 16
        # allowance_per_day = 6000 / 16 = 375
        expected_allowance = Decimal("6000") / Decimal("16")
        assert category["allowance_per_day"] == expected_allowance

    def test_no_spend_burn_rate_is_zero(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """When no spend, burn_rate_per_day should be 0."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("0")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        assert category["burn_rate_per_day"] == Decimal("0")

    def test_no_spend_projected_runout_date_is_none(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """When burn_rate is 0, projected_runout_date should be None."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("0")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        assert category["projected_runout_date"] is None


# ============================================================================
# Test: Spend Exactly Half by Midpoint
# ============================================================================


class TestHalfSpendByMidpoint:
    """Test category status when exactly half budget spent by midpoint."""

    def test_spend_half_budget_by_midpoint(
        self, pace_service, mock_categories_repository, mock_transactions_repository, frozen_clock
    ):
        """On day 15 of 30, if 3000 spent of 6000, burn rate is 3000/15 = 200/day."""
        # Sept 15 (day 15 of 30): spent 3000 of 6000
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("3000")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        # Verify spend and remaining
        assert category["spent"] == Decimal("3000")
        assert category["remaining"] == Decimal("3000")

        # Verify burn rate: 3000 spent / 15 days elapsed = 200 per day
        assert category["burn_rate_per_day"] == Decimal("200")

    def test_projected_runout_at_burn_rate_half_budget(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """On day 15 with 3000 spent, runout = Sept 1 + 6000/200 = Sept 31 (day 30)."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("3000")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        # Burn rate = 200/day
        # Runout = Sept 1 + (6000 / 200 days) = Sept 1 + 30 = Oct 1 (off by one, runout on last day)
        # Actually: projected_runout_date = month_start + timedelta(days=budget/burn_rate)
        # = Sept 1 + 30 days = Oct 1
        # But we want to verify it's around the end of the month
        assert category["projected_runout_date"] is not None
        runout_date = category["projected_runout_date"]
        # Should be Oct 1 (month_start + 30 days)
        assert runout_date.month == 10
        assert runout_date.day == 1
        assert runout_date.year == 2025


# ============================================================================
# Test: Spend at Rate That Exhausts Before Month End
# ============================================================================


class TestExhaustBeforeMonthEnd:
    """Test category status when spending rate would exhaust budget early."""

    def test_high_burn_rate_exhausts_before_month_end(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """On day 15 with 4000 spent of 6000, runout happens before month end."""
        # Sept 15: spent 4000 of 6000
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("4000")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        # Burn rate = 4000 / 15 = ~266.67/day
        assert category["burn_rate_per_day"] == Decimal("4000") / Decimal("15")

    def test_projected_runout_before_month_end(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """With high spend, runout date should be before Sept 30."""
        # Sept 15: spent 4500 of 6000 (75% spent, 75% of month elapsed)
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("4500")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        # Burn rate = 4500 / 15 = 300/day
        # Runout = Sept 1 + (6000 / 300) = Sept 1 + 20 days = Sept 21
        assert category["projected_runout_date"] is not None
        runout_date = category["projected_runout_date"]
        assert runout_date.month == 9
        assert runout_date.day == 21


# ============================================================================
# Test: Shared Envelope (Travel and Party Outside)
# ============================================================================


class TestSharedEnvelope:
    """Test categories sharing one envelope (travel and party_outside)."""

    def test_travel_and_party_outside_share_envelope(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """Travel and party_outside share one envelope, so same spent/budget numbers."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 10,
                "code": "travel",
                "display_name": "Travel",
                "is_active": True,
                "envelope_id": 2,
                "envelope_name": "PartyOutsideTravel",
                "monthly_amount": Decimal("4000"),
                "account_code": "SBI",
            },
            {
                "id": 11,
                "code": "party_outside",
                "display_name": "Party Outside",
                "is_active": True,
                "envelope_id": 2,
                "envelope_name": "PartyOutsideTravel",
                "monthly_amount": Decimal("4000"),
                "account_code": "SBI",
            },
        ]

        # Both categories query their shared envelope
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("1000")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)

        # Should have 2 entries, one for each category
        assert len(result) == 2

        travel = next(c for c in result if c["category_code"] == "travel")
        party = next(c for c in result if c["category_code"] == "party_outside")

        # Both should have same spent and remaining since they share envelope
        assert travel["spent"] == party["spent"] == Decimal("1000")
        assert travel["remaining"] == party["remaining"] == Decimal("3000")
        assert travel["budget"] == party["budget"] == Decimal("4000")

        # Both should have same pace numbers
        assert travel["burn_rate_per_day"] == party["burn_rate_per_day"]
        assert travel["allowance_per_day"] == party["allowance_per_day"]

    def test_each_category_appears_separately_but_with_same_pace(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """Each category appears as separate entry, but pace numbers are identical."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 10,
                "code": "travel",
                "display_name": "Travel",
                "is_active": True,
                "envelope_id": 2,
                "envelope_name": "PartyOutsideTravel",
                "monthly_amount": Decimal("4000"),
                "account_code": "SBI",
            },
            {
                "id": 11,
                "code": "party_outside",
                "display_name": "Party Outside",
                "is_active": True,
                "envelope_id": 2,
                "envelope_name": "PartyOutsideTravel",
                "monthly_amount": Decimal("4000"),
                "account_code": "SBI",
            },
        ]

        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("2000")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)

        # Both categories should be present
        codes = [c["category_code"] for c in result]
        assert "travel" in codes
        assert "party_outside" in codes

        travel = next(c for c in result if c["category_code"] == "travel")
        party = next(c for c in result if c["category_code"] == "party_outside")

        # Same display names maintained
        assert travel["display_name"] == "Travel"
        assert party["display_name"] == "Party Outside"


# ============================================================================
# Test: days_elapsed=0 Edge Case (First Day of Month)
# ============================================================================


class TestFirstDayOfMonth:
    """Test category status on the first day of the month."""

    def test_first_day_of_month_days_elapsed_is_one(self, mock_categories_repository, mock_transactions_repository, frozen_clock):
        """On day 1 of month, days_elapsed = 1."""
        # Freeze to Sept 1, 2025
        clock = frozen_clock(datetime(2025, 9, 1, 12, 0, 0, tzinfo=timezone.utc))
        pace_service = BudgetsPaceService(
            mock_categories_repository, mock_transactions_repository, clock
        )

        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("0")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        # days_elapsed = 1
        # Days in Sept = 30, so days_left = 30 - 1 + 1 = 30
        assert category["days_left"] == 30
        # burn_rate_per_day should still be 0 (no spend)
        assert category["burn_rate_per_day"] == Decimal("0")

    def test_first_day_no_division_by_zero_error(
        self, mock_categories_repository, mock_transactions_repository, frozen_clock
    ):
        """First day with zero spend should not raise division by zero."""
        clock = frozen_clock(datetime(2025, 9, 1, 12, 0, 0, tzinfo=timezone.utc))
        pace_service = BudgetsPaceService(
            mock_categories_repository, mock_transactions_repository, clock
        )

        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("0")
        )

        # Should not raise an exception
        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        assert len(result) == 1

    def test_first_day_with_spend_burn_rate_calculated(
        self, mock_categories_repository, mock_transactions_repository, frozen_clock
    ):
        """First day with spend should calculate burn rate correctly."""
        clock = frozen_clock(datetime(2025, 9, 1, 12, 0, 0, tzinfo=timezone.utc))
        pace_service = BudgetsPaceService(
            mock_categories_repository, mock_transactions_repository, clock
        )

        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("500")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        # Spend 500 on day 1: burn_rate = 500 / 1 = 500/day
        assert category["burn_rate_per_day"] == Decimal("500")


# ============================================================================
# Test: Multiple Categories
# ============================================================================


class TestMultipleCategories:
    """Test with multiple categories in the result."""

    def test_multiple_categories_returned(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """Service should return all categories."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            },
            {
                "id": 2,
                "code": "rent",
                "display_name": "Rent",
                "is_active": True,
                "envelope_id": 3,
                "envelope_name": "Rent",
                "monthly_amount": Decimal("17000"),
                "account_code": "SLICE",
            },
        ]

        # Set up different spend for each
        def mock_sum_by_envelope(user_id, month_id, envelope_id, is_overage=False):
            if envelope_id == 1:
                return Decimal("3000")
            elif envelope_id == 3:
                return Decimal("0")
            return Decimal("0")

        mock_transactions_repository.sum_expense_for_envelope_in_month.side_effect = (
            mock_sum_by_envelope
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)

        assert len(result) == 2
        food = next(c for c in result if c["category_code"] == "food")
        rent = next(c for c in result if c["category_code"] == "rent")

        assert food["spent"] == Decimal("3000")
        assert rent["spent"] == Decimal("0")

    def test_category_codes_and_display_names_preserved(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """Response should preserve category codes and display names."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food & Groceries",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            },
            {
                "id": 3,
                "code": "electricity",
                "display_name": "Electricity Bill",
                "is_active": True,
                "envelope_id": 4,
                "envelope_name": "Electricity",
                "monthly_amount": Decimal("100"),
                "account_code": "SLICE",
            },
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("0")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)

        assert any(c["category_code"] == "food" for c in result)
        assert any(c["category_code"] == "electricity" for c in result)

        food = next(c for c in result if c["category_code"] == "food")
        assert food["display_name"] == "Food & Groceries"


# ============================================================================
# Test: Response Schema and Data Types
# ============================================================================


class TestResponseSchema:
    """Test that response conforms to expected schema."""

    def test_response_is_list_of_dicts(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """Response should be a list of dicts."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("0")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)

        assert isinstance(result, list)
        assert len(result) > 0
        assert isinstance(result[0], dict)

    def test_response_includes_all_required_fields(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """Each category dict should include all required fields."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("0")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

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

    def test_decimal_values_in_response(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """Budget, spent, remaining, and rate fields should be Decimal."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("1000")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        # These should be Decimal
        assert isinstance(category["budget"], Decimal)
        assert isinstance(category["spent"], Decimal)
        assert isinstance(category["remaining"], Decimal)
        assert isinstance(category["allowance_per_day"], Decimal)
        assert isinstance(category["burn_rate_per_day"], Decimal)

    def test_int_values_in_response(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """days_left should be int."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("0")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        assert isinstance(category["days_left"], int)

    def test_str_values_in_response(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """category_code and display_name should be strings."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("0")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        assert isinstance(category["category_code"], str)
        assert isinstance(category["display_name"], str)


# ============================================================================
# Test: Remaining Budget Clamped >= 0
# ============================================================================


class TestRemainingBudgetClamped:
    """Test that remaining budget is clamped to >= 0."""

    def test_overspent_remaining_is_zero_not_negative(
        self, pace_service, mock_categories_repository, mock_transactions_repository
    ):
        """If spent > budget, remaining should be 0, not negative."""
        mock_categories_repository.get_all_active_categories_with_envelopes.return_value = [
            {
                "id": 1,
                "code": "food",
                "display_name": "Food",
                "is_active": True,
                "envelope_id": 1,
                "envelope_name": "Food",
                "monthly_amount": Decimal("6000"),
                "account_code": "ICICI",
            }
        ]
        # Spend more than budget
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = (
            Decimal("7000")
        )

        result = pace_service.get_all_category_statuses(user_id=1, month_id=1)
        category = result[0]

        assert category["spent"] == Decimal("7000")
        assert category["remaining"] == Decimal("0")  # Clamped to 0
