import psycopg2.errors
from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, EmailStr
from jose import JWTError, jwt

from services.db_config import get_db
from models.auth_models import UserCreate, Token, RefreshRequest
from services.auth import (
    get_password_hash, create_access_token, create_refresh_token, 
    verify_password, SECRET_KEY, ALGORITHM
)

router = APIRouter()

@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register_user(user: UserCreate, cursor=Depends(get_db)):
    hashed_password = get_password_hash(user.password)
    try:
        cursor.execute(
            "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s)",
            (user.username, user.email, hashed_password)
        )
    except psycopg2.errors.UniqueViolation:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered.",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )
    return {"message": "User registered successfully."}

@router.post("/login")
async def login_for_access_token(form_data: UserCreate, cursor=Depends(get_db)):
    try:
        cursor.execute(
            "SELECT user_id, password_hash FROM users WHERE username = %s",
            (form_data.username,)
        )
        user_data = cursor.fetchone()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )

    if not user_data or not verify_password(form_data.password, user_data[1]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = user_data[0]

    access_token = create_access_token(data={"sub": str(user_id)}, cursor=cursor)
    refresh_token = create_refresh_token(data={"sub": str(user_id)})

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }


@router.post("/refresh")
async def refresh_access_token(body: RefreshRequest, cursor=Depends(get_db)):
    refresh_token = body.refresh_token
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid refresh token",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "refresh":
            raise credentials_exception

        user_id = payload.get("sub")
        if user_id is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    new_access_token = create_access_token(data={"sub": user_id}, cursor=cursor)

    return {
        "access_token": new_access_token,
        "token_type": "bearer"
    }
