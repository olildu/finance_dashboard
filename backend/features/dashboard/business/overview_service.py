"""
Dashboard overview service: composition layer for all dashboard data.

This service composes AccountsService, BudgetsPaceService, CreditService,
and TransactionsRepository into a single overview response. It does NOT
reimplement any of their logic—it only calls their methods and merges
the results into one cohesive response.
"""

from core.clock import Clock


class OverviewService:
    """Service for composing dashboard overview data from multiple features."""

    def __init__(
        self,
        accounts_service,
        budgets_pace_service,
        credit_service,
        transactions_repository,
        clock: Clock = None,
    ):
        """
        Initialize the overview service with dependencies.

        Args:
            accounts_service: AccountsService instance for month-end check data.
            budgets_pace_service: BudgetsPaceService instance for budget status data.
            credit_service: CreditService instance for credit balance data.
            transactions_repository: TransactionsRepository instance for recent transactions.
            clock: Clock instance for time-based operations (defaults to new Clock() if not provided).

        Note:
            This service is a composition layer that calls each of the four dependencies
            and merges their results. It does NOT reimplement their logic.
        """
        self.accounts_service = accounts_service
        self.budgets_pace_service = budgets_pace_service
        self.credit_service = credit_service
        self.transactions_repository = transactions_repository
        self.clock = clock if clock is not None else Clock()

    def get_overview(self, user_id: int, month_id: int) -> dict:
        """
        Get a complete dashboard overview for the user in a given month.

        Composes data from:
        1. AccountsService.calculate_month_end_check() → month-end check data
        2. BudgetsPaceService.get_all_category_statuses() → budget pace/burn-rate data
        3. CreditService.current_balance() → credit balance
        4. TransactionsRepository.list_for_month() → recent transactions

        Args:
            user_id: ID of the user.
            month_id: ID of the budget month.

        Returns:
            dict: Merged overview containing:
            {
                "month_end_check": {...},  # from AccountsService
                "budget_statuses": [...],  # from BudgetsPaceService
                "credit_balance": {...},   # from CreditService
                "recent_transactions": []  # from TransactionsRepository
            }

        Raises:
            Various exceptions from underlying services (propagated to caller).
        """
        # Get current year and month from clock (for accounts service)
        now = self.clock.now()
        year = now.year
        month = now.month

        # Call all four services/repositories in sequence
        month_end_check = self.accounts_service.calculate_month_end_check(
            user_id=user_id,
            year=year,
            month=month,
        )

        budget_statuses = self.budgets_pace_service.get_all_category_statuses(
            user_id=user_id,
            month_id=month_id,
        )

        credit_balance_amount = self.credit_service.current_balance(user_id=user_id)

        recent_transactions = self.transactions_repository.list_for_month(
            user_id=user_id,
            month_id=month_id,
        )

        # Compose response: month_end_check, budget_statuses, credit_balance, recent_transactions
        return {
            "month_end_check": month_end_check,
            "budget_statuses": budget_statuses,
            "credit_balance": {"balance": credit_balance_amount},
            "recent_transactions": recent_transactions,
        }
