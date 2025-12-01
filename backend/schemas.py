from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from enum import Enum

# Role enum matching database RoleEnum
class RoleEnum(str, Enum):
    inspector = "inspector"
    manager = "manager"

# Token schemas
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    username: Optional[str] = None
    user_id: Optional[int] = None
    role: Optional[str] = None

# User schemas
class UserCreate(BaseModel):
    username: str
    password: str
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None

class UserOut(BaseModel):
    id: int
    username: str
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    role: RoleEnum
    phone: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

# Login form
class LoginForm(BaseModel):
    username: str
    password: str
