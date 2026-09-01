from contextlib import contextmanager
from typing import Generator

import psycopg2
from psycopg2.extras import RealDictCursor
from psycopg2.pool import SimpleConnectionPool

from core.config import settings

# The pool is created lazily on first use, not at import time, so that
# importing this module (e.g. during test collection or `python -c "import main"`)
# never requires a live Postgres connection.
_pool: SimpleConnectionPool | None = None


def _get_pool() -> SimpleConnectionPool:
    global _pool
    if _pool is None:
        _pool = SimpleConnectionPool(
            minconn=2,
            maxconn=20,
            dsn=settings.DATABASE_URL,
        )
    return _pool


@contextmanager
def get_conn():
    """
    Context manager for acquiring a connection from the pool.
    Commits on success, rolls back on exception, always releases to pool.
    """
    pool = _get_pool()
    conn = pool.getconn()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        pool.putconn(conn)


def get_db() -> Generator:
    """
    FastAPI dependency for database cursor access.
    Yields a cursor with RealDictCursor factory (dict-like rows).
    """
    with get_conn() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            yield cursor
        finally:
            cursor.close()
