from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta
from app.services.deps import get_db, get_current_user
from app.models.student import Student
from app.models.onboarding_token import OnboardingToken
from app.models.department import Department
import secrets
import json

router = APIRouter(prefix="/students", tags=["Students CRUD"])


# ===============================
# Request Models
# ===============================

class AddStudentRequest(BaseModel):
    full_name: str
    register_number: str
    department: str
    year: str
    section: str
    email: Optional[str] = None
    phone_number: Optional[str] = None
    date_of_birth: Optional[str] = None
    blood_group: Optional[str] = None
    gender: Optional[str] = None
    residential_type: Optional[str] = "Day Scholar"
    address: Optional[str] = None
    parent_name: Optional[str] = None
    parent_phone: Optional[str] = None
    parent_email: Optional[str] = None

# ✅ Added Partial Update Model for Flutter
class UpdateStudentRequest(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    phone_number: Optional[str] = None
    date_of_birth: Optional[str] = None
    blood_group: Optional[str] = None
    gender: Optional[str] = None
    residential_type: Optional[str] = None
    address: Optional[str] = None
    parent_name: Optional[str] = None
    parent_phone: Optional[str] = None
    parent_email: Optional[str] = None


# ===============================
# GET STUDENTS
# ===============================

@router.get("/")
def get_students(
    department_id: Optional[int] = None,
    year: Optional[str] = None,
    section: Optional[str] = None,
    department: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user['role'] not in ['faculty', 'admin', 'principal']:
        raise HTTPException(status_code=403, detail="Access denied")
    query = db.query(Student)

   # Filter using department_id
    if department_id:
        dept = db.query(Department).filter(Department.id == department_id).first()
        if dept:
            query = query.filter(Student.department.ilike(dept.code))

    # Filter using department code
    if department:
        query = query.filter(Student.department.ilike(department))

    if year:
        query = query.filter(Student.year == year)

    if section:
        query = query.filter(Student.section == section)

    students = query.all()

    return [
        {
            "id": s.id,
            "full_name": s.full_name,
            "register_number": s.register_number,
            "department": s.department,
            "year": s.year,
            "section": s.section,
            "email": s.email,
            "phone_number": s.phone_number,
            "gender": s.gender,
            "blood_group": s.blood_group,
            "residential_type": s.residential_type,
        }
        for s in students
    ]


# ===============================
# ADD STUDENT
# ===============================

@router.post("/")
def add_student(payload: AddStudentRequest, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user['role'] not in ['faculty', 'admin']:
        raise HTTPException(status_code=403, detail="Access denied")

    existing = db.query(Student).filter(
        Student.register_number == payload.register_number
    ).first()

    if existing:
        raise HTTPException(
            status_code=400,
            detail="Register number already exists"
        )

    student = Student(
        full_name=payload.full_name,
        register_number=payload.register_number,
        department=payload.department,
        year=payload.year,
        section=payload.section,
        email=payload.email,
        phone_number=payload.phone_number,
        date_of_birth=payload.date_of_birth,
        blood_group=payload.blood_group,
        gender=payload.gender,
        residential_type=payload.residential_type,
        address=payload.address,
        parent_name=payload.parent_name,
        parent_phone=payload.parent_phone,
        parent_email=payload.parent_email,
    )

    db.add(student)
    db.commit()
    db.refresh(student)

    return {
        "message": "Student added successfully",
        "student_id": student.id,
        "full_name": student.full_name,
        "register_number": student.register_number,
    }


# ===============================
# UPDATE STUDENT
# ===============================

@router.put("/{student_id}")
def update_student(
    student_id: int,
    payload: UpdateStudentRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user['role'] not in ['faculty', 'admin']:
        raise HTTPException(status_code=403, detail="Access denied")

    student = db.query(Student).filter(Student.id == student_id).first()

    if not student:
        raise HTTPException(
            status_code=404,
            detail="Student not found"
        )

    # Only update fields that were sent
    if payload.full_name is not None: student.full_name = payload.full_name
    if payload.email is not None: student.email = payload.email
    if payload.phone_number is not None: student.phone_number = payload.phone_number
    if payload.date_of_birth is not None: student.date_of_birth = payload.date_of_birth
    if payload.blood_group is not None: student.blood_group = payload.blood_group
    if payload.gender is not None: student.gender = payload.gender
    if payload.residential_type is not None: student.residential_type = payload.residential_type
    if payload.address is not None: student.address = payload.address
    if payload.parent_name is not None: student.parent_name = payload.parent_name
    if payload.parent_phone is not None: student.parent_phone = payload.parent_phone
    if payload.parent_email is not None: student.parent_email = payload.parent_email

    db.commit()
    db.refresh(student)

    return {
        "message": "Student updated successfully",
        "student_id": student.id
    }


# ===============================
# GET SINGLE STUDENT
# ===============================

@router.get("/{student_id}")
def get_student(student_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user['role'] not in ['faculty', 'admin', 'student']:
        raise HTTPException(status_code=403, detail="Access denied")

    student = db.query(Student).filter(Student.id == student_id).first()

    if not student:
        raise HTTPException(
            status_code=404,
            detail="Student not found"
        )

    return {
        "id": student.id,
        "full_name": student.full_name,
        "register_number": student.register_number,
        "department": student.department,
        "year": student.year,
        "section": student.section,
        "email": student.email,
        "phone_number": student.phone_number,
        "date_of_birth": student.date_of_birth,
        "blood_group": student.blood_group,
        "gender": student.gender,
        "residential_type": student.residential_type,
        "address": student.address,
        "parent_name": student.parent_name,
        "parent_phone": student.parent_phone,
        "parent_email": student.parent_email,
    }


# ===============================
# GENERATE STUDENT QR
# ===============================

@router.post("/{student_id}/generate-qr/")
def generate_student_qr(student_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user['role'] not in ['faculty', 'admin']:
        raise HTTPException(status_code=403, detail="Access denied")

    student = db.query(Student).filter(Student.id == student_id).first()

    if not student:
        raise HTTPException(
            status_code=404,
            detail="Student not found"
        )

    # ✅ Invalidate all previous unused tokens for this student
    old_tokens = db.query(OnboardingToken).filter(
        OnboardingToken.target_id == student_id,
        OnboardingToken.role == "student",
        OnboardingToken.used == False
    ).all()
    for old in old_tokens:
        old.used = True
        old.used_at = datetime.utcnow()
    if old_tokens:
        db.commit()

    token = secrets.token_urlsafe(32)

    qqr_token = OnboardingToken(
        token=token,
        role="student",
        target_id=student_id,
        expiry_time=datetime.utcnow() + timedelta(minutes=1),
        used=False
    )

    db.add(qr_token)
    db.commit()

    qr_data = json.dumps({
        "student_id": student_id,
        "register_number": student.register_number,
        "full_name": student.full_name,
        "token": token,
    })

    return {
        "qr_data": qr_data,
        "token": token,
        "student_id": student_id,
        "full_name": student.full_name,
        "register_number": student.register_number,
        "expires_in_minutes": 1,
    }