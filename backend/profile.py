"""
Profile Management API
Handles user profile operations for both Managers and Inspectors
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from pydantic import BaseModel, EmailStr
from datetime import datetime
import secrets
import string

from db import get_db
from auth import get_current_user
import models
from argon2 import PasswordHasher

router = APIRouter(prefix="/profile", tags=["Profile Management"])
ph = PasswordHasher()

# ==================== Schemas ====================

class ProfileUpdateRequest(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    years_experience: Optional[int] = None  # For inspectors

class PasswordUpdateRequest(BaseModel):
    current_password: str
    new_password: str

class CreateUserRequest(BaseModel):
    username: str
    password: Optional[str] = None  # Optional - can be auto-generated
    email: EmailStr
    role: str  # "manager" or "inspector"
    phone: Optional[str] = None
    years_experience: Optional[int] = None
    generate_temp_password: bool = False

class UpdateUserRequest(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None
    years_experience: Optional[int] = None

class ResetPasswordRequest(BaseModel):
    user_id: int
    new_password: Optional[str] = None  # Optional - can be auto-generated
    generate_temp_password: bool = False

class UserResponse(BaseModel):

    id: int
    username: str
    staff_id: str
    email: str
    role: str
    phone: Optional[str]
    profile_picture: Optional[str]
    years_experience: Optional[int]
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime]
    last_password_change: Optional[datetime]

    class Config:
        from_attributes = True

# UsersListResponse must be defined after UserResponse
class UsersListResponse(BaseModel):
    users: List[UserResponse]

class CreateUserResponse(BaseModel):
    message: str
    user: UserResponse
    temporary_password: Optional[str] = None
    note: Optional[str] = None

class ResetPasswordResponse(BaseModel):
    message: str
    temporary_password: Optional[str] = None
    note: Optional[str] = None
# ==================== Helper Functions ====================

def generate_temp_password(length=12):
    """Generate a secure temporary password"""
    characters = string.ascii_letters + string.digits + "!@#$%"
    return ''.join(secrets.choice(characters) for _ in range(length))

def generate_staff_id(db: Session, role: str) -> str:
    """Generate unique Staff ID in the format S001, S002, ... for all users"""
    users = db.query(models.User).filter(models.User.staff_id.like("S%"))
    max_num = 0
    for user in users:
        try:
            num = int(user.staff_id[1:])
            if num > max_num:
                max_num = num
        except:
            continue
    new_num = max_num + 1
    return f"S{new_num:03d}"

def log_activity(db: Session, manager_id: int, action: str, target_user_id: int = None, details: str = None):
    """Log account management activity - to be implemented with ActivityLog model"""
    # TODO: Implement activity logging when ActivityLog model is added
    pass

# ==================== Profile Endpoints (Inspector & Manager) ====================

@router.get("/me", response_model=UserResponse)
def get_my_profile(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's profile"""
    return current_user

@router.put("/me", response_model=UserResponse)
def update_my_profile(
    profile_data: ProfileUpdateRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update current user's profile"""
    
    # Update fields if provided
    if profile_data.username is not None and profile_data.username != current_user.username:
        # Check if new username is already taken
        existing_username = db.query(models.User).filter(
            models.User.username == profile_data.username,
            models.User.id != current_user.id
        ).first()
        if existing_username:
            raise HTTPException(status_code=400, detail="Username is already taken")
        current_user.username = profile_data.username
    if profile_data.email is not None:
        # Check if email is already used by another user
        existing = db.query(models.User).filter(
            models.User.email == profile_data.email,
            models.User.id != current_user.id
        ).first()
        if existing:
            raise HTTPException(status_code=400, detail="Email already in use")
        current_user.email = profile_data.email
    if profile_data.phone is not None:
        current_user.phone = profile_data.phone
    
    # Inspector-specific fields
    if current_user.role == models.RoleEnum.inspector:
        if profile_data.years_experience is not None:
            current_user.years_experience = profile_data.years_experience
    
    current_user.updated_at = func.now()
    db.commit()
    db.refresh(current_user)
    return current_user

@router.put("/me/password")
def update_my_password(
    password_data: PasswordUpdateRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update current user's password"""
    
    # Verify current password
    try:
        ph.verify(current_user.password_hash, password_data.current_password)
    except:
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    
    # Validate new password
    if len(password_data.new_password) < 6:
        raise HTTPException(status_code=400, detail="New password must be at least 6 characters")
    
    # Hash and update password
    current_user.password_hash = ph.hash(password_data.new_password)
    current_user.last_password_change = func.now()
    current_user.updated_at = func.now()
    db.commit()
    
    return {"message": "Password updated successfully"}

# ==================== Manager-Only Endpoints ====================

def require_manager(current_user: models.User = Depends(get_current_user)):
    """Dependency to ensure user is a manager"""
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can access this endpoint"
        )
    return current_user

@router.get("/users", response_model=UsersListResponse, dependencies=[Depends(require_manager)])
def get_all_users(
    include_inactive: bool = False,
    current_user: models.User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """Get list of all users (Manager only)"""
    
    import traceback
    try:
        query = db.query(models.User)
        if not include_inactive:
            query = query.filter(models.User.is_active == 1)
        users_orm = query.order_by(models.User.created_at.desc()).all()
        users_pydantic = [UserResponse.from_orm(user) for user in users_orm]
        print(f"[DEBUG] /profile/users called by: {current_user.username} (role: {current_user.role}) - Found {len(users_pydantic)} users.")
        return UsersListResponse(users=users_pydantic)
    except Exception as e:
        print("[ERROR] Exception in /profile/users:", e)
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/users", response_model=CreateUserResponse, dependencies=[Depends(require_manager)])
def create_user(
    user_data: CreateUserRequest,
    current_user: models.User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """Create a new user account (Manager only)"""
    
    # Check if username already exists
    existing = db.query(models.User).filter(models.User.username == user_data.username).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    # Check if email already exists
    if user_data.email:
        existing_email = db.query(models.User).filter(models.User.email == user_data.email).first()
        if existing_email:
            raise HTTPException(status_code=400, detail="Email already in use")
    
    # Validate role
    if user_data.role not in ["manager", "inspector"]:
        raise HTTPException(status_code=400, detail="Invalid role. Must be 'manager' or 'inspector'")
    
    # Generate password if requested or not provided
    password = user_data.password
    temp_password = None
    if user_data.generate_temp_password or not password:
        temp_password = generate_temp_password()
        password = temp_password
    
    # Validate password
    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    
    # Generate Staff ID
    staff_id = generate_staff_id(db, user_data.role)
    
    # Create user
    new_user = models.User(
        username=user_data.username,
        staff_id=staff_id,
        password_hash=ph.hash(password),
        email=user_data.email,
        phone=user_data.phone,
        role=models.RoleEnum.manager if user_data.role == "manager" else models.RoleEnum.inspector,
        years_experience=user_data.years_experience if user_data.role == "inspector" else None,
        is_active=1
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Log activity (Note: ActivityLog table needs to be added to models)
    # log_activity(db, current_user.id, "created", new_user.id, f"Created {user_data.role} account: {user_data.username}")
    
    user_response_data = UserResponse.from_orm(new_user)
    
    response = CreateUserResponse(
        message="User created successfully",
        user=user_response_data
    )
    
    if temp_password:
        response.temporary_password = temp_password
        response.note = "Please save this temporary password. User should change it after first login."
    
    return response

@router.get("/users/{user_id}", response_model=UserResponse, dependencies=[Depends(require_manager)])
def get_user(
    user_id: int,
    current_user: models.User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """Get specific user details (Manager only)"""
    
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user

@router.put("/users/{user_id}", response_model=UserResponse, dependencies=[Depends(require_manager)])
def update_user(
    user_id: int,
    user_data: UpdateUserRequest,
    current_user: models.User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """Update user account (Manager only)"""
    
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Update fields if provided
    if user_data.username is not None and user_data.username != user.username:
        # Check if new username is already taken
        existing_username = db.query(models.User).filter(
            models.User.username == user_data.username,
            models.User.id != user_id
        ).first()
        if existing_username:
            raise HTTPException(status_code=400, detail="Username is already taken")
        user.username = user_data.username
    if user_data.email is not None:
        # Check if email is already used
        existing = db.query(models.User).filter(
            models.User.email == user_data.email,
            models.User.id != user_id
        ).first()
        if existing:
            raise HTTPException(status_code=400, detail="Email already in use")
        user.email = user_data.email
    if user_data.phone is not None:
        user.phone = user_data.phone
    if user_data.role is not None:
        if user_data.role not in ["manager", "inspector"]:
            raise HTTPException(status_code=400, detail="Invalid role")
        user.role = models.RoleEnum.manager if user_data.role == "manager" else models.RoleEnum.inspector
    if user_data.is_active is not None:
        user.is_active = 1 if user_data.is_active else 0
    if user_data.years_experience is not None:
        user.years_experience = user_data.years_experience
    
    user.updated_at = func.now()
    db.commit()
    db.refresh(user)
    return user

@router.delete("/users/{user_id}", dependencies=[Depends(require_manager)])
def delete_user(
    user_id: int,
    current_user: models.User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """Delete user account (Manager only)"""
    
    # Prevent self-deletion
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot delete your own account")
    
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    username = user.username
    db.delete(user)
    db.commit()
    
    return {"message": f"User '{username}' deleted successfully"}

@router.put("/users/{user_id}/deactivate", dependencies=[Depends(require_manager)])
def deactivate_user(
    user_id: int,
    current_user: models.User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """Deactivate user account (Manager only)"""
    
    # Prevent self-deactivation
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot deactivate your own account")
    
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_active = 0
    user.updated_at = func.now()
    db.commit()
    
    return {"message": f"User '{user.username}' deactivated successfully"}

@router.put("/users/{user_id}/activate", dependencies=[Depends(require_manager)])
def activate_user(
    user_id: int,
    current_user: models.User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """Activate user account (Manager only)"""
    
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_active = 1
    user.updated_at = func.now()
    db.commit()
    
    return {"message": f"User '{user.username}' activated successfully"}

@router.post("/users/{user_id}/reset-password", response_model=ResetPasswordResponse, dependencies=[Depends(require_manager)])
def reset_user_password(
    user_id: int,
    reset_data: ResetPasswordRequest,
    current_user: models.User = Depends(require_manager),
    db: Session = Depends(get_db)
):
    """Reset user password (Manager only)"""
    
    if user_id != reset_data.user_id:
        raise HTTPException(status_code=400, detail="User ID mismatch")
    
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Generate password if requested or not provided
    password = reset_data.new_password
    temp_password = None
    if reset_data.generate_temp_password or not password:
        temp_password = generate_temp_password()
        password = temp_password
    
    # Validate password
    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    
    # Update password
    user.password_hash = ph.hash(password)
    user.last_password_change = func.now()
    user.updated_at = func.now()
    db.commit()
    
    response = ResetPasswordResponse(
        message=f"Password reset successfully for user '{user.username}'"
    )
    
    if temp_password:
        response.temporary_password = temp_password
        response.note = "Please save this temporary password and provide it to the user."
    
    return response
