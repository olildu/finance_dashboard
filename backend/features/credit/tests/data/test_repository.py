"""
Integration tests for credit data layer: repository.

Tests database access patterns against real db_conn fixture.
Verifies:
- insert_ledger_entry: inserting overage and payoff entries
- sum_balance: calculating total balance from mixed entries
- get_history: retrieving and ordering history entries
"""

from datetime import datetime, timezone
from decimal import Decimal

import pytest

from features.credit.data.repository import CreditRepository


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def repository(db_conn):
    """Provide a CreditRepository with a database connection."""
    return CreditRepository(db_conn)


@pytest.fixture
def setup_test_user(db_conn):
    """
    Create a test user and month for credit ledger tests.
    Returns (user_id, month_id).
    """
    # Create a user
    db_conn.execute(
        """
        INSERT INTO users (username, email, password_hash)
        VALUES (%s, %s, %s)
        RETURNING user_id
        """,
        ("testuser", "test@example.com", "hashed_password"),
    )
    user_id = db_conn.fetchone()["user_id"]

    # Create a month
    db_conn.execute(
        """
        INSERT INTO months (year, month)
        VALUES (%s, %s)
        RETURNING id
        """,
        (2025, 9),
    )
    month_id = db_conn.fetchone()["id"]

    # Create some transactions for linking
    db_conn.execute(
        """
        INSERT INTO transactions (user_id, month_id, category_id, funding_account_id, amount, type, date)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        RETURNING id
        """,
        (user_id, month_id, 1, 1, Decimal("100.00"), "expense", datetime.now(timezone.utc)),
    )
    txn_id_1 = db_conn.fetchone()["id"]

    db_conn.execute(
        """
        INSERT INTO transactions (user_id, month_id, category_id, funding_account_id, amount, type, date)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        RETURNING id
        """,
        (user_id, month_id, 1, 1, Decimal("200.00"), "credit_payoff", datetime.now(timezone.utc)),
    )
    txn_id_2 = db_conn.fetchone()["id"]

    return user_id, month_id, txn_id_1, txn_id_2


# ============================================================================
# Tests: insert_ledger_entry
# ============================================================================


class TestInsertLedgerEntry:
    """Test insert_ledger_entry method."""

    def test_insert_ledger_entry_persists_row(self, repository, setup_test_user):
        """insert_ledger_entry should insert a ledger entry successfully."""
        user_id, month_id, txn_id_1, _ = setup_test_user

        # Should not raise, should insert successfully
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_1,
            amount=Decimal("100.00"),
            entry_type="overage",
        )

        # Verify the entry was inserted
        repository.cursor.execute(
            "SELECT * FROM credit_ledger WHERE user_id = %s AND transaction_id = %s",
            (user_id, txn_id_1),
        )
        result = repository.cursor.fetchone()
        assert result is not None
        assert result["amount"] == Decimal("100.00")
        assert result["entry_type"] == "overage"

    def test_insert_ledger_entry_with_overage_type(self, repository, setup_test_user):
        """
        insert_ledger_entry should insert a row with entry_type='overage'.

        Expected behavior (when implemented):
        - Insert credit_ledger row with entry_type='overage'
        - Amount should be stored as positive value
        - Should have foreign keys linking to user, month, category, transaction
        """
        user_id, month_id, txn_id_1, _ = setup_test_user

        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_1,
            amount=Decimal("150.00"),
            entry_type="overage",
        )

        # Verify the entry was inserted correctly
        repository.cursor.execute(
            "SELECT * FROM credit_ledger WHERE user_id = %s AND transaction_id = %s",
            (user_id, txn_id_1),
        )
        result = repository.cursor.fetchone()
        assert result is not None
        assert result["amount"] == Decimal("150.00")
        assert result["entry_type"] == "overage"
        assert result["month_id"] == month_id
        assert result["category_id"] == 1

    def test_insert_ledger_entry_with_payoff_type(self, repository, setup_test_user):
        """
        insert_ledger_entry should insert a row with entry_type='payoff'.

        Expected behavior (when implemented):
        - Insert credit_ledger row with entry_type='payoff'
        - Amount should be negative value for payoffs
        - Should have all required foreign keys
        """
        user_id, month_id, txn_id_2, _ = setup_test_user

        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_2,
            amount=Decimal("-100.00"),
            entry_type="payoff",
        )

        # Verify the entry was inserted correctly
        repository.cursor.execute(
            "SELECT * FROM credit_ledger WHERE user_id = %s AND transaction_id = %s",
            (user_id, txn_id_2),
        )
        result = repository.cursor.fetchone()
        assert result is not None
        assert result["amount"] == Decimal("-100.00")
        assert result["entry_type"] == "payoff"
        assert result["month_id"] == month_id


# ============================================================================
# Tests: sum_balance
# ============================================================================


class TestSumBalance:
    """Test sum_balance method."""

    def test_sum_balance_returns_correct_total(self, repository, setup_test_user):
        """sum_balance should return Decimal balance."""
        user_id, _, _, _ = setup_test_user

        # Should not raise, should return a Decimal
        result = repository.sum_balance(user_id=user_id)
        assert isinstance(result, Decimal)

    def test_sum_balance_returns_decimal(self, repository, setup_test_user):
        """
        sum_balance should return a Decimal value.

        Expected behavior (when implemented):
        - Return type should be Decimal
        - Represents the total balance owed (sum of all ledger entries for user)
        """
        user_id, _, _, _ = setup_test_user

        result = repository.sum_balance(user_id=user_id)
        assert isinstance(result, Decimal)

    def test_sum_balance_zero_for_new_user(self, repository, db_conn):
        """
        sum_balance should return Decimal("0.00") if user has no ledger entries.

        Expected behavior (when implemented):
        - Create new user with no credit ledger entries
        - sum_balance should return 0
        """
        # Create a new user with no credit ledger entries
        db_conn.execute(
            """
            INSERT INTO users (username, email, password_hash)
            VALUES (%s, %s, %s)
            RETURNING user_id
            """,
            ("newuser", "new@example.com", "hashed_password"),
        )
        new_user_id = db_conn.fetchone()["user_id"]

        result = repository.sum_balance(user_id=new_user_id)
        assert result == Decimal("0.00")

    def test_sum_balance_with_single_overage(self, repository, setup_test_user):
        """
        sum_balance should correctly sum a single overage entry.

        Expected behavior (when implemented):
        - One overage entry: +100
        - sum_balance should return 100
        """
        user_id, month_id, txn_id_1, _ = setup_test_user

        # Insert an overage entry
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_1,
            amount=Decimal("100.00"),
            entry_type="overage",
        )

        result = repository.sum_balance(user_id=user_id)
        assert result == Decimal("100.00")

    def test_sum_balance_with_multiple_overages(self, repository, setup_test_user, db_conn):
        """
        sum_balance should correctly sum multiple overage entries.

        Expected behavior (when implemented):
        - First overage: +100
        - Second overage: +150
        - Third overage: +75
        - sum_balance should return 325
        """
        user_id, month_id, txn_id_1, txn_id_2 = setup_test_user

        # Insert multiple overage entries
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_1,
            amount=Decimal("100.00"),
            entry_type="overage",
        )

        # Create another transaction for the second overage
        db_conn.execute(
            """
            INSERT INTO transactions (user_id, month_id, category_id, funding_account_id, amount, type, date)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (user_id, month_id, 1, 1, Decimal("150.00"), "expense", datetime.now(timezone.utc)),
        )
        txn_id_3 = db_conn.fetchone()["id"]

        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_3,
            amount=Decimal("150.00"),
            entry_type="overage",
        )

        # Create a third transaction
        db_conn.execute(
            """
            INSERT INTO transactions (user_id, month_id, category_id, funding_account_id, amount, type, date)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (user_id, month_id, 1, 1, Decimal("75.00"), "expense", datetime.now(timezone.utc)),
        )
        txn_id_4 = db_conn.fetchone()["id"]

        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_4,
            amount=Decimal("75.00"),
            entry_type="overage",
        )

        result = repository.sum_balance(user_id=user_id)
        assert result == Decimal("325.00")

    def test_sum_balance_with_mixed_overage_and_payoff(self, repository, setup_test_user, db_conn):
        """
        sum_balance should correctly sum mixed overage and payoff entries.

        Expected behavior (when implemented):
        - Overage: +300
        - Payoff: -100
        - Overage: +50
        - Payoff: -75
        - sum_balance should return 175
        """
        user_id, month_id, txn_id_1, txn_id_2 = setup_test_user

        # Insert overage entry (+300)
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_1,
            amount=Decimal("300.00"),
            entry_type="overage",
        )

        # Insert payoff entry (-100)
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_2,
            amount=Decimal("-100.00"),
            entry_type="payoff",
        )

        # Create another transaction for second overage
        db_conn.execute(
            """
            INSERT INTO transactions (user_id, month_id, category_id, funding_account_id, amount, type, date)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (user_id, month_id, 1, 1, Decimal("50.00"), "expense", datetime.now(timezone.utc)),
        )
        txn_id_3 = db_conn.fetchone()["id"]

        # Insert overage entry (+50)
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_3,
            amount=Decimal("50.00"),
            entry_type="overage",
        )

        # Create another transaction for second payoff
        db_conn.execute(
            """
            INSERT INTO transactions (user_id, month_id, category_id, funding_account_id, amount, type, date)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (user_id, month_id, 1, 1, Decimal("75.00"), "credit_payoff", datetime.now(timezone.utc)),
        )
        txn_id_4 = db_conn.fetchone()["id"]

        # Insert payoff entry (-75)
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_4,
            amount=Decimal("-75.00"),
            entry_type="payoff",
        )

        result = repository.sum_balance(user_id=user_id)
        assert result == Decimal("175.00")

    def test_sum_balance_with_full_payoff(self, repository, setup_test_user):
        """
        sum_balance should handle case where balance is fully settled.

        Expected behavior (when implemented):
        - Overage: +200
        - Payoff: -200
        - sum_balance should return 0
        """
        user_id, month_id, txn_id_1, txn_id_2 = setup_test_user

        # Insert overage entry (+200)
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_1,
            amount=Decimal("200.00"),
            entry_type="overage",
        )

        # Insert payoff entry (-200)
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_2,
            amount=Decimal("-200.00"),
            entry_type="payoff",
        )

        result = repository.sum_balance(user_id=user_id)
        assert result == Decimal("0.00")

    def test_sum_balance_per_user_isolation(self, repository, db_conn):
        """
        sum_balance should only sum entries for the specific user.

        Expected behavior (when implemented):
        - Create two users with different ledger entries
        - sum_balance(user_1) should only count user_1's entries
        - sum_balance(user_2) should only count user_2's entries
        """
        # Create two users
        db_conn.execute(
            """
            INSERT INTO users (username, email, password_hash)
            VALUES (%s, %s, %s)
            RETURNING user_id
            """,
            ("user1", "user1@example.com", "hashed_password"),
        )
        user_1_id = db_conn.fetchone()["user_id"]

        db_conn.execute(
            """
            INSERT INTO users (username, email, password_hash)
            VALUES (%s, %s, %s)
            RETURNING user_id
            """,
            ("user2", "user2@example.com", "hashed_password"),
        )
        user_2_id = db_conn.fetchone()["user_id"]

        # Create a month
        db_conn.execute(
            """
            INSERT INTO months (year, month)
            VALUES (%s, %s)
            RETURNING id
            """,
            (2025, 9),
        )
        month_id = db_conn.fetchone()["id"]

        # Create transactions for user 1
        db_conn.execute(
            """
            INSERT INTO transactions (user_id, month_id, category_id, funding_account_id, amount, type, date)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (user_1_id, month_id, 1, 1, Decimal("100.00"), "expense", datetime.now(timezone.utc)),
        )
        user_1_txn_id = db_conn.fetchone()["id"]

        # Create transactions for user 2
        db_conn.execute(
            """
            INSERT INTO transactions (user_id, month_id, category_id, funding_account_id, amount, type, date)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (user_2_id, month_id, 1, 1, Decimal("200.00"), "expense", datetime.now(timezone.utc)),
        )
        user_2_txn_id = db_conn.fetchone()["id"]

        # Insert ledger entries for both users
        repository.insert_ledger_entry(
            user_id=user_1_id,
            month_id=month_id,
            category_id=1,
            transaction_id=user_1_txn_id,
            amount=Decimal("100.00"),
            entry_type="overage",
        )

        repository.insert_ledger_entry(
            user_id=user_2_id,
            month_id=month_id,
            category_id=1,
            transaction_id=user_2_txn_id,
            amount=Decimal("200.00"),
            entry_type="overage",
        )

        # Verify each user's balance is correct and isolated
        balance_1 = repository.sum_balance(user_id=user_1_id)
        balance_2 = repository.sum_balance(user_id=user_2_id)

        assert balance_1 == Decimal("100.00")
        assert balance_2 == Decimal("200.00")


# ============================================================================
# Tests: get_history
# ============================================================================


class TestGetHistory:
    """Test get_history method."""

    def test_get_history_returns_entries_in_order(self, repository, setup_test_user):
        """get_history should return a list."""
        user_id, _, _, _ = setup_test_user

        result = repository.get_history(user_id=user_id)
        assert isinstance(result, list)

    def test_get_history_returns_list(self, repository, setup_test_user):
        """
        get_history should return a list of entries.

        Expected behavior (when implemented):
        - Return type should be list
        - Each entry should be a dict with: id, month, category_code, amount, entry_type, created_at
        """
        user_id, _, _, _ = setup_test_user

        result = repository.get_history(user_id=user_id)
        assert isinstance(result, list)

    def test_get_history_empty_for_new_user(self, repository, db_conn):
        """
        get_history should return empty list if user has no ledger entries.

        Expected behavior (when implemented):
        - New user with no credit ledger entries
        - get_history should return []
        """
        # Create a new user with no credit ledger entries
        db_conn.execute(
            """
            INSERT INTO users (username, email, password_hash)
            VALUES (%s, %s, %s)
            RETURNING user_id
            """,
            ("historyuser", "history@example.com", "hashed_password"),
        )
        new_user_id = db_conn.fetchone()["user_id"]

        result = repository.get_history(user_id=new_user_id)
        assert result == []

    def test_get_history_entry_has_required_fields(self, repository, setup_test_user):
        """
        get_history entries should include required fields.

        Expected behavior (when implemented):
        - Each entry should have: id, month, category_code, amount, entry_type, created_at
        - category_code should come from categories table
        """
        user_id, month_id, txn_id_1, _ = setup_test_user

        # Insert an entry
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_1,
            amount=Decimal("100.00"),
            entry_type="overage",
        )

        result = repository.get_history(user_id=user_id)
        assert len(result) > 0
        entry = result[0]
        assert "id" in entry
        assert "month" in entry
        assert "category_code" in entry
        assert "amount" in entry
        assert "entry_type" in entry
        assert "created_at" in entry

    def test_get_history_ordered_by_created_at_desc(self, repository, setup_test_user, db_conn):
        """
        get_history should return entries ordered by created_at descending (newest first).

        Expected behavior (when implemented):
        - Insert multiple entries with time delays
        - Verify they're returned with newest first
        """
        user_id, month_id, txn_id_1, txn_id_2 = setup_test_user

        # Insert first entry
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_1,
            amount=Decimal("100.00"),
            entry_type="overage",
        )

        # Insert second entry (should be newer)
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_2,
            amount=Decimal("-50.00"),
            entry_type="payoff",
        )

        result = repository.get_history(user_id=user_id)
        assert len(result) == 2
        # First entry should be the second one inserted (newest first)
        assert result[0]["amount"] == Decimal("-50.00")
        # Second entry should be the first one inserted
        assert result[1]["amount"] == Decimal("100.00")

    def test_get_history_with_month_filter(self, repository, setup_test_user, db_conn):
        """
        get_history should filter by month_id when provided.

        Expected behavior (when implemented):
        - Insert entries in multiple months
        - get_history(user_id, month_id=X) should only return entries from month X
        - get_history(user_id, month_id=None) should return all entries
        """
        user_id, month_id, txn_id_1, _ = setup_test_user

        # Create another month
        db_conn.execute(
            """
            INSERT INTO months (year, month)
            VALUES (%s, %s)
            RETURNING id
            """,
            (2025, 10),
        )
        month_id_2 = db_conn.fetchone()["id"]

        # Create transaction for month 2
        db_conn.execute(
            """
            INSERT INTO transactions (user_id, month_id, category_id, funding_account_id, amount, type, date)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (user_id, month_id_2, 1, 1, Decimal("50.00"), "expense", datetime.now(timezone.utc)),
        )
        txn_id_2_month_2 = db_conn.fetchone()["id"]

        # Insert entry in first month
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_1,
            amount=Decimal("100.00"),
            entry_type="overage",
        )

        # Insert entry in second month
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id_2,
            category_id=1,
            transaction_id=txn_id_2_month_2,
            amount=Decimal("50.00"),
            entry_type="overage",
        )

        # Test month-specific query
        result_month_1 = repository.get_history(user_id=user_id, month_id=month_id)
        assert len(result_month_1) == 1
        assert result_month_1[0]["month"] == month_id
        assert result_month_1[0]["amount"] == Decimal("100.00")

        # Test month 2
        result_month_2 = repository.get_history(user_id=user_id, month_id=month_id_2)
        assert len(result_month_2) == 1
        assert result_month_2[0]["month"] == month_id_2
        assert result_month_2[0]["amount"] == Decimal("50.00")

        # Test all months
        result_all = repository.get_history(user_id=user_id)
        assert len(result_all) == 2

    def test_get_history_includes_both_entry_types(self, repository, setup_test_user):
        """
        get_history should include both overage and payoff entries.

        Expected behavior (when implemented):
        - Insert mix of overage and payoff entries
        - get_history should return both types
        """
        user_id, month_id, txn_id_1, txn_id_2 = setup_test_user

        # Insert overage entry
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_1,
            amount=Decimal("100.00"),
            entry_type="overage",
        )

        # Insert payoff entry
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_2,
            amount=Decimal("-50.00"),
            entry_type="payoff",
        )

        result = repository.get_history(user_id=user_id)
        assert len(result) == 2
        entry_types = {entry["entry_type"] for entry in result}
        assert "overage" in entry_types
        assert "payoff" in entry_types

    def test_get_history_preserves_decimal_amounts(self, repository, setup_test_user):
        """
        get_history should preserve amount precision (Decimal).

        Expected behavior (when implemented):
        - Amounts should be Decimal, preserving precision
        - 99.99 should remain 99.99, not 99.9900...
        """
        user_id, month_id, txn_id_1, _ = setup_test_user

        # Insert an entry with a precise amount
        repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=1,
            transaction_id=txn_id_1,
            amount=Decimal("99.99"),
            entry_type="overage",
        )

        result = repository.get_history(user_id=user_id)
        assert len(result) > 0
        entry = result[0]
        assert isinstance(entry["amount"], Decimal)
        assert entry["amount"] == Decimal("99.99")
