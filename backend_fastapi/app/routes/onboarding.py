# File: backend/app/routes/onboarding.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from app.services.deps import get_db, create_access_token
from app.models.onboarding_token import OnboardingToken
from app.models.faculty import Faculty
from app.models.student import Student
from app.models.user import User

router = APIRouter(prefix="/onboarding", tags=["Onboarding"])


# ============================================================================
# FACULTY ONBOARDING
# ============================================================================

@router.post("/faculty/validate-qr")
def validate_faculty_qr(payload: dict, db: Session = Depends(get_db)):
    """Called when faculty scans onboarding QR — no token needed"""

    token = payload.get("token")
    if not token:
        raise HTTPException(status_code=400, detail="Token is required")

    onboarding = db.query(OnboardingToken).filter(
        OnboardingToken.token == token,
        OnboardingToken.role == "faculty",
        OnboardingToken.used == False,
    ).first()

    if not onboarding:
        raise HTTPException(status_code=400, detail="Invalid or expired QR code")

    if datetime.utcnow() > onboarding.expiry_time:
        raise HTTPException(status_code=400, detail="QR code has expired")

    faculty = db.query(Faculty).filter(
        Faculty.id == onboarding.target_id
    ).first()

    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty not found")

    return {
        "faculty_id": faculty.id,
        "full_name": faculty.full_name,
        "employee_id": faculty.employee_id,
        "department": faculty.department,
        "email": faculty.email,
        "token": token,
    }


@router.post("/faculty/set-password")
def set_faculty_password(payload: dict, db: Session = Depends(get_db)):
    """Faculty sets password after QR scan — no token needed"""
    from passlib.hash import bcrypt

    faculty_id = payload.get("faculty_id")
    password = payload.get("password")
    token = payload.get("token")

    if not faculty_id or not password:
        raise HTTPException(status_code=400, detail="faculty_id and password required")

    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    # Mark onboarding token as used
    if token:
        onboarding = db.query(OnboardingToken).filter(
            OnboardingToken.token == token,
            OnboardingToken.role == "faculty",
            OnboardingToken.used == False,
        ).first()
        if onboarding:
            onboarding.used = True
            onboarding.used_at = datetime.utcnow()

    faculty = db.query(Faculty).filter(Faculty.id == faculty_id).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty not found")

    existing_user = db.query(User).filter(User.id == faculty.user_id).first()

    if existing_user:
        existing_user.password = bcrypt.hash(password)
        db.commit()
        user_id = existing_user.id
    else:
        new_user = User(
            name=faculty.full_name,
            email=faculty.email,
            password=bcrypt.hash(password),
            role="faculty",
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        faculty.user_id = new_user.id
        db.commit()
        user_id = new_user.id

    # Return JWT token so faculty is logged in immediately
    jwt_token = create_access_token({
        "user_id": user_id,
        "role": "faculty",
        "faculty_id": faculty.id,
    })

    # ✅ Save session token — single device enforcement
    from app.models.session_token import SessionToken
    existing = db.query(SessionToken).filter(
        SessionToken.user_id == user_id
    ).first()
    if existing:
        existing.token = jwt_token
        existing.expires_at = datetime.utcnow() + timedelta(days=30)
    else:
        db.add(SessionToken(
            user_id=user_id,
            token=jwt_token,
            expires_at=datetime.utcnow() + timedelta(days=30)
        ))
    db.commit()

    return {
        "message": "Password set successfully",
        "token": jwt_token,
        "user_id": user_id,
        "faculty_id": faculty.id,
        "full_name": faculty.full_name,
        "department": faculty.department,
        "email": faculty.email,
        "role": "faculty",
    }


# ============================================================================
# STUDENT ONBOARDING
# ============================================================================

@router.post("/student/validate-qr")
def validate_student_qr(payload: dict, db: Session = Depends(get_db)):
    """Called when student scans onboarding QR — no token needed"""

    token = payload.get("token")
    if not token:
        raise HTTPException(status_code=400, detail="Token is required")

    onboarding = db.query(OnboardingToken).filter(
        OnboardingToken.token == token,
        OnboardingToken.role == "student",
        OnboardingToken.used == False,
    ).first()

    if not onboarding:
        raise HTTPException(status_code=400, detail="Invalid or expired QR code")

    if datetime.utcnow() > onboarding.expiry_time:
        raise HTTPException(status_code=400, detail="QR code has expired")

    student = db.query(Student).filter(
        Student.id == onboarding.target_id
    ).first()

    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    return {
        "student_id": student.id,
        "full_name": student.full_name,
        "register_number": student.register_number,
        "department": student.department,
        "year": student.year,
        "section": student.section,
        "token": token,
    }


@router.post("/student/complete-registration")
def complete_student_registration(payload: dict, db: Session = Depends(get_db)):
    """Student sets password after QR scan — no token needed"""
    from passlib.hash import bcrypt

    token = payload.get("token")
    password = payload.get("password")

    if not token or not password:
        raise HTTPException(status_code=400, detail="Token and password required")

    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    onboarding = db.query(OnboardingToken).filter(
        OnboardingToken.token == token,
        OnboardingToken.role == "student",
        OnboardingToken.used == False,
    ).first()

    if not onboarding:
        raise HTTPException(status_code=400, detail="Invalid or expired QR code")

    if datetime.utcnow() > onboarding.expiry_time:
        raise HTTPException(status_code=400, detail="QR code has expired")

    student = db.query(Student).filter(
        Student.id == onboarding.target_id
    ).first()

    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    # Create user account
    existing_user = db.query(User).filter(
        User.email == student.register_number
    ).first()

    if not existing_user:
        new_user = User(
            name=student.full_name,
            email=student.register_number,
            password=bcrypt.hash(password),
            role="student",
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        student.user_id = new_user.id
        db.commit()
        user_id = new_user.id
    else:
        user_id = existing_user.id

    # Mark token as used
    onboarding.used = True
    onboarding.used_at = datetime.utcnow()
    db.commit()

    # Return JWT token so student is logged in immediately
    jwt_token = create_access_token({
        "user_id": user_id,
        "role": "student",
        "student_id": student.id,
    })

    # ✅ Save session token — single device enforcement
    from app.models.session_token import SessionToken
    existing = db.query(SessionToken).filter(
        SessionToken.user_id == user_id
    ).first()
    if existing:
        existing.token = jwt_token
        existing.expires_at = datetime.utcnow() + timedelta(days=30)
    else:
        db.add(SessionToken(
            user_id=user_id,
            token=jwt_token,
            expires_at=datetime.utcnow() + timedelta(days=30)
        ))
    db.commit()

    return {
        "message": "Registration complete",
        "token": jwt_token,
        "user_id": user_id,
        "student_id": student.id,
        "full_name": student.full_name,
        "register_number": student.register_number,
        "department": student.department,
        "year": student.year,
        "section": student.section,
        "role": "student",
    }

# ============================================================================
# HOD ONBOARDING (via Principal-generated QR)
# ============================================================================

@router.post("/hod/validate-qr")
def validate_hod_qr(payload: dict, db: Session = Depends(get_db)):
    """Called when HOD scans onboarding QR — no token needed"""

    token = payload.get("token")
    if not token:
        raise HTTPException(status_code=400, detail="Token is required")

    onboarding = db.query(OnboardingToken).filter(
        OnboardingToken.token == token,
        OnboardingToken.role == "admin",
        OnboardingToken.used == False,
    ).first()

    if not onboarding:
        raise HTTPException(status_code=400, detail="Invalid or expired QR code")

    if datetime.utcnow() > onboarding.expiry_time:
        raise HTTPException(status_code=400, detail="QR code has expired")

    hod_user = db.query(User).filter(
        User.id == onboarding.target_id,
        User.role == "admin"
    ).first()

    if not hod_user:
        raise HTTPException(status_code=404, detail="HOD not found")

    return {
        "hod_id": hod_user.id,
        "name": hod_user.name,
        "email": hod_user.email,
        "token": token,
    }


@router.post("/hod/set-password")
def set_hod_password(payload: dict, db: Session = Depends(get_db)):
    """HOD sets password after QR scan — no token needed"""
    from passlib.hash import bcrypt

    hod_id = payload.get("hod_id")
    password = payload.get("password")
    token = payload.get("token")

    if not hod_id or not password:
        raise HTTPException(status_code=400, detail="hod_id and password required")

    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    # Mark token as used
    if token:
        onboarding = db.query(OnboardingToken).filter(
            OnboardingToken.token == token,
            OnboardingToken.role == "admin",
            OnboardingToken.used == False,
        ).first()
        if onboarding:
            onboarding.used = True
            onboarding.used_at = datetime.utcnow()

    hod_user = db.query(User).filter(
        User.id == hod_id,
        User.role == "admin"
    ).first()

    if not hod_user:
        raise HTTPException(status_code=404, detail="HOD not found")

    hod_user.password = bcrypt.hash(password)
    db.commit()

    # Return JWT so HOD is logged in immediately
    jwt_token = create_access_token({
        "user_id": hod_user.id,
        "role": "admin",
    })

    user_id = hod_user.id

    # ✅ Save session token — single device enforcement
    from app.models.session_token import SessionToken
    existing = db.query(SessionToken).filter(
        SessionToken.user_id == user_id
    ).first()
    if existing:
        existing.token = jwt_token
        existing.expires_at = datetime.utcnow() + timedelta(days=30)
    else:
        db.add(SessionToken(
            user_id=user_id,
            token=jwt_token,
            expires_at=datetime.utcnow() + timedelta(days=30)
        ))
    db.commit()
    

    return {
        "message": "Password set successfully",
        "token": jwt_token,
        "user_id": hod_user.id,
        "name": hod_user.name,
        "email": hod_user.email,
        "role": "admin",
    }