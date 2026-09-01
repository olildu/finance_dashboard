"""
Security utilities for authentication: password hashing and JWT token management.
"""

from datetime import datetime, timedelta, timezone

import jwt
from passlib.context import CryptContext

from core.clock import Clock
from core.config import settings


class PasswordHasher:
    """Password hashing using bcrypt."""

    def __init__(self):
        self.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

    def hash_password(self, password: str) -> str:
        """Hash a password using bcrypt."""
        return self.pwd_context.hash(password)

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify a plain password against its bcrypt hash."""
        return self.pwd_context.verify(plain_password, hashed_password)


class TokenService:
    """JWT token creation and validation."""

    def __init__(self, secret: str, algorithm: str, clock: Clock):
        self.secret = secret
        self.algorithm = algorithm
        self.clock = clock

    def create_access_token(self, user_id: int, expires_in_minutes: int) -> str:
        """Create a signed JWT access token."""
        now = self.clock.now()
        expiry = now + timedelta(minutes=expires_in_minutes)
        payload = {
            "sub": str(user_id),
            "exp": expiry,
            "iat": now,
            "token_type": "access",
        }
        return jwt.encode(payload, self.secret, algorithm=self.algorithm)

    def create_refresh_token(self, user_id: int, expires_in_days: int) -> str:
        """Create a signed JWT refresh token."""
        now = self.clock.now()
        expiry = now + timedelta(days=expires_in_days)
        payload = {
            "sub": str(user_id),
            "exp": expiry,
            "iat": now,
            "token_type": "refresh",
        }
        return jwt.encode(payload, self.secret, algorithm=self.algorithm)

    def decode_token(self, token: str) -> dict:
        """Decode and validate a JWT token; raise jwt.InvalidTokenError on failure."""
        try:
            return jwt.decode(token, self.secret, algorithms=[self.algorithm])
        except jwt.InvalidTokenError:
            raise

    def get_user_id_from_token(self, token: str) -> int:
        """Extract user_id from a valid token."""
        payload = self.decode_token(token)
        return int(payload["sub"])
