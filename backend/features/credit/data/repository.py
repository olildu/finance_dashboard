"""
Repository for credit ledger database operations.

Implements database access patterns for managing credit ledger entries,
balances, and transaction history.
"""

from decimal import Decimal


class CreditRepository:
    """Repository for credit ledger database operations."""

    def __init__(self, cursor):
        """
        Initialize with a database cursor.

        Args:
            cursor: A psycopg2 cursor (with RealDictCursor factory for dict-like access).
        """
        self.cursor = cursor

    def insert_ledger_entry(
        self,
        user_id: int,
        month_id: int,
        category_id: int,
        transaction_id: int,
        amount: Decimal,
        entry_type: str,
    ) -> None:
        """
        Insert a credit ledger entry into the database.

        Args:
            user_id: The user id.
            month_id: The month id.
            category_id: The category id.
            transaction_id: The transaction id.
            amount: The amount for this entry.
            entry_type: The type of entry (e.g., 'overage', 'settlement').

        Raises:
            NotImplementedError: This is a stub implementation.
        """
        self.cursor.execute(
            """
            INSERT INTO credit_ledger (user_id, month_id, category_id, transaction_id, amount, entry_type)
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (user_id, month_id, category_id, transaction_id, amount, entry_type),
        )

    def sum_balance(self, user_id: int) -> Decimal:
        """
        Calculate the total balance owed by a user.

        Args:
            user_id: The user id.

        Returns:
            The total balance owed as a Decimal.

        Raises:
            NotImplementedError: This is a stub implementation.
        """
        self.cursor.execute(
            """
            SELECT COALESCE(SUM(amount), 0) as balance
            FROM credit_ledger
            WHERE user_id = %s
            """,
            (user_id,),
        )
        result = self.cursor.fetchone()
        balance = result["balance"] if result else Decimal("0.00")
        # Ensure the result is a Decimal
        if isinstance(balance, (int, float)):
            return Decimal(str(balance))
        return balance

    def get_history(self, user_id: int, month_id: int | None = None) -> list:
        """
        Get the credit ledger history for a user.

        Args:
            user_id: The user id.
            month_id: Optional month id to filter history. If None, returns all history.

        Returns:
            A list of credit ledger entries (dicts with id, month, category_code, amount, entry_type, created_at).

        Raises:
            NotImplementedError: This is a stub implementation.
        """
        if month_id is None:
            self.cursor.execute(
                """
                SELECT cl.id, cl.month_id as month, c.code as category_code,
                       cl.amount, cl.entry_type, cl.created_at
                FROM credit_ledger cl
                LEFT JOIN categories c ON cl.category_id = c.id
                WHERE cl.user_id = %s
                ORDER BY cl.created_at DESC
                """,
                (user_id,),
            )
        else:
            self.cursor.execute(
                """
                SELECT cl.id, cl.month_id as month, c.code as category_code,
                       cl.amount, cl.entry_type, cl.created_at
                FROM credit_ledger cl
                LEFT JOIN categories c ON cl.category_id = c.id
                WHERE cl.user_id = %s AND cl.month_id = %s
                ORDER BY cl.created_at DESC
                """,
                (user_id, month_id),
            )
        return self.cursor.fetchall()
