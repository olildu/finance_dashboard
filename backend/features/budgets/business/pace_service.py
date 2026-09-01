"""
Budget pace calculations for per-category allowance and burn-rate projections.

Computes, for the current month, per-category metrics including allowance pace,
burn-rate, and projected runout dates.
"""

import calendar
from datetime import timedelta
from decimal import Decimal

from core.clock import Clock
from features.categories.data.repository import CategoriesRepository
from features.transactions.data.repository import TransactionsRepository


class BudgetsPaceService:
    """Service for computing budget pace and burn-rate metrics per category."""

    def __init__(
        self,
        categories_repository: CategoriesRepository,
        transactions_repository: TransactionsRepository,
        clock: Clock,
    ):
        """
        Initialize the pace service.

        Args:
            categories_repository: Repository to fetch categories with envelope and budget info.
            transactions_repository: Repository to fetch transaction amounts for calculation.
            clock: Clock to get current date (never call datetime.now() directly).
        """
        self.categories_repository = categories_repository
        self.transactions_repository = transactions_repository
        self.clock = clock

    def get_all_category_statuses(self, user_id: int, month_id: int) -> list[dict]:
        """
        Compute budget status for all categories in a given month.

        Formula per category:
        - days_in_month = calendar.monthrange(year, month)[1]
        - days_elapsed = today.day
        - days_left = days_in_month - days_elapsed + 1
        - spent = sum_expense_for_envelope_in_month(...) [non-overage only]
        - remaining = max(budget - spent, 0)
        - allowance_per_day = remaining / days_left
        - burn_rate_per_day = spent / days_elapsed if days_elapsed > 0 else 0
        - projected_runout_date = None if burn_rate_per_day == 0
                                   else month_start + timedelta(days=budget/burn_rate_per_day)

        Note: travel and party_outside share one envelope, so their spent/budget/pace
        numbers will be identical to each other but each still appears as its own category entry.

        Args:
            user_id: ID of the user.
            month_id: ID of the budget month.

        Returns:
            A list of dicts, one per category, with keys:
            - category_code: str (e.g., 'food', 'rent', 'travel')
            - display_name: str (human-readable name)
            - budget: Decimal (monthly allocation)
            - spent: Decimal (non-overage expenses)
            - remaining: Decimal (budget - spent, clamped >= 0)
            - days_left: int
            - allowance_per_day: Decimal
            - burn_rate_per_day: Decimal
            - projected_runout_date: date or None

        Raises:
            NotImplementedError: This is a stub; real implementation TBD.
        """
        # Get current date from injected clock
        now = self.clock.now()
        current_year = now.year
        current_month = now.month
        current_day = now.day

        # Calculate days in month
        days_in_month = calendar.monthrange(current_year, current_month)[1]

        # Calculate days elapsed and days left
        days_elapsed = current_day
        days_left = days_in_month - days_elapsed + 1

        # Get all active categories with envelope info
        categories = self.categories_repository.get_all_active_categories_with_envelopes()

        result = []
        for category in categories:
            category_code = category["code"]
            display_name = category["display_name"]
            budget = Decimal(str(category["monthly_amount"]))
            envelope_id = category["envelope_id"]

            # Get spending for this envelope (non-overage only)
            spent = self.transactions_repository.sum_expense_for_envelope_in_month(
                user_id=user_id,
                month_id=month_id,
                envelope_id=envelope_id,
                is_overage=False,
            )

            # Calculate remaining (clamped to >= 0)
            remaining = max(budget - spent, Decimal("0"))

            # Calculate allowance per day
            allowance_per_day = remaining / Decimal(str(days_left))

            # Calculate burn rate per day
            if days_elapsed > 0:
                burn_rate_per_day = spent / Decimal(str(days_elapsed))
            else:
                burn_rate_per_day = Decimal("0")

            # Calculate projected runout date
            if burn_rate_per_day == Decimal("0"):
                projected_runout_date = None
            else:
                # month_start is the first day of current month
                month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
                # days_to_runout = budget / burn_rate_per_day
                days_to_runout = budget / burn_rate_per_day
                # projected_runout_date = month_start + timedelta(days=days_to_runout)
                projected_runout = month_start + timedelta(days=float(days_to_runout))
                projected_runout_date = projected_runout.date()

            result.append(
                {
                    "category_code": category_code,
                    "display_name": display_name,
                    "budget": budget,
                    "spent": spent,
                    "remaining": remaining,
                    "days_left": days_left,
                    "allowance_per_day": allowance_per_day,
                    "burn_rate_per_day": burn_rate_per_day,
                    "projected_runout_date": projected_runout_date,
                }
            )

        return result
