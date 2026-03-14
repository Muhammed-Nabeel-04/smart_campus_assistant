# File: campus_assistant/backend/app/routes/admin_routes.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date
import json

from app.services.deps import get_db, get_current_user
from app.models.user import User
from app.models.faculty import Faculty
from app.models.student import Student
from app.models.department import Department
from app.models.complaint import Complaint
from app.models.attendance_session import AttendanceSession
from app.models.attendance import Attendance
from app.models.class_model import ClassModel
from app.models.subject import Subject
from app.models.class_subject import ClassSubject

router = APIRouter(prefix="/admin", tags=["Admin"])


# ============================================================================
# SUBJECT TEMPLATES — auto-created per dept/year when admin assigns a class
# ============================================================================

DEPT_NAMES = {
    "CSE": "Computer Science Engineering",
    "AI":  "Artificial Intelligence & Data Science",
    "BME": "Biomedical Engineering",
    "ECE": "Electronics and Communication",
    "IT":  "Information Technology",
    "MECH": "Mechanical Engineering",
    "CIVIL": "Civil Engineering",
}

YEAR_TO_SEMESTER = {
    "1st Year": "Semester 1",
    "2nd Year": "Semester 3",
    "3rd Year": "Semester 5",
    "4th Year": "Semester 7",
}

# (name, code_suffix, credits, type)
_SUBJ = {
    "CSE": {
        "1st Year": [
            ("Engineering Mathematics I",   "MA101",  4, "Theory"),
            ("Engineering Physics",         "PH101",  3, "Theory"),
            ("Programming in C",             "CS101",  3, "Theory"),
            ("Programming Lab",              "CS101L", 2, "Lab"),
            ("Basic Electronics",            "EC101",  3, "Theory"),
            ("Technical English",            "EN101",  2, "Theory"),
        ],
        "2nd Year": [
            ("Data Structures",              "CS201",  4, "Theory"),
            ("Data Structures Lab",          "CS201L", 2, "Lab"),
            ("Database Management Systems",  "CS202",  3, "Theory"),
            ("DBMS Lab",                     "CS202L", 2, "Lab"),
            ("Object Oriented Programming",  "CS203",  3, "Theory"),
            ("Discrete Mathematics",         "MA201",  4, "Theory"),
        ],
        "3rd Year": [
            ("Operating Systems",            "CS301",  4, "Theory"),
            ("Computer Networks",            "CS302",  3, "Theory"),
            ("Software Engineering",         "CS303",  3, "Theory"),
            ("Web Technologies",             "CS304",  3, "Theory"),
            ("Networks Lab",                 "CS302L", 2, "Lab"),
        ],
        "4th Year": [
            ("Machine Learning",             "CS401",  4, "Theory"),
            ("Artificial Intelligence",      "CS402",  3, "Theory"),
            ("Cloud Computing",              "CS403",  3, "Theory"),
            ("Project Work",                 "CS404P", 6, "Project"),
        ],
    },
    "AI": {
        "1st Year": [
            ("Engineering Mathematics I",    "MA101",  4, "Theory"),
            ("Introduction to AI",           "AI101",  3, "Theory"),
            ("Python Programming",           "AI102",  3, "Theory"),
            ("Python Lab",                   "AI102L", 2, "Lab"),
            ("Data Science Basics",          "AI103",  3, "Theory"),
        ],
        "2nd Year": [
            ("Machine Learning Fundamentals","AI201",  4, "Theory"),
            ("Data Structures",              "CS201",  4, "Theory"),
            ("Database Systems",             "AI202",  3, "Theory"),
            ("Statistics for AI",            "AI203",  3, "Theory"),
            ("ML Lab",                       "AI201L", 2, "Lab"),
        ],
        "3rd Year": [
            ("Deep Learning",                "AI301",  4, "Theory"),
            ("Natural Language Processing",  "AI302",  3, "Theory"),
            ("Computer Vision",              "AI303",  3, "Theory"),
            ("AI Applications Lab",          "AI301L", 2, "Lab"),
        ],
        "4th Year": [
            ("Reinforcement Learning",       "AI401",  4, "Theory"),
            ("AI Ethics and Governance",     "AI402",  2, "Theory"),
            ("Advanced Deep Learning",       "AI403",  3, "Theory"),
            ("Project Work",                 "AI404P", 6, "Project"),
        ],
    },
    "BME": {
        "1st Year": [
            ("Engineering Mathematics I",    "MA101",  4, "Theory"),
            ("Biology for Engineers",        "BM101",  3, "Theory"),
            ("Engineering Physics",          "PH101",  3, "Theory"),
            ("Basic Electronics",            "EC101",  3, "Theory"),
            ("Human Anatomy",                "BM102",  3, "Theory"),
        ],
        "2nd Year": [
            ("Biomedical Instrumentation",   "BM201",  4, "Theory"),
            ("Signals and Systems",          "EC301",  4, "Theory"),
            ("Physiology",                   "BM202",  3, "Theory"),
            ("Medical Imaging",              "BM203",  3, "Theory"),
            ("Biomedical Lab",               "BM201L", 2, "Lab"),
        ],
        "3rd Year": [
            ("Medical Device Design",        "BM301",  4, "Theory"),
            ("Biomechanics",                 "BM302",  3, "Theory"),
            ("Rehabilitation Engineering",   "BM303",  3, "Theory"),
            ("Clinical Engineering Lab",     "BM301L", 2, "Lab"),
        ],
        "4th Year": [
            ("Telemedicine",                 "BM401",  3, "Theory"),
            ("Healthcare Systems",           "BM402",  3, "Theory"),
            ("Biomedical Signal Processing", "BM403",  4, "Theory"),
            ("Project Work",                 "BM404P", 6, "Project"),
        ],
    },
}

_DEFAULT_SUBJ = {
    "1st Year": [
        ("Engineering Mathematics I",    "MA101",  4, "Theory"),
        ("Engineering Physics",          "PH101",  3, "Theory"),
        ("Engineering Chemistry",        "CH101",  3, "Theory"),
        ("Programming in C",             "CS101",  3, "Theory"),
        ("Technical English",            "EN101",  2, "Theory"),
    ],
    "2nd Year": [
        ("Engineering Mathematics II",   "MA201",  4, "Theory"),
        ("Data Structures",              "CS201",  4, "Theory"),
        ("Analog Electronics",           "EC201",  3, "Theory"),
        ("Digital Electronics",          "EC202",  3, "Theory"),
        ("Lab Work",                     "LAB201", 2, "Lab"),
    ],
    "3rd Year": [
        ("Signals and Systems",          "EC301",  4, "Theory"),
        ("Microprocessors",              "EC302",  3, "Theory"),
        ("Control Systems",              "EE301",  3, "Theory"),
        ("Professional Ethics",          "HU301",  2, "Theory"),
        ("Advanced Lab",                 "LAB301", 2, "Lab"),
    ],
    "4th Year": [
        ("Embedded Systems",             "EC401",  3, "Theory"),
        ("Industrial Management",        "HU401",  2, "Theory"),
        ("Advanced Topics",              "ADV401", 3, "Theory"),
        ("Project Work",                 "PRJ401", 6, "Project"),
    ],
}


def _ensure_class_with_subjects(db: Session, year: str, dept_code: str, section: str) -> ClassModel:
    """
    Idempotently creates: Department → ClassModel → Subjects → ClassSubject links.
    Safe to call multiple times — skips anything that already exists.
    Returns the ClassModel.
    """
    # 1. Find or create department
    dept = db.query(Department).filter(Department.code == dept_code).first()
    if not dept:
        dept = Department(
            name=DEPT_NAMES.get(dept_code, dept_code),
            code=dept_code
        )
        db.add(dept)
        db.commit()
        db.refresh(dept)

    # 2. Find or create class
    cls = db.query(ClassModel).filter(
        ClassModel.department_id == dept.id,
        ClassModel.year == year,
        ClassModel.section == section,
    ).first()
    if not cls:
        cls = ClassModel(
            department_id=dept.id,
            year=year,
            section=section,
            current_semester=YEAR_TO_SEMESTER.get(year, "Semester 1"),
        )
        db.add(cls)
        db.commit()
        db.refresh(cls)

    # 3. Link subjects only if this class has none yet
    existing_links = db.query(ClassSubject).filter(
        ClassSubject.class_id == cls.id
    ).count()

    if existing_links == 0:
        semester  = YEAR_TO_SEMESTER.get(year, "Semester 1")
        templates = _SUBJ.get(dept_code, _DEFAULT_SUBJ).get(year, _DEFAULT_SUBJ.get(year, []))

        for name, code, credits, stype in templates:
            sub = db.query(Subject).filter(Subject.code == code).first()
            if not sub:
                sub = Subject(name=name, code=code, credits=credits, type=stype)
                db.add(sub)
                db.commit()
                db.refresh(sub)

            db.add(ClassSubject(class_id=cls.id, subject_id=sub.id, semester=semester))

        db.commit()

    return cls

# ============================================================================
# DASHBOARD & STATS
# ============================================================================

@router.get("/stats")
def get_admin_stats(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get admin dashboard statistics"""
    
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    
    # Count totals
    total_faculty = db.query(Faculty).count()
    total_students = db.query(Student).count()
    total_departments = db.query(Department).count()
    pending_complaints = db.query(Complaint).filter(
        Complaint.status == 'pending'
    ).count()
    
    # Active sessions today
    today = date.today()
    active_sessions = db.query(AttendanceSession).filter(
        func.date(AttendanceSession.started_at) == today,
        AttendanceSession.status == 'active'
    ).count()
    
    # Today's attendance percentage
    total_present = db.query(Attendance).filter(
        func.date(Attendance.timestamp) == today,
        Attendance.status == 'present'
    ).count()
    
    total_absent = db.query(Attendance).filter(
        func.date(Attendance.timestamp) == today,
        Attendance.status == 'absent'
    ).count()
    
    total_attendance = total_present + total_absent
    today_attendance = (total_present / total_attendance * 100) if total_attendance > 0 else 0
    
    return {
        "total_faculty": total_faculty,
        "total_students": total_students,
        "total_departments": total_departments,
        "pending_complaints": pending_complaints,
        "active_sessions": active_sessions,
        "today_attendance": round(today_attendance, 1),
        "total_present": total_present,
        "total_absent": total_absent,
    }


# ============================================================================
# FACULTY MANAGEMENT
# ============================================================================

class TeachingAssignment(BaseModel):
    year: str        # "1st Year" | "2nd Year" | "3rd Year" | "4th Year"
    department: str  # "CSE" | "AI" | "BME"
    section: str     # "A" | "B" | "C" ...

class CreateFacultyRequest(BaseModel):
    name: str
    email: str
    employee_id: str
    department: str
    phone: Optional[str] = None
    teaching_assignments: Optional[List[TeachingAssignment]] = []

class UpdateFacultyRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    department: Optional[str] = None
    phone: Optional[str] = None
    teaching_assignments: Optional[List[TeachingAssignment]] = None


@router.get("/faculty")
def get_all_faculty(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get all faculty members - filtered by HOD's department"""
    
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")

    # ✅ Get HOD's department from their email
    hod_user = db.query(User).filter(User.id == current_user['user_id']).first()
    hod_dept = None
    if hod_user:
        prefix = hod_user.email.split('@')[0].lower()
        dept_map = {
            'aids': 'AIDS', 'aids.hod': 'AIDS',
            'cse': 'CSE', 'cse.hod': 'CSE',
            'ece': 'ECE', 'ece.hod': 'ECE',
            'mech': 'MECH', 'mech.hod': 'MECH',
            'civil': 'CIVIL', 'civil.hod': 'CIVIL',
            'it': 'IT', 'it.hod': 'IT',
        }
        hod_dept = dept_map.get(prefix)

    # Filter by department if detected
    if hod_dept:
        faculty_list = db.query(Faculty).filter(
            Faculty.department == hod_dept
        ).all()
    else:
        faculty_list = db.query(Faculty).all()
    
    result = []
    for fac in faculty_list:
        user = db.query(User).filter(User.id == fac.user_id).first()
        assignments = []
        # ✅ FIX: Direct SQL query to bypass SQLAlchemy model cache
        raw = db.execute(
            __import__('sqlalchemy').text(
                "SELECT assigned_classes FROM faculty WHERE id = :id"
            ),
            {"id": fac.id}
        ).fetchone()
        
        assigned_classes = raw[0] if raw else None
        
        if assigned_classes:
            try:
                assignments = json.loads(assigned_classes)
            except Exception:
                assignments = []
                
        result.append({
            "id": fac.id,
            "user_id": fac.user_id,
            "name": fac.full_name,
            "email": fac.email or (user.email if user else None),
            "employee_id": fac.employee_id,
            "department": fac.department,
            "phone": fac.phone_number,
            "teaching_assignments": assignments,
            "created_at": fac.created_at.isoformat() if fac.created_at else None,
        })
    
    return result


@router.post("/faculty")
def create_faculty(
    payload: CreateFacultyRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Create new faculty member (admin only)"""
    
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    
    # Check if email already exists
    existing_user = db.query(User).filter(User.email == payload.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Check if employee ID exists
    existing_faculty = db.query(Faculty).filter(
        Faculty.employee_id == payload.employee_id
    ).first()
    if existing_faculty:
        raise HTTPException(status_code=400, detail="Employee ID already exists")
    
    # Create user account (no password yet - will be set via QR)
    new_user = User(
        name=payload.name,
        email=payload.email,
        password="",  # Will be set during QR onboarding
        role="faculty"
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Process teaching assignments — auto-creates depts, classes, subjects
    print(f"DEBUG assignments received: {payload.teaching_assignments}")
    assignments_list = []
    if payload.teaching_assignments:
        for ta in payload.teaching_assignments:
            _ensure_class_with_subjects(db, ta.year, ta.department, ta.section)
            assignments_list.append({
                "year": ta.year,
                "department": ta.department,
                "section": ta.section,
            })

    assigned_json = json.dumps(assignments_list) if assignments_list else None

    new_faculty = Faculty(
        user_id=new_user.id,
        full_name=payload.name,
        employee_id=payload.employee_id,
        department=payload.department,
        email=payload.email,
        phone_number=payload.phone,
    )
    db.add(new_faculty)
    db.commit()
    db.refresh(new_faculty)

    # Update assigned_classes directly via SQL to bypass SQLAlchemy model cache
    db.execute(
        __import__('sqlalchemy').text(
            "UPDATE faculty SET assigned_classes = :ac WHERE id = :id"
        ),
        {"ac": assigned_json, "id": new_faculty.id}
    )
    db.commit()
    
    return {
        "message": "Faculty created successfully",
        "faculty_id": new_faculty.id,
        "user_id": new_user.id
    }


@router.put("/faculty/{faculty_id}")
def update_faculty(
    faculty_id: int,
    payload: UpdateFacultyRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Update faculty member details"""
    
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    
    faculty = db.query(Faculty).filter(Faculty.id == faculty_id).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty not found")
    
    # Update fields if provided
    if payload.name:
        faculty.full_name = payload.name
        # Also update user name
        user = db.query(User).filter(User.id == faculty.user_id).first()
        if user:
            user.name = payload.name
    
    if payload.email:
        faculty.email = payload.email
    
    if payload.department:
        faculty.department = payload.department
    
    if payload.phone:
        faculty.phone_number = payload.phone
    
# Update teaching assignments if provided
    if payload.teaching_assignments is not None:
        assignments_list = []
        for ta in payload.teaching_assignments:
            _ensure_class_with_subjects(db, ta.year, ta.department, ta.section)
            assignments_list.append({
                "year": ta.year,
                "department": ta.department,
                "section": ta.section,
            })

        # ✅ End active sessions for classes that were removed
        new_class_keys = {
            f"{a['department']}_{a['year']}_{a['section']}"
            for a in assignments_list
        }

        old_assignments = []
        raw = db.execute(
            __import__('sqlalchemy').text(
                "SELECT assigned_classes FROM faculty WHERE id = :id"
            ),
            {"id": faculty_id}
        ).fetchone()
        if raw and raw[0]:
            try:
                old_assignments = json.loads(raw[0])
            except Exception:
                old_assignments = []

        for old in old_assignments:
            key = f"{old['department']}_{old['year']}_{old['section']}"
            if key not in new_class_keys:
                # This class was removed — find and end active sessions
                dept = db.query(Department).filter(
                    Department.code == old['department']
                ).first()
                if dept:
                    cls = db.query(ClassModel).filter(
                        ClassModel.department_id == dept.id,
                        ClassModel.year == old['year'],
                        ClassModel.section == old['section'],
                    ).first()
                    if cls:
                        active_sessions = db.query(AttendanceSession).filter(
                            AttendanceSession.faculty_id == faculty_id,
                            AttendanceSession.class_id == cls.id,
                            AttendanceSession.status == "active"
                        ).all()
                        for session in active_sessions:
                            session.status = "ended"
                            session.ended_at = datetime.utcnow()

        db.execute(
            __import__('sqlalchemy').text(
                "UPDATE faculty SET assigned_classes = :ac WHERE id = :id"
            ),
            {"ac": json.dumps(assignments_list), "id": faculty_id}
        )

    faculty.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(faculty)

    return {"message": "Faculty updated successfully"}


@router.delete("/faculty/{faculty_id}")
def delete_faculty(
    faculty_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Delete faculty member"""
    
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    
    faculty = db.query(Faculty).filter(Faculty.id == faculty_id).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty not found")

    # ✅ End all active attendance sessions before deleting
    active_sessions = db.query(AttendanceSession).filter(
        AttendanceSession.faculty_id == faculty_id,
        AttendanceSession.status == "active"
    ).all()
    for session in active_sessions:
        session.status = "ended"
        session.ended_at = datetime.utcnow()
    if active_sessions:
        db.commit()

    # Delete associated user account
    user = db.query(User).filter(User.id == faculty.user_id).first()
    if user:
        db.delete(user)
    
    # Delete faculty record
    db.delete(faculty)
    db.commit()
    
    return {
        "message": "Faculty deleted successfully",
        "sessions_ended": len(active_sessions)
    }


@router.post("/faculty/{faculty_id}/generate-qr")
def generate_faculty_qr(
    faculty_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Generate onboarding QR for faculty"""
    
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    
    from app.models.onboarding_token import OnboardingToken
    import secrets
    from datetime import timedelta
    
    faculty = db.query(Faculty).filter(Faculty.id == faculty_id).first()
    if not faculty:
        raise HTTPException(status_code=404, detail="Faculty not found")
    
    # ✅ Invalidate all previous unused tokens for this faculty
    old_tokens = db.query(OnboardingToken).filter(
        OnboardingToken.target_id == faculty_id,
        OnboardingToken.role == "faculty",
        OnboardingToken.used == False
    ).all()
    for old in old_tokens:
        old.used = True
        old.used_at = datetime.utcnow()
    if old_tokens:
        db.commit()

    # Generate unique token
    token = secrets.token_urlsafe(32)
    
    # Create onboarding token (5-minute expiry)
    qr_token = OnboardingToken(
        token=token,
        role="faculty",
        target_id=faculty_id,
        expiry_time=datetime.utcnow() + timedelta(minutes=1),
        used=False
    )
    
    db.add(qr_token)
    db.commit()
    
    return {
        "token": token,
        "faculty_id": faculty_id,
        "expires_in": 300  # seconds
    }


# ============================================================================
# COMPLAINTS MANAGEMENT
# ============================================================================

class UpdateComplaintRequest(BaseModel):
    status: str
    admin_response: Optional[str] = None


@router.get("/complaints")
def get_all_complaints(
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get all complaints (admin only)"""
    
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    
    query = db.query(Complaint)
    
    if status:
        query = query.filter(Complaint.status == status)
    
    complaints = query.order_by(Complaint.created_at.desc()).all()
    
    result = []
    for complaint in complaints:
        student = db.query(Student).filter(Student.id == complaint.student_id).first()
        result.append({
            "id": complaint.id,
            "student_id": complaint.student_id,
            "student_name": student.full_name if student else "Unknown",
            "category": complaint.category,
            "priority": complaint.priority,
            "title": complaint.title,
            "description": complaint.description,
            "status": complaint.status,
            "admin_response": complaint.admin_response,
            "created_at": complaint.created_at.isoformat(),
            "updated_at": complaint.updated_at.isoformat() if complaint.updated_at else None,
        })
    
    return result


@router.put("/complaints/{complaint_id}")
def update_complaint(
    complaint_id: int,
    payload: UpdateComplaintRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Update complaint status and response"""
    
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
    
    complaint.status = payload.status
    if payload.admin_response:
        complaint.admin_response = payload.admin_response
    
    complaint.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(complaint)
    
    return {"message": "Complaint updated successfully"}


# ============================================================================
# SYSTEM REPORTS
# ============================================================================

@router.get("/reports")
def get_system_reports(
    period: str = "today",  # today, week, month
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get system-wide reports"""
    
    if current_user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    
    # Calculate date range based on period
    today = date.today()
    if period == "today":
        start_date = today
    elif period == "week":
        from datetime import timedelta
        start_date = today - timedelta(days=7)
    else:  # month
        from datetime import timedelta
        start_date = today - timedelta(days=30)
    
    # Attendance sessions count
    total_sessions = db.query(AttendanceSession).filter(
        func.date(AttendanceSession.started_at) >= start_date
    ).count()
    
    # Attendance stats
    total_present = db.query(Attendance).filter(
        func.date(Attendance.timestamp) >= start_date,
        Attendance.status == 'present'
    ).count()
    
    total_absent = db.query(Attendance).filter(
        func.date(Attendance.timestamp) >= start_date,
        Attendance.status == 'absent'
    ).count()
    
    total_attendance = total_present + total_absent
    avg_attendance = (total_present / total_attendance * 100) if total_attendance > 0 else 0
    
    # Complaints stats
    complaints_resolved = db.query(Complaint).filter(
        func.date(Complaint.created_at) >= start_date,
        Complaint.status == 'resolved'
    ).count()
    
    complaints_pending = db.query(Complaint).filter(
        func.date(Complaint.created_at) >= start_date,
        Complaint.status == 'pending'
    ).count()
    
    return {
        "period": period,
        "total_attendance_sessions": total_sessions,
        "avg_attendance_percentage": round(avg_attendance, 1),
        "total_students_present": total_present,
        "total_students_absent": total_absent,
        "complaints_resolved": complaints_resolved,
        "complaints_pending": complaints_pending,
        "top_department": "Computer Science",  # TODO: Calculate from data
        "lowest_attendance_class": "N/A",  # TODO: Calculate from data
    }