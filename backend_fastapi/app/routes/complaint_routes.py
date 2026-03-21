from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.services.deps import get_db, get_current_user
from app.models.complaint import Complaint
from app.models.student import Student
from app.models.department import Department

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


def _complaint_dict(c: Complaint, db: Session) -> dict:
    student = db.query(Student).filter(Student.id == c.student_id).first()
    return {
        "id": c.id,
        "student_id": c.student_id,
        "student_name": student.full_name if student else "Unknown",
        "category": c.category,
        "priority": c.priority,
        "title": c.title,
        "description": c.description,
        "status": c.status,
        "admin_response": c.admin_response,
        "escalated_to_principal": bool(c.escalated_to_principal),
        "escalated_at": c.escalated_at.isoformat() if c.escalated_at else None,
        "created_at": c.created_at.isoformat(),
        "updated_at": c.updated_at.isoformat() if c.updated_at else None,
        "resolved_at": c.resolved_at.isoformat() if c.resolved_at else None,
    }


# ============================================================================
# SUBMIT COMPLAINT (student → HOD only)
# ============================================================================

@router.post("/")
def submit_complaint(
    payload: SubmitComplaintRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    student = db.query(Student).filter(Student.id == payload.student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    complaint = Complaint(
        student_id=payload.student_id,
        category=payload.category,
        priority=payload.priority,
        title=payload.title,
        description=payload.description,
        status="pending",
        escalated_to_principal=0,
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
# GET STUDENT'S OWN COMPLAINTS
# ============================================================================

@router.get("/student/{student_id}")
def get_student_complaints(
    student_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user['role'] == 'student':
        own = db.query(Student).filter(Student.user_id == current_user['user_id']).first()
        if not own or own.id != student_id:
            raise HTTPException(status_code=403, detail="Access denied")

    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    complaints = db.query(Complaint).filter(
        Complaint.student_id == student_id
    ).order_by(Complaint.created_at.desc()).all()

    return [_complaint_dict(c, db) for c in complaints]


# ============================================================================
# GET HOD COMPLAINTS (dept students only, not escalated ones)
# ============================================================================

@router.get("/department")
def get_hod_complaints(
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="HOD access required")

    # Get HOD's department
    dept = db.query(Department).filter(
        Department.hod_user_id == current_user['user_id']
    ).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")

    # Get students in this dept
    dept_students = db.query(Student).filter(
        Student.department.ilike(dept.code)
    ).all()
    student_ids = [s.id for s in dept_students]

    if not student_ids:
        return []

    query = db.query(Complaint).filter(
        Complaint.student_id.in_(student_ids),
        Complaint.escalated_to_principal == 0  # not yet escalated
    )
    if status:
        query = query.filter(Complaint.status == status)

    complaints = query.order_by(Complaint.created_at.desc()).all()
    return [_complaint_dict(c, db) for c in complaints]


# ============================================================================
# GET PRINCIPAL COMPLAINTS (escalated only)
# ============================================================================

@router.get("/principal")
def get_principal_complaints(
    status: Optional[str] = None,
    department_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user['role'] != 'principal':
        raise HTTPException(status_code=403, detail="Principal access required")

    query = db.query(Complaint).filter(
        Complaint.escalated_to_principal == 1
    )

    if department_id:
        dept = db.query(Department).filter(Department.id == department_id).first()
        if dept:
            dept_students = db.query(Student).filter(
                Student.department.ilike(dept.code)
            ).all()
            student_ids = [s.id for s in dept_students]
            query = query.filter(Complaint.student_id.in_(student_ids))

    if status:
        query = query.filter(Complaint.status == status)

    complaints = query.order_by(Complaint.created_at.desc()).all()
    return [_complaint_dict(c, db) for c in complaints]


# ============================================================================
# ESCALATE COMPLAINT TO PRINCIPAL (HOD only)
# ============================================================================

@router.post("/{complaint_id}/escalate")
def escalate_complaint(
    complaint_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="HOD access required")

    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")

    if complaint.escalated_to_principal:
        raise HTTPException(status_code=400, detail="Already escalated to principal")

    complaint.escalated_to_principal = 1
    complaint.escalated_at = datetime.utcnow()
    complaint.escalated_by = current_user['user_id']
    complaint.status = "escalated"
    db.commit()

    return {"message": "Complaint escalated to principal successfully"}


# ============================================================================
# UPDATE COMPLAINT STATUS (HOD or Principal)
# ============================================================================

@router.put("/{complaint_id}")
def update_complaint(
    complaint_id: int,
    payload: UpdateComplaintRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user['role'] not in ['admin', 'principal']:
        raise HTTPException(status_code=403, detail="Access denied")

    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")

    # Principal can only update escalated complaints
    if current_user['role'] == 'principal' and not complaint.escalated_to_principal:
        raise HTTPException(status_code=403, detail="Complaint not escalated to principal")

    complaint.status = payload.status
    if payload.admin_response:
        complaint.admin_response = payload.admin_response
    complaint.updated_at = datetime.utcnow()

    if payload.status == "resolved":
        complaint.resolved_at = datetime.utcnow()

    db.commit()

    return {
        "message": "Complaint updated successfully",
        "id": complaint.id,
        "status": complaint.status,
    }



