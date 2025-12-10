from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
import models
from db import get_db
from auth import get_current_user
from pydantic import BaseModel
from typing import Optional

router = APIRouter()

# Request models
class LocationCreate(BaseModel):
    name: str
    description: Optional[str] = None

class LocationUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None

# Get all active locations
@router.get("/locations")
def get_locations(
    include_inactive: bool = False,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get list of all locations"""
    
    query = db.query(models.Location)
    
    if not include_inactive:
        query = query.filter(models.Location.is_active == 1)
    
    locations = query.order_by(models.Location.name).all()
    
    return [{
        "id": loc.id,
        "name": loc.name,
        "description": loc.description,
        "is_active": bool(loc.is_active),
        "created_at": loc.created_at.isoformat() if loc.created_at else None
    } for loc in locations]

# Add new location (managers only)
@router.post("/locations")
def add_location(
    request: LocationCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add a new location - MANAGERS ONLY"""
    
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can add locations"
        )
    
    # Check if location already exists
    existing = db.query(models.Location).filter(
        models.Location.name == request.name.strip()
    ).first()
    
    if existing:
        # If it exists but is inactive, reactivate it
        if existing.is_active == 0:
            existing.is_active = 1
            existing.description = request.description
            existing.updated_at = datetime.now()
            db.commit()
            db.refresh(existing)
            return {
                "id": existing.id,
                "name": existing.name,
                "description": existing.description,
                "is_active": bool(existing.is_active),
                "message": "Location reactivated"
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Location already exists"
            )
    
    # Create new location
    new_location = models.Location(
        name=request.name.strip(),
        description=request.description,
        is_active=1
    )
    
    db.add(new_location)
    db.commit()
    db.refresh(new_location)
    
    return {
        "id": new_location.id,
        "name": new_location.name,
        "description": new_location.description,
        "is_active": bool(new_location.is_active),
        "message": "Location added successfully"
    }

# Update location (managers only)
@router.put("/locations/{location_id}")
def update_location(
    location_id: int,
    request: LocationUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update location - MANAGERS ONLY"""
    
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can update locations"
        )
    
    location = db.query(models.Location).filter(
        models.Location.id == location_id
    ).first()
    
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")
    
    if request.name is not None:
        location.name = request.name.strip()
    if request.description is not None:
        location.description = request.description
    if request.is_active is not None:
        location.is_active = 1 if request.is_active else 0
    
    location.updated_at = datetime.now()
    db.commit()
    db.refresh(location)
    
    return {
        "id": location.id,
        "name": location.name,
        "description": location.description,
        "is_active": bool(location.is_active),
        "message": "Location updated successfully"
    }

# Delete/deactivate location (managers only)
@router.delete("/locations/{location_id}")
def delete_location(
    location_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Deactivate location - MANAGERS ONLY"""
    
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can delete locations"
        )
    
    location = db.query(models.Location).filter(
        models.Location.id == location_id
    ).first()
    
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")
    
    # Soft delete by setting is_active to 0
    location.is_active = 0
    location.updated_at = datetime.now()
    db.commit()
    
    return {"message": "Location deactivated successfully"}
