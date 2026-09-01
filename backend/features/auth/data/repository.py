"""
Auth repository: database access layer for users.
"""

from typing import Optional

from psycopg2.extras import RealDictCursor


class AuthRepository:
    """Repository for user database operations."""

    def __init__(self, cursor: RealDictCursor):
        """Initialize with a database cursor."""
        self.cursor = cursor

    def insert_user(self, username: str, email: str, password_hash: str) -> int:
        """
        Insert a new user and return the user_id.
        Raises psycopg2.IntegrityError if username or email already exists.
        """
        self.cursor.execute(
            """
            INSERT INTO users (username, email, password_hash)
            VALUES (%s, %s, %s)
            RETURNING user_id
            """,
            (username, email, password_hash),
        )
        result = self.cursor.fetchone()
        return result["user_id"]

    def get_user_by_username(self, username: str) -> Optional[dict]:
        """Get user by username; return None if not found."""
        self.cursor.execute(
            "SELECT user_id, username, email, password_hash, created_at FROM users WHERE username = %s",
            (username,),
        )
        return self.cursor.fetchone()

    def get_user_by_email(self, email: str) -> Optional[dict]:
        """Get user by email; return None if not found."""
        self.cursor.execute(
            "SELECT user_id, username, email, password_hash, created_at FROM users WHERE email = %s",
            (email,),
        )
        return self.cursor.fetchone()

    def list_all_user_ids(self) -> list[int]:
        """Return every user_id, for jobs that must act across all users (e.g. rollover)."""
        self.cursor.execute("SELECT user_id FROM users")
        return [row["user_id"] for row in self.cursor.fetchall()]
