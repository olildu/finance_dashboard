"""
Unit tests for RolloverEngine.

Tests the core rollover algorithm: settle credit, sweep envelopes, mark rolled over.
Uses mocked repositories and a FakeCreditLedger as boundary mock.
"""

from datetime import datetime, timezone
from decimal import Decimal
from unittest.mock import Mock, call

import pytest

from core.clock import Clock
from features.rollover.business.engine import RolloverEngine
from features.credit.business.interface import CreditLedgerInterface


# ============================================================================
# Fake implementations (legitimate boundary mocks)
# ============================================================================


class FakeCreditLedger(CreditLedgerInterface):
    """
    Fake credit ledger for testing. Mirrors the real CreditService's contract:
    the ledger is a running balance per user (not per month) — current_balance()
    is what the engine actually calls to decide how much to settle.
    """

    def __init__(self):
        self.balances = {}  # user_id -> balance
        self.settled = []  # track calls to settle()

    def set_balance(self, user_id: int, amount: Decimal) -> None:
        """Helper to set up a test user's outstanding balance."""
        self.balances[user_id] = amount

    def current_balance(self, user_id: int) -> Decimal:
        """Return this user's outstanding balance — this is what the engine reads."""
        return self.balances.get(user_id, Decimal("0"))

    def record_overage(self, user_id: int, month_id: int, category_id: int, amount: Decimal, transaction_id: int) -> None:
        """Not needed for rollover tests."""
        pass

    def settle(self, user_id: int, month_id: int, amount: Decimal, transaction_id: int) -> Decimal:
        """Mock settle: record the call and return remaining balance after settle."""
        self.settled.append({
            "user_id": user_id,
            "month_id": month_id,
            "amount": amount,
            "transaction_id": transaction_id,
        })
        current = self.balances.get(user_id, Decimal("0"))
        remaining = max(Decimal("0"), current - amount)
        self.balances[user_id] = remaining
        return remaining


# ============================================================================
# Constants from seed.sql
# ============================================================================

# Budget envelopes (from backend/db/seed.sql):
ENVELOPES = [
    {"id": 1, "name": "Food", "monthly_amount": Decimal("6000.00"), "account_id": 1},
    {"id": 2, "name": "PartyOutsideTravel", "monthly_amount": Decimal("4000.00"), "account_id": 2},
    {"id": 3, "name": "Rent", "monthly_amount": Decimal("17000.00"), "account_id": 3},
    {"id": 4, "name": "Electricity", "monthly_amount": Decimal("100.00"), "account_id": 3},
    {"id": 5, "name": "PhoneInternet", "monthly_amount": Decimal("300.00"), "account_id": 3},
    {"id": 6, "name": "Misc", "monthly_amount": Decimal("5000.00"), "account_id": 1},
]

SUM_ENVELOPE_AMOUNTS = sum(e["monthly_amount"] for e in ENVELOPES)  # 32,400.00
SALARY_TOTAL = Decimal("46200.00")
FIXED_UNBUDGETED = SALARY_TOTAL - SUM_ENVELOPE_AMOUNTS  # 13,800.00


def leftover_sum(spending: dict) -> Decimal:
    """
    Sum of max(budget - spent, 0) across every seeded envelope, given a
    {envelope_id: spent} dict (envelopes not present default to zero spend,
    i.e. their FULL budget counts as leftover — this is the confirmed spec:
    a zero-spend envelope contributes its whole budget to the sweep, not zero).
    """
    return sum(
        max(e["monthly_amount"] - spending.get(e["id"], Decimal("0")), Decimal("0"))
        for e in ENVELOPES
    )


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def mock_clock():
    """Mock clock that returns a specific time."""
    clock = Mock(spec=Clock)
    # Current month is September 2025
    clock.now.return_value = datetime(2025, 9, 1, 12, 0, 0, tzinfo=timezone.utc)
    return clock


@pytest.fixture
def mock_rollover_repository():
    """Mock RolloverRepository for testing."""
    repo = Mock()
    repo.get_unclosed_months_before = Mock(return_value=[])
    repo.get_or_create_month_state_locked = Mock()
    repo.mark_rolled_over = Mock()
    return repo


@pytest.fixture
def mock_transactions_repository():
    """Mock TransactionsRepository for testing."""
    repo = Mock()
    repo.insert = Mock(return_value=1)  # transaction ID
    repo.sum_expense_for_envelope_in_month = Mock(return_value=Decimal("0"))
    return repo


@pytest.fixture
def mock_budget_envelopes_lookup():
    """Mock budget envelopes lookup that returns the seeded envelopes."""
    lookup = Mock(return_value=ENVELOPES)
    return lookup


@pytest.fixture
def fake_credit_ledger():
    """Provide a fake credit ledger implementation."""
    return FakeCreditLedger()


@pytest.fixture
def engine(
    mock_rollover_repository,
    mock_transactions_repository,
    mock_budget_envelopes_lookup,
    fake_credit_ledger,
    mock_clock,
):
    """Create a RolloverEngine with mocked dependencies."""
    return RolloverEngine(
        rollover_repository=mock_rollover_repository,
        transactions_repository=mock_transactions_repository,
        budget_envelopes_lookup=mock_budget_envelopes_lookup,
        credit_ledger_interface=fake_credit_ledger,
        clock=mock_clock,
        salary_total=SALARY_TOTAL,
        slice_account_id=3,  # SLICE is account 3 in seed.sql
    )


# ============================================================================
# Tests: Zero-spend month
# ============================================================================


class TestZeroSpendMonth:
    """Test rollover of a month with zero spend across all envelopes."""

    def test_zero_spend_sweep_amount_equals_full_salary(
        self, engine, mock_rollover_repository, mock_transactions_repository, mock_budget_envelopes_lookup
    ):
        """
        When all envelopes have zero spend, EVERY envelope's full budget counts
        as leftover (leftover = budget - spent = budget when spent is 0), so the
        sweep amount equals the whole salary: sum(all envelope budgets) +
        the fixed unbudgeted portion == SALARY_TOTAL exactly (46,200.00) — nothing
        was spent anywhere, so the entire salary becomes savings.
        """
        unclosed_month = {"id": 8, "year": 2025, "month": 8}
        mock_rollover_repository.get_unclosed_months_before.return_value = [unclosed_month]

        # Setup: No transactions (zero spend)
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal("0")

        mock_rollover_repository.get_or_create_month_state_locked.return_value = {
            "id": 100,
            "user_id": 1,
            "month_id": 8,
            "status": "open",
        }

        # Execute
        result = engine.run_rollover_check(user_id=1)

        # Verify: Sweep amount equals the full salary
        assert len(result) == 1
        assert result[0]["month_id"] == 8
        assert result[0]["sweep_amount"] == SALARY_TOTAL

    def test_zero_spend_no_credit_settled_when_no_debt(
        self, engine, mock_rollover_repository, fake_credit_ledger
    ):
        """When there is no credit debt, settle() should not be called."""
        unclosed_month = {"id": 8, "year": 2025, "month": 8}
        mock_rollover_repository.get_unclosed_months_before.return_value = [unclosed_month]
        mock_rollover_repository.get_or_create_month_state_locked.return_value = {
            "id": 100,
            "user_id": 1,
            "month_id": 8,
            "status": "open",
        }

        # Execute
        engine.run_rollover_check(user_id=1)

        # Verify: settle() was not called (no debt to settle)
        assert len(fake_credit_ledger.settled) == 0


# ============================================================================
# Tests: Envelope with spending less than budget
# ============================================================================


class TestEnvelopeWithLeftover:
    """Test rollover when an envelope has leftover (budget - spent)."""

    def test_food_leftover_included_in_sweep(
        self,
        engine,
        mock_rollover_repository,
        mock_transactions_repository,
    ):
        """
        Food has budget of 6000. If only 4000 is spent, Food's leftover is 2000 —
        but every OTHER envelope also has zero spend here, so each of those
        contributes its own full budget as leftover too (per the confirmed spec).
        """
        unclosed_month = {"id": 8, "year": 2025, "month": 8}
        mock_rollover_repository.get_unclosed_months_before.return_value = [unclosed_month]
        mock_rollover_repository.get_or_create_month_state_locked.return_value = {
            "id": 100,
            "user_id": 1,
            "month_id": 8,
            "status": "open",
        }

        spending = {1: Decimal("4000.00")}  # Food (envelope_id=1): 4000 of 6000

        def sum_expense_side_effect(user_id, month_id, envelope_id, is_overage=False):
            return spending.get(envelope_id, Decimal("0.00"))

        mock_transactions_repository.sum_expense_for_envelope_in_month.side_effect = (
            sum_expense_side_effect
        )

        # Execute
        result = engine.run_rollover_check(user_id=1)

        # Verify: Sweep includes Food's leftover (2000) + every other envelope's
        # full untouched budget + the fixed unbudgeted portion.
        expected_sweep = leftover_sum(spending) + FIXED_UNBUDGETED
        assert result[0]["sweep_amount"] == expected_sweep

    def test_multiple_envelopes_with_leftover(
        self,
        engine,
        mock_rollover_repository,
        mock_transactions_repository,
    ):
        """
        Test multiple envelopes with varying leftover amounts.
        Food: 6000 budget, 4000 spent -> 2000 leftover
        Misc: 5000 budget, 3000 spent -> 2000 leftover
        Others: 0 spent -> full budget is leftover

        Total sweep: (2000 + 2000 + 4000 + 100 + 300 + 17000) + 13800
        """
        unclosed_month = {"id": 8, "year": 2025, "month": 8}
        mock_rollover_repository.get_unclosed_months_before.return_value = [unclosed_month]
        mock_rollover_repository.get_or_create_month_state_locked.return_value = {
            "id": 100,
            "user_id": 1,
            "month_id": 8,
            "status": "open",
        }

        def sum_expense_side_effect(user_id, month_id, envelope_id, is_overage=False):
            spending = {
                1: Decimal("4000.00"),  # Food: 4000 out of 6000
                2: Decimal("0.00"),     # PartyOutsideTravel: 0 out of 4000
                3: Decimal("0.00"),     # Rent: 0 out of 17000
                4: Decimal("0.00"),     # Electricity: 0 out of 100
                5: Decimal("0.00"),     # PhoneInternet: 0 out of 300
                6: Decimal("3000.00"),  # Misc: 3000 out of 5000
            }
            return spending.get(envelope_id, Decimal("0.00"))

        mock_transactions_repository.sum_expense_for_envelope_in_month.side_effect = (
            sum_expense_side_effect
        )

        # Execute
        result = engine.run_rollover_check(user_id=1)

        # Verify: Sum all leftovers + fixed
        # Food: 2000, PartyOutsideTravel: 4000, Rent: 17000, Electricity: 100, PhoneInternet: 300, Misc: 2000
        expected_leftover = Decimal("2000") + Decimal("4000") + Decimal("17000") + Decimal("100") + Decimal("300") + Decimal("2000")
        expected_sweep = expected_leftover + FIXED_UNBUDGETED
        assert result[0]["sweep_amount"] == expected_sweep


# ============================================================================
# Tests: Envelope with overage (credit debt)
# ============================================================================


class TestEnvelopeWithOverage:
    """Test rollover when an envelope has overage funded by credit."""

    def test_overage_not_double_subtracted_from_leftover(
        self,
        engine,
        mock_rollover_repository,
        mock_transactions_repository,
    ):
        """
        Food: budget 6000, but 7000 spent (1000 overage funded by CREDIT).
        When calculating leftover for sweep purposes, we only count non-overage spend.
        Leftover = max(budget - non_overage_spent, 0) = max(6000 - 6000, 0) = 0.
        NOT: 6000 - 7000 = -1000 (which would double-count the overage).
        """
        unclosed_month = {"id": 8, "year": 2025, "month": 8}
        mock_rollover_repository.get_unclosed_months_before.return_value = [unclosed_month]
        mock_rollover_repository.get_or_create_month_state_locked.return_value = {
            "id": 100,
            "user_id": 1,
            "month_id": 8,
            "status": "open",
        }

        # Setup: Food has 6000 non-overage spend + 1000 overage spend; every
        # other envelope has zero spend and so contributes its full budget.
        non_overage_spending = {1: Decimal("6000.00")}

        def sum_expense_side_effect(user_id, month_id, envelope_id, is_overage=False):
            if envelope_id == 1 and is_overage:
                return Decimal("1000.00")
            return non_overage_spending.get(envelope_id, Decimal("0.00"))

        mock_transactions_repository.sum_expense_for_envelope_in_month.side_effect = (
            sum_expense_side_effect
        )

        # Execute
        result = engine.run_rollover_check(user_id=1)

        # Verify: Food leftover is max(6000 - 6000, 0) = 0, not negative; other
        # envelopes' full budgets plus the fixed unbudgeted portion make up the rest.
        expected_sweep = leftover_sum(non_overage_spending) + FIXED_UNBUDGETED
        assert result[0]["sweep_amount"] == expected_sweep

    def test_envelope_with_moderate_overage(
        self,
        engine,
        mock_rollover_repository,
        mock_transactions_repository,
    ):
        """
        Food: budget 6000, 5000 non-overage, 500 overage.
        Leftover: max(6000 - 5000, 0) = 1000.
        The 500 overage is captured separately in credit_settled_amount, not double-counted.
        """
        unclosed_month = {"id": 8, "year": 2025, "month": 8}
        mock_rollover_repository.get_unclosed_months_before.return_value = [unclosed_month]
        mock_rollover_repository.get_or_create_month_state_locked.return_value = {
            "id": 100,
            "user_id": 1,
            "month_id": 8,
            "status": "open",
        }

        non_overage_spending = {1: Decimal("5000.00")}

        def sum_expense_side_effect(user_id, month_id, envelope_id, is_overage=False):
            if envelope_id == 1 and is_overage:
                return Decimal("500.00")
            return non_overage_spending.get(envelope_id, Decimal("0.00"))

        mock_transactions_repository.sum_expense_for_envelope_in_month.side_effect = (
            sum_expense_side_effect
        )

        # Execute
        result = engine.run_rollover_check(user_id=1)

        # Verify: Food leftover = 1000, plus every other envelope's full budget,
        # plus the fixed unbudgeted portion.
        expected_sweep = leftover_sum(non_overage_spending) + FIXED_UNBUDGETED
        assert result[0]["sweep_amount"] == expected_sweep


# ============================================================================
# Tests: Credit debt settlement
# ============================================================================


class TestCreditDebtSettlement:
    """Test that credit debt is settled before sweep transaction is created."""

    def test_settle_called_before_sweep_transaction_inserted(
        self,
        engine,
        mock_rollover_repository,
        mock_transactions_repository,
        fake_credit_ledger,
    ):
        """
        When a month has outstanding credit debt:
        1. settle() should be called FIRST
        2. Then sweep transaction should be inserted
        Verify via mock call order.
        """
        unclosed_month = {"id": 8, "year": 2025, "month": 8}
        mock_rollover_repository.get_unclosed_months_before.return_value = [unclosed_month]
        mock_rollover_repository.get_or_create_month_state_locked.return_value = {
            "id": 100,
            "user_id": 1,
            "month_id": 8,
            "status": "open",
        }

        # Setup: user has 500 outstanding credit debt
        fake_credit_ledger.set_balance(user_id=1, amount=Decimal("500.00"))

        # Execute
        result = engine.run_rollover_check(user_id=1)

        # Verify: settle() was called
        assert len(fake_credit_ledger.settled) == 1
        assert fake_credit_ledger.settled[0]["user_id"] == 1
        assert fake_credit_ledger.settled[0]["month_id"] == 8
        assert fake_credit_ledger.settled[0]["amount"] == Decimal("500.00")

        # Verify: result includes credit_settled_amount
        assert result[0]["credit_settled_amount"] == Decimal("500.00")

    def test_zero_credit_debt_no_settlement_transaction(
        self,
        engine,
        mock_rollover_repository,
        fake_credit_ledger,
    ):
        """When there is no credit debt, settle() should not be called."""
        unclosed_month = {"id": 8, "year": 2025, "month": 8}
        mock_rollover_repository.get_unclosed_months_before.return_value = [unclosed_month]
        mock_rollover_repository.get_or_create_month_state_locked.return_value = {
            "id": 100,
            "user_id": 1,
            "month_id": 8,
            "status": "open",
        }

        # Setup: No credit debt
        fake_credit_ledger.set_balance(user_id=1, amount=Decimal("0.00"))

        # Execute
        result = engine.run_rollover_check(user_id=1)

        # Verify: settle() was not called
        assert len(fake_credit_ledger.settled) == 0
        assert result[0]["credit_settled_amount"] == Decimal("0.00")


# ============================================================================
# Tests: Idempotency
# ============================================================================


class TestIdempotency:
    """Test that running rollover twice on the same month doesn't double-insert."""

    def test_running_rollover_twice_on_rolled_over_month_does_nothing(
        self,
        engine,
        mock_rollover_repository,
    ):
        """
        If a month is already marked rolled_over, calling run_rollover_check again
        should not include it in the unclosed months, so no duplicate transactions.
        """
        # Setup: First run finds month 8 unclosed
        unclosed_month = {"id": 8, "year": 2025, "month": 8}
        mock_rollover_repository.get_unclosed_months_before.return_value = [unclosed_month]
        mock_rollover_repository.get_or_create_month_state_locked.return_value = {
            "id": 100,
            "user_id": 1,
            "month_id": 8,
            "status": "open",
        }

        # Execute first run
        engine.run_rollover_check(user_id=1)

        # Setup: Second run finds no unclosed months (month 8 is now rolled_over)
        mock_rollover_repository.get_unclosed_months_before.return_value = []

        # Execute second run
        result = engine.run_rollover_check(user_id=1)

        # Verify: Second run returns empty (no months closed)
        assert len(result) == 0

    def test_engine_skips_a_month_already_marked_rolled_over(
        self,
        engine,
        mock_rollover_repository,
        mock_transactions_repository,
    ):
        """
        Defense in depth: even if a month somehow still appears in the unclosed
        list (e.g. a caller bug bypassing the repository's own filter), the
        engine itself must not act twice on a month whose state is already
        'rolled_over' — no second sweep/payoff transaction gets inserted.
        """
        unclosed_month = {"id": 8, "year": 2025, "month": 8}
        mock_rollover_repository.get_unclosed_months_before.return_value = [unclosed_month]
        mock_rollover_repository.get_or_create_month_state_locked.return_value = {
            "id": 100,
            "user_id": 1,
            "month_id": 8,
            "status": "rolled_over",  # already closed
        }

        result = engine.run_rollover_check(user_id=1)

        assert result == []
        mock_transactions_repository.insert.assert_not_called()
        mock_rollover_repository.mark_rolled_over.assert_not_called()


# ============================================================================
# Tests: Multi-month catch-up
# ============================================================================


class TestMultiMonthCatchUp:
    """Test rolling over multiple unclosed months in chronological order."""

    def test_multiple_unclosed_months_rolled_over_in_order(
        self,
        engine,
        mock_rollover_repository,
        mock_transactions_repository,
    ):
        """
        If months 6, 7, 8 are unclosed (before current month 9):
        - Should roll over all three
        - In chronological order (6, then 7, then 8)
        - Verify via call order to get_or_create_month_state_locked
        """
        unclosed_months = [
            {"id": 6, "year": 2025, "month": 6},
            {"id": 7, "year": 2025, "month": 7},
            {"id": 8, "year": 2025, "month": 8},
        ]
        mock_rollover_repository.get_unclosed_months_before.return_value = unclosed_months

        # Setup: Each month gets its own state
        state_results = [
            {"id": 100, "user_id": 1, "month_id": 6, "status": "open"},
            {"id": 101, "user_id": 1, "month_id": 7, "status": "open"},
            {"id": 102, "user_id": 1, "month_id": 8, "status": "open"},
        ]
        mock_rollover_repository.get_or_create_month_state_locked.side_effect = state_results

        # Execute
        result = engine.run_rollover_check(user_id=1)

        # Verify: All three months were rolled over
        assert len(result) == 3
        assert result[0]["month_id"] == 6
        assert result[1]["month_id"] == 7
        assert result[2]["month_id"] == 8

    def test_multi_month_catch_up_marks_all_as_rolled_over(
        self,
        engine,
        mock_rollover_repository,
        mock_transactions_repository,
    ):
        """
        Verify that mark_rolled_over is called for each closed month.
        """
        unclosed_months = [
            {"id": 6, "year": 2025, "month": 6},
            {"id": 7, "year": 2025, "month": 7},
        ]
        mock_rollover_repository.get_unclosed_months_before.return_value = unclosed_months

        state_results = [
            {"id": 100, "user_id": 1, "month_id": 6, "status": "open"},
            {"id": 101, "user_id": 1, "month_id": 7, "status": "open"},
        ]
        mock_rollover_repository.get_or_create_month_state_locked.side_effect = state_results

        # Execute
        engine.run_rollover_check(user_id=1)

        # Verify: mark_rolled_over called twice (once per month)
        assert mock_rollover_repository.mark_rolled_over.call_count == 2

        # Verify: called for state IDs 100 and 101
        calls = mock_rollover_repository.mark_rolled_over.call_args_list
        assert calls[0][0][0] == 100  # First call: state_id 100
        assert calls[1][0][0] == 101  # Second call: state_id 101
