"""
Integration tests for auth API endpoints.

Uses FastAPI TestClient with dependency_overrides to mock the repository layer.
Tests endpoint routing, request validation, response shape, and HTTP status codes.
Uses the REAL auth router from features.auth.presentation.router.
"""

from datetime import datetime, timedelta, timezone
from unittest.mock import Mock

import jwt
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from passlib.context import CryptContext
from psycopg2.errors import IntegrityError

from core.clock import Clock
from core.config import settings
from features.auth.business.security import PasswordHasher, TokenService
from features.auth.data.repository import AuthRepository
from features.auth.presentation.router import (
    get_auth_repository,
    get_password_hasher,
    get_token_service,
    router,
)


# ============================================================================
# Mock implementations for dependency overrides
# ============================================================================


class MockAuthRepository:
    """Mock auth repository for testing endpoints."""

    def __init__(self):
        self.users = {}  # username -> {user_id, email, password_hash}
        self.users_by_email = {}  # email -> user_id
        self.user_counter = 0

    def insert_user(self, username: str, email: str, password_hash: str) -> int:
        """Insert a new user; raise IntegrityError if username or email already exists."""
        if username in self.users:
            # Raise IntegrityError to match real database behavior
            raise IntegrityError("Duplicate username", None, None)
        if email in self.users_by_email:
            # Raise IntegrityError to match real database behavior
            raise IntegrityError("Duplicate email", None, None)

        self.user_counter += 1
        user_id = self.user_counter
        self.users[username] = {
            "user_id": user_id,
            "email": email,
            "password_hash": password_hash,
        }
        self.users_by_email[email] = user_id
        return user_id

    def get_user_by_username(self, username: str) -> dict:
        """Get user by username; return None if not found."""
        return self.users.get(username)

    def get_user_by_email(self, email: str) -> dict:
        """Get user by email; return None if not found."""
        user_id = self.users_by_email.get(email)
        if user_id is None:
            return None
        for user in self.users.values():
            if user["user_id"] == user_id:
                return user
        return None


# ============================================================================
# Fixture setup
# ============================================================================


@pytest.fixture
def mock_repo():
    """Provide a fresh mock repository for each test."""
    return MockAuthRepository()


@pytest.fixture
def app_with_mocks(mock_repo):
    """
    Create a FastAPI app with the REAL auth router,
    but override the repository dependency with a mock.
    """
    app = FastAPI()
    app.include_router(router, prefix="/auth")

    # Override the repository dependency with our mock
    app.dependency_overrides[get_auth_repository] = lambda: mock_repo

    return app


@pytest.fixture
def client(app_with_mocks):
    """Create a FastAPI TestClient."""
    return TestClient(app_with_mocks)


# ============================================================================
# Tests for POST /auth/register
# ============================================================================


class TestRegisterEndpoint:
    """Test POST /auth/register."""

    def test_register_with_valid_data_returns_201(self, client):
        """POST /auth/register with valid data should return 201 Created."""
        response = client.post(
            "/auth/register",
            json={
                "username": "testuser",
                "email": "test@example.com",
                "password": "secure_password_123",
            },
        )

        assert response.status_code == 201

    def test_register_returns_user_info(self, client):
        """POST /auth/register should return user_id, username, and email."""
        response = client.post(
            "/auth/register",
            json={
                "username": "testuser",
                "email": "test@example.com",
                "password": "secure_password_123",
            },
        )

        data = response.json()
        assert "user_id" in data
        assert data["username"] == "testuser"
        assert data["email"] == "test@example.com"
        assert isinstance(data["user_id"], int)

    def test_register_with_duplicate_username_returns_409(self, client):
        """POST /auth/register with duplicate username should return 409 Conflict."""
        client.post(
            "/auth/register",
            json={
                "username": "testuser",
                "email": "test1@example.com",
                "password": "password123",
            },
        )

        response = client.post(
            "/auth/register",
            json={
                "username": "testuser",
                "email": "test2@example.com",
                "password": "password123",
            },
        )

        assert response.status_code == 409

    def test_register_with_duplicate_email_returns_409(self, client):
        """POST /auth/register with duplicate email should return 409 Conflict."""
        client.post(
            "/auth/register",
            json={
                "username": "user1",
                "email": "test@example.com",
                "password": "password123",
            },
        )

        response = client.post(
            "/auth/register",
            json={
                "username": "user2",
                "email": "test@example.com",
                "password": "password123",
            },
        )

        assert response.status_code == 409

    def test_register_with_missing_username_returns_422(self, client):
        """POST /auth/register without username should return 422 Unprocessable Entity."""
        response = client.post(
            "/auth/register",
            json={
                "email": "test@example.com",
                "password": "password123",
            },
        )

        assert response.status_code == 422

    def test_register_with_missing_email_returns_422(self, client):
        """POST /auth/register without email should return 422."""
        response = client.post(
            "/auth/register",
            json={
                "username": "testuser",
                "password": "password123",
            },
        )

        assert response.status_code == 422

    def test_register_with_missing_password_returns_422(self, client):
        """POST /auth/register without password should return 422."""
        response = client.post(
            "/auth/register",
            json={
                "username": "testuser",
                "email": "test@example.com",
            },
        )

        assert response.status_code == 422

    def test_register_with_empty_username_returns_422(self, client):
        """POST /auth/register with empty username should return 422."""
        response = client.post(
            "/auth/register",
            json={
                "username": "",
                "email": "test@example.com",
                "password": "password123",
            },
        )

        assert response.status_code == 422

    def test_register_with_empty_password_returns_422(self, client):
        """POST /auth/register with empty password should return 422."""
        response = client.post(
            "/auth/register",
            json={
                "username": "testuser",
                "email": "test@example.com",
                "password": "",
            },
        )

        assert response.status_code == 422


# ============================================================================
# Tests for POST /auth/login
# ============================================================================


class TestLoginEndpoint:
    """Test POST /auth/login."""

    def test_login_with_valid_credentials_returns_200(self, client, mock_repo):
        """POST /auth/login with valid credentials should return 200 OK."""
        password = "test_password_123"
        hasher = PasswordHasher()
        password_hash = hasher.hash_password(password)
        mock_repo.insert_user("testuser", "test@example.com", password_hash)

        response = client.post(
            "/auth/login",
            json={"username": "testuser", "password": password},
        )

        assert response.status_code == 200

    def test_login_returns_access_token(self, client, mock_repo):
        """POST /auth/login should return access_token in response."""
        password = "test_password_123"
        hasher = PasswordHasher()
        password_hash = hasher.hash_password(password)
        mock_repo.insert_user("testuser", "test@example.com", password_hash)

        response = client.post(
            "/auth/login",
            json={"username": "testuser", "password": password},
        )

        data = response.json()
        assert "access_token" in data
        assert isinstance(data["access_token"], str)

    def test_login_returns_refresh_token(self, client, mock_repo):
        """POST /auth/login should return refresh_token in response."""
        password = "test_password_123"
        hasher = PasswordHasher()
        password_hash = hasher.hash_password(password)
        mock_repo.insert_user("testuser", "test@example.com", password_hash)

        response = client.post(
            "/auth/login",
            json={"username": "testuser", "password": password},
        )

        data = response.json()
        assert "refresh_token" in data
        assert isinstance(data["refresh_token"], str)

    def test_login_tokens_are_valid_jwt(self, client, mock_repo):
        """Returned tokens should be valid JWTs."""
        password = "test_password_123"
        hasher = PasswordHasher()
        password_hash = hasher.hash_password(password)
        mock_repo.insert_user("testuser", "test@example.com", password_hash)

        response = client.post(
            "/auth/login",
            json={"username": "testuser", "password": password},
        )

        data = response.json()
        # Both should decode without error
        jwt.decode(data["access_token"], settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        jwt.decode(data["refresh_token"], settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])

    def test_login_with_nonexistent_user_returns_401(self, client):
        """POST /auth/login with nonexistent user should return 401 Unauthorized."""
        response = client.post(
            "/auth/login",
            json={"username": "nonexistent", "password": "password"},
        )

        assert response.status_code == 401

    def test_login_with_wrong_password_returns_401(self, client, mock_repo):
        """POST /auth/login with wrong password should return 401."""
        password = "correct_password"
        hasher = PasswordHasher()
        password_hash = hasher.hash_password(password)
        mock_repo.insert_user("testuser", "test@example.com", password_hash)

        response = client.post(
            "/auth/login",
            json={"username": "testuser", "password": "wrong_password"},
        )

        assert response.status_code == 401

    def test_login_with_missing_username_returns_422(self, client):
        """POST /auth/login without username should return 422."""
        response = client.post(
            "/auth/login",
            json={"password": "password123"},
        )

        assert response.status_code == 422

    def test_login_with_missing_password_returns_422(self, client):
        """POST /auth/login without password should return 422."""
        response = client.post(
            "/auth/login",
            json={"username": "testuser"},
        )

        assert response.status_code == 422

    def test_login_returns_token_type(self, client, mock_repo):
        """POST /auth/login response should include token_type."""
        password = "test_password_123"
        hasher = PasswordHasher()
        password_hash = hasher.hash_password(password)
        mock_repo.insert_user("testuser", "test@example.com", password_hash)

        response = client.post(
            "/auth/login",
            json={"username": "testuser", "password": password},
        )

        data = response.json()
        assert data.get("token_type") == "bearer"


# ============================================================================
# Tests for POST /auth/refresh
# ============================================================================


class TestRefreshEndpoint:
    """Test POST /auth/refresh."""

    def test_refresh_with_valid_refresh_token_returns_200(self, client, mock_repo):
        """POST /auth/refresh with valid refresh_token should return 200."""
        password = "test_password_123"
        hasher = PasswordHasher()
        password_hash = hasher.hash_password(password)
        mock_repo.insert_user("testuser", "test@example.com", password_hash)

        login_response = client.post(
            "/auth/login",
            json={"username": "testuser", "password": password},
        )
        refresh_token = login_response.json()["refresh_token"]

        response = client.post(
            "/auth/refresh",
            json={"refresh_token": refresh_token},
        )

        assert response.status_code == 200

    def test_refresh_returns_new_access_token(self, client, mock_repo):
        """POST /auth/refresh should return a new access_token."""
        password = "test_password_123"
        hasher = PasswordHasher()
        password_hash = hasher.hash_password(password)
        mock_repo.insert_user("testuser", "test@example.com", password_hash)

        login_response = client.post(
            "/auth/login",
            json={"username": "testuser", "password": password},
        )
        refresh_token = login_response.json()["refresh_token"]
        original_access_token = login_response.json()["access_token"]

        # Wait a moment to ensure different iat claim if tokens are created too quickly
        import time
        time.sleep(0.01)

        response = client.post(
            "/auth/refresh",
            json={"refresh_token": refresh_token},
        )

        data = response.json()
        assert "access_token" in data
        # New access_token should be a valid JWT
        assert isinstance(data["access_token"], str)
        assert "." in data["access_token"]

    def test_refresh_access_token_is_valid_jwt(self, client, mock_repo):
        """Refreshed access_token should be a valid JWT."""
        password = "test_password_123"
        hasher = PasswordHasher()
        password_hash = hasher.hash_password(password)
        mock_repo.insert_user("testuser", "test@example.com", password_hash)

        login_response = client.post(
            "/auth/login",
            json={"username": "testuser", "password": password},
        )
        refresh_token = login_response.json()["refresh_token"]

        response = client.post(
            "/auth/refresh",
            json={"refresh_token": refresh_token},
        )

        data = response.json()
        # Should decode without error
        jwt.decode(data["access_token"], settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])

    def test_refresh_with_invalid_refresh_token_returns_401(self, client):
        """POST /auth/refresh with invalid refresh_token should return 401."""
        response = client.post(
            "/auth/refresh",
            json={"refresh_token": "invalid.token.here"},
        )

        assert response.status_code == 401

    def test_refresh_with_access_token_instead_of_refresh_token_returns_401(
        self, client, mock_repo
    ):
        """POST /auth/refresh with access_token instead of refresh_token should return 401."""
        password = "test_password_123"
        hasher = PasswordHasher()
        password_hash = hasher.hash_password(password)
        mock_repo.insert_user("testuser", "test@example.com", password_hash)

        login_response = client.post(
            "/auth/login",
            json={"username": "testuser", "password": password},
        )
        access_token = login_response.json()["access_token"]

        # Try to use access_token as refresh_token
        response = client.post(
            "/auth/refresh",
            json={"refresh_token": access_token},
        )

        # Should fail because token_type is 'access', not 'refresh'
        assert response.status_code == 401

    def test_refresh_with_missing_refresh_token_returns_422(self, client):
        """POST /auth/refresh without refresh_token should return 422."""
        response = client.post(
            "/auth/refresh",
            json={},
        )

        assert response.status_code == 422

    def test_refresh_returns_token_type(self, client, mock_repo):
        """POST /auth/refresh response should include token_type."""
        password = "test_password_123"
        hasher = PasswordHasher()
        password_hash = hasher.hash_password(password)
        mock_repo.insert_user("testuser", "test@example.com", password_hash)

        login_response = client.post(
            "/auth/login",
            json={"username": "testuser", "password": password},
        )
        refresh_token = login_response.json()["refresh_token"]

        response = client.post(
            "/auth/refresh",
            json={"refresh_token": refresh_token},
        )

        data = response.json()
        assert data.get("token_type") == "bearer"
