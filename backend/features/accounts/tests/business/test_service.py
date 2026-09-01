"""
Unit tests for accounts business logic: month-end-check balance calculations.

Uses mocked repository and clock. Tests the expected-balance calculation for
accounts funding budget envelopes.
"""

from datetime import datetime, timezone
from decimal import Decimal
from unittest.mock import Mock

import pytest

from core.clock import Clock
from features.accounts.business.service import AccountsService


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def mock_repository():
    """Mock accounts repository."""
    repo = Mock()

    # Seeded account data
    repo.get_all_accounts.return_value = [
        {"id": 1, "code": "ICICI", "display_name": "ICICI Bank", "kind": "bank", "fixed_amount": None},
        {"id": 2, "code": "SBI", "display_name": "SBI Bank", "kind": "bank", "fixed_amount": None},
        {"id": 3, "code": "SLICE", "display_name": "Slice", "kind": "bank", "fixed_amount": None},
        {"id": 4, "code": "HDFC", "display_name": "HDFC (Fixed)", "kind": "fixed", "fixed_amount": 2500.00},
        {"id": 5, "code": "CREDIT", "display_name": "Credit Ledger", "kind": "pseudo_credit", "fixed_amount": None},
    ]

    # Seeded budget envelopes
    repo.get_all_budget_envelopes.return_value = [
        {"id": 1, "name": "Food", "monthly_amount": 6000.00, "account_id": 1},  # ICICI
        {"id": 2, "name": "PartyOutsideTravel", "monthly_amount": 4000.00, "account_id": 2},  # SBI
        {"id": 3, "name": "Rent", "monthly_amount": 17000.00, "account_id": 3},  # SLICE
        {"id": 4, "name": "Electricity", "monthly_amount": 100.00, "account_id": 3},  # SLICE
        {"id": 5, "name": "PhoneInternet", "monthly_amount": 300.00, "account_id": 3},  # SLICE
        {"id": 6, "name": "Misc", "monthly_amount": 5000.00, "account_id": 1},  # ICICI
    ]

    repo.get_month_id.return_value = 1
    repo.create_month.return_value = 1

    return repo


@pytest.fixture
def frozen_clock():
    """Provide a frozen clock for predictable time."""
    class FrozenClock(Clock):
        def __init__(self):
            self._time = datetime(2025, 9, 1, 12, 0, 0, tzinfo=timezone.utc)

        def now(self):
            return self._time

    return FrozenClock()


@pytest.fixture
def service(mock_repository, frozen_clock):
    """Provide an AccountsService with mocked dependencies."""
    return AccountsService(mock_repository, frozen_clock)


# ============================================================================
# Tests: No spend yet
# ============================================================================


class TestExpectedBalanceNoSpend:
    """Test expected-balance calculation when no transactions exist."""

    def test_no_spend_balance_equals_envelope_totals(self, service, mock_repository):
        """
        With no transactions, expected balance = sum of monthly_amounts for envelopes
        funded by that account.
        """
        # No transactions
        mock_repository.get_transactions_for_month.return_value = []

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)

        # ICICI funds Food (6000) and Misc (5000) = 11000
        assert result["ICICI"]["expected_balance"] == 11000.0
        # SBI funds PartyOutsideTravel (4000)
        assert result["SBI"]["expected_balance"] == 4000.0
        # SLICE funds Rent (17000), Electricity (100), PhoneInternet (300) = 17400
        assert result["SLICE"]["expected_balance"] == 17400.0
        # HDFC is fixed at 2500
        assert result["hdfc_reserve"] == 2500.0
        # Total = 11000 + 4000 + 17400 + 2500 = 34900
        assert result["total_net_worth"] == 34900.0

    def test_no_spend_all_envelopes_funded_correctly(self, service, mock_repository):
        """Verify all envelopes are allocated to correct accounts."""
        mock_repository.get_transactions_for_month.return_value = []

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)

        # ICICI should have Food + Misc
        icici_balance = result["ICICI"]["expected_balance"]
        assert icici_balance == 11000.0

        # SBI should have PartyOutsideTravel
        sbi_balance = result["SBI"]["expected_balance"]
        assert sbi_balance == 4000.0

        # SLICE should have Rent + Electricity + PhoneInternet
        slice_balance = result["SLICE"]["expected_balance"]
        assert slice_balance == 17400.0


# ============================================================================
# Tests: Spend within budget
# ============================================================================


class TestExpectedBalanceWithSpend:
    """Test expected-balance calculation with expense transactions."""

    def test_spend_within_budget_reduces_balance(self, service, mock_repository):
        """Expenses (is_overage=false) should reduce expected balance."""
        # Single transaction: 1000 expense on ICICI
        mock_repository.get_transactions_for_month.return_value = [
            {
                "id": 1,
                "funding_account_id": 1,  # ICICI
                "type": "expense",
                "is_overage": False,
                "amount": 1000.00,
                "category_id": 1,  # food
            }
        ]

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)

        # ICICI: (6000 + 5000) - 1000 = 10000
        assert result["ICICI"]["expected_balance"] == 10000.0
        # Other accounts unchanged
        assert result["SBI"]["expected_balance"] == 4000.0
        assert result["SLICE"]["expected_balance"] == 17400.0

    def test_multiple_expenses_on_same_account(self, service, mock_repository):
        """Multiple expenses on same account should sum correctly."""
        mock_repository.get_transactions_for_month.return_value = [
            {
                "id": 1,
                "funding_account_id": 3,  # SLICE
                "type": "expense",
                "is_overage": False,
                "amount": 500.00,
            },
            {
                "id": 2,
                "funding_account_id": 3,  # SLICE
                "type": "expense",
                "is_overage": False,
                "amount": 200.00,
            },
        ]

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)

        # SLICE: (17000 + 100 + 300) - (500 + 200) = 17400 - 700 = 16700
        assert result["SLICE"]["expected_balance"] == 16700.0

    def test_expenses_on_different_accounts(self, service, mock_repository):
        """Expenses on different accounts should only affect those accounts."""
        mock_repository.get_transactions_for_month.return_value = [
            {
                "id": 1,
                "funding_account_id": 1,  # ICICI
                "type": "expense",
                "is_overage": False,
                "amount": 100.00,
            },
            {
                "id": 2,
                "funding_account_id": 2,  # SBI
                "type": "expense",
                "is_overage": False,
                "amount": 200.00,
            },
        ]

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)

        # ICICI: 11000 - 100 = 10900
        assert result["ICICI"]["expected_balance"] == 10900.0
        # SBI: 4000 - 200 = 3800
        assert result["SBI"]["expected_balance"] == 3800.0
        # SLICE unchanged
        assert result["SLICE"]["expected_balance"] == 17400.0


# ============================================================================
# Tests: Rollover sweep transactions
# ============================================================================


class TestExpectedBalanceWithRolloverSweep:
    """Test expected-balance with rollover_sweep transactions."""

    def test_rollover_sweep_into_slice_increases_balance(self, service, mock_repository):
        """rollover_sweep transactions (category_id=None) should increase balance."""
        mock_repository.get_transactions_for_month.return_value = [
            {
                "id": 1,
                "funding_account_id": 3,  # SLICE
                "type": "rollover_sweep",
                "is_overage": False,
                "amount": 1000.00,
                "category_id": None,  # No category for rollover
            }
        ]

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)

        # SLICE: (17000 + 100 + 300) + 1000 = 17400 + 1000 = 18400
        assert result["SLICE"]["expected_balance"] == 18400.0

    def test_multiple_rollover_sweeps(self, service, mock_repository):
        """Multiple rollover sweeps should sum correctly."""
        mock_repository.get_transactions_for_month.return_value = [
            {
                "id": 1,
                "funding_account_id": 1,  # ICICI
                "type": "rollover_sweep",
                "is_overage": False,
                "amount": 500.00,
                "category_id": None,
            },
            {
                "id": 2,
                "funding_account_id": 1,  # ICICI
                "type": "rollover_sweep",
                "is_overage": False,
                "amount": 250.00,
                "category_id": None,
            },
        ]

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)

        # ICICI: (6000 + 5000) + (500 + 250) = 11000 + 750 = 11750
        assert result["ICICI"]["expected_balance"] == 11750.0

    def test_rollover_sweep_combined_with_expenses(self, service, mock_repository):
        """Both expenses and rollover sweeps should be accounted for."""
        mock_repository.get_transactions_for_month.return_value = [
            {
                "id": 1,
                "funding_account_id": 2,  # SBI
                "type": "expense",
                "is_overage": False,
                "amount": 500.00,
                "category_id": 5,  # party_outside
            },
            {
                "id": 2,
                "funding_account_id": 2,  # SBI
                "type": "rollover_sweep",
                "is_overage": False,
                "amount": 800.00,
                "category_id": None,
            },
        ]

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)

        # SBI: (4000) - (500) + (800) = 4300
        assert result["SBI"]["expected_balance"] == 4300.0


# ============================================================================
# Tests: HDFC fixed reserve
# ============================================================================


class TestHDFCFixedReserve:
    """Test that HDFC reserve is always 2500 regardless of transactions."""

    def test_hdfc_reserve_is_always_2500(self, service, mock_repository):
        """HDFC should always return 2500 as fixed reserve."""
        # Even with transactions
        mock_repository.get_transactions_for_month.return_value = []

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)
        assert result["hdfc_reserve"] == 2500.0

    def test_hdfc_reserve_with_transactions(self, service, mock_repository):
        """HDFC reserve should not be affected by transactions on other accounts."""
        mock_repository.get_transactions_for_month.return_value = [
            {
                "id": 1,
                "funding_account_id": 1,  # ICICI
                "type": "expense",
                "is_overage": False,
                "amount": 1000.00,
                "category_id": 1,
            }
        ]

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)
        # HDFC reserve should still be 2500
        assert result["hdfc_reserve"] == 2500.0


# ============================================================================
# Tests: Total net worth calculation
# ============================================================================


class TestTotalNetWorth:
    """Test total_net_worth calculation."""

    def test_total_net_worth_no_spend(self, service, mock_repository):
        """total_net_worth = sum of all account balances + hdfc_reserve."""
        mock_repository.get_transactions_for_month.return_value = []

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)

        # 11000 (ICICI) + 4000 (SBI) + 17400 (SLICE) + 2500 (HDFC) = 34900
        assert result["total_net_worth"] == 34900.0

    def test_total_net_worth_with_spend(self, service, mock_repository):
        """total_net_worth should decrease with expenses."""
        mock_repository.get_transactions_for_month.return_value = [
            {
                "id": 1,
                "funding_account_id": 1,  # ICICI
                "type": "expense",
                "is_overage": False,
                "amount": 500.00,
                "category_id": 1,
            }
        ]

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)

        # 10500 (ICICI) + 4000 (SBI) + 17400 (SLICE) + 2500 (HDFC) = 34400
        assert result["total_net_worth"] == 34400.0

    def test_total_net_worth_with_rollover_sweep(self, service, mock_repository):
        """total_net_worth should increase with rollover sweeps."""
        mock_repository.get_transactions_for_month.return_value = [
            {
                "id": 1,
                "funding_account_id": 3,  # SLICE
                "type": "rollover_sweep",
                "is_overage": False,
                "amount": 1000.00,
                "category_id": None,
            }
        ]

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)

        # 11000 (ICICI) + 4000 (SBI) + 18400 (SLICE) + 2500 (HDFC) = 35900
        assert result["total_net_worth"] == 35900.0

    def test_total_net_worth_complex_transactions(self, service, mock_repository):
        """total_net_worth with multiple transactions across accounts."""
        mock_repository.get_transactions_for_month.return_value = [
            {
                "id": 1,
                "funding_account_id": 1,  # ICICI
                "type": "expense",
                "is_overage": False,
                "amount": 100.00,
                "category_id": 1,
            },
            {
                "id": 2,
                "funding_account_id": 2,  # SBI
                "type": "expense",
                "is_overage": False,
                "amount": 200.00,
                "category_id": 5,
            },
            {
                "id": 3,
                "funding_account_id": 3,  # SLICE
                "type": "rollover_sweep",
                "is_overage": False,
                "amount": 500.00,
                "category_id": None,
            },
        ]

        result = service.calculate_month_end_check(user_id=1, year=2025, month=9)

        # 10900 (ICICI) + 3800 (SBI) + 17900 (SLICE) + 2500 (HDFC) = 35100
        assert result["total_net_worth"] == 35100.0
