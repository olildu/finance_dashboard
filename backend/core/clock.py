from datetime import datetime, timezone


class Clock:
    """Provides the current time; can be mocked in tests to freeze time."""

    def now(self) -> datetime:
        """Return current datetime in UTC."""
        return datetime.now(timezone.utc)


# Module-level singleton instance
_clock = Clock()


def get_clock() -> Clock:
    """
    FastAPI dependency for accessing the clock.
    Can be overridden in tests to provide a frozen or mocked clock.
    """
    return _clock


# Convention: Do not call datetime.now() directly anywhere else in the codebase.
# Always use get_clock().now() or pass the clock as a dependency.
