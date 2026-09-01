"""
Integration tests for RolloverRepository.

Tests database operations against a real test database:
- get_or_create_month_state_locked: atomic creation/locking
- get_unclosed_months_before: proper ordering and filtering
- mark_rolled_over: status transitions
"""

from decimal import Decimal

import pytest

from core.clock import Clock
from features.rollover.data.repository import RolloverRepository


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def rollover_repo(db_conn):
    """Provide a RolloverRepository connected to test database."""
    return RolloverRepository(db_conn, Clock())


@pytest.fixture
def user_id(db_conn):
    """Create a test user and return user_id."""
    db_conn.execute(
        """
        INSERT INTO users (username, email, password_hash)
        VALUES (%s, %s, %s)
        RETURNING user_id
        """,
        ("testuser", "test@example.com", "hashed_password"),
    )
    return db_conn.fetchone()["user_id"]


@pytest.fixture
def months(db_conn):
    """Create test months and return their IDs."""
    # Create months 6, 7, 8, 9 for 2025
    month_ids = []
    for m in [6, 7, 8, 9]:
        db_conn.execute(
            "INSERT INTO months (year, month) VALUES (%s, %s) RETURNING id",
            (2025, m),
        )
        month_ids.append(db_conn.fetchone()["id"])
    return month_ids  # [month_6_id, month_7_id, month_8_id, month_9_id]


# ============================================================================
# Tests: get_or_create_month_state_locked
# ============================================================================


class TestGetOrCreateMonthStateLocked:
    """Test atomic get/create with row-level locking."""

    def test_creates_new_month_state_when_not_exists(self, rollover_repo, user_id, months, db_conn):
        """
        When user_month_state doesn't exist for (user_id, month_id),
        get_or_create_month_state_locked should INSERT and return the new row.
        """
        month_id = months[0]

        # Execute
        result = rollover_repo.get_or_create_month_state_locked(user_id, month_id)

        # Verify: Result has expected fields
        assert result["user_id"] == user_id
        assert result["month_id"] == month_id
        assert result["status"] == "open"
        assert result["credit_settled_amount"] == 0 or result["credit_settled_amount"] is None
        assert result["sweep_amount"] == 0 or result["sweep_amount"] is None

        # Verify: Row was actually inserted
        db_conn.execute(
            "SELECT id FROM user_month_state WHERE user_id = %s AND month_id = %s",
            (user_id, month_id),
        )
        row = db_conn.fetchone()
        assert row is not None
        assert row["id"] == result["id"]

    def test_returns_existing_month_state_when_exists(self, rollover_repo, user_id, months, db_conn):
        """
        When user_month_state already exists, get_or_create_month_state_locked
        should return the existing row (with a lock).
        """
        month_id = months[0]

        # Setup: Insert a month_state
        db_conn.execute(
            """
            INSERT INTO user_month_state (user_id, month_id, status)
            VALUES (%s, %s, 'open')
            RETURNING id
            """,
            (user_id, month_id),
        )
        existing_id = db_conn.fetchone()["id"]

        # Execute: Call get_or_create again
        result = rollover_repo.get_or_create_month_state_locked(user_id, month_id)

        # Verify: Same row returned
        assert result["id"] == existing_id
        assert result["status"] == "open"

    def test_double_call_is_idempotent(self, rollover_repo, user_id, months, db_conn):
        """
        Calling get_or_create_month_state_locked twice for the same (user_id, month_id)
        should not error and should return the same row both times.
        """
        month_id = months[0]

        # First call
        result1 = rollover_repo.get_or_create_month_state_locked(user_id, month_id)

        # Second call
        result2 = rollover_repo.get_or_create_month_state_locked(user_id, month_id)

        # Verify: Same row both times
        assert result1["id"] == result2["id"]
        assert result1["month_id"] == result2["month_id"] == month_id

    def test_state_persists_after_get_or_create(self, rollover_repo, user_id, months, db_conn):
        """
        After calling get_or_create_month_state_locked, the row should persist
        in the database and be queryable.
        """
        month_id = months[0]

        # Execute
        created = rollover_repo.get_or_create_month_state_locked(user_id, month_id)

        # Verify: Can query it back
        db_conn.execute(
            "SELECT * FROM user_month_state WHERE id = %s",
            (created["id"],),
        )
        row = db_conn.fetchone()
        assert row is not None
        assert row["user_id"] == user_id
        assert row["month_id"] == month_id


# ============================================================================
# Tests: get_unclosed_months_before
# ============================================================================


class TestGetUnclosedMonthsBefore:
    """Test fetching unclosed months in chronological order."""

    def test_returns_empty_when_all_rolled_over(self, rollover_repo, user_id, months, db_conn):
        """
        When all months before current are marked rolled_over,
        get_unclosed_months_before should return an empty list.
        """
        # Setup: Create and mark all months as rolled_over
        for m_id in months[:3]:  # months 6, 7, 8
            db_conn.execute(
                """
                INSERT INTO user_month_state (user_id, month_id, status)
                VALUES (%s, %s, 'rolled_over')
                """,
                (user_id, m_id),
            )

        current_month_id = months[3]  # month 9

        # Execute
        result = rollover_repo.get_unclosed_months_before(user_id, current_month_id)

        # Verify: Empty list
        assert result == []

    def test_returns_unclosed_months_in_chronological_order(self, rollover_repo, user_id, months, db_conn):
        """
        When months 6, 7, 8 are unclosed (status='open') and month 9 is current,
        get_unclosed_months_before should return [month_6, month_7, month_8] in order.
        """
        # Setup: Create month states for months 6, 7, 8 (all open)
        for m_id in months[:3]:
            db_conn.execute(
                """
                INSERT INTO user_month_state (user_id, month_id, status)
                VALUES (%s, %s, 'open')
                """,
                (user_id, m_id),
            )

        current_month_id = months[3]  # month 9

        # Execute
        result = rollover_repo.get_unclosed_months_before(user_id, current_month_id)

        # Verify: All three months returned in chronological order
        assert len(result) == 3
        assert result[0]["month"] == 6
        assert result[1]["month"] == 7
        assert result[2]["month"] == 8

    def test_excludes_current_month(self, rollover_repo, user_id, months, db_conn):
        """
        Even if current month is open, it should not be included
        in get_unclosed_months_before (only strictly before).
        """
        # Setup: All months open
        for m_id in months:
            db_conn.execute(
                """
                INSERT INTO user_month_state (user_id, month_id, status)
                VALUES (%s, %s, 'open')
                """,
                (user_id, m_id),
            )

        current_month_id = months[3]  # month 9

        # Execute
        result = rollover_repo.get_unclosed_months_before(user_id, current_month_id)

        # Verify: Only months 6, 7, 8 (not month 9)
        assert len(result) == 3
        month_numbers = [m["month"] for m in result]
        assert 9 not in month_numbers

    def test_filters_by_user_id(self, rollover_repo, user_id, months, db_conn):
        """
        user_month_state is per-user. If user A has already closed (rolled_over)
        month 8 but user B has not, month 8 must disappear from A's unclosed
        list while still appearing in B's — one user's state can't leak into
        another's. (Months with no state row at all for a user are legitimately
        unclosed for that user, since nothing has ever closed them.)
        """
        db_conn.execute(
            """
            INSERT INTO users (username, email, password_hash)
            VALUES (%s, %s, %s)
            RETURNING user_id
            """,
            ("otheruser", "other@example.com", "hashed"),
        )
        other_user_id = db_conn.fetchone()["user_id"]

        # First user has already rolled over month 8.
        db_conn.execute(
            "INSERT INTO user_month_state (user_id, month_id, status) VALUES (%s, %s, 'rolled_over')",
            (user_id, months[2]),  # month 8
        )
        # Other user has an explicit OPEN state on month 8 (still unclosed for them).
        db_conn.execute(
            "INSERT INTO user_month_state (user_id, month_id, status) VALUES (%s, %s, 'open')",
            (other_user_id, months[2]),
        )

        current_month_id = months[3]  # month 9

        result_first_user = rollover_repo.get_unclosed_months_before(user_id, current_month_id)
        result_other_user = rollover_repo.get_unclosed_months_before(other_user_id, current_month_id)

        # First user: month 8 is closed for them, so only 6 and 7 remain unclosed.
        assert [m["month"] for m in result_first_user] == [6, 7]
        # Other user: month 8 is still open for them, so it's included alongside 6 and 7.
        assert [m["month"] for m in result_other_user] == [6, 7, 8]

    def test_mixed_open_and_rolled_over_states(self, rollover_repo, user_id, months, db_conn):
        """
        When months 6, 7, 8 exist but only 6 and 8 are open (7 is rolled_over),
        should only return 6 and 8 (in order).
        """
        # Setup: month 6 open, 7 rolled_over, 8 open
        db_conn.execute(
            "INSERT INTO user_month_state (user_id, month_id, status) VALUES (%s, %s, 'open')",
            (user_id, months[0]),
        )
        db_conn.execute(
            "INSERT INTO user_month_state (user_id, month_id, status) VALUES (%s, %s, 'rolled_over')",
            (user_id, months[1]),
        )
        db_conn.execute(
            "INSERT INTO user_month_state (user_id, month_id, status) VALUES (%s, %s, 'open')",
            (user_id, months[2]),
        )

        current_month_id = months[3]

        # Execute
        result = rollover_repo.get_unclosed_months_before(user_id, current_month_id)

        # Verify: Only months 6 and 8
        assert len(result) == 2
        month_numbers = [m["month"] for m in result]
        assert month_numbers == [6, 8]


# ============================================================================
# Tests: mark_rolled_over
# ============================================================================


class TestMarkRolledOver:
    """Test marking a month as rolled over with settlement/sweep amounts."""

    def test_marks_month_as_rolled_over(self, rollover_repo, user_id, months, db_conn):
        """
        mark_rolled_over should update status to 'rolled_over' and set timestamps.
        """
        month_id = months[0]

        # Setup: Create open month_state
        db_conn.execute(
            """
            INSERT INTO user_month_state (user_id, month_id, status)
            VALUES (%s, %s, 'open')
            RETURNING id
            """,
            (user_id, month_id),
        )
        state_id = db_conn.fetchone()["id"]

        # Execute
        rollover_repo.mark_rolled_over(
            state_id,
            credit_settled_amount=Decimal("500.00"),
            sweep_amount=Decimal("13800.00"),
        )

        # Verify: Status changed to rolled_over
        db_conn.execute("SELECT status FROM user_month_state WHERE id = %s", (state_id,))
        result = db_conn.fetchone()
        assert result["status"] == "rolled_over"

    def test_records_settlement_and_sweep_amounts(self, rollover_repo, user_id, months, db_conn):
        """
        mark_rolled_over should record credit_settled_amount and sweep_amount.
        """
        month_id = months[0]

        # Setup
        db_conn.execute(
            """
            INSERT INTO user_month_state (user_id, month_id, status)
            VALUES (%s, %s, 'open')
            RETURNING id
            """,
            (user_id, month_id),
        )
        state_id = db_conn.fetchone()["id"]

        settled = Decimal("250.75")
        swept = Decimal("15800.50")

        # Execute
        rollover_repo.mark_rolled_over(state_id, credit_settled_amount=settled, sweep_amount=swept)

        # Verify: Amounts recorded
        db_conn.execute(
            "SELECT credit_settled_amount, sweep_amount FROM user_month_state WHERE id = %s",
            (state_id,),
        )
        result = db_conn.fetchone()
        assert result["credit_settled_amount"] == settled
        assert result["sweep_amount"] == swept

    def test_sets_rolled_over_timestamp(self, rollover_repo, user_id, months, db_conn):
        """
        mark_rolled_over should set rolled_over_at timestamp.
        """
        month_id = months[0]

        # Setup
        db_conn.execute(
            """
            INSERT INTO user_month_state (user_id, month_id, status)
            VALUES (%s, %s, 'open')
            RETURNING id
            """,
            (user_id, month_id),
        )
        state_id = db_conn.fetchone()["id"]

        # Execute
        rollover_repo.mark_rolled_over(
            state_id,
            credit_settled_amount=Decimal("0"),
            sweep_amount=Decimal("13800"),
        )

        # Verify: rolled_over_at is set
        db_conn.execute(
            "SELECT rolled_over_at FROM user_month_state WHERE id = %s",
            (state_id,),
        )
        result = db_conn.fetchone()
        assert result["rolled_over_at"] is not None

    def test_preserves_user_and_month_ids(self, rollover_repo, user_id, months, db_conn):
        """
        mark_rolled_over should not change user_id or month_id.
        """
        month_id = months[0]

        # Setup
        db_conn.execute(
            """
            INSERT INTO user_month_state (user_id, month_id, status)
            VALUES (%s, %s, 'open')
            RETURNING id
            """,
            (user_id, month_id),
        )
        state_id = db_conn.fetchone()["id"]

        original_user_id = user_id
        original_month_id = month_id

        # Execute
        rollover_repo.mark_rolled_over(
            state_id,
            credit_settled_amount=Decimal("100"),
            sweep_amount=Decimal("15000"),
        )

        # Verify: IDs unchanged
        db_conn.execute(
            "SELECT user_id, month_id FROM user_month_state WHERE id = %s",
            (state_id,),
        )
        result = db_conn.fetchone()
        assert result["user_id"] == original_user_id
        assert result["month_id"] == original_month_id
