import os
from typing import Optional


class Settings:
    """Application configuration loaded from environment variables."""

    def __init__(self):
        self.DATABASE_URL: str = os.getenv(
            "DATABASE_URL",
            "postgresql://finance_dashboard:finance_dashboard@localhost:5432/finance_dashboard",
        )
        # TODO: Harden JWT_SECRET to fail fast if not set in production, rather than silently using a fallback
        self.JWT_SECRET: str = os.getenv("JWT_SECRET", "your-secret-key-change-in-production")
        self.JWT_ALGORITHM: str = "HS256"
        self.SALARY_TOTAL: float = float(os.getenv("SALARY_TOTAL", "46200"))
        self.ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
        self.REFRESH_TOKEN_EXPIRE_DAYS: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "7"))


# Singleton instance
settings = Settings()
