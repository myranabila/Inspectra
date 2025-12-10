def ensure_pdf_for_inspection(inspection):
    """Ensure the inspection has a PDF report. If not, assign a sample PDF based on status."""
    if not inspection.pdf_report_path or not os.path.exists(inspection.pdf_report_path):
        status = inspection.status.value
        sample_map = {
            'scheduled': 'reports/sample_pdfs/sample_scheduled.pdf',
            'pending_review': 'reports/sample_pdfs/sample_pending_review.pdf',
            'completed': 'reports/sample_pdfs/sample_completed.pdf',
            'rejected': 'reports/sample_pdfs/sample_rejected.pdf',
        }
        sample_pdf = sample_map.get(status)
        if sample_pdf and os.path.exists(sample_pdf):
            inspection.pdf_report_path = sample_pdf
    return inspection
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from datetime import datetime, date, timedelta
from db import get_db
from auth import get_current_user
import models
import os
import shutil
from pathlib import Path

router = APIRouter()

# INSPECTOR: Get my assigned tasks
@router.get("/my-tasks")
def get_my_tasks(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all tasks assigned to current inspector"""
    
    if current_user.role != models.RoleEnum.inspector:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only inspectors can access this endpoint"
        )
    
    # Get all inspections assigned to this inspector
    inspections = db.query(models.Inspection).filter(
        models.Inspection.inspector_id == current_user.id
    ).order_by(
        models.Inspection.scheduled_date.desc(),
        models.Inspection.created_at.desc()
    ).all()
    
    return [{
        "id": insp.id,
        "title": insp.title,
        "location": insp.location,
        "equipment_id": insp.equipment_id,
        "equipment_type": insp.equipment_type,
        "status": insp.status.value,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "rejection_reason": insp.rejection_reason,
        "rejection_feedback": insp.rejection_feedback,
        "rejection_count": insp.rejection_count,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

@router.get("/history")
def get_inspection_history(
    month: int = None,
    year: int = None,
    status: str = None,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get inspection history with optional filters for month, year, and status"""
    
    if current_user.role != models.RoleEnum.inspector:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only inspectors can access this endpoint"
        )
    
    # Start with base query for this inspector
    query = db.query(models.Inspection).filter(
        models.Inspection.inspector_id == current_user.id
    )
    
    # Apply month filter (filter by scheduled_date month)
    if month is not None:
        query = query.filter(extract('month', models.Inspection.scheduled_date) == month)
    
    # Apply year filter (filter by scheduled_date year)
    if year is not None:
        query = query.filter(extract('year', models.Inspection.scheduled_date) == year)
    
    # Apply status filter
    if status and status.lower() != 'all':
        try:
            status_enum = models.InspectionStatusEnum[status]
            query = query.filter(models.Inspection.status == status_enum)
        except KeyError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid status: {status}"
            )
    
    # Get all matching inspections
    inspections = query.order_by(
        models.Inspection.scheduled_date.desc(),
        models.Inspection.created_at.desc()
    ).all()
    
    # Get total count
    total_count = len(inspections)
    
    # Format response
    result = [{
        "id": insp.id,
        "title": insp.title,
        "location": insp.location,
        "equipment_id": insp.equipment_id,
        "equipment_type": insp.equipment_type,
        "status": insp.status.value,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "rejection_reason": insp.rejection_reason,
        "rejection_feedback": insp.rejection_feedback,
        "rejection_count": insp.rejection_count,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]
    
    return {
        "total_count": total_count,
        "inspections": result
    }

def get_start_date_from_period(period: str) -> date | None:
    """Calculate the start date based on the period string."""
    today = date.today()
    if period == "day":
        return today
    elif period == "week":
        return today - timedelta(days=today.weekday())
    elif period == "month":
        return today.replace(day=1)
    elif period == "year":
        return today.replace(month=1, day=1)
    return None # "all"

@router.get("/stats")
def get_dashboard_stats(
    period: str = "all", # "all", "year", "month", "week", "day"
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get dashboard statistics based on a time period."""

    start_date = get_start_date_from_period(period)

    # Base query for inspections, filtered by role
    query = db.query(models.Inspection)
    if current_user.role == models.RoleEnum.inspector:
        query = query.filter(models.Inspection.inspector_id == current_user.id)

    # 1. Total Inspections (Created in period)
    total_query = query
    if start_date:
        total_query = total_query.filter(models.Inspection.created_at >= start_date)
    total_inspections = total_query.count()

    # 2. Completed (Completed in period)
    completed_query = query.filter(models.Inspection.status == models.InspectionStatusEnum.completed)
    if start_date:
        completed_query = completed_query.filter(models.Inspection.completion_date >= start_date)
    completed = completed_query.count()

    # 3. Scheduled (Scheduled in period)
    scheduled_query = query.filter(models.Inspection.status == models.InspectionStatusEnum.scheduled)
    if start_date:
        scheduled_query = scheduled_query.filter(models.Inspection.scheduled_date >= start_date)
    scheduled = scheduled_query.count()

    # 4. Pending Review (Created in period)
    pending_query = query.filter(models.Inspection.status == models.InspectionStatusEnum.pending_review)
    if start_date:
        pending_query = pending_query.filter(models.Inspection.created_at >= start_date)
    pending_review = pending_query.count()

    # 5. Reports Generated (Same as completed)
    reports_generated = completed

    return {
        "total_inspections": total_inspections,
        "reports_generated": reports_generated,
        "pending_review": pending_review,
        "completed": completed,
        "scheduled": scheduled,
        "filter_period": period,
    }

@router.get("/inspections/recent")
def get_recent_inspections(
    limit: int = 5,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get recent inspections - filtered by role"""
    
    # Role-based filtering
    if current_user.role == models.RoleEnum.inspector:
        # Inspectors only see their own COMPLETED inspections
        inspections = db.query(models.Inspection)\
            .filter(
                models.Inspection.inspector_id == current_user.id,
                models.Inspection.status == models.InspectionStatusEnum.completed
            )\
            .order_by(models.Inspection.completion_date.desc())\
            .limit(limit)\
            .all()
    else:
        # Managers see all inspections
        inspections = db.query(models.Inspection)\
            .order_by(models.Inspection.created_at.desc())\
            .limit(limit)\
            .all()
    
    return [{
        "id": insp.id,
        "title": insp.title,
        "status": insp.status.value,
        "location": insp.location,
        "equipment_id": insp.equipment_id,
        "equipment_type": insp.equipment_type,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "inspector": insp.inspector.username if insp.inspector else "Unassigned",
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

@router.get("/reports/recent")
def get_recent_reports(
    limit: int = 5,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get recent reports - filtered by role"""
    
    # Role-based filtering
    if current_user.role == models.RoleEnum.inspector:
        # Inspectors only see their own APPROVED reports
        reports = db.query(models.Report)\
            .filter(
                models.Report.created_by == current_user.id,
                models.Report.status == models.ReportStatusEnum.approved
            )\
            .order_by(models.Report.created_at.desc())\
            .limit(limit)\
            .all()
    else:
        # Managers see all reports
        reports = db.query(models.Report)\
            .order_by(models.Report.created_at.desc())\
            .limit(limit)\
            .all()
    
    return [{
        "id": report.id,
        "title": report.title,
        "status": report.status.value,
        "inspection": report.inspection.title if report.inspection else "N/A",
        "created_by": report.created_by_user.username if report.created_by_user else "Unknown",
        "created_at": report.created_at.isoformat()
    } for report in reports]

@router.get("/inspections/all")
def get_all_inspections(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all inspections - role-based filtering"""
    
    # Role-based filtering
    if current_user.role == models.RoleEnum.inspector:
        # Inspectors see only their own inspections
        inspections = db.query(models.Inspection).filter(
            models.Inspection.inspector_id == current_user.id
        ).order_by(
            models.Inspection.scheduled_date.desc(),
            models.Inspection.created_at.desc()
        ).all()
    else:
        # Managers see all inspections
        inspections = db.query(models.Inspection).order_by(
            models.Inspection.scheduled_date.desc(),
            models.Inspection.created_at.desc()
        ).all()
    
    return [{
        "id": insp.id,
        "title": insp.title,
        "location": insp.location,
        "status": insp.status.value,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

@router.get("/inspections/completed")
def get_completed_inspections(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get completed inspections (Reports Generated) - role-based filtering"""
    
    # Role-based filtering
    if current_user.role == models.RoleEnum.inspector:
        # Inspectors see only their own completed inspections
        inspections = db.query(models.Inspection).filter(
            models.Inspection.inspector_id == current_user.id,
            models.Inspection.status == models.InspectionStatusEnum.completed
        ).order_by(
            models.Inspection.completion_date.desc()
        ).all()
    else:
        # Managers see all completed inspections
        inspections = db.query(models.Inspection).filter(
            models.Inspection.status == models.InspectionStatusEnum.completed
        ).order_by(
            models.Inspection.completion_date.desc()
        ).all()
    
    return [{
        "id": insp.id,
        "title": insp.title,
        "location": insp.location,
        "status": insp.status.value,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

@router.get("/inspections/pending-review")
def get_pending_review_inspections(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get pending review inspections - role-based filtering"""
    
    # Role-based filtering
    if current_user.role == models.RoleEnum.inspector:
        # Inspectors see only their own pending review inspections
        inspections = db.query(models.Inspection).filter(
            models.Inspection.inspector_id == current_user.id,
            models.Inspection.status == models.InspectionStatusEnum.pending_review
        ).order_by(
            models.Inspection.created_at.desc()
        ).all()
    else:
        # Managers see all pending review inspections
        inspections = db.query(models.Inspection).filter(
            models.Inspection.status == models.InspectionStatusEnum.pending_review
        ).order_by(
            models.Inspection.created_at.desc()
        ).all()
    
    return [{
        "id": insp.id,
        "title": insp.title,
        "location": insp.location,
        "status": insp.status.value,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

@router.get("/inspections/completed-this-month")
def get_completed_this_month(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get inspections completed this month - role-based filtering"""
    
    now = datetime.now()
    current_month = now.month
    current_year = now.year
    
    # Role-based filtering
    if current_user.role == models.RoleEnum.inspector:
        # Inspectors see only their own completed inspections this month
        inspections = db.query(models.Inspection).filter(
            models.Inspection.inspector_id == current_user.id,
            models.Inspection.status == models.InspectionStatusEnum.completed,
            extract('month', models.Inspection.completion_date) == current_month,
            extract('year', models.Inspection.completion_date) == current_year
        ).order_by(
            models.Inspection.completion_date.desc()
        ).all()
    else:
        # Managers see all completed inspections this month
        inspections = db.query(models.Inspection).filter(
            models.Inspection.status == models.InspectionStatusEnum.completed,
            extract('month', models.Inspection.completion_date) == current_month,
            extract('year', models.Inspection.completion_date) == current_year
        ).order_by(
            models.Inspection.completion_date.desc()
        ).all()
    
    return [{
        "id": insp.id,
        "title": insp.title,
        "location": insp.location,
        "status": insp.status.value,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

@router.post("/inspections/{inspection_id}/submit")
async def submit_inspection_report(
    inspection_id: int,
    findings: str,
    recommendations: str,
    notes: str = None,
    pdf_file: UploadFile = File(None),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Submit inspection report for manager review with optional PDF"""
    
    if current_user.role != models.RoleEnum.inspector:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only inspectors can submit reports"
        )
    
    # Get the inspection
    inspection = db.query(models.Inspection).filter(
        models.Inspection.id == inspection_id,
        models.Inspection.inspector_id == current_user.id
    ).first()
    
    if not inspection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inspection not found or not assigned to you"
        )
    
    # Save PDF file if provided
    pdf_path = None
    if pdf_file:
        # Create reports directory if it doesn't exist
        reports_dir = Path("reports")
        reports_dir.mkdir(exist_ok=True)
        
        # Generate unique filename
        filename = f"inspection_{inspection_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        file_path = reports_dir / filename
        
        # Save the file
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(pdf_file.file, buffer)
        
        pdf_path = str(file_path)
    
    # Update inspection with report data and status
    inspection.report_findings = findings
    inspection.report_recommendations = recommendations
    if notes:
        inspection.notes = notes
    if pdf_path:
        inspection.pdf_report_path = pdf_path
    inspection.status = models.InspectionStatusEnum.pending_review
    inspection.completion_date = date.today()
    
    try:
        db.commit()
        db.refresh(inspection)
        
        return {
            "message": "Inspection report submitted successfully",
            "inspection_id": inspection.id,
            "status": inspection.status.value,
            "pdf_path": pdf_path
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to submit inspection: {str(e)}"
        )

@router.get("/inspections/{inspection_id}/pdf")
def get_inspection_pdf(
    inspection_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Download PDF report for an inspection. Ensures a sample PDF exists if missing."""
    inspection = db.query(models.Inspection).filter(
        models.Inspection.id == inspection_id
    ).first()
    if not inspection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inspection not found"
        )
    inspection = ensure_pdf_for_inspection(inspection)
    db.commit()
    if not inspection.pdf_report_path or not os.path.exists(inspection.pdf_report_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="PDF report not found for this inspection"
        )
    return FileResponse(
        path=inspection.pdf_report_path,
        media_type="application/pdf",
        filename=f"inspection_{inspection_id}_report.pdf"
    )

@router.get("/inspections/scheduled")
def get_scheduled(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get scheduled inspections - role-based filtering"""
    
    # Role-based filtering
    if current_user.role == models.RoleEnum.inspector:
        # Inspectors see only their own in-progress/scheduled inspections
        inspections = db.query(models.Inspection).filter(
            models.Inspection.inspector_id == current_user.id,
            models.Inspection.status == models.InspectionStatusEnum.scheduled
        ).order_by(
            models.Inspection.scheduled_date.asc()
        ).all()
    else:
        # Managers see all in-progress/scheduled inspections
        inspections = db.query(models.Inspection).filter(
            models.Inspection.status == models.InspectionStatusEnum.scheduled
        ).order_by(
            models.Inspection.scheduled_date.asc()
        ).all()
    
    return [{
        "id": insp.id,
        "title": insp.title,
        "location": insp.location,
        "status": insp.status.value,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]
