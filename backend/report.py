from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from db import get_db
from auth import get_current_user
import models
from datetime import datetime
import json
import os
from pathlib import Path

router = APIRouter(prefix="/report", tags=["Report Management"])

# Inspector submits report
@router.post("/submit/{inspection_id}")
def submit_report(
    inspection_id: int, 
    report_data: dict, 
    current_user: models.User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    # Check if inspection exists
    inspection = db.query(models.Inspection).filter(models.Inspection.id == inspection_id).first()
    if not inspection:
        raise HTTPException(status_code=404, detail="Inspection not found")

    # Update Inspection status
    inspection.status = models.InspectionStatusEnum.pending_review
    inspection.report_findings = report_data.get('findings', '')
    inspection.report_recommendations = report_data.get('recommendations', '')
    
    # Handle PDF File saving
    # report_data['pdf_file'] is expected to be a list of integers (bytes)
    pdf_bytes_list = report_data.get('pdf_file')
    if pdf_bytes_list and isinstance(pdf_bytes_list, list):
        try:
            # Create reports directory if it doesn't exist
            reports_dir = Path("reports")
            reports_dir.mkdir(exist_ok=True)
            
            # Generate unique filename
            filename = f"inspection_{inspection_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
            file_path = reports_dir / filename
            
            # Convert list of ints to bytes
            pdf_bytes = bytes(pdf_bytes_list)
            
            # Save the file
            with open(file_path, "wb") as f:
                f.write(pdf_bytes)
            
            # Update path in DB
            inspection.pdf_report_path = str(file_path)
        except Exception as e:
            print(f"Error saving PDF: {e}")
            # We don't fail the whole request, but we log it. 
            # In production, we might want to alert.

    inspection.updated_at = datetime.now()

    # Create a Report record (Audit trail)
    new_report = models.Report(
        title=f"Inspection Report for {inspection.title}",
        inspection_id=inspection.id,
        status=models.ReportStatusEnum.pending_review,
        content=report_data.get('notes', 'No notes provided.'),
        findings=report_data.get('findings', ''),
        recommendations=report_data.get('recommendations', ''),
        created_by=current_user.id,
        created_at=datetime.now(),
        updated_at=datetime.now()
    )
    db.add(new_report)
    
    db.commit()
    return {"message": "Report submitted successfully", "inspection_id": inspection_id}

# Manager approves report
@router.post("/approve/{report_id}", dependencies=[Depends(get_current_user)])
def approve_report(report_id: int, db: Session = Depends(get_db)):
    report = db.query(models.Report).filter(models.Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    report.status = models.ReportStatusEnum.approved
    report.updated_at = datetime.now()
    db.commit()
    return {"message": "Report approved", "report_id": report_id}

# Manager rejects report
@router.post("/reject/{report_id}", dependencies=[Depends(get_current_user)])
def reject_report(report_id: int, reason: str = "", db: Session = Depends(get_db)):
    report = db.query(models.Report).filter(models.Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
        
    report.status = models.ReportStatusEnum.draft
    # Validating if we should update content to include rejection reason
    if reason:
        report.content = (report.content or "") + f"\n\n[REJECTED]: {reason}"
        
    report.updated_at = datetime.now()
    db.commit()
    return {"message": "Report rejected", "report_id": report_id, "reason": reason}

# Inspector resubmits report
@router.post("/resubmit/{report_id}")
def resubmit_report(report_id: int, report_data: dict, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    report = db.query(models.Report).filter(models.Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
        
    report.status = models.ReportStatusEnum.pending_review
    report.findings = report_data.get('findings', report.findings)
    report.recommendations = report_data.get('recommendations', report.recommendations)
    report.content = report_data.get('notes', report.content)
    report.updated_at = datetime.now()
    
    db.commit()
    return {"message": "Report resubmitted", "report_id": report_id}
