"""
Repository for categories database operations.

Implements database access patterns for retrieving categories with their
associated budget_envelope and funding account information.
"""


class CategoriesRepository:
    """Repository for categories database operations."""

    def __init__(self, cursor):
        """
        Initialize with a database cursor.

        Args:
            cursor: A psycopg2 cursor (with RealDictCursor factory for dict-like access).
        """
        self.cursor = cursor

    def get_all_active_categories_with_envelopes(self) -> list:
        """
        Get all active categories with their budget_envelope and funding account info.

        Returns a list of dicts with:
        - category: id, code, display_name, is_active, envelope_id
        - envelope: name, monthly_amount
        - account: code (account_code)

        Query joins:
        - categories -> budget_envelopes (on envelope_id)
        - budget_envelopes -> accounts (on account_id)

        Returns in order by category id.
        """
        self.cursor.execute(
            """
            SELECT
                c.id,
                c.code,
                c.display_name,
                c.is_active,
                c.envelope_id,
                be.name as envelope_name,
                be.monthly_amount,
                a.code as account_code
            FROM categories c
            JOIN budget_envelopes be ON c.envelope_id = be.id
            JOIN accounts a ON be.account_id = a.id
            WHERE c.is_active = true
            ORDER BY c.id
            """
        )
        return self.cursor.fetchall()

    def get_category_by_code(self, code: str) -> dict | None:
        """
        Get a single active category by code, with envelope and account info.

        Args:
            code: The category code (e.g., 'food', 'rent', 'travel').

        Returns:
            A dict with category, envelope, and account info, or None if not found.
        """
        self.cursor.execute(
            """
            SELECT
                c.id,
                c.code,
                c.display_name,
                c.is_active,
                c.envelope_id,
                be.name as envelope_name,
                be.monthly_amount,
                a.code as account_code
            FROM categories c
            JOIN budget_envelopes be ON c.envelope_id = be.id
            JOIN accounts a ON be.account_id = a.id
            WHERE c.code = %s AND c.is_active = true
            """,
            (code,),
        )
        return self.cursor.fetchone()

    def get_categories_by_envelope_id(self, envelope_id: int) -> list:
        """
        Get all active categories that belong to a specific envelope.

        Args:
            envelope_id: The id of the budget_envelope.

        Returns:
            A list of category dicts belonging to this envelope, ordered by id.
        """
        self.cursor.execute(
            """
            SELECT
                c.id,
                c.code,
                c.display_name,
                c.is_active,
                c.envelope_id,
                be.name as envelope_name,
                be.monthly_amount,
                a.code as account_code
            FROM categories c
            JOIN budget_envelopes be ON c.envelope_id = be.id
            JOIN accounts a ON be.account_id = a.id
            WHERE c.envelope_id = %s AND c.is_active = true
            ORDER BY c.id
            """,
            (envelope_id,),
        )
        return self.cursor.fetchall()
