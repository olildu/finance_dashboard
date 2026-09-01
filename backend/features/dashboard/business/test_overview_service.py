"""
Unit tests for dashboard business logic: overview service composition.

Tests that OverviewService correctly composes data from four services:
- AccountsService (month-end check)
- BudgetsPaceService (budget statuses)
- CreditService (credit balance)
- TransactionsRepository (recent transactions)

Uses mocked repositories/services. Tests composition, error handling,
and response shape.
"""

from datetime import datetime, date, timezone
from decimal import Decimal
from unittest.mock import Mock

import pytest

from features.dashboard.business.overview_service import OverviewService


# ============================================================================
# Fixtures: Mocked services returning realistic data
# ============================================================================


@pytest.fixture
def mock_accounts_service():
    """Mock AccountsService returning realistic MonthEndCheckResponse data."""
    service = Mock()
    # Realistic month-end check response matching MonthEndCheckResponse schema
    service.calculate_month_end_check.return_value = {
        "ICICI": {"expected_balance": 15000.00},
        "SBI": {"expected_balance": 8500.00},
        "SLICE": {"expected_balance": 22000.00},
        "hdfc_reserve": 2500.00,
        "total_net_worth": 48000.00,
    }
    return service


@pytest.fixture
def mock_budgets_pace_service():
    """Mock BudgetsPaceService returning realistic CategoryStatus list."""
    service = Mock()
    # Realistic budget statuses matching CategoryStatus schema
    service.get_all_category_statuses.return_value = [
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
        {
            "category_code": "travel",
            "display_name": "Travel & Transport",
            "budget": Decimal("4000.00"),
            "spent": Decimal("800.00"),
            "remaining": Decimal("3200.00"),
            "days_left": 15,
            "allowance_per_day": Decimal("213.33"),
            "burn_rate_per_day": Decimal("53.33"),
            "projected_runout_date": None,
        },
    ]
    return service


@pytest.fixture
def mock_credit_service():
    """Mock CreditService returning realistic CreditBalanceResponse data."""
    service = Mock()
    # Realistic credit balance response
    service.current_balance.return_value = Decimal("1250.50")
    return service


@pytest.fixture
def mock_transactions_repository():
    """Mock TransactionsRepository returning realistic TransactionResponse list."""
    repo = Mock()
    # Realistic transactions for the month
    repo.list_for_month.return_value = [
        {
            "id": 1,
            "category_code": "food",
            "funding_account_code": "ICICI",
            "amount": Decimal("450.00"),
            "type": "expense",
            "is_overage": False,
            "reason": "Dinner at restaurant",
            "date": datetime(2025, 1, 15, 12, 30, 0, tzinfo=timezone.utc),
        },
        {
            "id": 2,
            "category_code": "travel",
            "funding_account_code": "ICICI",
            "amount": Decimal("350.00"),
            "type": "expense",
            "is_overage": False,
            "reason": "Uber trip",
            "date": datetime(2025, 1, 14, 18, 45, 0, tzinfo=timezone.utc),
        },
    ]
    return repo


@pytest.fixture
def overview_service(
    mock_accounts_service,
    mock_budgets_pace_service,
    mock_credit_service,
    mock_transactions_repository,
):
    """Create OverviewService with all mocked dependencies."""
    return OverviewService(
        accounts_service=mock_accounts_service,
        budgets_pace_service=mock_budgets_pace_service,
        credit_service=mock_credit_service,
        transactions_repository=mock_transactions_repository,
    )


# ============================================================================
# Tests: Happy path - all services return data
# ============================================================================


class TestOverviewServiceComposition:
    """Test that OverviewService correctly composes data from all services."""

    def test_get_overview_calls_all_four_services(
        self,
        overview_service,
        mock_accounts_service,
        mock_budgets_pace_service,
        mock_credit_service,
        mock_transactions_repository,
    ):
        """
        get_overview should call all four services/repositories.

        Expected behavior:
        - Call accounts_service.calculate_month_end_check(user_id, year, month)
        - Call budgets_pace_service.get_all_category_statuses(user_id, month_id)
        - Call credit_service.current_balance(user_id)
        - Call transactions_repository.list_for_month(user_id, month_id)
        """
        user_id = 1
        month_id = 1

        result = overview_service.get_overview(user_id=user_id, month_id=month_id)

        # When implemented, these should be called:
        mock_accounts_service.calculate_month_end_check.assert_called_once()
        mock_budgets_pace_service.get_all_category_statuses.assert_called_once_with(user_id=user_id, month_id=month_id)
        mock_credit_service.current_balance.assert_called_once_with(user_id=user_id)
        mock_transactions_repository.list_for_month.assert_called_once_with(user_id=user_id, month_id=month_id)

    def test_get_overview_returns_composed_dict_structure(
        self, overview_service
    ):
        """
        get_overview should return dict with keys: month_end_check, budget_statuses,
        credit_balance, recent_transactions.

        Expected behavior:
        - Returns dict with exactly these keys:
          - month_end_check: dict from AccountsService
          - budget_statuses: list from BudgetsPaceService
          - credit_balance: dict with balance key from CreditService
          - recent_transactions: list from TransactionsRepository
        """
        result = overview_service.get_overview(user_id=1, month_id=1)

        # Check that the result has the expected keys
        assert isinstance(result, dict)
        assert set(result.keys()) == {"month_end_check", "budget_statuses", "credit_balance", "recent_transactions"}
        assert isinstance(result["month_end_check"], dict)
        assert isinstance(result["budget_statuses"], list)
        assert isinstance(result["credit_balance"], dict)
        assert isinstance(result["recent_transactions"], list)

    def test_get_overview_merges_realistic_service_data(
        self,
        overview_service,
        mock_accounts_service,
        mock_budgets_pace_service,
        mock_credit_service,
        mock_transactions_repository,
    ):
        """
        When implemented, get_overview should merge realistic data from all services.

        Documents expected structure with real schema data.
        """
        user_id = 1
        month_id = 1

        result = overview_service.get_overview(user_id=user_id, month_id=month_id)

        # Should compose correctly with all data from mocked services
        assert result["month_end_check"] == mock_accounts_service.calculate_month_end_check.return_value
        assert result["budget_statuses"] == mock_budgets_pace_service.get_all_category_statuses.return_value
        assert result["credit_balance"]["balance"] == mock_credit_service.current_balance.return_value
        assert result["recent_transactions"] == mock_transactions_repository.list_for_month.return_value


# ============================================================================
# Tests: Error handling - propagation strategy
# ============================================================================


class TestOverviewServiceErrorHandling:
    """
    Test error handling when one service fails.

    Error Strategy: Propagate errors from any failing service to the caller.
    This keeps the implementation simple and allows the API to fail fast.
    If a specific service failure should be handled gracefully (e.g., missing
    transactions), that can be added in the future.

    Note: During stub phase, get_overview raises NotImplementedError before
    calling any services. These tests document the EXPECTED behavior when
    the service is implemented.
    """

    def test_get_overview_propagates_service_errors(
        self,
        overview_service,
        mock_accounts_service,
    ):
        """
        get_overview should propagate errors from services to caller.

        When implemented, it will call the four services in sequence,
        propagating any errors that occur.
        """
        # Make accounts_service raise an error
        mock_accounts_service.calculate_month_end_check.side_effect = ValueError("Test error")

        with pytest.raises(ValueError, match="Test error"):
            overview_service.get_overview(user_id=1, month_id=1)

    def test_error_handling_strategy_documented(self):
        """
        Documents the error handling strategy for when get_overview is implemented.

        When implemented, get_overview should:
        1. Call accounts_service.calculate_month_end_check(user_id, month_id)
           → If fails: Propagate error (critical for dashboard)
        2. Call budgets_pace_service.get_all_category_statuses(user_id, month_id)
           → If fails: Propagate error (critical for dashboard)
        3. Call credit_service.current_balance(user_id)
           → If fails: Propagate error (part of financial overview)
        4. Call transactions_repository.list_for_month(user_id, month_id)
           → If fails: Propagate error (needed for activity feed)

        This propagation strategy keeps the implementation simple and allows
        the API to fail fast. The caller (endpoint) can decide whether to
        return partial data, retry, or propagate to user.
        """
        pass  # This is a documentation test


# ============================================================================
# Tests: Service initialization
# ============================================================================


class TestOverviewServiceInitialization:
    """Test OverviewService initialization."""

    def test_service_stores_all_dependencies(
        self,
        overview_service,
        mock_accounts_service,
        mock_budgets_pace_service,
        mock_credit_service,
        mock_transactions_repository,
    ):
        """OverviewService should store all four dependencies as instance variables."""
        assert overview_service.accounts_service is mock_accounts_service
        assert overview_service.budgets_pace_service is mock_budgets_pace_service
        assert overview_service.credit_service is mock_credit_service
        assert overview_service.transactions_repository is mock_transactions_repository

    def test_service_can_be_created_with_none_dependencies(self):
        """OverviewService constructor should accept any objects (no type checking)."""
        # Should not raise
        service = OverviewService(
            accounts_service=None,
            budgets_pace_service=None,
            credit_service=None,
            transactions_repository=None,
        )
        assert service.accounts_service is None
