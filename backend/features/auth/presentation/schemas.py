"""
Pydantic schemas for auth requests and responses.
"""

from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    """Request body for POST /auth/register."""

    username: str = Field(..., min_length=1)
    email: str
    password: str = Field(..., min_length=1)


class LoginRequest(BaseModel):
    """Request body for POST /auth/login."""

    username: str
    password: str


class RefreshRequest(BaseModel):
    """Request body for POST /auth/refresh."""

    refresh_token: str


class TokenResponse(BaseModel):
    """Response for successful login or refresh."""

    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"


class UserResponse(BaseModel):
    """Response for user info (e.g., after registration)."""

    user_id: int
    username: str
    email: str
