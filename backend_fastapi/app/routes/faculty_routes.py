from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta
from typing import Optional
from app.services.deps import get_db, get_current_user
from app.models.attendance_session import AttendanceSession
from app.models.attendance import Attendance
from app.models.student import Student
from app.models.subject import Subject
from app.models.class_model import ClassModel
from app.models.user import User
from app.models.faculty import Faculty
from app.models.department import Department
from app.models.class_model import ClassModel
from app.models.onboarding_token import OnboardingToken
import secrets
import json

router = APIRouter(prefix="/faculty", tags=["Faculty"])


# ============================================================================
# MY ASSIGNMENTS — returns ONLY what this faculty is assigned to teach
# ============================================================================

@router.get("/me")
def get_my_profile(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    faculty = db.query(Faculty).filter(Faculty.user_id == current_user['user_id']).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty not found")
    dept = db.query(Department).filter(Department.code == faculty.department).first()
    return {
        "faculty_id": faculty.id,
        "full_name": faculty.full_name,
        "employee_id": faculty.employee_id,
        "department": dept.name if dept else faculty.department,
        "phone_number": faculty.phone_number,
        "email": faculty.email,
    }


@router.get("/my-departments")
def get_my_departments(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Distinct departments this faculty teaches (from assigned_classes)."""
    if current_user['role'] != 'faculty':
        raise HTTPException(status_code=403, detail="Faculty access required")

    faculty = db.query(Faculty).filter(Faculty.user_id == current_user['user_id']).first()
    if not faculty:
        return []

    # ✅ Raw SQL to bypass SQLAlchemy column cache bug
    from sqlalchemy import text
    raw = db.execute(
        text("SELECT assigned_classes FROM faculty WHERE id = :id"),
        {"id": faculty.id}
    ).fetchone()
    assigned_classes = raw[0] if raw else None

    if not assigned_classes:
        return []

    try:
        assignments = json.loads(assigned_classes)
    except Exception:
        return []

    seen = set()  # ✅ Fix: was missing, caused NameError
    result = []
    for a in assignments:
        code = a.get("department")
        if code and code not in seen:
            seen.add(code)
            dept = db.query(Department).filter(Department.code == code).first()
            if dept:
                result.append({"id": dept.id, "name": dept.name, "code": dept.code})
    return result


@router.get("/my-classes")
def get_my_classes(
    department_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Classes this faculty is assigned to, filtered by department_id if provided."""
    if current_user['role'] != 'faculty':
        raise HTTPException(status_code=403, detail="Faculty access required")

    faculty = db.query(Faculty).filter(Faculty.user_id == current_user['user_id']).first()
    if not faculty:
        return []

    # ✅ Raw SQL to bypass SQLAlchemy column cache bug
    from sqlalchemy import text
    raw = db.execute(
        text("SELECT assigned_classes FROM faculty WHERE id = :id"),
        {"id": faculty.id}
    ).fetchone()
    assigned_classes = raw[0] if raw else None

    if not assigned_classes:
        return []

    try:
        assignments = json.loads(assigned_classes)
    except Exception:
        return []

    result = []
    for a in assignments:
        dept = db.query(Department).filter(Department.code == a.get("department")).first()
        if not dept:
            continue
        if department_id and dept.id != department_id:
            continue

        cls = db.query(ClassModel).filter(
            ClassModel.department_id == dept.id,
            ClassModel.year == a.get("year"),
            ClassModel.section == a.get("section"),
        ).first()

        if cls:
            student_count = db.query(Student).filter(
                Student.department == dept.code,
                Student.year == cls.year,
                Student.section == cls.section,
            ).count()
            result.append({
                "id": cls.id,
                "year": cls.year,
                "section": cls.section,
                "current_semester": cls.current_semester,
                "department_id": dept.id,
                "department_code": dept.code,
                "department_name": dept.name,
                "total_students": student_count,
                "display": f"{cls.year} - Section {cls.section}",
            })
    return result


# ============================================================================
# QR ONBOARDING
# ============================================================================

@router.post("/generate-qr")
def generate_faculty_qr(payload: dict, db: Session = Depends(get_db)):
    """Admin generates QR for faculty onboarding"""

    faculty_id = payload.get("faculty_id")
    if not faculty_id:
        raise HTTPException(status_code=400, detail="faculty_id is required")

    faculty = db.query(Faculty).filter(Faculty.id == faculty_id).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty not found")

    token = secrets.token_urlsafe(32)

    onboarding = OnboardingToken(
        token=token,
        role="faculty",
        target_id=faculty_id,
        expiry_time=datetime.utcnow() + timedelta(minutes=10),
        used=False,
    )

    db.add(onboarding)
    db.commit()

    qr_data = json.dumps({
        "faculty_id": faculty_id,
        "token": token,
    })

    return {
        "qr_data": qr_data,
        "token": token,
        "faculty_id": faculty_id,
        "expires_in_minutes": 10,
    }


@router.post("/validate-qr")
def validate_faculty_qr(payload: dict, db: Session = Depends(get_db)):
    """Called when faculty scans onboarding QR"""

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

    dept = db.query(Department).filter(
        Department.code.ilike(faculty.department)
    ).first()
    return {
        "faculty_id": faculty.id,
        "full_name": faculty.full_name,
        "employee_id": faculty.employee_id,
        "department": dept.name if dept else faculty.department,
        "phone_number": faculty.phone_number,
        "email": faculty.email,
    }


@router.post("/set-password")
def set_faculty_password(payload: dict, db: Session = Depends(get_db)):
    """Faculty sets password after scanning onboarding QR"""
    from passlib.hash import bcrypt

    faculty_id = payload.get("faculty_id")
    password = payload.get("password")

    if not faculty_id or not password:
        raise HTTPException(status_code=400, detail="faculty_id and password are required")

    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

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

    return {
        "message": "Password set successfully",
        "user_id": user_id,
        "faculty_id": faculty.id,
        "full_name": faculty.full_name,
        "department": faculty.department,
        "email": faculty.email,
        "role": "faculty",
    }


# ============================================================================
# DASHBOARD STATS
# ============================================================================

@router.get("/{faculty_id}/stats")
def get_faculty_stats(
    faculty_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user['role'] not in ['faculty', 'admin']:
        raise HTTPException(status_code=403, detail="Access denied")

    total_sessions = db.query(AttendanceSession).filter(
        AttendanceSession.faculty_id == faculty_id
    ).count()

    today = datetime.utcnow().date()

    sessions_today = db.query(AttendanceSession).filter(
        AttendanceSession.faculty_id == faculty_id,
        func.date(AttendanceSession.started_at) == today
    ).count()

    from sqlalchemy import text
    raw = db.execute(
        text("SELECT assigned_classes FROM faculty WHERE id = :id"),
        {"id": faculty_id}
    ).fetchone()

    total_students = 0
    if raw and raw[0]:
        try:
            assignments = json.loads(raw[0])
            for a in assignments:
                dept = db.query(Department).filter(
                    Department.code == a.get("department")
                ).first()
                if dept:
                    total_students += db.query(Student).filter(
                        Student.department.ilike(a.get("department")),
                        Student.year == a.get("year"),
                        Student.section == a.get("section"),
                    ).count()
        except Exception:
            total_students = 0

    # Only count attendance for THIS faculty's sessions
    faculty_session_ids = [
        s.id for s in db.query(AttendanceSession).filter(
            AttendanceSession.faculty_id == faculty_id,
            AttendanceSession.status == "ended",
        ).all()
    ]

    total_present = 0
    total_records = 0
    avg_attendance = 0

    if faculty_session_ids:
        total_present = db.query(Attendance).filter(
            Attendance.session_id.in_(faculty_session_ids),
            Attendance.status == "present"
        ).count()

        ended_sessions_count = len(faculty_session_ids)
        total_possible = ended_sessions_count * total_students

        if total_possible > 0:
            avg_attendance = round((total_present / total_possible) * 100, 2)

    return {
        "total_sessions": total_sessions,
        "sessions_today": sessions_today,
        "total_students": total_students,
        "average_attendance": avg_attendance,
    }

@router.get("/{faculty_id}/active-sessions")
def get_active_sessions(faculty_id: int, db: Session = Depends(get_db)):
    sessions = db.query(AttendanceSession).filter(
        AttendanceSession.faculty_id == faculty_id,
        AttendanceSession.status == "active"
    ).all()

    result = []
    for s in sessions:
        count = db.query(Attendance).filter(Attendance.session_id == s.id).count()
        subject = db.query(Subject).filter(Subject.id == s.subject_id).first()
        cls = db.query(ClassModel).filter(ClassModel.id == s.class_id).first()
        result.append({
            "session_id": s.id,
            "subject_name": subject.name if subject else "Unknown",
            "class_name": f"{cls.year} Sec {cls.section}" if cls else "Unknown",
            "started_at": s.started_at.isoformat(),
            "students_present": count,
        })
    return result


@router.get("/{faculty_id}/sessions-by-period")
def get_sessions_by_period(
    faculty_id: int,
    period: str = "all",
    db: Session = Depends(get_db)
):
    from datetime import timedelta
    today = datetime.utcnow().date()
    yesterday = today - timedelta(days=1)

    query = db.query(AttendanceSession).filter(
        AttendanceSession.faculty_id == faculty_id
    )

    if period == "today":
        query = query.filter(func.date(AttendanceSession.started_at) == today)
    elif period == "yesterday":
        query = query.filter(func.date(AttendanceSession.started_at) == yesterday)

    sessions = query.order_by(AttendanceSession.started_at.desc()).all()

    result = []
    for s in sessions:
        count = db.query(Attendance).filter(Attendance.session_id == s.id).count()
        subject = db.query(Subject).filter(Subject.id == s.subject_id).first()
        cls = db.query(ClassModel).filter(ClassModel.id == s.class_id).first()
        result.append({
            "session_id": s.id,
            "subject_name": subject.name if subject else "Unknown",
            "class_name": f"{cls.year} Sec {cls.section}" if cls else "Unknown",
            "status": s.status,
            "started_at": s.started_at.isoformat(),
            "ended_at": s.ended_at.isoformat() if s.ended_at else None,
            "students_present": count,
        })
    return result


@router.get("/{faculty_id}/recent-sessions")
def get_recent_sessions(faculty_id: int, db: Session = Depends(get_db)):

    sessions = db.query(AttendanceSession).filter(
        AttendanceSession.faculty_id == faculty_id
    ).order_by(
        AttendanceSession.started_at.desc()
    ).limit(10).all()

    result = []
    for s in sessions:
        count = db.query(Attendance).filter(
            Attendance.session_id == s.id
        ).count()

        result.append({
            "session_id": s.id,
            "class_id": s.class_id,
            "subject_id": s.subject_id,
            "status": s.status,
            "started_at": s.started_at,
            "ended_at": s.ended_at,
            "attendance_count": count,
        })

    return result