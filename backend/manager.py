from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, date, timedelta
from typing import List, Optional
from db import get_db
from auth import get_current_user
from pydantic import BaseModel
import models

router = APIRouter()

# Request models
class AssignTaskRequest(BaseModel):
    inspector_id: int
    title: str = None  # Manager-defined inspection title
    inspection_type: str
    location: str
    equipment_tag: str
    due_date: str
    require_external: bool = True
    require_weld: bool = False
    require_internal: bool = False
    require_thickness: bool = False
    notes: str = None
    initial_conditions: str = None  # Comma-separated list of conditions

class ApproveInspectionRequest(BaseModel):
    inspection_id: int
    action: str  # "approve" or "reject"
    notes: str = None

class ApproveReportRequest(BaseModel):
    report_id: int
    action: str  # "approve" or "reject"
    notes: str = None

class RejectInspectionRequest(BaseModel):
    inspection_id: int
    rejection_reason: str  # Required rejection reason
    rejection_feedback: str = None  # Optional detailed feedback

# ==================== Helper Functions / Dependencies ====================

def require_manager(current_user: models.User = Depends(get_current_user)):
    """Dependency to ensure user is a manager"""
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can access this endpoint"
        )
    return current_user

def get_start_date_from_period(period: str) -> date | None:
    """Calculate the start date based on the period string."""
    today = date.today()
    if period == "day":
        return today
    elif period == "week":
        # Start of the current week (Monday)
        return today - timedelta(days=today.weekday())
    elif period == "month":
        return today.replace(day=1)
    elif period == "year":
        return today.replace(month=1, day=1)
    # "all" or any other value returns None, resulting in no date filter
    return None

# MANAGER-ONLY: Assign task to inspector
@router.post("/assign-task", dependencies=[Depends(require_manager)])
def assign_task(
    request: AssignTaskRequest,
    db: Session = Depends(get_db)
):
    """Assign inspection task to an inspector - MANAGERS ONLY"""
    
    # Import helper functions for ID generation
    from models_helpers import generate_inspection_id, generate_report_number
    
    # Verify inspector exists
    inspector = db.query(models.User).filter(
        models.User.id == request.inspector_id,
        models.User.role == models.RoleEnum.inspector
    ).first()
    
    if not inspector:
        raise HTTPException(status_code=404, detail="Inspector not found")
    
    # Parse scheduled date
    scheduled_date_obj = None
    if request.due_date:
        try:
            scheduled_date_obj = datetime.fromisoformat(request.due_date.replace('Z', '+00:00')).date()
        except:
            scheduled_date_obj = datetime.strptime(request.due_date, '%Y-%m-%d').date()
    
    # AUTO-GENERATE IDs
    inspection_id_display = generate_inspection_id(db)
    report_number_display = generate_report_number(db)
    
    # Create inspection with manager-defined title and auto-generated IDs
    new_inspection = models.Inspection(
        inspection_id_display=inspection_id_display,  # NEW
        report_number=report_number_display,  # NEW
        title=request.title if request.title else request.inspection_type,
        location=request.location,
        area=request.location,  # Also store in area field
        equipment_id=request.equipment_tag,
        equipment_type=request.inspection_type,  # Use actual type from request
        inspector_id=request.inspector_id,
        status=models.InspectionStatusEnum.scheduled,
        scheduled_date=scheduled_date_obj,
        require_external=request.require_external,
        require_weld=request.require_weld,
        require_internal=request.require_internal,
        require_thickness=request.require_thickness,
        notes=request.notes,
        created_at=datetime.now(),
        updated_at=datetime.now()
    )

    
    db.add(new_inspection)
    db.commit()
    db.refresh(new_inspection)
    
    return {
        "message": "Task successfully assigned",
        "inspection_id": new_inspection.id,
        "inspection_id_display": inspection_id_display,  # NEW
        "report_number": report_number_display,  # NEW
        "inspector": inspector.username,
        "status": new_inspection.status.value
    }

# MANAGER-ONLY: Get all inspections (for viewing and approval)
@router.get("/inspections", dependencies=[Depends(require_manager)])
def get_all_inspections(
    db: Session = Depends(get_db)
):
    """Get all inspections - MANAGERS ONLY"""
    inspections = db.query(models.Inspection).order_by(
        models.Inspection.created_at.desc()
    ).all()
    
    return [{
        "id": insp.id,
        "title": insp.title,
        "location": insp.location,
        "status": insp.status.value,
        "inspector": insp.inspector.username if insp.inspector else "Unassigned",
        "inspector_id": insp.inspector_id,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

# MANAGER-ONLY: Get all pending inspections for approval
@router.get("/pending/inspections", dependencies=[Depends(require_manager)])
def get_pending_inspections(
    db: Session = Depends(get_db)
):
    """Get all inspections pending approval - MANAGERS ONLY"""
    inspections = db.query(models.Inspection).filter(
        models.Inspection.status == models.InspectionStatusEnum.pending_review
    ).order_by(models.Inspection.created_at.desc()).all()
    
    return [{
        "id": insp.id,
        "inspection_id_display": insp.inspection_id_display,  # For Edit Dialog
        "title": insp.title,
        "location": insp.location,
        "equipment_tag": insp.equipment_id,  # For Edit Dialog
        "inspection_type": insp.equipment_type,  # For Edit Dialog
        "status": insp.status.value,
        "inspector": insp.inspector.username if insp.inspector else "Unassigned",
        "inspector_id": insp.inspector_id,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "report_findings": insp.report_findings,
        "report_recommendations": insp.report_recommendations,
        "pdf_report_path": insp.pdf_report_path,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

# MANAGER-ONLY: Get all pending reports for approval
@router.get("/pending/reports", dependencies=[Depends(require_manager)])
def get_pending_reports(
    db: Session = Depends(get_db)
):
    """Get all reports pending approval - MANAGERS ONLY"""
    reports = db.query(models.Report).filter(
        models.Report.status == models.ReportStatusEnum.pending_review
    ).order_by(models.Report.created_at.desc()).all()
    
    return [{
        "id": report.id,
        "title": report.title,
        "status": report.status.value,
        "inspection": report.inspection.title if report.inspection else "N/A",
        "inspection_id": report.inspection_id,
        "created_by": report.created_by_user.username if report.created_by_user else "Unknown",
        "created_by_id": report.created_by,
        "content": report.content,
        "findings": report.findings,
        "recommendations": report.recommendations,
        "created_at": report.created_at.isoformat()
    } for report in reports]

# Pydantic model for approve request via query params AND body
class ApproveInspectionBodyRequest(BaseModel):
    notes: Optional[str] = None

# MANAGER-ONLY: Approve inspection
@router.post("/approve/inspection", dependencies=[Depends(require_manager)])
def approve_inspection(
    inspection_id: int,  # Query param
    request: ApproveInspectionBodyRequest = None,  # Optional body
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Approve an inspection and mark as completed - MANAGERS ONLY"""
    inspection = db.query(models.Inspection).filter(
        models.Inspection.id == inspection_id
    ).first()
    
    if not inspection:
        raise HTTPException(status_code=404, detail="Inspection not found")
    
    if inspection.status != models.InspectionStatusEnum.pending_review:
        raise HTTPException(
            status_code=400,
            detail="Only inspections pending review can be approved"
        )
    
    # Approve the inspection
    inspection.status = models.InspectionStatusEnum.completed
    if not inspection.completion_date:
        inspection.completion_date = date.today()
    
    # Add manager notes if provided (from body)
    notes = request.notes if request else None
    if notes:
        approval_note = f"\n[Manager Approved by {current_user.username} on {date.today().isoformat()}]: {notes}"
        inspection.notes = (inspection.notes or "") + approval_note
    
    inspection.updated_at = datetime.now()
    
    try:
        db.commit()
        db.refresh(inspection)
        
        return {
            "message": "Inspection approved successfully",
            "inspection_id": inspection.id,
            "status": inspection.status.value,
            "completion_date": inspection.completion_date.isoformat() if inspection.completion_date else None
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to approve inspection: {str(e)}"
        )

# Pydantic model for reject request body
class RejectInspectionBodyRequest(BaseModel):
    rejection_reason: str
    rejection_feedback: Optional[str] = None

# MANAGER-ONLY: Reject inspection and require revision
@router.post("/reject/inspection", dependencies=[Depends(require_manager)])
def reject_inspection(
    inspection_id: int,  # Query param
    request: RejectInspectionBodyRequest,  # Body params
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Reject an inspection and send back for revision - MANAGERS ONLY"""
    inspection = db.query(models.Inspection).filter(
        models.Inspection.id == inspection_id
    ).first()
    
    if not inspection:
        raise HTTPException(status_code=404, detail="Inspection not found")
    
    if inspection.status != models.InspectionStatusEnum.pending_review:
        raise HTTPException(
            status_code=400, 
            detail="Only inspections pending review can be rejected"
        )
    
    # Update inspection with rejection details (from body)
    rejection_reason = request.rejection_reason
    rejection_feedback = request.rejection_feedback
    
    inspection.status = models.InspectionStatusEnum.rejected
    inspection.rejection_reason = rejection_reason
    inspection.rejection_feedback = rejection_feedback
    inspection.rejection_count = (inspection.rejection_count or 0) + 1
    inspection.last_rejected_at = datetime.now()
    inspection.updated_at = datetime.now()
    
    # Add rejection note to inspection notes
    rejection_note = f"\n[REJECTED by {current_user.username} on {date.today().isoformat()}]\nReason: {rejection_reason}"
    if rejection_feedback:
        rejection_note += f"\nFeedback: {rejection_feedback}"
    inspection.notes = (inspection.notes or "") + rejection_note
    
    try:
        db.commit()
        db.refresh(inspection)
        
        return {
            "message": "Inspection rejected successfully. Inspector will be notified to make revisions.",
            "inspection_id": inspection.id,
            "status": inspection.status.value,
            "rejection_count": inspection.rejection_count,
            "rejection_reason": rejection_reason
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to reject inspection: {str(e)}"
        )

# Pydantic model for reassign request body
class ReassignInspectionRequest(BaseModel):
    inspector_id: int
    notes: Optional[str] = None

# MANAGER-ONLY: Reassign a rejected inspection to same or different inspector
@router.post("/reassign/inspection", dependencies=[Depends(require_manager)])
def reassign_inspection(
    inspection_id: int,  # Query param
    request: ReassignInspectionRequest,  # Body params
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Reassign a rejected inspection to an inspector - MANAGERS ONLY"""
    inspection = db.query(models.Inspection).filter(
        models.Inspection.id == inspection_id
    ).first()
    
    if not inspection:
        raise HTTPException(status_code=404, detail="Inspection not found")
    
    if inspection.status != models.InspectionStatusEnum.rejected:
        raise HTTPException(
            status_code=400, 
            detail="Only rejected inspections can be reassigned"
        )
    
    # Verify new inspector exists
    new_inspector = db.query(models.User).filter(
        models.User.id == request.inspector_id,
        models.User.role == models.RoleEnum.inspector
    ).first()
    
    if not new_inspector:
        raise HTTPException(status_code=404, detail="Inspector not found")
    
    # Store old inspector for logging
    old_inspector_id = inspection.inspector_id
    
    # Update inspection
    inspection.inspector_id = request.inspector_id
    inspection.status = models.InspectionStatusEnum.scheduled  # Reset to scheduled
    inspection.rejection_reason = None  # Clear rejection fields
    inspection.rejection_feedback = None
    inspection.updated_at = datetime.now()
    
    # Add reassignment note
    reassign_note = f"\n[REASSIGNED by {current_user.username} on {date.today().isoformat()}]"
    if old_inspector_id != request.inspector_id:
        reassign_note += f"\nReassigned from inspector ID {old_inspector_id} to {new_inspector.username}"
    else:
        reassign_note += f"\nReassigned back to {new_inspector.username} for revision"
    if request.notes:
        reassign_note += f"\nNotes: {request.notes}"
    inspection.notes = (inspection.notes or "") + reassign_note
    
    try:
        db.commit()
        db.refresh(inspection)
        
        return {
            "message": f"Inspection reassigned to {new_inspector.username}",
            "inspection_id": inspection.id,
            "new_inspector": new_inspector.username,
            "status": inspection.status.value
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to reassign inspection: {str(e)}"
        )


# MANAGER-ONLY: Approve or reject report
@router.post("/approve/report", dependencies=[Depends(require_manager)])
def approve_report(
    request: ApproveReportRequest,
    db: Session = Depends(get_db)
):
    """Approve or reject a report - MANAGERS ONLY"""
    report = db.query(models.Report).filter(
        models.Report.id == request.report_id
    ).first()
    
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    if request.action == "approve":
        report.status = models.ReportStatusEnum.approved
        if request.notes:
            report.content = (report.content or "") + f"\n\n[Manager Notes: {request.notes}]"
        message = "Report approved successfully"
    elif request.action == "reject":
        report.status = models.ReportStatusEnum.draft
        if request.notes:
            report.content = (report.content or "") + f"\n\n[Manager Feedback: {request.notes}]"
        message = "Report rejected and returned to draft"
    else:
        raise HTTPException(status_code=400, detail="Invalid action. Use 'approve' or 'reject'")
    
    report.updated_at = datetime.now()
    db.commit()
    
    return {
        "message": message,
        "report_id": report.id,
        "new_status": report.status.value
    }

# MANAGER-ONLY: Get all inspectors
@router.get("/inspectors", dependencies=[Depends(require_manager)])
def get_inspectors(
    period: str = "all",  # "all", "year", "month", "week", "day"
    db: Session = Depends(get_db)
):
    """Get list of all inspectors with performance metrics - MANAGERS ONLY"""
    start_date = get_start_date_from_period(period)

    inspectors = db.query(models.User).filter(
        models.User.role == models.RoleEnum.inspector
    ).all()
    
    result = []
    for insp in inspectors:
        # Base queries for inspections and reports
        inspection_query = db.query(models.Inspection).filter(
            models.Inspection.inspector_id == insp.id
        )
        report_query = db.query(models.Report).filter(
            models.Report.created_by == insp.id
        )

        # Apply date filter if a period is specified
        if start_date:
            # We filter inspections by scheduled_date and reports by created_at
            inspection_query = inspection_query.filter(models.Inspection.scheduled_date >= start_date)
            report_query = report_query.filter(models.Report.created_at >= start_date)

        # Calculate stats from the filtered queries
        total_tasks = inspection_query.count()
        completed_tasks = inspection_query.filter(models.Inspection.status == models.InspectionStatusEnum.completed).count()
        pending_review = inspection_query.filter(models.Inspection.status == models.InspectionStatusEnum.pending_review).count()
        scheduled = inspection_query.filter(models.Inspection.status == models.InspectionStatusEnum.scheduled).count()
        total_reports = report_query.count()
        approved_reports = report_query.filter(models.Report.status == models.ReportStatusEnum.approved).count()
        
        # Calculate completion rate
        completion_rate = round((completed_tasks / total_tasks * 100) if total_tasks > 0 else 0, 1)
        
        # Calculate approval rate
        approval_rate = round((approved_reports / total_reports * 100) if total_reports > 0 else 0, 1)
        
        result.append({
            "id": insp.id,
            "username": insp.username,
            "name": insp.username,
            "email": insp.email,
            "phone": insp.phone,
            "total_tasks": total_tasks,
            "completed_tasks": completed_tasks,
            "pending_review": pending_review,
            "scheduled": scheduled,
            "total_reports": total_reports,
            "approved_reports": approved_reports,
            "completion_rate": completion_rate,
            "approval_rate": approval_rate
        })
    
    return result

# MANAGER-ONLY: Get inspector statistics
@router.get("/inspector/{inspector_id}/stats", dependencies=[Depends(require_manager)])
def get_inspector_stats(
    inspector_id: int,
    period: str = "all",  # "all", "year", "month", "week", "day"
    db: Session = Depends(get_db)
):
    """Get statistics for a specific inspector - MANAGERS ONLY"""
    start_date = get_start_date_from_period(period)

    inspector = db.query(models.User).filter(
        models.User.id == inspector_id,
        models.User.role == models.RoleEnum.inspector
    ).first()
    
    if not inspector:
        raise HTTPException(status_code=404, detail="Inspector not found")
    
    # Base queries
    inspection_query = db.query(models.Inspection).filter(
        models.Inspection.inspector_id == inspector_id
    )
    report_query = db.query(models.Report).filter(
        models.Report.created_by == inspector_id
    )

    # Apply date filter
    if start_date:
        inspection_query = inspection_query.filter(models.Inspection.scheduled_date >= start_date)
        report_query = report_query.filter(models.Report.created_at >= start_date)

    # Calculate stats from filtered queries
    total_inspections = inspection_query.count()
    completed = inspection_query.filter(models.Inspection.status == models.InspectionStatusEnum.completed).count()
    pending = inspection_query.filter(models.Inspection.status == models.InspectionStatusEnum.pending_review).count()
    total_reports = report_query.count()
    approved_reports = report_query.filter(models.Report.status == models.ReportStatusEnum.approved).count()
    
    return {
        "inspector_id": inspector_id,
        "inspector_name": inspector.username,
        "total_inspections": total_inspections,
        "completed_inspections": completed,
        "pending_inspections": pending,
        "total_reports": total_reports,
        "approved_reports": approved_reports,
        "approval_rate": round((approved_reports / total_reports * 100) if total_reports > 0 else 0, 1)
    }

# Pydantic model for update inspection request
class UpdateInspectionRequest(BaseModel):
    location: str
    inspection_type: str

# Area-Equipment Type validation mapping
AREA_EQUIPMENT_MAP = {
    'Plant 1': ['Reactor', 'Pressure Vessel', 'Heat Exchanger'],
    'Plant 2': ['Storage Tank', 'Tower', 'Pressure Vessel'],
    'Utility Area': ['Heat Exchanger', 'Storage Tank'],
    'Offsite Area': ['Storage Tank', 'Tower'],
    'Process Area': ['Reactor', 'Pressure Vessel', 'Heat Exchanger', 'Tower'],
}

# MANAGER-ONLY: Update inspection details (Area and Equipment Type)
@router.post("/update/inspection", dependencies=[Depends(require_manager)])
def update_inspection(
    inspection_id: int,  # Query param
    request: UpdateInspectionRequest,  # Body params
    db: Session = Depends(get_db)
):
    """Update inspection area and equipment type - MANAGERS ONLY"""
    inspection = db.query(models.Inspection).filter(
        models.Inspection.id == inspection_id
    ).first()
    
    if not inspection:
        raise HTTPException(status_code=404, detail="Inspection not found")
    
    # Validate Area-Equipment Type combination
    valid_equipment_types = AREA_EQUIPMENT_MAP.get(request.location, [])
    if not valid_equipment_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid area: {request.location}"
        )
    
    if request.inspection_type not in valid_equipment_types:
        raise HTTPException(
            status_code=400,
            detail=f"Equipment Type '{request.inspection_type}' is not valid for Area '{request.location}'. Valid types are: {', '.join(valid_equipment_types)}"
        )
    
    # Update inspection
    inspection.location = request.location
    inspection.area = request.location  # Also update area field
    inspection.equipment_type = request.inspection_type
    inspection.updated_at = datetime.now()
    
    try:
        db.commit()
        db.refresh(inspection)
        
        return {
            "message": "Inspection updated successfully",
            "inspection_id": inspection.id,
            "location": inspection.location,
            "equipment_type": inspection.equipment_type
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update inspection: {str(e)}"
        )
