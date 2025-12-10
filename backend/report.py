from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from db import get_db
from auth import get_current_user
import models

router = APIRouter(prefix="/report", tags=["Report Management"])

# Inspector submits report
@router.post("/submit/{inspection_id}")
def submit_report(inspection_id: int, report_data: dict, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    # TODO: Save report, mark as submitted
    return {"message": "Report submitted", "inspection_id": inspection_id}

# Manager approves report
@router.post("/approve/{report_id}", dependencies=[Depends(get_current_user)])
def approve_report(report_id: int, db: Session = Depends(get_db)):
    # TODO: Mark report as approved
    return {"message": "Report approved", "report_id": report_id}

# Manager rejects report
@router.post("/reject/{report_id}", dependencies=[Depends(get_current_user)])
def reject_report(report_id: int, reason: str = "", db: Session = Depends(get_db)):
    # TODO: Mark report as rejected, save reason
    return {"message": "Report rejected", "report_id": report_id, "reason": reason}

# Inspector resubmits report
@router.post("/resubmit/{report_id}")
def resubmit_report(report_id: int, report_data: dict, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    # TODO: Update report, mark as resubmitted
    return {"message": "Report resubmitted", "report_id": report_id}
