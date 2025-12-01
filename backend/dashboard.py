from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from datetime import datetime, date
import models
from db import get_db
from auth import get_current_user

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
        "status": insp.status.value,
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "completion_date": insp.completion_date.isoformat() if insp.completion_date else None,
        "notes": insp.notes,
        "created_at": insp.created_at.isoformat()
    } for insp in inspections]

@router.get("/stats/monthly")
def get_monthly_stats(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get dashboard statistics for the current month"""
    
    # Get current month and year
    now = datetime.now()
    current_month = now.month
    current_year = now.year
    
    # ROLE-BASED FILTERING
    # Inspectors: Only see approved/completed work (all stats show 0 until manager approves)
    # Managers: See all data
    
    if current_user.role == models.RoleEnum.inspector:
        # For inspectors, only count APPROVED reports and COMPLETED inspections
        # This means their dashboard shows 0 until manager approves their work
        
        # Total Inspections - only completed and approved by manager
        total_inspections = db.query(models.Inspection).filter(
            models.Inspection.inspector_id == current_user.id,
            models.Inspection.status == models.InspectionStatusEnum.completed
        ).count()
        
        # Inspections this month - only completed
        inspections_this_month = db.query(models.Inspection).filter(
            models.Inspection.inspector_id == current_user.id,
            models.Inspection.status == models.InspectionStatusEnum.completed,
            extract('month', models.Inspection.completion_date) == current_month,
            extract('year', models.Inspection.completion_date) == current_year
        ).count()
        
        # Total Reports - only approved
        total_reports = db.query(models.Report).filter(
            models.Report.created_by == current_user.id,
            models.Report.status == models.ReportStatusEnum.approved
        ).count()
        
        # Reports this month - only approved
        reports_this_month = db.query(models.Report).filter(
            models.Report.created_by == current_user.id,
            models.Report.status == models.ReportStatusEnum.approved,
            extract('month', models.Report.created_at) == current_month,
            extract('year', models.Report.created_at) == current_year
        ).count()
        
        # Pending Review - inspector cannot see pending items (shows 0)
        pending_review_inspections = 0
        pending_review_reports = 0
        
        # Completed this month - only approved completed work
        completed_this_month = inspections_this_month
        
        # Previous month stats for inspectors
        prev_month = current_month - 1 if current_month > 1 else 12
        prev_year = current_year if current_month > 1 else current_year - 1
        
        inspections_prev_month = db.query(models.Inspection).filter(
            models.Inspection.inspector_id == current_user.id,
            models.Inspection.status == models.InspectionStatusEnum.completed,
            extract('month', models.Inspection.completion_date) == prev_month,
            extract('year', models.Inspection.completion_date) == prev_year
        ).count()
        
        reports_prev_month = db.query(models.Report).filter(
            models.Report.created_by == current_user.id,
            models.Report.status == models.ReportStatusEnum.approved,
            extract('month', models.Report.created_at) == prev_month,
            extract('year', models.Report.created_at) == prev_year
        ).count()
        
        completed_prev_month = inspections_prev_month
        
    else:  # Manager role
        # Managers see ALL data
        
        # Total Inspections (all time)
        total_inspections = db.query(models.Inspection).count()
        
        # Inspections this month
        inspections_this_month = db.query(models.Inspection).filter(
            extract('month', models.Inspection.created_at) == current_month,
            extract('year', models.Inspection.created_at) == current_year
        ).count()
        
        # Total Reports Generated (all time)
        total_reports = db.query(models.Report).count()
        
        # Reports this month
        reports_this_month = db.query(models.Report).filter(
            extract('month', models.Report.created_at) == current_month,
            extract('year', models.Report.created_at) == current_year
        ).count()
        
        # Pending Review (inspections)
        pending_review_inspections = db.query(models.Inspection).filter(
            models.Inspection.status == models.InspectionStatusEnum.pending_review
        ).count()
        
        # Pending Review (reports)
        pending_review_reports = db.query(models.Report).filter(
            models.Report.status == models.ReportStatusEnum.pending_review
        ).count()
    
    total_pending_review = pending_review_inspections + pending_review_reports
    
    # Completed This Month - for managers only
    if current_user.role == models.RoleEnum.manager:
        completed_this_month = db.query(models.Inspection).filter(
            models.Inspection.status == models.InspectionStatusEnum.completed,
            extract('month', models.Inspection.completion_date) == current_month,
            extract('year', models.Inspection.completion_date) == current_year
        ).count()
        
        # Get previous month stats for managers
        prev_month = current_month - 1 if current_month > 1 else 12
        prev_year = current_year if current_month > 1 else current_year - 1
        
        inspections_prev_month = db.query(models.Inspection).filter(
            extract('month', models.Inspection.created_at) == prev_month,
            extract('year', models.Inspection.created_at) == prev_year
        ).count()
        
        reports_prev_month = db.query(models.Report).filter(
            extract('month', models.Report.created_at) == prev_month,
            extract('year', models.Report.created_at) == prev_year
        ).count()
        
        completed_prev_month = db.query(models.Inspection).filter(
            models.Inspection.status == models.InspectionStatusEnum.completed,
            extract('month', models.Inspection.completion_date) == prev_month,
            extract('year', models.Inspection.completion_date) == prev_year
        ).count()
    # For inspectors, completed_this_month, inspections_prev_month, reports_prev_month, 
    # completed_prev_month are already set above
    
    # Calculate percentage changes
    def calc_change(current, previous):
        if previous == 0:
            return "+100%" if current > 0 else "0%"
        change = ((current - previous) / previous) * 100
        sign = "+" if change >= 0 else ""
        return f"{sign}{int(change)}%"
    
    inspections_change = calc_change(inspections_this_month, inspections_prev_month)
    reports_change = calc_change(reports_this_month, reports_prev_month)
    completed_change = calc_change(completed_this_month, completed_prev_month)
    
    return {
        "total_inspections": total_inspections,
        "inspections_this_month": inspections_this_month,
        "inspections_change": inspections_change,
        
        "total_reports": total_reports,
        "reports_this_month": reports_this_month,
        "reports_change": reports_change,
        
        "pending_review": total_pending_review,
        "pending_review_inspections": pending_review_inspections,
        "pending_review_reports": pending_review_reports,
        
        "completed_this_month": completed_this_month,
        "completed_change": completed_change,
        
        "current_month": now.strftime("%B %Y"),
        "user_role": current_user.role.value
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
        "scheduled_date": insp.scheduled_date.isoformat() if insp.scheduled_date else None,
        "inspector": insp.inspector.full_name if insp.inspector else "Unassigned",
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
        "created_by": report.created_by_user.full_name if report.created_by_user else "Unknown",
        "created_at": report.created_at.isoformat()
    } for report in reports]
