from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List
from passlib.context import CryptContext

from app.services.deps import get_db, get_current_user
from app.models.user import User
from app.models.subject import Subject
from app.models.department import Department
from app.models.class_model import ClassModel
from app.models.class_subject import ClassSubject

router = APIRouter(prefix="/hod", tags=["HOD Setup"])

bcrypt = CryptContext(schemes=["bcrypt"])


# ============================================================================
# CHANGE PASSWORD
# ============================================================================

class ChangePasswordRequest(BaseModel):
    new_password: str


@router.post("/change-password")
def change_password(
    payload: ChangePasswordRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """HOD changes their password during initial setup"""

    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")

    user = db.query(User).filter(User.id == current_user['user_id']).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.password = bcrypt.hash(payload.new_password)
    db.commit()

    return {"message": "Password changed successfully"}


# ============================================================================
# BATCH CREATE SUBJECTS
# ============================================================================

class SubjectCreate(BaseModel):
    name: str
    department: str
    year: str
    semester: int


class BatchSubjectsRequest(BaseModel):
    subjects: List[SubjectCreate]


@router.post("/subjects/batch")
def create_subjects_batch(
    payload: BatchSubjectsRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create multiple subjects + link to existing classes"""

    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")

    created_subjects = []

    for subject_data in payload.subjects:
        existing = db.query(Subject).filter(
            Subject.name == subject_data.name,
            Subject.department == subject_data.department,
            Subject.year == subject_data.year,
            Subject.semester == subject_data.semester
        ).first()

        if existing:
            sub = existing
        else:
            sub = Subject(
                name=subject_data.name,
                department=subject_data.department,
                year=subject_data.year,
                semester=subject_data.semester,
                code=f"{subject_data.department[:3].upper()}{subject_data.semester}{len(created_subjects)+1:02d}"
            )
            db.add(sub)
            db.commit()
            db.refresh(sub)
            created_subjects.append(sub)

        # ✅ Link to existing classes for this dept + year
        dept = db.query(Department).filter(
            Department.code == subject_data.department
        ).first()

        if dept:
            classes = db.query(ClassModel).filter(
                ClassModel.department_id == dept.id,
                ClassModel.year == subject_data.year,
            ).all()

            for cls in classes:
                existing_link = db.query(ClassSubject).filter(
                    ClassSubject.class_id == cls.id,
                    ClassSubject.subject_id == sub.id,
                ).first()

                if not existing_link:
                    db.add(ClassSubject(
                        class_id=cls.id,
                        subject_id=sub.id,
                        semester=f"Semester {subject_data.semester}"
                    ))

    db.commit()

    return {
        "message": f"Created {len(created_subjects)} subjects",
        "count": len(created_subjects)
    }


# ============================================================================
# CHECK SETUP STATUS
# ============================================================================

@router.get("/setup-status")
def check_setup_status(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Check if HOD has completed initial setup"""

    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")

    user = db.query(User).filter(User.id == current_user['user_id']).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # ✅ Get department from DB
    dept = db.query(Department).filter(
        Department.hod_user_id == current_user['user_id']
    ).first()

    department = dept.code if dept else None

    subjects_exist = False
    if department:
        subjects_exist = db.query(Subject).filter(
            Subject.department == department
        ).count() > 0

    password_changed = len(user.password) > 0 and user.password != "default"
    setup_completed = password_changed and subjects_exist

    return {
        "setup_completed": setup_completed,
        "password_changed": password_changed,
        "subjects_added": subjects_exist,
        "department": department or "UNKNOWN"
    }


# ============================================================================
# GET HOD DEPARTMENT
# ============================================================================

@router.get("/department")
def get_hod_department(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get HOD's department from DB (dynamic)"""

    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")

    user = db.query(User).filter(User.id == current_user['user_id']).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # ✅ Get department from DB via hod_user_id
    dept = db.query(Department).filter(
        Department.hod_user_id == current_user['user_id']
    ).first()

    department = dept.code if dept else "UNKNOWN"
    dept_name = dept.name if dept else "Unknown Department"

    return {
        "department": department,
        "department_name": dept_name,
        "email": user.email,
        "name": user.name
    }