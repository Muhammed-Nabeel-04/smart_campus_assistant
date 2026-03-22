from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
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
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")

    user = db.query(User).filter(User.id == current_user['user_id']).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

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
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")

    user = db.query(User).filter(User.id == current_user['user_id']).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    dept = db.query(Department).filter(
        Department.hod_user_id == current_user['user_id']
    ).first()

    department = dept.code if dept else "UNKNOWN"
    dept_name = dept.name if dept else "Unknown Department"

    return {
        "department": department,
        "department_code": department,
        "department_name": dept_name,
        "department_id": dept.id if dept else None,
        "email": user.email,
        "name": user.name
    }


# ============================================================================
# GET HOD SUBJECTS
# ============================================================================

@router.get("/subjects")
def get_hod_subjects(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")

    dept = db.query(Department).filter(
        Department.hod_user_id == current_user['user_id']
    ).first()

    if not dept:
        return {}

    subjects = db.query(Subject).filter(
        Subject.department == dept.code
    ).all()

    result = {}
    for sub in subjects:
        year = sub.year or 'Unknown'
        if year not in result:
            result[year] = []
        result[year].append({
            "id": sub.id,
            "name": sub.name,
            "code": sub.code,
            "semester": sub.semester,
            "credits": sub.credits,
            "type": sub.type,
        })

    classes = db.query(ClassModel).filter(
        ClassModel.department_id == dept.id
    ).all()

    semesters = {}
    for cls in classes:
        if cls.year not in semesters:
            semesters[cls.year] = cls.current_semester

    return {
        "department": dept.code,
        "subjects_by_year": result,
        "current_semesters": semesters,
    }


# ============================================================================
# ADD SINGLE SUBJECT
# ============================================================================

class AddSubjectRequest(BaseModel):
    name: str
    year: str
    semester: int
    credits: int = 3
    subject_type: str = "Theory"


@router.post("/subjects/add")
def add_subject(
    payload: AddSubjectRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")

    dept = db.query(Department).filter(
        Department.hod_user_id == current_user['user_id']
    ).first()

    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")

    existing = db.query(Subject).filter(
        Subject.name == payload.name,
        Subject.department == dept.code,
        Subject.year == payload.year,
        Subject.semester == payload.semester
    ).first()

    if existing:
        raise HTTPException(status_code=400, detail="Subject already exists")

    count = db.query(Subject).filter(
        Subject.department == dept.code
    ).count()

    new_sub = Subject(
        name=payload.name,
        code=f"{dept.code[:3].upper()}{payload.semester}{count+1:02d}",
        department=dept.code,
        year=payload.year,
        semester=payload.semester,
        credits=payload.credits,
        type=payload.subject_type,
    )
    db.add(new_sub)
    db.commit()
    db.refresh(new_sub)

    classes = db.query(ClassModel).filter(
        ClassModel.department_id == dept.id,
        ClassModel.year == payload.year,
    ).all()

    for cls in classes:
        existing_link = db.query(ClassSubject).filter(
            ClassSubject.class_id == cls.id,
            ClassSubject.subject_id == new_sub.id,
        ).first()
        if not existing_link:
            db.add(ClassSubject(
                class_id=cls.id,
                subject_id=new_sub.id,
                semester=f"Semester {payload.semester}"
            ))
    db.commit()

    return {
        "message": "Subject added successfully",
        "id": new_sub.id,
        "name": new_sub.name,
        "code": new_sub.code,
    }


# ============================================================================
# DELETE SUBJECT
# ============================================================================

@router.delete("/subjects/{subject_id}")
def delete_subject(
    subject_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")

    dept = db.query(Department).filter(
        Department.hod_user_id == current_user['user_id']
    ).first()

    subject = db.query(Subject).filter(
        Subject.id == subject_id,
        Subject.department == (dept.code if dept else None)
    ).first()

    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")

    db.query(ClassSubject).filter(
        ClassSubject.subject_id == subject_id
    ).delete()

    db.delete(subject)
    db.commit()

    return {"message": "Subject deleted successfully"}


# ============================================================================
# UPDATE CURRENT SEMESTER FOR A YEAR
# ============================================================================

class UpdateSemesterRequest(BaseModel):
    year: str
    semester: int


@router.put("/classes/update-semester")
def update_class_semester(
    payload: UpdateSemesterRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")

    dept = db.query(Department).filter(
        Department.hod_user_id == current_user['user_id']
    ).first()

    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")

    classes = db.query(ClassModel).filter(
        ClassModel.department_id == dept.id,
        ClassModel.year == payload.year,
    ).all()

    for cls in classes:
        cls.current_semester = f"Semester {payload.semester}"

    db.commit()

    return {
        "message": f"Updated {len(classes)} classes to Semester {payload.semester}",
        "year": payload.year,
        "semester": payload.semester,
    }

# ── Get HOD department sections (per year) ────────────────────
@router.get("/sections")
def get_hod_sections(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="HOD access required")
    dept = db.query(Department).filter(
        Department.hod_user_id == current_user["user_id"]
    ).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    import json
    try:
        data = json.loads(dept.sections or "{}")
        # Handle old format (list) — migrate to per-year
        if isinstance(data, list):
            years = ["1st Year", "2nd Year", "3rd Year", "4th Year"]
            data = {year: data for year in years}
    except Exception:
        data = {}
    return {"sections_by_year": data}

# ── Update HOD department sections (per year) ─────────────────
class SectionsByYearPayload(BaseModel):
    sections_by_year: dict

@router.put("/sections")
def update_hod_sections(
    payload: SectionsByYearPayload,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="HOD access required")
    dept = db.query(Department).filter(
        Department.hod_user_id == current_user["user_id"]
    ).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    import json
    dept.sections = json.dumps(payload.sections_by_year)
    db.commit()
    return {"message": "Sections updated", "sections_by_year": payload.sections_by_year}

class UpdateSubjectPayload(BaseModel):
    name: Optional[str] = None
    credits: Optional[int] = None
    subject_type: Optional[str] = None

@router.put("/subjects/{subject_id}")
def update_hod_subject(
    subject_id: int,
    payload: UpdateSubjectPayload,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="HOD access required")

    subject = db.query(Subject).filter(Subject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")

    if payload.name:
        subject.name = payload.name
    if payload.credits is not None:
        subject.credits = payload.credits
    if payload.subject_type:
        subject.type = payload.subject_type

    db.commit()
    return {"message": "Subject updated successfully"}

# ── Get period timings ────────────────────────────────────────
@router.get("/period-timings")
def get_period_timings(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="HOD access required")
    dept = db.query(Department).filter(
        Department.hod_user_id == current_user["user_id"]
    ).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    import json
    try:
        timings = json.loads(dept.period_timings or "[]")
    except Exception:
        timings = []
    # Default 5 periods if none set
    if not timings:
        timings = [
            {"period": 1, "start": "09:00", "end": "10:00"},
            {"period": 2, "start": "10:00", "end": "11:00"},
            {"period": 3, "start": "11:00", "end": "12:00"},
            {"period": 4, "start": "13:00", "end": "14:00"},
            {"period": 5, "start": "14:00", "end": "15:00"},
        ]
    return {"period_timings": timings}

# ── Update period timings ─────────────────────────────────────
class PeriodTimingsPayload(BaseModel):
    period_timings: list

@router.put("/period-timings")
def update_period_timings(
    payload: PeriodTimingsPayload,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="HOD access required")
    dept = db.query(Department).filter(
        Department.hod_user_id == current_user["user_id"]
    ).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    import json
    dept.period_timings = json.dumps(payload.period_timings)
    db.commit()
    return {"message": "Period timings updated", "period_timings": payload.period_timings}