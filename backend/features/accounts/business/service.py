"""
Accounts business logic: expected-balance calculations for month-end check.

Pure Python use-case logic with no database access.
Depends on AccountsRepository (data layer) and Clock (time source).
"""

from decimal import Decimal

from core.clock import Clock


class AccountsService:
    """Service for accounts business logic."""

    def __init__(self, repository, clock: Clock):
        """
        Initialize with repository and clock dependencies.

        Args:
            repository: AccountsRepository instance for database access.
            clock: Clock instance for time-based logic (or mocking in tests).
        """
        self.repository = repository
        self.clock = clock

    def get_all_accounts(self) -> list:
        """
        Get all accounts.

        Returns:
            List of all accounts: [{"id": int, "code": str, "display_name": str, "kind": str, "fixed_amount": float|None}, ...]
        """
        return self.repository.get_all_accounts()

    def calculate_month_end_check(self, user_id: int, year: int, month: int) -> dict:
        """
        Calculate expected balances for bank accounts at month-end.

        For each bank account (ICICI/SBI/SLICE), computes expected balance as:
        - Sum of monthly_amount for envelopes funded by that account
        - Minus sum of 'expense' transactions (is_overage=false) for that account
        - Plus/minus 'transfer'/'rollover_sweep'/'credit_payoff' transactions

        HDFC is a fixed reserve always valued at 2500.
        CREDIT (pseudo-account) is excluded from the check.

        Args:
            user_id: User ID for transaction lookup.
            year: Year (e.g., 2025)
            month: Month (1-12)

        Returns:
            dict: {
                "ICICI": {"expected_balance": float},
                "SBI": {"expected_balance": float},
                "SLICE": {"expected_balance": float},
                "hdfc_reserve": float,
                "total_net_worth": float
            }
        """
        # Get all accounts
        accounts = self.repository.get_all_accounts()
        account_map = {acc["code"]: acc for acc in accounts}

        # Get all budget envelopes
        envelopes = self.repository.get_all_budget_envelopes()

        # Get month_id; create if it doesn't exist
        month_id = self.repository.get_month_id(year, month)
        if not month_id:
            month_id = self.repository.create_month(year, month)

        # Get transactions for this user/month
        transactions = self.repository.get_transactions_for_month(user_id, month_id)

        result = {}

        # Calculate balance for each bank account (ICICI, SBI, SLICE)
        for code in ["ICICI", "SBI", "SLICE"]:
            account = account_map.get(code)
            if not account:
                continue

            # Sum monthly amounts for envelopes funded by this account
            envelope_total = sum(
                Decimal(str(env["monthly_amount"]))
                for env in envelopes
                if env["account_id"] == account["id"]
            )

            # Sum expenses for this account (is_overage=false, type='expense')
            expenses = sum(
                Decimal(str(txn["amount"]))
                for txn in transactions
                if (
                    txn["funding_account_id"] == account["id"]
                    and txn["type"] == "expense"
                    and not txn["is_overage"]
                )
            )

            # Add/subtract non-expense transactions (transfer, rollover_sweep, credit_payoff)
            non_expense_net = sum(
                Decimal(str(txn["amount"])) if txn["type"] in ["transfer", "rollover_sweep", "credit_payoff"] else Decimal("0")
                for txn in transactions
                if txn["funding_account_id"] == account["id"] and txn["type"] != "expense"
            )

            balance = envelope_total - expenses + non_expense_net
            result[code] = {"expected_balance": float(balance)}

        # HDFC is fixed - read from accounts.fixed_amount
        hdfc_account = account_map.get("HDFC")
        hdfc_reserve = Decimal(str(hdfc_account["fixed_amount"])) if hdfc_account else Decimal("0")
        result["hdfc_reserve"] = float(hdfc_reserve)

        # Calculate total net worth
        total = sum(
            Decimal(str(b["expected_balance"]))
            for b in result.values()
            if isinstance(b, dict) and "expected_balance" in b
        )
        total += hdfc_reserve
        result["total_net_worth"] = float(total)

        return result
