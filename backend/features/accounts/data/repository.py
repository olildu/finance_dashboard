"""
Accounts data layer: database access patterns for accounts, budgets, and transactions.

Uses feature-sliced architecture: repository is the only layer touching SQL.
All queries operate on a RealDictCursor for dict-like row access.
"""


class AccountsRepository:
    """Repository for accounts database operations."""

    def __init__(self, cursor):
        """
        Initialize with a database cursor.

        Args:
            cursor: RealDictCursor from FastAPI get_db() dependency.
        """
        self.cursor = cursor

    def get_all_accounts(self) -> list:
        """
        Get all accounts with id, code, display_name, kind, fixed_amount.

        Returns:
            List of dicts: [{"id": int, "code": str, "display_name": str, "kind": str, "fixed_amount": float|None}, ...]
        """
        self.cursor.execute(
            """
            SELECT id, code, display_name, kind, fixed_amount
            FROM accounts
            ORDER BY id
            """
        )
        return self.cursor.fetchall()

    def get_all_budget_envelopes(self) -> list:
        """
        Get all budget envelopes with id, name, monthly_amount, account_id.

        Returns:
            List of dicts: [{"id": int, "name": str, "monthly_amount": float, "account_id": int}, ...]
        """
        self.cursor.execute(
            """
            SELECT id, name, monthly_amount, account_id
            FROM budget_envelopes
            ORDER BY id
            """
        )
        return self.cursor.fetchall()

    def get_month_id(self, year: int, month: int) -> int | None:
        """
        Get month_id for given year/month; return None if not found.

        Args:
            year: Year (e.g., 2025)
            month: Month (1-12)

        Returns:
            int: month_id if found, None otherwise.
        """
        self.cursor.execute(
            "SELECT id FROM months WHERE year = %s AND month = %s",
            (year, month),
        )
        result = self.cursor.fetchone()
        return result["id"] if result else None

    def create_month(self, year: int, month: int) -> int:
        """
        Create a new month entry; return month_id.

        Handles race condition: if month already exists (UNIQUE constraint),
        returns the existing month_id.

        Args:
            year: Year (e.g., 2025)
            month: Month (1-12)

        Returns:
            int: The month_id (newly created or existing).
        """
        self.cursor.execute(
            "INSERT INTO months (year, month) VALUES (%s, %s) ON CONFLICT (year, month) DO NOTHING RETURNING id",
            (year, month),
        )
        result = self.cursor.fetchone()
        if result:
            return result["id"]
        # If INSERT returned nothing (conflict), re-select
        return self.get_month_id(year, month)

    def get_transactions_for_month(self, user_id: int, month_id: int) -> list:
        """
        Get all transactions for a user in a given month.

        Args:
            user_id: User ID
            month_id: Month ID

        Returns:
            List of dicts: [{"id": int, "user_id": int, "month_id": int, "category_id": int|None,
                            "funding_account_id": int, "amount": float, "type": str, "is_overage": bool,
                            "reason": str|None, "date": datetime, "created_at": datetime}, ...]
        """
        self.cursor.execute(
            """
            SELECT id, user_id, month_id, category_id, funding_account_id,
                   amount, type, is_overage, reason, date, created_at
            FROM transactions
            WHERE user_id = %s AND month_id = %s
            ORDER BY id
            """,
            (user_id, month_id),
        )
        return self.cursor.fetchall()

