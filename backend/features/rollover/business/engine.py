"""
Rollover engine: monthly settle, refill, and sweep business logic.

The engine implements the core algorithm for closing out old months and rolling
over balances into the current month. The algorithm ensures credit debt is settled,
envelopes are swept for reuse, and fixed allocations are maintained.
"""

from decimal import Decimal


class RolloverEngine:
    """
    Monthly rollover engine: settle credit, sweep envelopes, prepare next month.

    Algorithm (run_rollover_check):
    1. Find the current month from the clock.
    2. For each unclosed month strictly before the current month (in chronological order):
       a. Settle outstanding credit debt from Slice account:
          - Query the credit ledger's total outstanding balance for this user.
          - If > 0, insert a credit_payoff transaction funded FROM Slice (money leaves
            savings to pay the card off) and call credit_ledger_interface.settle(...).
       b. Refill (no-op in the current design):
          - Spend is always derived fresh from transactions; no refill needed.
       c. Sweep leftover-per-envelope + fixed allocation:
          - For each budget envelope, leftover = max(monthly_amount - non_overage_spend, 0).
            Overage spend is excluded — that money already went to Credit, it was
            never envelope capacity to begin with, so it must not double-count here.
          - Sum all leftovers, add the fixed unbudgeted portion
            (settings.SALARY_TOTAL - sum(all envelope monthly_amounts)).
          - Insert a single rollover_sweep transaction funded INTO Slice for that total.
       d. Mark month as rolled_over with amounts recorded.

    A month whose user_month_state is already 'rolled_over' is skipped even if it
    somehow appears in the unclosed list (defense in depth against a caller bypassing
    the repository's own filter).
    """

    def __init__(
        self,
        rollover_repository,
        transactions_repository,
        budget_envelopes_lookup,
        credit_ledger_interface,
        clock,
        salary_total: Decimal,
        slice_account_id: int,
    ):
        """
        Initialize the rollover engine.

        Args:
            rollover_repository: RolloverRepository instance for month state queries.
            transactions_repository: TransactionsRepository for inserting payoff/sweep.
            budget_envelopes_lookup: Zero-arg callable returning all budget envelopes
                                     (each with at least "id" and "monthly_amount").
            credit_ledger_interface: CreditLedgerInterface for settling credit debt.
            clock: Clock instance for getting current month — never call datetime.now().
            salary_total: The fixed monthly salary total (from core.config.settings),
                          used to compute the unbudgeted portion swept to savings.
            slice_account_id: Account id for Slice — both the payoff source and the
                              sweep destination.
        """
        self.rollover_repository = rollover_repository
        self.transactions_repository = transactions_repository
        self.budget_envelopes_lookup = budget_envelopes_lookup
        self.credit_ledger_interface = credit_ledger_interface
        self.clock = clock
        self.salary_total = Decimal(str(salary_total))
        self.slice_account_id = slice_account_id

    def run_rollover_check(self, user_id: int) -> list[dict]:
        """
        Run the rollover check and close out unclosed months for this user.

        Returns:
            A list of dicts, one per month actually closed during this call, with:
            - month_id, credit_settled_amount, sweep_amount
        """
        now = self.clock.now()
        current_month_id = self.rollover_repository.get_or_create_month(now.year, now.month)

        unclosed_months = self.rollover_repository.get_unclosed_months_before(
            user_id, current_month_id
        )

        results = []
        for month in unclosed_months:
            month_id = month["id"]

            month_state = self.rollover_repository.get_or_create_month_state_locked(
                user_id, month_id
            )

            # Defense in depth: the repository's own query should already exclude
            # rolled-over months, but never act twice on the same month regardless.
            if month_state["status"] == "rolled_over":
                continue

            state_id = month_state["id"]

            credit_settled_amount = self._settle_credit_debt(user_id, month_id)
            sweep_amount = self._sweep_envelopes(user_id, month_id)

            self.rollover_repository.mark_rolled_over(
                state_id,
                credit_settled_amount=credit_settled_amount,
                sweep_amount=sweep_amount,
            )

            results.append(
                {
                    "month_id": month_id,
                    "credit_settled_amount": credit_settled_amount,
                    "sweep_amount": sweep_amount,
                }
            )

        return results

    def _settle_credit_debt(self, user_id: int, month_id: int) -> Decimal:
        """
        Pay off the user's entire outstanding credit balance from Slice.

        The credit ledger tracks an ongoing balance across all months (it is debt,
        not a per-month figure), so the whole outstanding amount is settled here,
        attributed to the month being closed.

        Returns:
            The Decimal amount settled (0 if there was no debt).
        """
        outstanding = self.credit_ledger_interface.current_balance(user_id)

        if outstanding <= 0:
            return Decimal("0")

        transaction_id = self.transactions_repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=None,
            funding_account_id=self.slice_account_id,
            amount=outstanding,
            type="credit_payoff",
            is_overage=False,
            reason="Monthly credit payoff",
            date=self.clock.now().date().isoformat(),
        )

        self.credit_ledger_interface.settle(user_id, month_id, outstanding, transaction_id)

        return outstanding

    def _sweep_envelopes(self, user_id: int, month_id: int) -> Decimal:
        """
        Sweep leftover budget across all envelopes, plus the fixed unbudgeted
        portion of salary, into a single transaction funded into Slice.

        Returns:
            The Decimal total sweep amount (leftover + fixed unbudgeted portion).
        """
        envelopes = self.budget_envelopes_lookup()

        total_leftover = Decimal("0")
        total_envelope_budget = Decimal("0")

        for envelope in envelopes:
            monthly_amount = Decimal(str(envelope["monthly_amount"]))
            total_envelope_budget += monthly_amount

            # Only non-overage spend consumed envelope capacity; overage spend
            # was funded by Credit and must not reduce this envelope's leftover.
            spent = self.transactions_repository.sum_expense_for_envelope_in_month(
                user_id, month_id, envelope["id"], is_overage=False
            )

            leftover = max(monthly_amount - spent, Decimal("0"))
            total_leftover += leftover

        fixed_unbudgeted = self.salary_total - total_envelope_budget
        total_sweep = total_leftover + fixed_unbudgeted

        self.transactions_repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=None,
            funding_account_id=self.slice_account_id,
            amount=total_sweep,
            type="rollover_sweep",
            is_overage=False,
            reason="Monthly rollover sweep",
            date=self.clock.now().date().isoformat(),
        )

        return total_sweep
