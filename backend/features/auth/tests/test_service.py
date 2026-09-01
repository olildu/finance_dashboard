"""
Unit tests for auth service.

Tests password hashing/verification and JWT encode/decode with real PasswordHasher and TokenService classes.
No database access — these classes are pure functions.
"""

from datetime import datetime, timedelta, timezone

import jwt
import pytest

from core.clock import Clock
from core.config import settings
from features.auth.business.security import PasswordHasher, TokenService


# ============================================================================
# Tests for password hashing and verification
# ============================================================================


class TestPasswordHashing:
    """Test password hashing and verification."""

    def test_hash_password_returns_non_empty_hash(self):
        """hash_password should return a bcrypt hash string."""
        hasher = PasswordHasher()
        password = "test_password_123"

        hashed = hasher.hash_password(password)

        assert hashed
        assert isinstance(hashed, str)
        assert len(hashed) > 0

    def test_hash_password_produces_different_hashes_for_same_password(self):
        """hash_password should produce different hashes each time (due to salt)."""
        hasher = PasswordHasher()
        password = "test_password_123"

        hash1 = hasher.hash_password(password)
        hash2 = hasher.hash_password(password)

        assert hash1 != hash2

    def test_verify_password_succeeds_with_correct_password(self):
        """verify_password should return True for correct plain password."""
        hasher = PasswordHasher()
        plain_password = "test_password_123"
        hashed = hasher.hash_password(plain_password)

        assert hasher.verify_password(plain_password, hashed) is True

    def test_verify_password_fails_with_incorrect_password(self):
        """verify_password should return False for incorrect plain password."""
        hasher = PasswordHasher()
        hashed = hasher.hash_password("test_password_123")

        assert hasher.verify_password("wrong_password", hashed) is False

    def test_verify_password_is_case_sensitive(self):
        """verify_password should be case-sensitive."""
        hasher = PasswordHasher()
        plain_password = "TestPassword123"
        hashed = hasher.hash_password(plain_password)

        assert hasher.verify_password("testpassword123", hashed) is False

    def test_verify_password_fails_with_empty_password(self):
        """verify_password should return False when comparing empty password."""
        hasher = PasswordHasher()
        hashed = hasher.hash_password("test_password_123")

        assert hasher.verify_password("", hashed) is False


# ============================================================================
# Tests for JWT token creation and decoding
# ============================================================================


class TestTokenCreation:
    """Test JWT token creation."""

    def test_create_access_token_returns_valid_jwt(self):
        """create_access_token should return a JWT string."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)

        token = token_service.create_access_token(user_id=1, expires_in_minutes=30)

        assert token
        assert isinstance(token, str)
        assert "." in token  # JWT format: header.payload.signature

    def test_create_access_token_includes_user_id_in_payload(self):
        """create_access_token payload should contain user_id in 'sub' claim."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)
        user_id = 42

        token = token_service.create_access_token(user_id=user_id, expires_in_minutes=30)
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])

        assert payload["sub"] == str(user_id)

    def test_create_access_token_sets_token_type(self):
        """create_access_token payload should have token_type='access'."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)

        token = token_service.create_access_token(user_id=1, expires_in_minutes=30)
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])

        assert payload["token_type"] == "access"

    def test_create_refresh_token_returns_valid_jwt(self):
        """create_refresh_token should return a JWT string."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)

        token = token_service.create_refresh_token(user_id=1, expires_in_days=7)

        assert token
        assert isinstance(token, str)
        assert "." in token

    def test_create_refresh_token_includes_user_id_in_payload(self):
        """create_refresh_token payload should contain user_id in 'sub' claim."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)
        user_id = 99

        token = token_service.create_refresh_token(user_id=user_id, expires_in_days=7)
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])

        assert payload["sub"] == str(user_id)

    def test_create_refresh_token_sets_token_type(self):
        """create_refresh_token payload should have token_type='refresh'."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)

        token = token_service.create_refresh_token(user_id=1, expires_in_days=7)
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])

        assert payload["token_type"] == "refresh"


class TestTokenDecoding:
    """Test JWT token decoding and validation."""

    def test_decode_token_with_valid_token_returns_payload(self):
        """decode_token should return the payload dict for a valid token."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)
        token = token_service.create_access_token(user_id=1, expires_in_minutes=30)

        payload = token_service.decode_token(token)

        assert isinstance(payload, dict)
        assert "sub" in payload
        assert payload["sub"] == "1"

    def test_decode_token_raises_with_invalid_signature(self):
        """decode_token should raise jwt.InvalidTokenError if signature is invalid."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)
        token = token_service.create_access_token(user_id=1, expires_in_minutes=30)

        # Tamper with the signature segment specifically (flipping a character
        # elsewhere, e.g. in the payload, can decode to the same bytes due to
        # base64url padding and would make this test flaky).
        header, payload, signature = token.split(".")
        tampered_signature = ("A" if signature[0] != "A" else "B") + signature[1:]
        tampered_token = f"{header}.{payload}.{tampered_signature}"

        with pytest.raises(jwt.InvalidTokenError):
            token_service.decode_token(tampered_token)

    def test_decode_token_raises_with_malformed_token(self):
        """decode_token should raise jwt.InvalidTokenError for malformed tokens."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)

        with pytest.raises(jwt.InvalidTokenError):
            token_service.decode_token("not.a.valid.jwt")

    def test_decode_token_raises_with_empty_token(self):
        """decode_token should raise jwt.InvalidTokenError for empty token."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)

        with pytest.raises(jwt.InvalidTokenError):
            token_service.decode_token("")

    def test_get_user_id_from_token_returns_correct_id(self):
        """get_user_id_from_token should extract and return the user_id as int."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)
        user_id = 123
        token = token_service.create_access_token(user_id=user_id, expires_in_minutes=30)

        extracted_id = token_service.get_user_id_from_token(token)

        assert extracted_id == user_id
        assert isinstance(extracted_id, int)

    def test_get_user_id_from_token_raises_with_invalid_token(self):
        """get_user_id_from_token should raise jwt.InvalidTokenError for invalid tokens."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)

        with pytest.raises(jwt.InvalidTokenError):
            token_service.get_user_id_from_token("invalid.token.here")


class TestTokenExpiration:
    """Test JWT token expiration using real time (not frozen)."""

    def test_access_token_has_correct_expiry_claim(self):
        """Access token should have exp claim set correctly (30 minutes ahead)."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)

        before = datetime.now(timezone.utc)
        token = token_service.create_access_token(user_id=1, expires_in_minutes=30)
        after = datetime.now(timezone.utc)

        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM], options={"verify_exp": False})

        exp_time = datetime.fromtimestamp(payload["exp"], tz=timezone.utc)
        # Token expiry should be approximately 30 minutes in the future
        assert 29 * 60 < (exp_time - before).total_seconds() < 31 * 60

    def test_refresh_token_has_correct_expiry_claim(self):
        """Refresh token should have exp claim set correctly (7 days ahead)."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)

        before = datetime.now(timezone.utc)
        token = token_service.create_refresh_token(user_id=1, expires_in_days=7)
        after = datetime.now(timezone.utc)

        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM], options={"verify_exp": False})

        exp_time = datetime.fromtimestamp(payload["exp"], tz=timezone.utc)
        # Token expiry should be approximately 7 days in the future
        assert 6.99 * 86400 < (exp_time - before).total_seconds() < 7.01 * 86400

    def test_expired_token_raises_expiration_error(self):
        """Decoding an expired token should raise jwt.ExpiredSignatureError."""
        # Create a token that's already expired by setting exp to the past
        secret = settings.JWT_SECRET
        algorithm = settings.JWT_ALGORITHM
        past_time = datetime.now(timezone.utc) - timedelta(hours=1)
        payload = {
            "sub": "1",
            "exp": past_time,
            "iat": past_time - timedelta(hours=2),
            "token_type": "access",
        }
        token = jwt.encode(payload, secret, algorithm=algorithm)

        with pytest.raises(jwt.ExpiredSignatureError):
            jwt.decode(token, secret, algorithms=[algorithm])

    def test_token_iat_claim_is_set(self):
        """Token should have iat (issued at) claim set to current time."""
        clock = Clock()
        token_service = TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, clock)

        before = datetime.now(timezone.utc)
        token = token_service.create_access_token(user_id=1, expires_in_minutes=30)
        after = datetime.now(timezone.utc)

        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM], options={"verify_exp": False})

        iat_time = datetime.fromtimestamp(payload["iat"], tz=timezone.utc)
        # iat should be close to when we created the token
        assert (iat_time - before).total_seconds() >= -1  # Allow 1 second tolerance
        assert (iat_time - after).total_seconds() <= 1  # Allow 1 second tolerance
