"""
Repository for rollover database operations.

Implements database access patterns for managing month state, unclosed months,
and marking months as rolled over.
"""


class RolloverRepository:
    """Repository for rollover database operations."""

    def __init__(self, cursor, clock):
        """
        Initialize with a database cursor and the app's injected clock.

        Args:
            cursor: A psycopg2 cursor (with RealDictCursor factory for dict-like access).
            clock: Clock instance — the only allowed source of "now" (never datetime.now()).
        """
        self.cursor = cursor
        self.clock = clock

    def get_or_create_month(self, year: int, month: int) -> int:
        """
        Get or create a month record and return its ID.

        Race-safe: uses INSERT ... ON CONFLICT DO NOTHING so two concurrent
        callers for the same (year, month) never both attempt a plain INSERT.
        """
        self.cursor.execute(
            "SELECT id FROM months WHERE year = %s AND month = %s",
            (year, month),
        )
        result = self.cursor.fetchone()
        if result:
            return result["id"]

        self.cursor.execute(
            """
            INSERT INTO months (year, month) VALUES (%s, %s)
            ON CONFLICT (year, month) DO NOTHING
            RETURNING id
            """,
            (year, month),
        )
        inserted = self.cursor.fetchone()
        if inserted:
            return inserted["id"]

        # Lost the race to another caller — re-select the row it created.
        self.cursor.execute(
            "SELECT id FROM months WHERE year = %s AND month = %s",
            (year, month),
        )
        return self.cursor.fetchone()["id"]

    def get_unclosed_months_before(self, user_id: int, current_month_id: int) -> list[dict]:
        """
        Get all unclosed months strictly before the current month, in chronological order.

        An unclosed month is one with no 'rolled_over' status in user_month_state.
        "Before" is compared on (year, month) — NOT on the months.id surrogate key,
        since id order only matches chronological order if rows happen to have been
        inserted in date order, which isn't guaranteed (e.g. backfilling a missed month).

        Args:
            user_id: The ID of the user.
            current_month_id: The ID of the current month.

        Returns:
            A list of month dicts (id, year, month) in chronological order.
        """
        self.cursor.execute(
            """
            SELECT m.id, m.year, m.month
            FROM months m
            CROSS JOIN (SELECT year, month FROM months WHERE id = %s) AS current_month
            LEFT JOIN user_month_state ums ON ums.user_id = %s AND ums.month_id = m.id
            WHERE (m.year, m.month) < (current_month.year, current_month.month)
              AND (
                ums.status IS NULL
                OR ums.status != 'rolled_over'
              )
            ORDER BY m.year ASC, m.month ASC
            """,
            (current_month_id, user_id),
        )
        return self.cursor.fetchall()

    def get_or_create_month_state_locked(self, user_id: int, month_id: int) -> dict:
        """
        Get or create a user_month_state row for the user/month pair, with row-level
        locking so a concurrent rollover attempt on the same month cannot race.

        Design: INSERT ... ON CONFLICT DO NOTHING (so an existing row is never
        clobbered back to 'open'), then SELECT ... FOR UPDATE to lock the row for
        the remainder of the caller's transaction.

        Returns:
            A dict with id, user_id, month_id, status, credit_settled_amount,
            sweep_amount, rolled_over_at.
        """
        self.cursor.execute(
            """
            INSERT INTO user_month_state (user_id, month_id, status)
            VALUES (%s, %s, 'open')
            ON CONFLICT (user_id, month_id) DO NOTHING
            """,
            (user_id, month_id),
        )

        self.cursor.execute(
            """
            SELECT id, user_id, month_id, status, credit_settled_amount, sweep_amount, rolled_over_at
            FROM user_month_state
            WHERE user_id = %s AND month_id = %s
            FOR UPDATE
            """,
            (user_id, month_id),
        )
        return self.cursor.fetchone()

    def mark_rolled_over(self, state_id: int, credit_settled_amount, sweep_amount) -> None:
        """
        Mark a month_state as rolled over and record settlement/sweep amounts.
        """
        now = self.clock.now()
        self.cursor.execute(
            """
            UPDATE user_month_state
            SET status = 'rolled_over',
                credit_settled_amount = %s,
                sweep_amount = %s,
                rolled_over_at = %s
            WHERE id = %s
            """,
            (credit_settled_amount, sweep_amount, now, state_id),
        )
