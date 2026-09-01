"""
Unit tests for transactions business logic: overage handling and transaction recording.

Uses mocked repository and a fake CreditLedgerInterface implementation.
Tests the record_expense method with various scenarios including budget overflow,
shared envelopes (travel/party_outside), and correct funding account assignment.
"""

from decimal import Decimal
from unittest.mock import Mock

import pytest

from features.categories.data.repository import CategoriesRepository
from features.credit.business.interface import CreditLedgerInterface
from features.transactions.business.service import TransactionsService
from features.transactions.data.repository import TransactionsRepository


# ============================================================================
# Fake CreditLedgerInterface implementation (legitimate boundary mock)
# ============================================================================


class FakeCreditLedger(CreditLedgerInterface):
    """In-test fake implementation of CreditLedgerInterface for testing."""

    def __init__(self):
        self.recorded_overages = []

    def current_balance(self, user_id: int) -> Decimal:
        """Return current balance (not used in these tests)."""
        return Decimal("0")

    def record_overage(
        self, user_id: int, month_id: int, category_id: int, amount: Decimal, transaction_id: int
    ) -> None:
        """Record an overage transaction."""
        self.recorded_overages.append(
            {
                "user_id": user_id,
                "month_id": month_id,
                "category_id": category_id,
                "amount": amount,
                "transaction_id": transaction_id,
            }
        )

    def settle(self, user_id: int, month_id: int, amount: Decimal, transaction_id: int) -> Decimal:
        """Settle a credit ledger amount (not used in these tests)."""
        return Decimal("0")


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def mock_transactions_repository():
    """Mock transactions repository."""
    repo = Mock(spec=TransactionsRepository)
    repo.sum_expense_for_envelope_in_month = Mock(return_value=Decimal("0"))
    repo.insert = Mock(return_value=1)
    return repo


@pytest.fixture
def mock_categories_repository():
    """Mock categories repository with seeded category data."""
    repo = Mock(spec=CategoriesRepository)

    # Seeded categories with envelope and account info
    categories_by_code = {
        "food": {
            "id": 1,
            "code": "food",
            "display_name": "Food",
            "envelope_id": 1,
            "envelope_name": "Food",
            "monthly_amount": Decimal("6000.00"),
            "account_code": "ICICI",
        },
        "rent": {
            "id": 3,
            "code": "rent",
            "display_name": "Rent",
            "envelope_id": 3,
            "envelope_name": "Rent",
            "monthly_amount": Decimal("17000.00"),
            "account_code": "SLICE",
        },
        "travel": {
            "id": 5,
            "code": "travel",
            "display_name": "Travel",
            "envelope_id": 2,  # SHARED with party_outside
            "envelope_name": "PartyOutsideTravel",
            "monthly_amount": Decimal("4000.00"),
            "account_code": "SBI",
        },
        "party_outside": {
            "id": 6,
            "code": "party_outside",
            "display_name": "Party Outside",
            "envelope_id": 2,  # SHARED with travel
            "envelope_name": "PartyOutsideTravel",
            "monthly_amount": Decimal("4000.00"),
            "account_code": "SBI",
        },
        "electricity": {
            "id": 4,
            "code": "electricity",
            "display_name": "Electricity",
            "envelope_id": 4,
            "envelope_name": "Electricity",
            "monthly_amount": Decimal("100.00"),
            "account_code": "SLICE",
        },
        "phone_internet": {
            "id": 7,
            "code": "phone_internet",
            "display_name": "Phone Internet",
            "envelope_id": 5,
            "envelope_name": "PhoneInternet",
            "monthly_amount": Decimal("300.00"),
            "account_code": "SLICE",
        },
        "misc": {
            "id": 8,
            "code": "misc",
            "display_name": "Misc",
            "envelope_id": 6,
            "envelope_name": "Misc",
            "monthly_amount": Decimal("5000.00"),
            "account_code": "ICICI",
        },
    }

    def get_category_by_code(code: str):
        return categories_by_code.get(code)

    repo.get_category_by_code = Mock(side_effect=get_category_by_code)
    return repo


@pytest.fixture
def fake_credit_interface():
    """Provide a fake CreditLedgerInterface implementation."""
    return FakeCreditLedger()


@pytest.fixture
def service(mock_transactions_repository, mock_categories_repository, fake_credit_interface):
    """Provide a TransactionsService with mocked dependencies."""
    return TransactionsService(
        mock_transactions_repository, mock_categories_repository, fake_credit_interface
    )


# ============================================================================
# Tests: No prior spend + amount <= budget (no overage)
# ============================================================================


class TestNoPriorSpendUnderBudget:
    """Test record_expense when no prior spend and amount <= budget."""

    def test_no_spend_under_budget_is_overage_false(self, service, mock_transactions_repository):
        """No prior spend + amount <= budget should set is_overage=False."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal("0")

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="food",
            amount=Decimal("500.00"),
            reason="Lunch",
            date="2025-09-01",
        )

        assert result["is_overage"] is False

    def test_no_spend_under_budget_funding_account_is_envelope_account(
        self, service, mock_transactions_repository
    ):
        """Funding account should be the envelope's real account code."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal("0")

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="food",
            amount=Decimal("500.00"),
            reason="Lunch",
            date="2025-09-01",
        )

        assert result["funding_account_code"] == "ICICI"

    def test_no_spend_under_budget_credit_interface_not_called(
        self, service, mock_transactions_repository, fake_credit_interface
    ):
        """credit_interface.record_overage should NOT be called."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal("0")

        service.record_expense(
            user_id=1,
            month_id=1,
            category_code="food",
            amount=Decimal("500.00"),
            reason="Lunch",
            date="2025-09-01",
        )

        assert len(fake_credit_interface.recorded_overages) == 0

    def test_no_spend_under_budget_repository_insert_called_with_correct_values(
        self, service, mock_transactions_repository
    ):
        """repository.insert should be called with correct values."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal("0")

        service.record_expense(
            user_id=1,
            month_id=1,
            category_code="food",
            amount=Decimal("500.00"),
            reason="Lunch",
            date="2025-09-01",
        )

        # Verify insert was called
        assert mock_transactions_repository.insert.called
        call_args = mock_transactions_repository.insert.call_args

        # Check named or positional arguments
        assert call_args.kwargs.get("is_overage") is False or call_args[0][6] is False
        assert call_args.kwargs.get("amount") == Decimal("500.00") or call_args[0][4] == Decimal(
            "500.00"
        )


# ============================================================================
# Tests: Prior spend + new amount > budget (overage)
# ============================================================================


class TestPriorSpendPlusNewExceedsBudget:
    """Test record_expense when (prior_spend + amount) > budget."""

    def test_prior_plus_new_exceeds_budget_is_overage_true(
        self, service, mock_transactions_repository
    ):
        """(prior + amount) > budget should set is_overage=True."""
        # Prior spend: 3800, Budget: 4000, New amount: 300
        # 3800 + 300 = 4100 > 4000 → overage
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal(
            "3800.00"
        )

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="travel",  # Envelope: 4000
            amount=Decimal("300.00"),
            reason="Flight",
            date="2025-09-05",
        )

        assert result["is_overage"] is True

    def test_prior_plus_new_exceeds_budget_funding_account_is_credit(
        self, service, mock_transactions_repository
    ):
        """Funding account should be CREDIT for overage."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal(
            "3800.00"
        )

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="travel",
            amount=Decimal("300.00"),
            reason="Flight",
            date="2025-09-05",
        )

        assert result["funding_account_code"] == "CREDIT"

    def test_prior_plus_new_exceeds_budget_credit_interface_called(
        self, service, mock_transactions_repository, fake_credit_interface
    ):
        """credit_interface.record_overage should be called."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal(
            "3800.00"
        )

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="travel",
            amount=Decimal("300.00"),
            reason="Flight",
            date="2025-09-05",
        )

        assert len(fake_credit_interface.recorded_overages) == 1
        overage = fake_credit_interface.recorded_overages[0]
        assert overage["user_id"] == 1
        assert overage["month_id"] == 1
        assert overage["category_id"] == 5  # travel category id
        assert overage["amount"] == Decimal("300.00")

    def test_prior_plus_new_exceeds_budget_entire_amount_is_overage(
        self, service, mock_transactions_repository
    ):
        """Entire new transaction should be marked as overage."""
        # Prior: 3900, Budget: 4000, New: 500
        # 3900 + 500 = 4400 > 4000 → entire 500 is overage
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal(
            "3900.00"
        )

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="travel",
            amount=Decimal("500.00"),
            reason="Hotel",
            date="2025-09-06",
        )

        assert result["amount"] == Decimal("500.00")
        assert result["is_overage"] is True


# ============================================================================
# Tests: Prior spend == budget (even small amount is overage)
# ============================================================================


class TestPriorSpendEqualsExactBudget:
    """Test record_expense when prior spend exactly equals budget."""

    def test_prior_equals_budget_any_amount_is_overage(
        self, service, mock_transactions_repository
    ):
        """When prior spend == budget, any positive amount should be overage."""
        # Prior: 4000 (exactly = budget), New: 100
        # 4000 + 100 = 4100 > 4000 → overage
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal(
            "4000.00"
        )

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="travel",
            amount=Decimal("100.00"),
            reason="Snack",
            date="2025-09-07",
        )

        assert result["is_overage"] is True

    def test_prior_equals_budget_even_one_cent_is_overage(
        self, service, mock_transactions_repository
    ):
        """Even a tiny amount when at budget should be overage."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal(
            "4000.00"
        )

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="travel",
            amount=Decimal("0.01"),
            reason="Tiny thing",
            date="2025-09-08",
        )

        assert result["is_overage"] is True
        assert result["funding_account_code"] == "CREDIT"


# ============================================================================
# Tests: Shared envelope (travel and party_outside)
# ============================================================================


class TestSharedEnvelopeTravelPartyOutside:
    """Test record_expense with shared envelope (travel and party_outside)."""

    def test_party_outside_spending_counts_toward_shared_envelope(
        self, service, mock_transactions_repository
    ):
        """Party outside expense should count toward shared 4000 budget."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal(
            "0.00"
        )

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="party_outside",
            amount=Decimal("2000.00"),
            reason="Birthday party",
            date="2025-09-01",
        )

        assert result["is_overage"] is False
        assert result["funding_account_code"] == "SBI"
        # Sum was called for the shared envelope
        assert mock_transactions_repository.sum_expense_for_envelope_in_month.called

    def test_travel_spending_counts_toward_shared_envelope(
        self, service, mock_transactions_repository
    ):
        """Travel expense should count toward shared 4000 budget."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal(
            "0.00"
        )

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="travel",
            amount=Decimal("2500.00"),
            reason="Flight",
            date="2025-09-02",
        )

        assert result["is_overage"] is False
        assert result["funding_account_code"] == "SBI"

    def test_party_outside_then_travel_exceed_shared_budget(
        self, service, mock_transactions_repository, fake_credit_interface
    ):
        """
        Scenario: Record party_outside (2500), then travel (2000).
        Shared budget is 4000. 2500 + 2000 = 4500 > 4000.
        Second transaction should be marked overage.
        """
        # First call: no prior spend
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal(
            "2500.00"
        )

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="travel",  # Using travel after party_outside
            amount=Decimal("2000.00"),
            reason="Flight",
            date="2025-09-02",
        )

        # 2500 + 2000 = 4500 > 4000 → overage
        assert result["is_overage"] is True
        assert result["funding_account_code"] == "CREDIT"

        # credit_interface should have been called
        assert len(fake_credit_interface.recorded_overages) == 1

    def test_travel_then_party_outside_exceed_shared_budget(
        self, service, mock_transactions_repository, fake_credit_interface
    ):
        """
        Scenario: Record travel (2500), then party_outside (2000).
        Shared budget is 4000. 2500 + 2000 = 4500 > 4000.
        Second transaction should be marked overage.
        """
        # First transaction: travel (2500) - no prior spend
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal(
            "0.00"
        )
        result1 = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="travel",
            amount=Decimal("2500.00"),
            reason="Flight",
            date="2025-09-01",
        )
        assert result1["is_overage"] is False

        # Second transaction: party_outside (2000) - prior spend is 2500
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal(
            "2500.00"
        )
        result2 = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="party_outside",
            amount=Decimal("2000.00"),
            reason="Birthday party",
            date="2025-09-02",
        )

        # 2500 + 2000 = 4500 > 4000 → overage
        assert result2["is_overage"] is True
        assert result2["funding_account_code"] == "CREDIT"

    def test_within_shared_budget_no_overage(
        self, service, mock_transactions_repository
    ):
        """When spending stays within shared budget, no overage."""
        # Travel: 2000, Party: 1500 = 3500 < 4000
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal(
            "2000.00"
        )

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="party_outside",
            amount=Decimal("1500.00"),
            reason="Dinner",
            date="2025-09-03",
        )

        assert result["is_overage"] is False
        assert result["funding_account_code"] == "SBI"


# ============================================================================
# Tests: Response structure and content
# ============================================================================


class TestRecordExpenseResponseStructure:
    """Test the structure and content of record_expense response."""

    def test_response_includes_all_required_fields(self, service, mock_transactions_repository):
        """Response should include id, category_code, funding_account_code, amount, etc."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal("0")
        mock_transactions_repository.insert.return_value = 42

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="food",
            amount=Decimal("500.00"),
            reason="Lunch",
            date="2025-09-01",
        )

        assert "id" in result
        assert "category_code" in result
        assert "funding_account_code" in result
        assert "amount" in result
        assert "type" in result
        assert "is_overage" in result
        assert "reason" in result
        assert "date" in result

    def test_response_category_code_matches_input(self, service, mock_transactions_repository):
        """Response category_code should match the input."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal("0")

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="rent",
            amount=Decimal("1000.00"),
            reason="Rent",
            date="2025-09-01",
        )

        assert result["category_code"] == "rent"

    def test_response_amount_matches_input(self, service, mock_transactions_repository):
        """Response amount should match the input."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal("0")

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="food",
            amount=Decimal("750.50"),
            reason="Lunch",
            date="2025-09-01",
        )

        assert result["amount"] == Decimal("750.50")

    def test_response_type_is_expense(self, service, mock_transactions_repository):
        """Response type should always be 'expense'."""
        mock_transactions_repository.sum_expense_for_envelope_in_month.return_value = Decimal("0")

        result = service.record_expense(
            user_id=1,
            month_id=1,
            category_code="food",
            amount=Decimal("500.00"),
            reason="Lunch",
            date="2025-09-01",
        )

        assert result["type"] == "expense"
