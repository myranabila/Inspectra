from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, date, timedelta
from typing import List
from db import get_db
from auth import get_current_user
from pydantic import BaseModel
import models

router = APIRouter()

# Request models
class AssignTaskRequest(BaseModel):
    inspector_id: int
    title: str
    location: str
    equipment_id: str = None  # Equipment Tag Number
    equipment_type: str = None  # Equipment Type/Description
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
        equipment_id=request.equipment_id,
        equipment_type=request.equipment_type,
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
        "title": insp.title,
        "location": insp.location,
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

# MANAGER-ONLY: Approve inspection
@router.post("/approve/inspection", dependencies=[Depends(require_manager)])
def approve_inspection(
    inspection_id: int,
    notes: str = None,
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
    
    # Add manager notes if provided
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

# MANAGER-ONLY: Reject inspection and require revision
@router.post("/reject/inspection", dependencies=[Depends(require_manager)])
def reject_inspection(
    inspection_id: int,
    rejection_reason: str,
    rejection_feedback: str = None,
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
    
    # Update inspection with rejection details
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
