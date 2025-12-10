from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import models
import schemas
from db import get_db
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from datetime import datetime, timedelta
from jose import jwt, JWTError
import os
from dotenv import load_dotenv

load_dotenv()

JWT_SECRET = os.getenv("JWT_SECRET", "change_me")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 1440))

router = APIRouter()

# Argon2 hasher instance
ph = PasswordHasher()


# JWT TOKEN CREATION

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    now = datetime.utcnow()
    expire = now + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))

    to_encode.update({"exp": expire, "iat": now})

    encoded_jwt = jwt.encode(to_encode, JWT_SECRET, algorithm=ALGORITHM)
    return encoded_jwt


# PASSWORD HASHING + VERIFYING (using Argon2)

def verify_password(plain_password: str, hashed_password: str):
    try:
        return ph.verify(hashed_password, plain_password)
    except VerifyMismatchError:
        return False


def get_password_hash(password: str):
    return ph.hash(password)


# AUTHENTICATE USER

def authenticate_user(db: Session, username: str, password: str):
    print(f"\n[DEBUG] Attempting login for username/staff_id: '{username}'")
    print(f"[DEBUG] Password length: {len(password)}")
    
    # Try to find user by username or staff_id
    user = db.query(models.User).filter(
        (models.User.username == username) | (models.User.staff_id == username)
    ).first()
    if not user:
        print(f"[DEBUG] User not found: '{username}'")
        return None
    
    print(f"[DEBUG] User found: {user.username}")
    print(f"[DEBUG] Stored hash starts with: {user.password_hash[:30]}...")
    
    verification_result = verify_password(password, user.password_hash)
    print(f"[DEBUG] Password verification result: {verification_result}")
    
    if not verification_result:
        return None
    return user

# TOKEN + CURRENT USER HANDLING

from fastapi.security import OAuth2PasswordBearer
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        user_id: int = payload.get("user_id")
        role: str = payload.get("role")

        if username is None or user_id is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise credentials_exception

    return user


def get_current_active_user(current_user: models.User = Depends(get_current_user)):
    return current_user

# LOGIN

@router.post("/login", response_model=schemas.Token)
def login(form_data: schemas.LoginForm, db: Session = Depends(get_db)):
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid username or password")

    access_token = create_access_token(
        {"sub": user.username, "user_id": user.id, "role": user.role}
    )
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }

# PROFILE

@router.get("/me", response_model=schemas.UserOut)
def read_users_me(current_user: models.User = Depends(get_current_active_user)):
    return current_user
