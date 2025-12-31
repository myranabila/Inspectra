"""
Updated Manager API Endpoints for Role-Based System
Add this to backend/manager.py
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel, validator
from db import get_db
from models import Inspection, User, RoleEnum, InspectionStatusEnum
from models import generate_inspection_id, generate_report_number, validate_equipment_tag
from auth import get_current_user
from datetime import date

router = APIRouter()


# Pydantic Schemas for Request/Response
class TaskAssignmentRequest(BaseModel):
    """Manager assigns inspection task - ONLY manager fields"""
    title: str
    equipment_type: str  # Reactor, Pressure Vessel, Heat Exchanger, Storage Tank, Tower
    equipment_tag: str  # R001, P001, H001, T001, TW001
    area: str  # Plant 1, Plant 2, Utility Area, Offsite Area, Process Area
    require_external: bool = True
    require_weld: bool = False
    require_internal: bool = False
    require_thickness: bool = False
    inspector_id: int
    due_date: str  # YYYY-MM-DD
    
    @validator('equipment_type')
    def validate_equipment_type(cls, v):
        allowed = ["Reactor", "Pressure Vessel", "Heat Exchanger", "Storage Tank", "Tower"]
        if v not in allowed:
            raise ValueError(f"Equipment type must be one of: {', '.join(allowed)}")
        return v
    
    @validator('area')
    def validate_area(cls, v):
        allowed = ["Plant 1", "Plant 2", "Utility Area", "Offsite Area", "Process Area"]
        if v not in allowed:
            raise ValueError(f"Area must be one of: {', '.join(allowed)}")
        return v
    
    @validator('equipment_tag')
    def validate_tag_format(cls, v, values):
        if 'equipment_type' in values:
            is_valid, error_msg = validate_equipment_tag(values['equipment_type'], v)
            if not is_valid:
                raise ValueError(error_msg)
        return v.upper()  # Normalize to uppercase


class TaskAssignmentResponse(BaseModel):
    """Response after creating task"""
    id: int
    inspection_id_display: str  # Auto-generated
    report_number: str  # Auto-generated
    title: str
    equipment_type: str
    equipment_tag: str
    area: str
    require_external: bool
    require_weld: bool
    require_internal: bool
    require_thickness: bool
    inspector_id: int
    inspector_name: str
    due_date: str
    status: str
    created_at: str
    
    class Config:
        orm_mode = True


@router.post("/assign-task", response_model=TaskAssignmentResponse)
async def assign_inspection_task(
    task: TaskAssignmentRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Manager assigns new inspection task
    - Auto-generates Inspection ID and Report Number
    - Validates equipment tag format
    - Only accepts manager-specific fields
    """
    
    # Role check - only managers can assign tasks
    if current_user.role != RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can assign inspection tasks"
        )
    
    # Verify inspector exists and has inspector role
    inspector = db.query(User).filter(
        User.id == task.inspector_id,
        User.role == RoleEnum.inspector,
        User.is_active == 1
    ).first()
    
    if not inspector:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid inspector ID or inspector not active"
        )
    
    # Ensure at least one section is required
    if not any([task.require_external, task.require_weld, task.require_internal, task.require_thickness]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one inspection section must be required"
        )
    
    # Auto-generate IDs
    inspection_id_display = generate_inspection_id(db)
    report_number = generate_report_number(db)
    
    # Create inspection
    new_inspection = Inspection(
        # Auto-generated fields
        inspection_id_display=inspection_id_display,
        report_number=report_number,
        
        # Manager input fields
        title=task.title,
        equipment_type=task.equipment_type,
        equipment_id=task.equipment_tag,  # Using equipment_id column for tag
        area=task.area,
        require_external=task.require_external,
        require_weld=task.require_weld,
        require_internal=task.require_internal,
        require_thickness=task.require_thickness,
        inspector_id=task.inspector_id,
        scheduled_date=date.fromisoformat(task.due_date),
        
        # Status
        status=InspectionStatusEnum.scheduled
    )
    
    db.add(new_inspection)
    db.commit()
    db.refresh(new_inspection)
    
    # Prepare response
    return TaskAssignmentResponse(
        id=new_inspection.id,
        inspection_id_display=new_inspection.inspection_id_display,
        report_number=new_inspection.report_number,
        title=new_inspection.title,
        equipment_type=new_inspection.equipment_type,
        equipment_tag=new_inspection.equipment_id,
        area=new_inspection.area,
        require_external=new_inspection.require_external,
        require_weld=new_inspection.require_weld,
        require_internal=new_inspection.require_internal,
        require_thickness=new_inspection.require_thickness,
        inspector_id=new_inspection.inspector_id,
        inspector_name=inspector.username,
        due_date=str(new_inspection.scheduled_date),
        status=new_inspection.status.value,
        created_at=str(new_inspection.created_at)
    )


@router.get("/equipment-types")
async def get_equipment_types(current_user: User = Depends(get_current_user)):
    """Get list of valid equipment types for dropdown"""
    return {
        "equipment_types": [
            "Reactor",
            "Pressure Vessel",
            "Heat Exchanger",
            "Storage Tank",
            "Tower"
        ]
    }


@router.get("/areas")
async def get_areas(current_user: User = Depends(get_current_user)):
    """Get list of valid areas for dropdown"""
    return {
        "areas": [
            "Plant 1",
            "Plant 2",
            "Utility Area",
            "Offsite Area",
            "Process Area"
        ]
    }


@router.get("/inspectors")
async def get_active_inspectors(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get list of active inspectors for dropdown"""
    
    # Only managers can access this
    if current_user.role != RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can view inspector list"
        )
    
    inspectors = db.query(User).filter(
        User.role == RoleEnum.inspector,
        User.is_active == 1
    ).all()
    
    return {
        "inspectors": [
            {
                "id": i.id,
                "name": i.username,
                "staff_id": i.staff_id,
                "email": i.email,
                "years_experience": i.years_experience
            }
            for i in inspectors
        ]
    }


# Example validation endpoint
@router.post("/validate-equipment-tag")
async def validate_tag(
    equipment_type: str,
    equipment_tag: str,
    current_user: User = Depends(get_current_user)
):
    """Validate equipment tag format - for real-time validation in UI"""
    is_valid, error_msg = validate_equipment_tag(equipment_type, equipment_tag.upper())
    
    return {
        "valid": is_valid,
        "error": error_msg if not is_valid else None,
        "normalized_tag": equipment_tag.upper()
    }
