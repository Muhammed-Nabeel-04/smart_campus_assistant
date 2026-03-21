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


def _ensure_class_with_subjects(db: Session, year: str, dept_code: str, section: str) -> ClassModel:
    """
    Idempotently creates: Department → ClassModel → ClassSubject links.
    Uses subjects added by HOD instead of hardcoded templates.
    """
    # 1. Find or create department
    dept = db.query(Department).filter(Department.code == dept_code).first()
    if not dept:
        dept = Department(name=dept_code, code=dept_code)
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
            current_semester="Semester 1",
        )
        db.add(cls)
        db.commit()
        db.refresh(cls)

    # 3. Link subjects only if this class has none yet
    existing_links = db.query(ClassSubject).filter(
        ClassSubject.class_id == cls.id
    ).count()

    if existing_links == 0:
        # ✅ Get subjects from DB added by HOD for this dept + year
        hod_subjects = db.query(Subject).filter(
            Subject.department == dept_code,
            Subject.year == year,
        ).all()

        for sub in hod_subjects:
            db.add(ClassSubject(
                class_id=cls.id,
                subject_id=sub.id,
                semester=f"Semester {sub.semester}" if sub.semester else "Semester 1"
            ))

        if hod_subjects:
            db.commit()

        # Update class current_semester from first subject
        if hod_subjects and hod_subjects[0].semester:
            cls.current_semester = f"Semester {hod_subjects[0].semester}"
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
    
    if current_user['role'] not in ['admin', 'principal']:
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

    # ✅ Get HOD's department from DB (dynamic, not hardcoded)
    hod_dept = None
    dept = db.query(Department).filter(
        Department.hod_user_id == current_user['user_id']
    ).first()
    if dept:
        hod_dept = dept.code

    # Filter by department if found
    if hod_dept:
        faculty_list = db.query(Faculty).filter(
            Faculty.department.ilike(hod_dept)
        ).all()
    else:
        faculty_list = db.query(Faculty).all()
    
    result = []
    for fac in faculty_list:
        if fac.user_id == current_user['user_id']:
            continue
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
            "department": db.query(Department).filter(Department.code.ilike(fac.department)).first().name if db.query(Department).filter(Department.code.ilike(fac.department)).first() else fac.department,
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

    # Delete session token
    from app.models.session_token import SessionToken
    if faculty.user_id:
        session = db.query(SessionToken).filter(
            SessionToken.user_id == faculty.user_id
        ).first()
        if session:
            db.delete(session)

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
        "expires_in": 60  # seconds
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
    period: str = "today",
    department_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get system-wide reports"""
    
    if current_user['role'] not in ['admin', 'principal']:
        raise HTTPException(status_code=403, detail="Admin access required")

    # ✅ HOD sees only their department
    if current_user['role'] == 'admin':
        hod_dept = db.query(Department).filter(
            Department.hod_user_id == current_user['user_id']
        ).first()
        if hod_dept:
            department_id = hod_dept.id

    # Calculate date range based on period
    from datetime import timedelta
    today = date.today()
    if period == "today":
        start_date = today
    elif period == "week":
        start_date = today - timedelta(days=7)
    else:  # month
        start_date = today - timedelta(days=30)

    start_datetime = datetime(start_date.year, start_date.month, start_date.day, 0, 0, 0)

    # ✅ Get class IDs for the department filter
    if department_id:
        dept_classes = db.query(ClassModel).filter(
            ClassModel.department_id == department_id
        ).all()
        filtered_class_ids = [c.id for c in dept_classes]
        dept_obj = db.query(Department).filter(Department.id == department_id).first()
        dept_code = dept_obj.code if dept_obj else None
    else:
        filtered_class_ids = None
        dept_code = None
    
    # Attendance sessions count
    session_query = db.query(AttendanceSession).filter(
        AttendanceSession.started_at >= start_datetime.isoformat()
    )
    if filtered_class_ids:
        session_query = session_query.filter(
            AttendanceSession.class_id.in_(filtered_class_ids)
        )
    total_sessions = session_query.count()
    
    # Attendance stats
    ended_query = db.query(AttendanceSession).filter(
        AttendanceSession.started_at >= start_datetime.isoformat(),
        AttendanceSession.status == 'ended'
    )
    if filtered_class_ids is not None:
        ended_query = ended_query.filter(
            AttendanceSession.class_id.in_(filtered_class_ids)
        )
    ended_sessions = ended_query.all()
    ended_session_ids = [s.id for s in ended_sessions]

    if ended_session_ids:
        total_present = db.query(Attendance).filter(
            Attendance.session_id.in_(ended_session_ids),
            Attendance.status == 'present'
        ).count()
    else:
        total_present = 0

    # Also count manual entries (session_id=0)
    if dept_code:
        dept_student_ids = [
            s.id for s in db.query(Student).filter(
                Student.department.ilike(dept_code)
            ).all()
        ]
    else:
        dept_student_ids = [s.id for s in db.query(Student).all()]

    manual_present = db.query(Attendance).filter(
        Attendance.session_id == 0,
        Attendance.status == 'present',
        Attendance.student_id.in_(dept_student_ids),
        Attendance.timestamp >= start_datetime.isoformat(),
    ).count() if dept_student_ids else 0

    total_present += manual_present

    total_possible = 0
    for s in ended_sessions:
        cls = db.query(ClassModel).filter(ClassModel.id == s.class_id).first()
        if cls:
            dept = db.query(Department).filter(Department.id == cls.department_id).first()
            if dept:
                count = db.query(Student).filter(
                    Student.department.ilike(dept.code),
                    Student.year == cls.year,
                    Student.section == cls.section,
                ).count()
                total_possible += count

    total_absent = max(total_possible - total_present, 0)
    avg_attendance = round((total_present / total_possible * 100), 1) if total_possible > 0 else 0
    
    # Complaints stats — filter by dept students if needed
    complaint_query_base = db.query(Complaint).filter(
        Complaint.created_at >= start_datetime
    )
    if dept_code:
        dept_student_ids = [
            s.id for s in db.query(Student).filter(
                Student.department.ilike(dept_code)
            ).all()
        ]
        complaint_query_base = complaint_query_base.filter(
            Complaint.student_id.in_(dept_student_ids)
        ) if dept_student_ids else complaint_query_base.filter(False)

    complaints_resolved = complaint_query_base.filter(
        Complaint.status == 'resolved'
    ).count()
    complaints_pending = complaint_query_base.filter(
        Complaint.status == 'pending'
    ).count()
    
    # ✅ Calculate top department by attendance
    top_department = "N/A"
    lowest_class = "N/A"

    try:
        dept_attendance = {}
        all_depts = db.query(Department).all()

        for dept in all_depts:
            classes = db.query(ClassModel).filter(
                ClassModel.department_id == dept.id
            ).all()
            class_ids = [c.id for c in classes]
            if not class_ids:
                continue

            dept_sessions = db.query(AttendanceSession).filter(
                AttendanceSession.class_id.in_(class_ids),
                AttendanceSession.started_at >= start_datetime.isoformat(),
                AttendanceSession.status == 'ended'
            ).all()
            session_ids = [s.id for s in dept_sessions]
            if not session_ids:
                continue

            present = db.query(Attendance).filter(
                Attendance.session_id.in_(session_ids),
                Attendance.status == 'present'
            ).count()

            # Total possible = sessions × students in each class
            total_possible_dept = 0
            for cls in classes:
                if cls.id not in [s.class_id for s in dept_sessions]:
                    continue
                cls_student_count = db.query(Student).filter(
                    Student.department.ilike(dept.code),
                    Student.year == cls.year,
                    Student.section == cls.section,
                ).count()
                cls_session_count = sum(1 for s in dept_sessions if s.class_id == cls.id)
                total_possible_dept += cls_student_count * cls_session_count

            if total_possible_dept > 0:
                dept_attendance[dept.name] = round(present / total_possible_dept * 100, 1)

        if dept_attendance:
            max_pct = max(dept_attendance.values())
            top_depts = [d for d, p in dept_attendance.items() if p == max_pct]
            top_department = ", ".join(top_depts)

           # Lowest attendance classes
            lowest_pct = 101
            lowest_classes = []
            for dept in all_depts:
                classes = db.query(ClassModel).filter(
                    ClassModel.department_id == dept.id
                ).all()
                for cls in classes:
                    cls_sessions = db.query(AttendanceSession).filter(
                        AttendanceSession.class_id == cls.id,
                        AttendanceSession.started_at >= start_datetime.isoformat(),
                        AttendanceSession.status == 'ended'
                    ).all()
                    cls_session_ids = [s.id for s in cls_sessions]
                    if not cls_session_ids:
                        continue
                    p = db.query(Attendance).filter(
                        Attendance.session_id.in_(cls_session_ids),
                        Attendance.status == 'present'
                    ).count()
                    student_count = db.query(Student).filter(
                        Student.department.ilike(dept.code),
                        Student.year == cls.year,
                        Student.section == cls.section,
                    ).count()
                    t = len(cls_session_ids) * student_count
                    if t > 0:
                        pct = round(p / t * 100, 1)
                        if pct < lowest_pct:
                            lowest_pct = pct
                            lowest_classes = [f"{dept.name} {cls.year} Sec {cls.section} ({pct}%)"]
                        elif pct == lowest_pct:
                            lowest_classes.append(f"{dept.name} {cls.year} Sec {cls.section} ({pct}%)")

            # Strip percentage from display
            lowest_classes_clean = [c.rsplit(' (', 1)[0] for c in lowest_classes]
            lowest_class = ", ".join(lowest_classes_clean) if lowest_classes_clean else "N/A"
    except Exception:
        pass

    return {
        "period": period,
        "total_attendance_sessions": total_sessions,
        "avg_attendance_percentage": round(avg_attendance, 1),
        "total_students_present": total_present,
        "total_students_absent": total_absent,
        "complaints_resolved": complaints_resolved,
        "complaints_pending": complaints_pending,
        "top_department": top_department,
        "lowest_attendance_class": lowest_class,
    }