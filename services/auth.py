from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta, timezone

from services.db_config import get_db

SECRET_KEY = "your_super_secret_key_that_is_very_long_and_secure"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 15  
REFRESH_TOKEN_EXPIRE_DAYS = 7     

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, cursor):
    """Creates a new JWT access token."""
    to_encode = data.copy()
    user_id = data.get("sub")

    if not user_id:
        raise ValueError("Missing 'sub' (user_id) in token data")

    cursor.execute(
        "SELECT username FROM users WHERE user_id = %s",
        (user_id,)
    )
    user_data = cursor.fetchone()

    if not user_data:
        raise ValueError(f"No user found with user_id: {user_id}")

    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({
        "exp": expire,
        "type": "access",
        "username": user_data[0]
    })
    
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt



def create_refresh_token(data: dict):
    """Creates a new JWT refresh token."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    # Add a specific claim to identify this as a refresh token
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    Dependency to verify ACCESS token and return user ID.
    This function will reject refresh tokens.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        print(payload)
        # Check if it's an access token
        if payload.get("type") != "access":
            raise credentials_exception
            
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
            
    except JWTError:
        raise credentials_exception
        
    return int(user_id)

def get_current_username(token: str = Depends(oauth2_scheme)):
    """
    Dependency to verify ACCESS token and return the username.
    This function will reject refresh tokens.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        # Ensure it's an access token
        if payload.get("type") != "access":
            raise credentials_exception

        username: str = payload.get("username")
        if username is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    return username
