"""
Repository for transactions database operations.

Implements database access patterns for managing transaction records including
insertion, retrieval, deletion, and aggregation of transactions.
"""

from decimal import Decimal


class TransactionsRepository:
    """Repository for transactions database operations."""

    def __init__(self, cursor):
        """
        Initialize with a database cursor.

        Args:
            cursor: A psycopg2 cursor (with RealDictCursor factory for dict-like access).
        """
        self.cursor = cursor

    def insert(
        self,
        user_id: int,
        month_id: int,
        category_id: int,
        funding_account_id: int,
        amount: Decimal,
        type: str,
        is_overage: bool,
        reason: str | None,
        date: str,
    ) -> int:
        """
        Insert a new transaction into the database.

        Args:
            user_id: ID of the user.
            month_id: ID of the budget month.
            category_id: ID of the category.
            funding_account_id: ID of the funding account.
            amount: Transaction amount.
            type: Transaction type (e.g., 'expense', 'income').
            is_overage: Whether this is an overage transaction.
            reason: Optional reason for the transaction.
            date: Date of the transaction.

        Returns:
            The ID of the inserted transaction.
        """
        self.cursor.execute(
            """
            INSERT INTO transactions
            (user_id, month_id, category_id, funding_account_id, amount, type, is_overage, reason, date)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (user_id, month_id, category_id, funding_account_id, amount, type, is_overage, reason, date),
        )
        result = self.cursor.fetchone()
        return result["id"]

    def list_for_month(self, user_id: int, month_id: int) -> list:
        """
        Get all transactions for a user in a specific month.

        Args:
            user_id: ID of the user.
            month_id: ID of the budget month.

        Returns:
            A list of transaction dicts with category_code and account_code.
        """
        self.cursor.execute(
            """
            SELECT t.id, t.user_id, t.month_id, t.category_id, t.funding_account_id,
                   t.amount, t.type, t.is_overage, t.reason, t.date, t.created_at,
                   c.code as category_code, a.code as funding_account_code
            FROM transactions t
            LEFT JOIN categories c ON t.category_id = c.id
            JOIN accounts a ON t.funding_account_id = a.id
            WHERE t.user_id = %s AND t.month_id = %s
            ORDER BY t.id
            """,
            (user_id, month_id),
        )
        return self.cursor.fetchall()

    def delete(self, user_id: int, transaction_id: int) -> bool:
        """
        Delete a transaction by ID.

        Args:
            user_id: ID of the user.
            transaction_id: ID of the transaction to delete.

        Returns:
            True if the transaction was deleted, False if not found.
        """
        self.cursor.execute(
            """
            DELETE FROM transactions
            WHERE id = %s AND user_id = %s
            """,
            (transaction_id, user_id),
        )
        self.cursor.connection.commit()
        return self.cursor.rowcount > 0

    def get_account_id_by_code(self, code: str) -> int:
        """
        Look up an account's id by its code (e.g. 'ICICI', 'CREDIT').

        Args:
            code: The account code.

        Returns:
            The account's id.

        Raises:
            ValueError: If no account with that code exists.
        """
        self.cursor.execute("SELECT id FROM accounts WHERE code = %s", (code,))
        result = self.cursor.fetchone()
        if result is None:
            raise ValueError(f"Account code '{code}' not found")
        return result["id"]

    def sum_expense_for_envelope_in_month(
        self, user_id: int, month_id: int, envelope_id: int, is_overage: bool = False
    ) -> Decimal:
        """
        Sum expense transactions for an envelope in a specific month.

        Args:
            user_id: ID of the user.
            month_id: ID of the budget month.
            envelope_id: ID of the budget envelope.
            is_overage: If False (default), sum non-overage expenses. If True, sum overage expenses.

        Returns:
            The sum of expenses matching the is_overage filter, or 0 if none found.
        """
        self.cursor.execute(
            """
            SELECT COALESCE(SUM(t.amount), 0) as total
            FROM transactions t
            JOIN categories c ON t.category_id = c.id
            WHERE t.user_id = %s
              AND t.month_id = %s
              AND c.envelope_id = %s
              AND t.type = 'expense'
              AND t.is_overage = %s
            """,
            (user_id, month_id, envelope_id, is_overage),
        )
        result = self.cursor.fetchone()
        return Decimal(str(result["total"])) if result else Decimal("0")
