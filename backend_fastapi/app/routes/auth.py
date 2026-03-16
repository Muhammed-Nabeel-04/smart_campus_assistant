from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from passlib.hash import bcrypt
from datetime import datetime,timedelta

# ✅ Added get_current_user to the import here
from app.services.deps import get_db, create_access_token, get_current_user
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

    # ✅ Save token to DB — replaces any existing session (single device)
    from app.models.session_token import SessionToken
    existing_session = db.query(SessionToken).filter(
        SessionToken.user_id == user.id
    ).first()
    if existing_session:
        existing_session.token = token
        existing_session.expires_at = datetime.utcnow() + timedelta(days=30)
    else:
        db.add(SessionToken(
            user_id=user.id,
            token=token,
            expires_at=datetime.utcnow() + timedelta(days=30)
        ))
    db.commit()

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


# ============================================================================
# LOGOUT
# ============================================================================

@router.post("/logout")
def logout(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Logout — invalidates session token"""
    from app.models.session_token import SessionToken
    
    session = db.query(SessionToken).filter(
        SessionToken.user_id == current_user['user_id']
    ).first()
    
    if session:
        db.delete(session)
        db.commit()
        
    return {"message": "Logged out successfully"}

# ============================================================================
# STUDENT QR LOGIN
# ============================================================================

@router.post("/student-qr-login")
def student_qr_login(payload: dict, db: Session = Depends(get_db)):
    """Student scans QR to login — validates token, returns JWT"""

    token = payload.get("token")
    if not token:
        raise HTTPException(status_code=400, detail="Token is required")

    # Validate onboarding/login token
    from app.models.onboarding_token import OnboardingToken
    onboarding = db.query(OnboardingToken).filter(
        OnboardingToken.token == token,
        OnboardingToken.role == "student",
        OnboardingToken.used == False,
    ).first()

    if not onboarding:
        raise HTTPException(status_code=400, detail="Invalid or expired QR code")

    if datetime.utcnow() > onboarding.expiry_time:
        raise HTTPException(status_code=400, detail="QR code has expired")

    from app.models.student import Student
    student = db.query(Student).filter(
        Student.id == onboarding.target_id
    ).first()

    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    # Get or check user account
    user = db.query(User).filter(User.id == student.user_id).first()
    if not user:
        raise HTTPException(
            status_code=400,
            detail="Account not set up. Please complete registration first."
        )

    # Mark token as used
    onboarding.used = True
    onboarding.used_at = datetime.utcnow()
    db.commit()

    # Generate JWT
    jwt_token = create_access_token({
        "user_id": user.id,
        "role": "student",
        "student_id": student.id,
    })

    # ✅ Save session token — single device enforcement
    from app.models.session_token import SessionToken
    existing = db.query(SessionToken).filter(
        SessionToken.user_id == user.id
    ).first()
    if existing:
        existing.token = jwt_token
        existing.expires_at = datetime.utcnow() + timedelta(days=30)
    else:
        db.add(SessionToken(
            user_id=user.id,
            token=jwt_token,
            expires_at=datetime.utcnow() + timedelta(days=30)
        ))
    db.commit()

    return {
        "message": "Login successful",
        "token": jwt_token,
        "user_id": user.id,
        "student_id": student.id,
        "name": student.full_name,
        "email": student.email or student.register_number,
        "role": "student",
        "department": student.department,
        "year": student.year,
        "section": student.section,
        "register_number": student.register_number,
        "is_first_login": False,
    }