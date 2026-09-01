"""
Auth endpoints: register, login, refresh, and get_current_user dependency.
"""

import jwt
from fastapi import APIRouter, Depends, HTTPException, Header, status
from psycopg2.errors import IntegrityError

from core.clock import get_clock
from core.config import settings
from core.db import get_db
from features.auth.business.security import PasswordHasher, TokenService
from features.auth.data.repository import AuthRepository
from features.auth.presentation.schemas import (
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)

router = APIRouter(tags=["auth"])


def get_password_hasher() -> PasswordHasher:
    """Dependency: password hasher instance."""
    return PasswordHasher()


def get_token_service() -> TokenService:
    """Dependency: token service instance."""
    return TokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, get_clock())


def get_auth_repository(db=Depends(get_db)) -> AuthRepository:
    """Dependency: auth repository with database cursor."""
    return AuthRepository(db)


def get_current_user(authorization: str = Header(None)) -> int:
    """
    Dependency: extract and validate user_id from Bearer token.
    Raises HTTPException(401) if token is missing or invalid.
    """
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing authorization header")
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header format")

    token = authorization[7:]
    token_service = get_token_service()
    try:
        user_id = token_service.get_user_id_from_token(token)
        return user_id
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


@router.post("/register", status_code=status.HTTP_201_CREATED, response_model=UserResponse)
def register(
    req: RegisterRequest,
    repository: AuthRepository = Depends(get_auth_repository),
    hasher: PasswordHasher = Depends(get_password_hasher),
):
    """Register a new user."""
    try:
        password_hash = hasher.hash_password(req.password)
        user_id = repository.insert_user(req.username, req.email, password_hash)
        return UserResponse(user_id=user_id, username=req.username, email=req.email)
    except IntegrityError as e:
        # Determine if duplicate username or email
        if "username" in str(e):
            detail = f"Username '{req.username}' already exists"
        elif "email" in str(e):
            detail = f"Email '{req.email}' already exists"
        else:
            detail = "User with this credentials already exists"
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=detail)


@router.post("/login", response_model=TokenResponse)
def login(
    req: LoginRequest,
    repository: AuthRepository = Depends(get_auth_repository),
    hasher: PasswordHasher = Depends(get_password_hasher),
    token_service: TokenService = Depends(get_token_service),
):
    """Authenticate and return access and refresh tokens."""
    user = repository.get_user_by_username(req.username)
    if not user or not hasher.verify_password(req.password, user["password_hash"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    user_id = user["user_id"]
    access_token = token_service.create_access_token(
        user_id=user_id,
        expires_in_minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES,
    )
    refresh_token = token_service.create_refresh_token(
        user_id=user_id,
        expires_in_days=settings.REFRESH_TOKEN_EXPIRE_DAYS,
    )
    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/refresh", response_model=dict)
def refresh(
    req: RefreshRequest,
    token_service: TokenService = Depends(get_token_service),
):
    """Refresh access token using a valid refresh token."""
    try:
        # Decode the refresh token
        payload = token_service.decode_token(req.refresh_token)

        # Verify it's actually a refresh token (not an access token)
        if payload.get("token_type") != "refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token")

        user_id = int(payload["sub"])
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token")

    # Create new access token
    access_token = token_service.create_access_token(
        user_id=user_id,
        expires_in_minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES,
    )
    return {"access_token": access_token, "token_type": "bearer"}
