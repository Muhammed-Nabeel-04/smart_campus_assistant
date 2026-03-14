from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from passlib.hash import bcrypt
from datetime import datetime

from app.services.deps import get_db, create_access_token
from app.models.user import User
from app.models.student import Student
from app.models.faculty import Faculty

router = APIRouter(prefix="/auth", tags=["Authentication"])


# ============================================================================
# REQUEST MODELS
# ============================================================================

class StudentRegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    department: str
    year: str

class FacultyRegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    employee_id: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# ============================================================================
# REGISTER STUDENT
# ============================================================================

@router.post("/register-student")
def register_student(payload: StudentRegisterRequest, db: Session = Depends(get_db)):

    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    if len(payload.password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    new_user = User(
        name=payload.name,
        email=payload.email,
        password=bcrypt.hash(payload.password),
        role="student",
        created_at=datetime.utcnow()
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    new_student = Student(
        user_id=new_user.id,
        full_name=payload.name,
        register_number=payload.email,
        department=payload.department,
        year=payload.year,
        section="A",
    )
    db.add(new_student)
    db.commit()
    db.refresh(new_student)

    token = create_access_token({
        "user_id": new_user.id,
        "role": "student",
        "student_id": new_student.id,
    })

    return {
        "message": "Registration successful",
        "token": token,
        "user_id": new_user.id,
        "name": new_user.name,
        "email": new_user.email,
        "role": "student",
        "student_id": new_student.id,
        "department": new_student.department,
        "year": new_student.year,
    }


# ============================================================================
# REGISTER FACULTY
# ============================================================================

@router.post("/register-faculty")
def register_faculty(payload: FacultyRegisterRequest, db: Session = Depends(get_db)):

    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    if len(payload.password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    new_user = User(
        name=payload.name,
        email=payload.email,
        password=bcrypt.hash(payload.password),
        role="faculty",
        created_at=datetime.utcnow()
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    token = create_access_token({
        "user_id": new_user.id,
        "role": "faculty",
    })

    return {
        "message": "Faculty registration successful",
        "token": token,
        "user_id": new_user.id,
        "name": new_user.name,
        "email": new_user.email,
        "role": "faculty",
    }


# ============================================================================
# LOGIN
# ============================================================================

@router.post("/login")
def login(payload: LoginRequest, db: Session = Depends(get_db)):

    user = db.query(User).filter(User.email == payload.email).first()

    if not user or not bcrypt.verify(payload.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # Build token data based on role
    token_data = {"user_id": user.id, "role": user.role}

    student_id = None
    faculty_id = None
    department = None
    year = None
    section = None
    register_number = None

    if user.role == "student":
        student = db.query(Student).filter(Student.user_id == user.id).first()
        if student:
            student_id = student.id
            department = student.department
            year = student.year
            section = student.section
            register_number = student.register_number
            token_data["student_id"] = student_id

    elif user.role == "faculty":
        faculty = db.query(Faculty).filter(Faculty.user_id == user.id).first()
        if faculty:
            faculty_id = faculty.id
            department = faculty.department
            token_data["faculty_id"] = faculty_id

    token = create_access_token(token_data)

    return {
        "message": "Login successful",
        "token": token,
        "user_id": user.id,
        "name": user.name,
        "email": user.email,
        "role": user.role,
        "student_id": student_id,
        "faculty_id": faculty_id,
        "department": department,
        "year": year,
        "section": section,
        "register_number": register_number,
    }