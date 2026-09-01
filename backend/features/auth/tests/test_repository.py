"""
Integration tests for auth repository.

Tests database access: insert users, lookup by username/email, constraint enforcement.
Uses real AuthRepository class with real db_conn fixture from backend/conftest.py.
"""

import psycopg2
import pytest
from psycopg2.errors import IntegrityError

from features.auth.data.repository import AuthRepository


# ============================================================================
# Tests for user insertion
# ============================================================================


class TestInsertUser:
    """Test inserting users into the database."""

    def test_insert_user_creates_record_with_all_fields(self, db_conn):
        """Inserting a user should create a record with username, email, and password_hash."""
        repo = AuthRepository(db_conn)
        user_id = repo.insert_user("testuser", "test@example.com", "hashed_password_123")

        # Verify the user was inserted
        user = repo.get_user_by_username("testuser")

        assert user is not None
        assert user["username"] == "testuser"
        assert user["email"] == "test@example.com"
        assert user["password_hash"] == "hashed_password_123"

    def test_insert_user_returns_auto_incremented_user_id(self, db_conn):
        """Inserted user should have an auto-incremented user_id."""
        repo = AuthRepository(db_conn)
        user_id_1 = repo.insert_user("user1", "user1@example.com", "hash1")
        user_id_2 = repo.insert_user("user2", "user2@example.com", "hash2")

        assert user_id_2 > user_id_1

    def test_insert_user_sets_created_at_timestamp(self, db_conn):
        """Inserted user should have a created_at timestamp."""
        repo = AuthRepository(db_conn)
        user_id = repo.insert_user("testuser", "test@example.com", "hash")

        user = repo.get_user_by_username("testuser")

        assert user["created_at"] is not None

    def test_insert_multiple_users_with_different_usernames(self, db_conn):
        """Should be able to insert multiple users with different usernames."""
        repo = AuthRepository(db_conn)
        repo.insert_user("user1", "user1@example.com", "hash1")
        repo.insert_user("user2", "user2@example.com", "hash2")

        # Verify both users exist
        user1 = repo.get_user_by_username("user1")
        user2 = repo.get_user_by_username("user2")

        assert user1 is not None
        assert user2 is not None


# ============================================================================
# Tests for unique constraints
# ============================================================================


class TestUsernameUniqueness:
    """Test username uniqueness constraint."""

    def test_duplicate_username_raises_integrity_error(self, db_conn):
        """Inserting a user with duplicate username should raise IntegrityError."""
        repo = AuthRepository(db_conn)
        repo.insert_user("testuser", "test1@example.com", "hash1")

        with pytest.raises(IntegrityError):
            repo.insert_user("testuser", "test2@example.com", "hash2")

        # Rollback transaction after constraint error
        db_conn.connection.rollback()

    def test_username_comparison_is_case_sensitive(self, db_conn):
        """Username uniqueness should be case-sensitive (PostgreSQL default)."""
        repo = AuthRepository(db_conn)
        repo.insert_user("testuser", "test1@example.com", "hash1")

        # Different case should be allowed (case-sensitive uniqueness)
        repo.insert_user("TestUser", "test2@example.com", "hash2")

        user1 = repo.get_user_by_username("testuser")
        user2 = repo.get_user_by_username("TestUser")

        assert user1 is not None
        assert user2 is not None
        assert user1["user_id"] != user2["user_id"]


class TestEmailUniqueness:
    """Test email uniqueness constraint."""

    def test_duplicate_email_raises_integrity_error(self, db_conn):
        """Inserting a user with duplicate email should raise IntegrityError."""
        repo = AuthRepository(db_conn)
        repo.insert_user("user1", "test@example.com", "hash1")

        with pytest.raises(IntegrityError):
            repo.insert_user("user2", "test@example.com", "hash2")

        # Rollback transaction after constraint error
        db_conn.connection.rollback()

    def test_email_comparison_is_case_sensitive(self, db_conn):
        """Email uniqueness should be case-sensitive (PostgreSQL default)."""
        repo = AuthRepository(db_conn)
        repo.insert_user("user1", "test@example.com", "hash1")

        # Different case should be allowed (case-sensitive uniqueness)
        repo.insert_user("user2", "Test@Example.com", "hash2")

        user1 = repo.get_user_by_email("test@example.com")
        user2 = repo.get_user_by_email("Test@Example.com")

        assert user1 is not None
        assert user2 is not None
        assert user1["user_id"] != user2["user_id"]


# ============================================================================
# Tests for user lookups
# ============================================================================


class TestGetUserByUsername:
    """Test looking up users by username."""

    def test_get_existing_user_by_username_returns_user(self, db_conn):
        """Getting an existing user by username should return the user record."""
        repo = AuthRepository(db_conn)
        user_id = repo.insert_user("testuser", "test@example.com", "hashed_password")

        user = repo.get_user_by_username("testuser")

        assert user is not None
        assert user["user_id"] == user_id
        assert user["username"] == "testuser"
        assert user["email"] == "test@example.com"

    def test_get_nonexistent_user_by_username_returns_none(self, db_conn):
        """Getting a nonexistent user by username should return None."""
        repo = AuthRepository(db_conn)
        user = repo.get_user_by_username("nonexistent")

        assert user is None

    def test_get_user_by_username_is_case_sensitive(self, db_conn):
        """Username lookup should be case-sensitive."""
        repo = AuthRepository(db_conn)
        repo.insert_user("testuser", "test@example.com", "hash")

        # Wrong case should not find the user
        user = repo.get_user_by_username("TestUser")

        assert user is None

    def test_get_user_by_username_with_special_characters(self, db_conn):
        """Username lookup should work with special characters."""
        repo = AuthRepository(db_conn)
        user_id = repo.insert_user("user_123-test", "test@example.com", "hash")

        user = repo.get_user_by_username("user_123-test")

        assert user is not None
        assert user["user_id"] == user_id


class TestGetUserByEmail:
    """Test looking up users by email."""

    def test_get_existing_user_by_email_returns_user(self, db_conn):
        """Getting an existing user by email should return the user record."""
        repo = AuthRepository(db_conn)
        user_id = repo.insert_user("testuser", "test@example.com", "hashed_password")

        user = repo.get_user_by_email("test@example.com")

        assert user is not None
        assert user["user_id"] == user_id
        assert user["email"] == "test@example.com"

    def test_get_nonexistent_user_by_email_returns_none(self, db_conn):
        """Getting a nonexistent user by email should return None."""
        repo = AuthRepository(db_conn)
        user = repo.get_user_by_email("nonexistent@example.com")

        assert user is None

    def test_get_user_by_email_is_case_sensitive(self, db_conn):
        """Email lookup should be case-sensitive."""
        repo = AuthRepository(db_conn)
        repo.insert_user("testuser", "test@example.com", "hash")

        # Wrong case should not find the user
        user = repo.get_user_by_email("Test@Example.com")

        assert user is None

    def test_get_user_by_email_with_complex_email_format(self, db_conn):
        """Email lookup should work with complex email formats."""
        repo = AuthRepository(db_conn)
        email = "user+tag@sub.example.co.uk"
        user_id = repo.insert_user("testuser", email, "hash")

        user = repo.get_user_by_email(email)

        assert user is not None
        assert user["user_id"] == user_id


# ============================================================================
# Tests for password_hash storage
# ============================================================================


class TestPasswordHashStorage:
    """Test password_hash storage and retrieval."""

    def test_password_hash_is_stored_correctly(self, db_conn):
        """Password hash should be stored and retrieved exactly as provided."""
        repo = AuthRepository(db_conn)
        password_hash = "$2b$12$R9h7cIPz0gi.URNNX3kh2OPST9/PgBkqquzi.Ss7KIUgO2t0jWMUm"
        user_id = repo.insert_user("testuser", "test@example.com", password_hash)

        user = repo.get_user_by_username("testuser")

        assert user["password_hash"] == password_hash

    def test_password_hash_can_be_long_bcrypt_hash(self, db_conn):
        """Password hash should support long bcrypt hashes (60+ chars)."""
        repo = AuthRepository(db_conn)
        # Typical bcrypt hash is 60 characters
        password_hash = "$2b$12$" + "a" * 53  # 60 chars total
        repo.insert_user("testuser", "test@example.com", password_hash)

        user = repo.get_user_by_username("testuser")

        assert user["password_hash"] == password_hash

    def test_password_hash_cannot_be_null(self, db_conn):
        """Password hash should not be nullable."""
        repo = AuthRepository(db_conn)

        with pytest.raises(IntegrityError):
            repo.insert_user("testuser", "test@example.com", None)

        # Rollback transaction after constraint error
        db_conn.connection.rollback()


# ============================================================================
# Tests for constraint interactions
# ============================================================================


class TestConstraintInteractions:
    """Test interactions between multiple constraints."""

    def test_same_user_cannot_have_duplicate_username_and_email(self, db_conn):
        """A second insert with same username and email should fail on username."""
        repo = AuthRepository(db_conn)
        repo.insert_user("testuser", "test@example.com", "hash1")

        with pytest.raises(IntegrityError):
            repo.insert_user("testuser", "test@example.com", "hash2")

        # Rollback transaction after constraint error
        db_conn.connection.rollback()

    def test_transaction_rollback_on_duplicate_email_restores_connection(self, db_conn):
        """Connection should still be usable after IntegrityError."""
        repo = AuthRepository(db_conn)

        # Try to insert with duplicate email (will fail since it's unique constraint)
        try:
            repo.insert_user("user1", "test@example.com", "hash1")
            repo.insert_user("user2", "test@example.com", "hash2")
        except IntegrityError:
            # Rollback transaction after constraint error to restore connection state
            db_conn.connection.rollback()

        # Connection should still be usable - we can insert a new record
        new_user_id = repo.insert_user("user3", "different@example.com", "hash3")
        assert new_user_id is not None

        # And we can query
        user = repo.get_user_by_username("user3")
        assert user is not None
        assert user["username"] == "user3"
