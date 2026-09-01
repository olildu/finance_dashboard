"""
Pytest configuration and fixtures.

IMPORTANT: Tests expect DATABASE_URL to point at a scratch/test database
(e.g., from docker-compose.ci.yml), never the development database.
"""

from datetime import datetime, timezone
from pathlib import Path

import psycopg2
import pytest
from psycopg2.extras import RealDictCursor

from core.clock import Clock
from core.config import settings


@pytest.fixture(scope="session")
def db_setup():
    """Initialize the test database schema and seed data once per test session."""
    conn = psycopg2.connect(settings.DATABASE_URL)
    cursor = conn.cursor()

    # Drop all existing tables to start fresh
    cursor.execute("DROP SCHEMA public CASCADE; CREATE SCHEMA public;")

    # Read and execute schema.sql
    schema_path = Path(__file__).parent / "db" / "schema.sql"
    with open(schema_path, "r") as f:
        schema_sql = f.read()
    cursor.execute(schema_sql)

    # Read and execute seed.sql
    seed_path = Path(__file__).parent / "db" / "seed.sql"
    with open(seed_path, "r") as f:
        seed_sql = f.read()
    cursor.execute(seed_sql)

    conn.commit()
    cursor.close()
    conn.close()


@pytest.fixture
def db_conn(db_setup):
    """
    Fixture providing a database connection and cursor for a single test.
    Yields a RealDictCursor, truncates relevant tables after the test.
    """
    conn = psycopg2.connect(settings.DATABASE_URL)
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    yield cursor

    # Truncate only transactional/user data — accounts, budget_envelopes, and
    # categories are seeded reference data and must survive between tests.
    cursor.execute(
        """
        TRUNCATE transactions, credit_ledger, user_month_state, months, users
        CASCADE;
        """
    )
    conn.commit()
    cursor.close()
    conn.close()


class FrozenClock(Clock):
    """A mock Clock that returns a fixed time."""

    def __init__(self, frozen_time: datetime):
        self.frozen_time = frozen_time

    def now(self) -> datetime:
        return self.frozen_time


@pytest.fixture
def frozen_clock():
    """
    Fixture providing a FrozenClock for use in tests.
    Example: frozen_clock(datetime(2025, 9, 1, 12, 0, 0, tzinfo=timezone.utc))
    """
    return lambda dt: FrozenClock(dt)
