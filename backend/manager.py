from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, date
import models
from db import get_db
from auth import get_current_user
from pydantic import BaseModel

router = APIRouter()

# Request models
class AssignTaskRequest(BaseModel):
    inspector_id: int
    title: str
    location: str
    scheduled_date: str = None
    notes: str = None

class ApproveInspectionRequest(BaseModel):
    inspection_id: int
    action: str  # "approve" or "reject"
    notes: str = None

class ApproveReportRequest(BaseModel):
    report_id: int
    action: str  # "approve" or "reject"
    notes: str = None

# MANAGER-ONLY: Assign task to inspector
@router.post("/assign-task")
def assign_task(
    request: AssignTaskRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Assign inspection task to an inspector - MANAGERS ONLY"""
    
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can assign tasks"
        )
    
    # Verify inspector exists
    inspector = db.query(models.User).filter(
        models.User.id == request.inspector_id,
        models.User.role == models.RoleEnum.inspector
    ).first()
    
    if not inspector:
        raise HTTPException(status_code=404, detail="Inspector not found")
    
    # Parse scheduled date
    scheduled_date_obj = None
    if request.scheduled_date:
        try:
            scheduled_date_obj = datetime.fromisoformat(request.scheduled_date.replace('Z', '+00:00')).date()
        except:
            scheduled_date_obj = datetime.strptime(request.scheduled_date, '%Y-%m-%d').date()
    
    # Create inspection
    new_inspection = models.Inspection(
        title=request.title,
        location=request.location,
        inspector_id=request.inspector_id,
        status=models.InspectionStatusEnum.scheduled,
        scheduled_date=scheduled_date_obj,
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
        "inspector": inspector.full_name,
        "status": new_inspection.status.value
    }

# MANAGER-ONLY: Get all inspections (for viewing and approval)
@router.get("/inspections")
def get_all_inspections(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all inspections - MANAGERS ONLY"""
    
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can access inspections"
        )
    
    inspections = db.query(models.Inspection).order_by(
        models.Inspection.created_at.desc()
    ).all()
    
    return [{
        "id": insp.id,
        "title": insp.title,
        "location": insp.location,
        "status": insp.status.value,
        "inspector": insp.inspector.full_name if insp.inspector else "Unassigned",
        "inspector_id": insp.inspector_id,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

# MANAGER-ONLY: Get all pending inspections for approval
@router.get("/pending/inspections")
def get_pending_inspections(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all inspections pending approval - MANAGERS ONLY"""
    
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can access pending approvals"
        )
    
    inspections = db.query(models.Inspection).filter(
        models.Inspection.status == models.InspectionStatusEnum.pending_review
    ).order_by(models.Inspection.created_at.desc()).all()
    
    return [{
        "id": insp.id,
        "title": insp.title,
        "location": insp.location,
        "status": insp.status.value,
        "inspector": insp.inspector.full_name if insp.inspector else "Unassigned",
        "inspector_id": insp.inspector_id,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

# MANAGER-ONLY: Get all pending reports for approval
@router.get("/pending/reports")
def get_pending_reports(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all reports pending approval - MANAGERS ONLY"""
    
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can access pending approvals"
        )
    
    reports = db.query(models.Report).filter(
        models.Report.status == models.ReportStatusEnum.pending_review
    ).order_by(models.Report.created_at.desc()).all()
    
    return [{
        "id": report.id,
        "title": report.title,
        "status": report.status.value,
        "inspection": report.inspection.title if report.inspection else "N/A",
        "inspection_id": report.inspection_id,
        "created_by": report.created_by_user.full_name if report.created_by_user else "Unknown",
        "created_by_id": report.created_by,
        "content": report.content,
        "findings": report.findings,
        "recommendations": report.recommendations,
        "created_at": report.created_at.isoformat()
    } for report in reports]

# MANAGER-ONLY: Approve or reject inspection
@router.post("/approve/inspection")
def approve_inspection(
    request: ApproveInspectionRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Approve or reject an inspection - MANAGERS ONLY"""
    
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can approve inspections"
        )
    
    inspection = db.query(models.Inspection).filter(
        models.Inspection.id == request.inspection_id
    ).first()
    
    if not inspection:
        raise HTTPException(status_code=404, detail="Inspection not found")
    
    if request.action == "approve":
        inspection.status = models.InspectionStatusEnum.completed
        inspection.completion_date = datetime.now().date()
        if request.notes:
            inspection.notes = (inspection.notes or "") + f"\n[Manager Approved: {request.notes}]"
        message = "Inspection approved successfully"
    elif request.action == "reject":
        inspection.status = models.InspectionStatusEnum.in_progress
        if request.notes:
            inspection.notes = (inspection.notes or "") + f"\n[Manager Rejected: {request.notes}]"
        message = "Inspection rejected and returned to in-progress"
    else:
        raise HTTPException(status_code=400, detail="Invalid action. Use 'approve' or 'reject'")
    
    inspection.updated_at = datetime.now()
    db.commit()
    
    return {
        "message": message,
        "inspection_id": inspection.id,
        "new_status": inspection.status.value
    }

# MANAGER-ONLY: Approve or reject report
@router.post("/approve/report")
def approve_report(
    request: ApproveReportRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Approve or reject a report - MANAGERS ONLY"""
    
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can approve reports"
        )
    
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
@router.get("/inspectors")
def get_inspectors(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get list of all inspectors - MANAGERS ONLY"""
    
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can view inspector list"
        )
    
    inspectors = db.query(models.User).filter(
        models.User.role == models.RoleEnum.inspector
    ).all()
    
    return [{
        "id": insp.id,
        "username": insp.username,
        "full_name": insp.full_name,
        "email": insp.email,
        "phone": insp.phone
    } for insp in inspectors]

# MANAGER-ONLY: Get inspector statistics
@router.get("/inspector/{inspector_id}/stats")
def get_inspector_stats(
    inspector_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get statistics for a specific inspector - MANAGERS ONLY"""
    
    if current_user.role != models.RoleEnum.manager:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only managers can view inspector statistics"
        )
    
    inspector = db.query(models.User).filter(
        models.User.id == inspector_id,
        models.User.role == models.RoleEnum.inspector
    ).first()
    
    if not inspector:
        raise HTTPException(status_code=404, detail="Inspector not found")
    
    total_inspections = db.query(models.Inspection).filter(
        models.Inspection.inspector_id == inspector_id
    ).count()
    
    completed = db.query(models.Inspection).filter(
        models.Inspection.inspector_id == inspector_id,
        models.Inspection.status == models.InspectionStatusEnum.completed
    ).count()
    
    pending = db.query(models.Inspection).filter(
        models.Inspection.inspector_id == inspector_id,
        models.Inspection.status == models.InspectionStatusEnum.pending_review
    ).count()
    
    total_reports = db.query(models.Report).filter(
        models.Report.created_by == inspector_id
    ).count()
    
    approved_reports = db.query(models.Report).filter(
        models.Report.created_by == inspector_id,
        models.Report.status == models.ReportStatusEnum.approved
    ).count()
    
    return {
        "inspector_id": inspector_id,
        "inspector_name": inspector.full_name,
        "total_inspections": total_inspections,
        "completed_inspections": completed,
        "pending_inspections": pending,
        "total_reports": total_reports,
        "approved_reports": approved_reports,
        "approval_rate": round((approved_reports / total_reports * 100) if total_reports > 0 else 0, 1)
    }
