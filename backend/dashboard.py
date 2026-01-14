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
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from sqlalchemy import func, extract, text  
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
        "report_number": insp.report_number,
        "inspector_name": insp.inspector.username if insp.inspector else "Unassigned",
        "dosh_registration": insp.dosh_registration,
        "notes": insp.notes,
        "rejection_reason": insp.rejection_reason,
        "rejection_feedback": insp.rejection_feedback,
        "rejection_count": insp.rejection_count,
        "require_external": insp.require_external,
        "require_weld": insp.require_weld,
        "require_internal": insp.require_internal,
        "require_thickness": insp.require_thickness,
        "pdf_report_path": insp.pdf_report_path,
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
        "dosh_registration": insp.dosh_registration,
        "pdf_report_path": insp.pdf_report_path,
        "inspector_name": insp.inspector.username if insp.inspector else "Unassigned",
        "notes": insp.notes,
        "rejection_reason": insp.rejection_reason,
        "rejection_feedback": insp.rejection_feedback,
        "rejection_count": insp.rejection_count,
        "require_external": insp.require_external,
        "require_weld": insp.require_weld,
        "require_internal": insp.require_internal,
        "require_thickness": insp.require_thickness,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]
    
    return {
        "total_count": total_count,
        "inspections": result
    }

def get_date_range_from_period(period: str) -> tuple[date | None, date | None]:
    """Calculate the start and end date based on the period string."""
    today = date.today()

    if period in ("day", "today"):
        return today, today
    elif period == "week":
        start = today - timedelta(days=today.weekday())
        end = start + timedelta(days=6)
        return start, end
    elif period == "month":
        start = today.replace(day=1)
        next_month = start.replace(day=28) + timedelta(days=4)
        end = next_month - timedelta(days=next_month.day)
        return start, end
    elif period == "year":
        start = today.replace(month=1, day=1)
        end = today.replace(month=12, day=31)
        return start, end
    return None, None # "all"

@router.get("/stats")
def get_dashboard_stats(
    period: str = "all", # "all", "year", "month", "week", "day"
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get dashboard statistics based on a time period."""

    start_date, end_date = get_date_range_from_period(period)

    # Base query for inspections, filtered by role
    query = db.query(models.Inspection)
    if current_user.role == models.RoleEnum.inspector:
        query = query.filter(models.Inspection.inspector_id == current_user.id)

    def apply_period_filter(q, date_column, is_timestamp=False):
        if start_date:
            q = q.filter(date_column >= start_date)
        if end_date:
            if is_timestamp:
                # For TIMESTAMP, filter < next_day to include the full end_date
                next_day = end_date + timedelta(days=1)
                q = q.filter(date_column < next_day)
            else:
                # For Date, <= end_date is inclusive
                q = q.filter(date_column <= end_date)
        return q

    # 1. Scheduled (Scheduled in period)
    scheduled_query = query.filter(models.Inspection.status == models.InspectionStatusEnum.scheduled)
    scheduled_query = apply_period_filter(scheduled_query, models.Inspection.scheduled_date, is_timestamp=False)
    scheduled = scheduled_query.count()

    # 2. Completed (Completed in period)
    completed_query = query.filter(models.Inspection.status == models.InspectionStatusEnum.completed)
    completed_query = apply_period_filter(completed_query, models.Inspection.completion_date, is_timestamp=False)
    completed = completed_query.count()

    # 3. Pending Review (Submitted in period - use completion_date)
    pending_query = query.filter(models.Inspection.status == models.InspectionStatusEnum.pending_review)
    pending_query = apply_period_filter(pending_query, models.Inspection.completion_date, is_timestamp=False)
    pending_review = pending_query.count()

    # 4. Rejected (Rejected in period - use updated_at as proxy for decision time)
    rejected_query = query.filter(models.Inspection.status == models.InspectionStatusEnum.rejected)
    rejected_query = apply_period_filter(rejected_query, models.Inspection.updated_at, is_timestamp=True)
    rejected = rejected_query.count()

    # 5. Total Inspections (Sum of all active statuses in period)
    total_inspections = scheduled + completed + pending_review + rejected

    # 6. Reports Generated (Same as completed)
    reports_generated = completed

    return {
        "total_inspections": total_inspections,
        "reports_generated": reports_generated,
        "pending_review": pending_review,
        "completed": completed,
        "scheduled": scheduled,
        "rejected": rejected,
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
        "dosh_registration": insp.dosh_registration,
        "report_number": insp.report_number,
        "inspector": insp.inspector.username if insp.inspector else "Unassigned",
        "require_external": insp.require_external,
        "require_weld": insp.require_weld,
        "require_internal": insp.require_internal,
        "require_thickness": insp.require_thickness,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

@router.get("/inspections/{inspection_id}/details")
def get_inspection_details(
    inspection_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get details of a single inspection"""
    
    # Base query
    query = db.query(models.Inspection).filter(models.Inspection.id == inspection_id)
    
    # Role-based access control - RELAXED for Chat Sharing
    # Allow any authenticated user (Inspector or Manager) to view details of any inspection
    # This enables clicking on shared tasks in chat to view the PDF report
    # if current_user.role == models.RoleEnum.inspector:
    #     # Inspector can only see their own inspections
    #     query = query.filter(models.Inspection.inspector_id == current_user.id)
        
    inspection = query.first()
    
    if not inspection:
         raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inspection not found"
        )

        
    return {
        "id": inspection.id,
        "inspection_id_display": inspection.inspection_id_display,  # Added
        "report_number": inspection.report_number,  # Added
        "title": inspection.title,
        "location": inspection.location,
        "equipment_id": inspection.equipment_id,
        "equipment_type": inspection.equipment_type,
        "dosh_registration": inspection.dosh_registration,  # Added
        "status": inspection.status.value,
        "scheduled_date": inspection.scheduled_date.isoformat() if inspection.scheduled_date else None,
        "completion_date": inspection.completion_date.isoformat() if inspection.completion_date else None,
        "pdf_report_path": inspection.pdf_report_path, # Debug: Path verified

        "notes": inspection.notes,
        "inspector_name": inspection.inspector.username if inspection.inspector else None,  # Added
        "inspector_id": inspection.inspector_id,
        "require_external": inspection.require_external,
        "require_weld": inspection.require_weld,
        "require_internal": inspection.require_internal,
        "require_thickness": inspection.require_thickness,
        "created_at": inspection.created_at.isoformat()
    }

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
        "require_external": insp.require_external,
        "require_weld": insp.require_weld,
        "require_internal": insp.require_internal,
        "require_thickness": insp.require_thickness,
        "report_number": insp.report_number,
        "equipment_id": insp.equipment_id,
        "equipment_type": insp.equipment_type,
        "dosh_registration": insp.dosh_registration,
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
        "equipment_id": insp.equipment_id,
        "equipment_type": insp.equipment_type,
        "dosh_registration": insp.dosh_registration,
        "inspector_name": insp.inspector.username if insp.inspector else "Unassigned",
        "status": insp.status.value,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "require_external": insp.require_external,
        "require_weld": insp.require_weld,
        "require_internal": insp.require_internal,
        "require_thickness": insp.require_thickness,
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
        "equipment_id": insp.equipment_id,
        "equipment_type": insp.equipment_type,
        "dosh_registration": insp.dosh_registration,
        "inspector_name": insp.inspector.username if insp.inspector else "Unassigned",
        "status": insp.status.value,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "require_external": insp.require_external,
        "require_weld": insp.require_weld,
        "require_internal": insp.require_internal,
        "require_thickness": insp.require_thickness,
        "report_number": insp.report_number,
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
        "require_external": insp.require_external,
        "require_weld": insp.require_weld,
        "require_internal": insp.require_internal,
        "require_thickness": insp.require_thickness,
        "report_number": insp.report_number,
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

@router.post("/inspections/{inspection_id}/submit-visual-report")
async def submit_visual_inspection_report(
    inspection_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
    inspection_date: str = Form(None),
    report_type: str = Form(None),
    equipment_finding: str = Form(None),
    equipment_recommendation: str = Form(None),
    # External section with NEW dropdown fields
    external_finding: str = Form(None),
    external_condition: str = Form(None),  # NEW
    external_section_recommendation: str = Form(None),  # NEW
    external_recommendation: str = Form(None),
    # Weld section with NEW dropdown fields
    weld_finding: str = Form(None),
    weld_condition: str = Form(None),  # NEW
    weld_section_recommendation: str = Form(None),  # NEW
    weld_recommendation: str = Form(None),
    # Internal section with NEW dropdown fields
    internal_accessible: str = Form("false"),
    internal_finding: str = Form(None),
    internal_condition: str = Form(None),  # NEW
    internal_section_recommendation: str = Form(None),  # NEW
    internal_recommendation: str = Form(None),
    # Thickness section with NEW dropdown fields
    thickness_data: str = Form(None),
    thickness_condition: str = Form(None),  # NEW
    thickness_section_recommendation: str = Form(None),  # NEW
    # Overall summary with NEW field
    overall_condition: str = Form(None),
    overall_recommendation: str = Form(None),  # NEW
    general_recommendation: str = Form(None),
    photo_sections: str = Form(None),
    status_field: str = Form(None),
    pdf_file: UploadFile = File(None),
):
    """Submit visual inspection report for manager review"""
    
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
    
    # Build findings string from all sections
    findings_parts = []
    if external_finding:
        findings_parts.append(f"External: {external_finding}")
    if weld_finding:
        findings_parts.append(f"Weld: {weld_finding}")
    if internal_accessible and internal_accessible.lower() == "true" and internal_finding:
        findings_parts.append(f"Internal: {internal_finding}")
    if equipment_finding:
        findings_parts.append(f"Equipment: {equipment_finding}")
    
    findings = "\n".join(findings_parts) if findings_parts else "Visual inspection completed."
    
    # Build recommendations string
    rec_parts = []
    if external_recommendation:
        rec_parts.append(f"External: {external_recommendation}")
    if weld_recommendation:
        rec_parts.append(f"Weld: {weld_recommendation}")
    if internal_accessible and internal_accessible.lower() == "true" and internal_recommendation:
        rec_parts.append(f"Internal: {internal_recommendation}")
    if equipment_recommendation:
        rec_parts.append(f"Equipment: {equipment_recommendation}")
    if general_recommendation:
        rec_parts.append(f"General: {general_recommendation}")
    
    recommendations = "\n".join(rec_parts) if rec_parts else "Continue routine inspection schedule."
    
    # Update inspection
    inspection.report_findings = findings
    inspection.report_recommendations = recommendations
    inspection.status = models.InspectionStatusEnum.pending_review
    inspection.completion_date = date.today()
    
    # NEW: Save per-section inspector fields
    # External section
    inspection.external_finding = external_finding
    inspection.external_condition = external_condition  # NEW
    inspection.external_section_recommendation = external_section_recommendation  # NEW
    inspection.external_recommendation = external_recommendation
    # Weld section
    inspection.weld_finding = weld_finding
    inspection.weld_condition = weld_condition  # NEW
    inspection.weld_section_recommendation = weld_section_recommendation  # NEW
    inspection.weld_recommendation = weld_recommendation
    # Internal section
    if internal_accessible and internal_accessible.lower() == "true":
        inspection.internal_finding = internal_finding
        inspection.internal_condition = internal_condition  # NEW
        inspection.internal_section_recommendation = internal_section_recommendation  # NEW
        inspection.internal_recommendation = internal_recommendation
    else:
        inspection.internal_finding = None
        inspection.internal_condition = None
        inspection.internal_section_recommendation = None
        inspection.internal_recommendation = None
    # Thickness section
    inspection.thickness_condition = thickness_condition  # NEW
    inspection.thickness_section_recommendation = thickness_section_recommendation  # NEW
    # Overall summary
    inspection.overall_finding = overall_condition  # Temporarily using overall_condition field
    inspection.overall_recommendation = overall_recommendation  # NEW
    inspection.additional_comments = general_recommendation  # Using general_recommendation as additional comments
    inspection.general_recommendation = general_recommendation
    
    # Add notes with overall condition
    if overall_condition:
        inspection.notes = (inspection.notes or "") + f"\n[Overall Condition: {overall_condition}]"
    
    # Save the uploaded PDF report (the actual report generated by the inspector)
    try:
        reports_dir = Path("reports/generated")
        reports_dir.mkdir(parents=True, exist_ok=True)
        
        filename = f"inspection_{inspection_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        pdf_path = reports_dir / filename
        
        # PRIORITY 1: Use the uploaded PDF from frontend (the actual inspector's report)
        if pdf_file is not None and pdf_file.filename:
            print(f"[PDF] Saving uploaded PDF: {pdf_file.filename}")
            content = await pdf_file.read()
            with open(pdf_path, 'wb') as f:
                f.write(content)
            inspection.pdf_report_path = str(pdf_path)
            print(f"[PDF] Saved {len(content)} bytes to {pdf_path}")
        else:
            # FALLBACK: Copy a sample PDF if no file was uploaded
            print("[PDF] No PDF uploaded, using sample fallback")
            sample_pdf = Path("reports/sample_pdfs/sample_pending_review.pdf")
            if sample_pdf.exists():
                shutil.copy(sample_pdf, pdf_path)
                inspection.pdf_report_path = str(pdf_path)
    except Exception as pdf_error:
        print(f"Warning: Could not save PDF: {pdf_error}")
        # Continue without PDF - don't fail the submission
    
    try:
        db.commit()
        db.refresh(inspection)
        
        return {
            "message": "Visual inspection report submitted successfully",
            "inspection_id": inspection.id,
            "status": inspection.status.value,
            "pdf_path": inspection.pdf_report_path
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
        filename=f"inspection_{inspection_id}_report.pdf",
        content_disposition_type="inline"
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
        "equipment_id": insp.equipment_id,
        "equipment_type": insp.equipment_type,
        "dosh_registration": insp.dosh_registration,
        "inspector_name": insp.inspector.username if insp.inspector else "Unassigned",
        "status": insp.status.value,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "require_external": insp.require_external,
        "require_weld": insp.require_weld,
        "require_internal": insp.require_internal,
        "require_thickness": insp.require_thickness,
        "report_number": insp.report_number,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

@router.get("/analytics/defects")
def get_defect_analytics(
    period: str = "all",
    db: Session = Depends(get_db),
):
    start_date, end_date = get_date_range_from_period(period)

    sql = """
    SELECT equipment_type, defect_type, COUNT(*) as count
    FROM (
        SELECT equipment_type, external_finding AS defect_type, completion_date, status
        FROM inspections
        UNION ALL
        SELECT equipment_type, weld_finding AS defect_type, completion_date, status
        FROM inspections
        UNION ALL
        SELECT equipment_type, internal_finding AS defect_type, completion_date, status
        FROM inspections
        UNION ALL
        SELECT equipment_type, thickness_finding AS defect_type, completion_date, status
        FROM inspections
    )
    WHERE status = 'completed'
      AND defect_type IS NOT NULL
      AND defect_type != 'Nil'
    """

    params = {}
    if start_date:
        sql += " AND completion_date >= :start_date"
        params["start_date"] = start_date
    if end_date:
        # completion_date is a DATE field, so use <= for inclusive range
        sql += " AND completion_date <= :end_date"
        params["end_date"] = end_date
    
    sql += " GROUP BY equipment_type, defect_type"

    result = db.execute(text(sql), params).fetchall()

    return [
        {
            "equipment_type": r[0],
            "defect_type": r[1],
            "count": r[2],
        }
        for r in result
    ]