"""
Unit tests for credit business logic: service layer.

Uses mocked repository. Tests business logic for:
- current_balance: summing credit ledger entries
- record_overage: recording overage entries (positive amounts)
- settle: settling amounts (negative amounts), returning new balance
"""

from decimal import Decimal
from unittest.mock import Mock

import pytest

from features.credit.business.service import CreditService


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def mock_repository():
    """Mock credit repository."""
    return Mock()


@pytest.fixture
def service(mock_repository):
    """Provide a CreditService with mocked repository."""
    return CreditService(mock_repository)


# ============================================================================
# Tests: current_balance
# ============================================================================


class TestCurrentBalance:
    """Test current_balance method."""

    def test_current_balance_returns_sum_from_repository(self, service, mock_repository):
        """current_balance should call repository.sum_balance and return its result."""
        mock_repository.sum_balance.return_value = Decimal("500.00")
        result = service.current_balance(user_id=1)
        assert result == Decimal("500.00")
        mock_repository.sum_balance.assert_called_once_with(1)

    def test_current_balance_calls_repository_sum_balance(self, service, mock_repository):
        """
        current_balance should call repository.sum_balance(user_id) and return its result.

        Expected behavior (when implemented):
        - Call repository.sum_balance(user_id=1)
        - Return the Decimal result from repository
        """
        # Mock repository to return a balance
        mock_repository.sum_balance.return_value = Decimal("500.00")

        result = service.current_balance(user_id=1)
        assert result == Decimal("500.00")
        mock_repository.sum_balance.assert_called_once_with(1)

    def test_current_balance_zero_when_no_entries(self, service, mock_repository):
        """
        current_balance should return Decimal("0.00") if user has no ledger entries.

        Expected behavior (when implemented):
        - User with no credit ledger entries should have balance of 0
        """
        mock_repository.sum_balance.return_value = Decimal("0.00")

        result = service.current_balance(user_id=999)
        assert result == Decimal("0.00")


# ============================================================================
# Tests: record_overage
# ============================================================================


class TestRecordOverage:
    """Test record_overage method."""

    def test_record_overage_delegates_to_repository(self, service, mock_repository):
        """record_overage should call repository.insert_ledger_entry."""
        mock_repository.insert_ledger_entry.return_value = None

        result = service.record_overage(
            user_id=1,
            month_id=1,
            category_id=1,
            amount=Decimal("100.00"),
            transaction_id=1,
        )

        assert result is None
        mock_repository.insert_ledger_entry.assert_called_once()

    def test_record_overage_calls_repository_insert_ledger_entry(self, service, mock_repository):
        """
        record_overage should call repository.insert_ledger_entry with:
        - user_id
        - month_id
        - category_id
        - transaction_id
        - amount (positive)
        - entry_type='overage'

        Expected behavior (when implemented):
        - Insert a credit_ledger row with entry_type='overage'
        - amount should be positive (the overage amount)
        - Return None
        """
        mock_repository.insert_ledger_entry.return_value = None

        service.record_overage(
            user_id=1,
            month_id=1,
            category_id=1,
            amount=Decimal("250.00"),
            transaction_id=1,
        )

        mock_repository.insert_ledger_entry.assert_called_once_with(
            user_id=1,
            month_id=1,
            category_id=1,
            transaction_id=1,
            amount=Decimal("250.00"),
            entry_type="overage",
        )

    def test_record_overage_with_positive_amount(self, service, mock_repository):
        """
        record_overage should insert entry with positive amount.

        Expected behavior (when implemented):
        - amount should be stored as-is (positive)
        - entry_type should be 'overage'
        """
        mock_repository.insert_ledger_entry.return_value = None

        service.record_overage(
            user_id=1,
            month_id=1,
            category_id=2,
            amount=Decimal("150.50"),
            transaction_id=5,
        )

        mock_repository.insert_ledger_entry.assert_called_once_with(
            user_id=1,
            month_id=1,
            category_id=2,
            transaction_id=5,
            amount=Decimal("150.50"),
            entry_type="overage",
        )


# ============================================================================
# Tests: settle
# ============================================================================


class TestSettle:
    """Test settle method."""

    def test_settle_records_payoff_and_returns_new_balance(self, service, mock_repository):
        """settle should insert ledger entry and return new balance."""
        mock_repository.insert_ledger_entry.return_value = None
        mock_repository.sum_balance.return_value = Decimal("300.00")

        result = service.settle(
            user_id=1,
            month_id=1,
            amount=Decimal("100.00"),
            transaction_id=1,
        )

        assert result == Decimal("300.00")

    def test_settle_calls_repository_insert_ledger_entry(self, service, mock_repository):
        """
        settle should call repository.insert_ledger_entry with:
        - user_id
        - month_id
        - amount as NEGATIVE (- amount)
        - entry_type='payoff'
        - transaction_id

        Expected behavior (when implemented):
        - Insert a credit_ledger row with entry_type='payoff'
        - amount stored should be negative of the settle amount (-amount)
        - Return the new balance (current_balance - settle_amount)
        """
        # Mock repository behavior
        mock_repository.sum_balance.return_value = Decimal("300.00")
        mock_repository.insert_ledger_entry.return_value = None

        result = service.settle(
            user_id=1,
            month_id=1,
            amount=Decimal("200.00"),
            transaction_id=1,
        )

        mock_repository.insert_ledger_entry.assert_called_once_with(
            user_id=1,
            month_id=1,
            category_id=None,
            transaction_id=1,
            amount=Decimal("-200.00"),
            entry_type="payoff",
        )
        assert result == Decimal("300.00")

    def test_settle_returns_new_balance(self, service, mock_repository):
        """
        settle should return the remaining balance after settlement.

        Expected behavior (when implemented):
        - Before settle: balance = 500
        - Settle amount: 200
        - After settle: balance = 300
        - Should return Decimal("300.00")
        """
        mock_repository.sum_balance.return_value = Decimal("300.00")
        mock_repository.insert_ledger_entry.return_value = None

        result = service.settle(
            user_id=1,
            month_id=1,
            amount=Decimal("200.00"),
            transaction_id=1,
        )

        assert result == Decimal("300.00")

    def test_settle_with_exact_balance(self, service, mock_repository):
        """
        settle should allow settling exact balance amount.

        Expected behavior (when implemented):
        - Balance: 300
        - Settle: 300
        - New balance: 0
        - Should return Decimal("0.00")
        """
        mock_repository.sum_balance.return_value = Decimal("0.00")
        mock_repository.insert_ledger_entry.return_value = None

        result = service.settle(
            user_id=1,
            month_id=1,
            amount=Decimal("300.00"),
            transaction_id=1,
        )

        assert result == Decimal("0.00")

    def test_settle_inserts_negative_amount(self, service, mock_repository):
        """
        settle should insert a negative amount in ledger.

        Expected behavior (when implemented):
        - Settle amount: 150
        - Amount inserted: -150
        - entry_type: 'payoff'
        """
        mock_repository.sum_balance.return_value = Decimal("350.00")
        mock_repository.insert_ledger_entry.return_value = None

        result = service.settle(
            user_id=1,
            month_id=1,
            amount=Decimal("150.00"),
            transaction_id=1,
        )

        # Verify negative amount was inserted
        call_args = mock_repository.insert_ledger_entry.call_args
        assert call_args[1]["amount"] == Decimal("-150.00")
        assert call_args[1]["entry_type"] == "payoff"
        assert result == Decimal("350.00")
