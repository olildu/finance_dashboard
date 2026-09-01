"""
Integration tests for transactions data layer (repository).

Tests database access patterns against real seeded data using db_conn fixture.
Verifies insert, list, delete, and sum_expense_for_envelope_in_month queries.
"""

from datetime import datetime, timezone
from decimal import Decimal

import pytest

from features.transactions.data.repository import TransactionsRepository


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def repository(db_conn):
    """Provide a TransactionsRepository with a database connection."""
    return TransactionsRepository(db_conn)


@pytest.fixture
def db_with_user_and_month(db_conn):
    """
    Create a test user and month in the database.
    Returns (user_id, month_id) for use in tests.
    """
    # Create a test user
    db_conn.execute(
        """
        INSERT INTO users (username, email, password_hash)
        VALUES ('testuser', 'test@example.com', 'hashed_password')
        RETURNING user_id
        """
    )
    user_id = db_conn.fetchone()["user_id"]

    # Create a test month
    db_conn.execute(
        """
        INSERT INTO months (year, month)
        VALUES (2025, 9)
        RETURNING id
        """
    )
    month_id = db_conn.fetchone()["id"]

    # Create user_month_state
    db_conn.execute(
        """
        INSERT INTO user_month_state (user_id, month_id)
        VALUES (%s, %s)
        """,
        (user_id, month_id),
    )

    # Get the connection to commit
    db_conn.connection.commit()

    return user_id, month_id


# ============================================================================
# Tests: insert
# ============================================================================


class TestInsert:
    """Test TransactionsRepository.insert method."""

    def test_insert_returns_transaction_id(self, repository, db_with_user_and_month):
        """insert should return the ID of the inserted transaction."""
        user_id, month_id = db_with_user_and_month

        # Get the Food category (id=1) and its funding account (ICICI, account_id=1)
        transaction_id = repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,  # Food
            funding_account_id=1,  # ICICI
            amount=Decimal("500.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-09-01",
        )

        assert isinstance(transaction_id, int)
        assert transaction_id > 0

    def test_insert_stores_transaction_in_database(self, repository, db_conn, db_with_user_and_month):
        """insert should store the transaction in the database."""
        user_id, month_id = db_with_user_and_month

        transaction_id = repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,  # Food
            funding_account_id=1,  # ICICI
            amount=Decimal("500.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-09-01",
        )

        # Verify the transaction was inserted
        db_conn.execute("SELECT * FROM transactions WHERE id = %s", (transaction_id,))
        result = db_conn.fetchone()

        assert result is not None
        assert result["id"] == transaction_id
        assert result["user_id"] == user_id
        assert result["month_id"] == month_id
        assert result["category_id"] == 1
        assert result["funding_account_id"] == 1
        assert result["amount"] == Decimal("500.00")
        assert result["type"] == "expense"
        assert result["is_overage"] is False
        assert result["reason"] == "Lunch"

    def test_insert_overage_transaction(self, repository, db_conn, db_with_user_and_month):
        """insert should handle overage transactions."""
        user_id, month_id = db_with_user_and_month

        transaction_id = repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,  # Food
            funding_account_id=2,  # CREDIT for overage
            amount=Decimal("1000.00"),
            type="expense",
            is_overage=True,
            reason="Over budget",
            date="2025-09-05",
        )

        db_conn.execute("SELECT * FROM transactions WHERE id = %s", (transaction_id,))
        result = db_conn.fetchone()

        assert result["is_overage"] is True
        assert result["funding_account_id"] == 2


# ============================================================================
# Tests: list_for_month
# ============================================================================


class TestListForMonth:
    """Test TransactionsRepository.list_for_month method."""

    def test_list_for_month_returns_list(self, repository, db_with_user_and_month):
        """list_for_month should return a list."""
        user_id, month_id = db_with_user_and_month

        result = repository.list_for_month(user_id, month_id)

        assert isinstance(result, list)

    def test_list_for_month_empty_returns_empty_list(self, repository, db_with_user_and_month):
        """list_for_month should return empty list when no transactions exist."""
        user_id, month_id = db_with_user_and_month

        result = repository.list_for_month(user_id, month_id)

        assert result == []

    def test_list_for_month_returns_inserted_transactions(
        self, repository, db_with_user_and_month
    ):
        """list_for_month should return all transactions for the month."""
        user_id, month_id = db_with_user_and_month

        # Insert two transactions
        t1_id = repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,  # Food
            funding_account_id=1,
            amount=Decimal("500.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-09-01",
        )

        t2_id = repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=2,  # Envelope: PartyOutsideTravel
            funding_account_id=2,
            amount=Decimal("300.00"),
            type="expense",
            is_overage=False,
            reason="Movie",
            date="2025-09-02",
        )

        result = repository.list_for_month(user_id, month_id)

        assert len(result) == 2
        assert any(t["id"] == t1_id for t in result)
        assert any(t["id"] == t2_id for t in result)

    def test_list_for_month_filters_by_user(self, repository, db_conn, db_with_user_and_month):
        """list_for_month should only return transactions for the given user."""
        user_id, month_id = db_with_user_and_month

        # Insert a transaction for user 1
        repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            funding_account_id=1,
            amount=Decimal("500.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-09-01",
        )

        # Create another user
        db_conn.execute(
            """
            INSERT INTO users (username, email, password_hash)
            VALUES ('otheruser', 'other@example.com', 'hashed_password')
            RETURNING user_id
            """
        )
        other_user_id = db_conn.fetchone()["user_id"]
        db_conn.connection.commit()

        # Insert a transaction for other user (should not appear in list)
        repository.insert(
            user_id=other_user_id,
            month_id=month_id,
            category_id=1,
            funding_account_id=1,
            amount=Decimal("800.00"),
            type="expense",
            is_overage=False,
            reason="Dinner",
            date="2025-09-03",
        )

        result = repository.list_for_month(user_id, month_id)

        assert len(result) == 1
        assert result[0]["user_id"] == user_id

    def test_list_for_month_filters_by_month(self, repository, db_conn, db_with_user_and_month):
        """list_for_month should only return transactions for the given month."""
        user_id, month_id = db_with_user_and_month

        # Insert a transaction for month 1
        repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            funding_account_id=1,
            amount=Decimal("500.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-09-01",
        )

        # Create another month
        db_conn.execute(
            """
            INSERT INTO months (year, month)
            VALUES (2025, 10)
            RETURNING id
            """
        )
        other_month_id = db_conn.fetchone()["id"]

        db_conn.execute(
            """
            INSERT INTO user_month_state (user_id, month_id)
            VALUES (%s, %s)
            """,
            (user_id, other_month_id),
        )
        db_conn.connection.commit()

        # Insert a transaction for other month (should not appear in list)
        repository.insert(
            user_id=user_id,
            month_id=other_month_id,
            category_id=1,
            funding_account_id=1,
            amount=Decimal("600.00"),
            type="expense",
            is_overage=False,
            reason="Dinner",
            date="2025-10-01",
        )

        result = repository.list_for_month(user_id, month_id)

        assert len(result) == 1
        assert result[0]["month_id"] == month_id


# ============================================================================
# Tests: delete
# ============================================================================


class TestDelete:
    """Test TransactionsRepository.delete method."""

    def test_delete_returns_true_for_existing_transaction(
        self, repository, db_with_user_and_month
    ):
        """delete should return True when deleting an existing transaction."""
        user_id, month_id = db_with_user_and_month

        transaction_id = repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            funding_account_id=1,
            amount=Decimal("500.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-09-01",
        )

        result = repository.delete(user_id, transaction_id)

        assert result is True

    def test_delete_returns_false_for_nonexistent_transaction(
        self, repository, db_with_user_and_month
    ):
        """delete should return False when transaction does not exist."""
        user_id, month_id = db_with_user_and_month

        result = repository.delete(user_id, 99999)

        assert result is False

    def test_delete_removes_transaction_from_database(
        self, repository, db_conn, db_with_user_and_month
    ):
        """delete should remove the transaction from the database."""
        user_id, month_id = db_with_user_and_month

        transaction_id = repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            funding_account_id=1,
            amount=Decimal("500.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-09-01",
        )

        repository.delete(user_id, transaction_id)

        db_conn.execute("SELECT * FROM transactions WHERE id = %s", (transaction_id,))
        result = db_conn.fetchone()

        assert result is None

    def test_delete_only_deletes_user_own_transactions(
        self, repository, db_conn, db_with_user_and_month
    ):
        """delete should only delete transactions owned by the given user."""
        user_id, month_id = db_with_user_and_month

        transaction_id = repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            funding_account_id=1,
            amount=Decimal("500.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-09-01",
        )

        # Create another user
        db_conn.execute(
            """
            INSERT INTO users (username, email, password_hash)
            VALUES ('otheruser', 'other@example.com', 'hashed_password')
            RETURNING user_id
            """
        )
        other_user_id = db_conn.fetchone()["user_id"]
        db_conn.connection.commit()

        # Try to delete transaction as different user
        result = repository.delete(other_user_id, transaction_id)

        assert result is False

        # Verify transaction still exists
        db_conn.execute("SELECT * FROM transactions WHERE id = %s", (transaction_id,))
        assert db_conn.fetchone() is not None


# ============================================================================
# Tests: sum_expense_for_envelope_in_month
# ============================================================================


class TestSumExpenseForEnvelopeInMonth:
    """Test TransactionsRepository.sum_expense_for_envelope_in_month method."""

    def test_sum_returns_decimal_zero_for_no_transactions(
        self, repository, db_with_user_and_month
    ):
        """sum should return Decimal(0) when no transactions exist."""
        user_id, month_id = db_with_user_and_month

        result = repository.sum_expense_for_envelope_in_month(user_id, month_id, 1)

        assert result == Decimal("0")

    def test_sum_returns_total_of_non_overage_expenses(
        self, repository, db_with_user_and_month
    ):
        """sum should return total of non-overage expense transactions only."""
        user_id, month_id = db_with_user_and_month

        # Insert non-overage transactions
        repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,  # Food envelope_id=1
            funding_account_id=1,
            amount=Decimal("300.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-09-01",
        )

        repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,  # Food same envelope
            funding_account_id=1,
            amount=Decimal("200.00"),
            type="expense",
            is_overage=False,
            reason="Dinner",
            date="2025-09-02",
        )

        result = repository.sum_expense_for_envelope_in_month(user_id, month_id, 1)

        assert result == Decimal("500.00")

    def test_sum_excludes_overage_transactions(
        self, repository, db_with_user_and_month
    ):
        """sum should exclude overage transactions."""
        user_id, month_id = db_with_user_and_month

        # Insert non-overage transaction
        repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            funding_account_id=1,
            amount=Decimal("300.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-09-01",
        )

        # Insert overage transaction for same envelope
        repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,  # Same envelope
            funding_account_id=2,  # CREDIT
            amount=Decimal("200.00"),
            type="expense",
            is_overage=True,
            reason="Over budget",
            date="2025-09-02",
        )

        result = repository.sum_expense_for_envelope_in_month(user_id, month_id, 1)

        # Should only count non-overage: 300.00
        assert result == Decimal("300.00")

    def test_sum_filters_by_month(self, repository, db_conn, db_with_user_and_month):
        """sum should only count transactions in the specified month."""
        user_id, month_id = db_with_user_and_month

        # Insert transaction in month 1
        repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            funding_account_id=1,
            amount=Decimal("300.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-09-01",
        )

        # Create another month
        db_conn.execute(
            """
            INSERT INTO months (year, month)
            VALUES (2025, 10)
            RETURNING id
            """
        )
        other_month_id = db_conn.fetchone()["id"]

        db_conn.execute(
            """
            INSERT INTO user_month_state (user_id, month_id)
            VALUES (%s, %s)
            """,
            (user_id, other_month_id),
        )
        db_conn.connection.commit()

        # Insert transaction in month 2
        repository.insert(
            user_id=user_id,
            month_id=other_month_id,
            category_id=1,
            funding_account_id=1,
            amount=Decimal("500.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-10-01",
        )

        result = repository.sum_expense_for_envelope_in_month(user_id, month_id, 1)

        # Should only count month 1: 300.00
        assert result == Decimal("300.00")

    def test_sum_filters_by_envelope(self, repository, db_with_user_and_month):
        """sum should only count transactions for the specified envelope."""
        user_id, month_id = db_with_user_and_month

        # Food category has envelope_id=1
        # Party/Travel category has envelope_id=2
        # Rent category has envelope_id=3

        repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=1,  # Food (envelope_id=1)
            funding_account_id=1,
            amount=Decimal("300.00"),
            type="expense",
            is_overage=False,
            reason="Lunch",
            date="2025-09-01",
        )

        repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=3,  # Rent (envelope_id=3)
            funding_account_id=3,
            amount=Decimal("500.00"),
            type="expense",
            is_overage=False,
            reason="Rent payment",
            date="2025-09-01",
        )

        result = repository.sum_expense_for_envelope_in_month(user_id, month_id, 1)

        # Should only count envelope 1: 300.00
        assert result == Decimal("300.00")
