from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.services.deps import get_db
from app.models.complaint import Complaint
from app.models.student import Student

router = APIRouter(prefix="/complaints", tags=["Complaints"])


class SubmitComplaintRequest(BaseModel):
    student_id: int
    category: str
    priority: str
    title: str
    description: str


class UpdateComplaintRequest(BaseModel):
    status: str
    admin_response: Optional[str] = None


# ============================================================================
# SUBMIT COMPLAINT
# ============================================================================

@router.post("/")
def submit_complaint(
    payload: SubmitComplaintRequest,
    db: Session = Depends(get_db)
):
    # Check student exists
    student = db.query(Student).filter(
        Student.id == payload.student_id
    ).first()

    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    complaint = Complaint(
        student_id=payload.student_id,
        category=payload.category,
        priority=payload.priority,
        title=payload.title,
        description=payload.description,
        status="pending",
    )

    db.add(complaint)
    db.commit()
    db.refresh(complaint)

    return {
        "message": "Complaint submitted successfully",
        "id": complaint.id,
        "status": complaint.status,
    }


# ============================================================================
# GET STUDENT COMPLAINTS
# ============================================================================

@router.get("/student/{student_id}")
def get_student_complaints(student_id: int, db: Session = Depends(get_db)):

    # Check student exists
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    complaints = db.query(Complaint).filter(
        Complaint.student_id == student_id
    ).order_by(Complaint.created_at.desc()).all()

    return [
        {
            "id": c.id,
            "category": c.category,
            "priority": c.priority,
            "title": c.title,
            "description": c.description,
            "status": c.status,
            "admin_response": c.admin_response,
            "created_at": c.created_at.isoformat(),
            "resolved_at": c.resolved_at.isoformat() if c.resolved_at else None,
        }
        for c in complaints
    ]


# ============================================================================
# GET ALL COMPLAINTS (for admin)
# ============================================================================

@router.get("/")
def get_all_complaints(
    status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Complaint)

    if status:
        query = query.filter(Complaint.status == status)

    complaints = query.order_by(Complaint.created_at.desc()).all()

    return [
        {
            "id": c.id,
            "student_id": c.student_id,
            "category": c.category,
            "priority": c.priority,
            "title": c.title,
            "status": c.status,
            "created_at": c.created_at.isoformat(),
        }
        for c in complaints
    ]


# ============================================================================
# UPDATE COMPLAINT STATUS (for admin)
# ============================================================================

@router.put("/{complaint_id}")
def update_complaint(
    complaint_id: int,
    payload: UpdateComplaintRequest,
    db: Session = Depends(get_db)
):
    complaint = db.query(Complaint).filter(
        Complaint.id == complaint_id
    ).first()

    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")

    complaint.status = payload.status
    complaint.admin_response = payload.admin_response

    if payload.status == "resolved":
        complaint.resolved_at = datetime.utcnow()

    db.commit()

    return {
        "message": "Complaint updated successfully",
        "id": complaint.id,
        "status": complaint.status,
    }