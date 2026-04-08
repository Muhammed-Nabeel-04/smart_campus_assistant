from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, date
from app.services.deps import get_db, get_current_user
from app.models.attendance_session import AttendanceSession
from app.models.attendance import Attendance
from app.models.student import Student
from app.models.faculty import Faculty
from app.models.subject import Subject
from app.models.class_subject import ClassSubject
from app.models.department import Department
from app.models.class_model import ClassModel
import secrets


router = APIRouter(prefix="/attendance", tags=["Attendance"])


class StartSessionRequest(BaseModel):
    class_id: int
    subject_id: int
    faculty_id: Optional[int] = None
    duration_minutes: Optional[int] = None  # Auto-end after this many minutes


class ManualAttendanceRecord(BaseModel):
    student_id: int
    status: str
    date: Optional[str] = None


class ManualAttendanceRequest(BaseModel):
    records: List[ManualAttendanceRecord]


# ============================================================================
# SESSIONS
# ============================================================================

@router.post("/sessions/start/")
def start_session(
    payload: StartSessionRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    # Resolve faculty_id: use payload value or extract from JWT
    faculty_id = payload.faculty_id
    if not faculty_id:
        user_id = current_user.get("user_id")
        faculty = db.query(Faculty).filter(Faculty.user_id == user_id).first()
        if not faculty:
            raise HTTPException(status_code=403, detail="Only faculty can start sessions")
        faculty_id = faculty.id

    # Check no active session already running for this class+subject
    existing = db.query(AttendanceSession).filter(
        AttendanceSession.class_id == payload.class_id,
        AttendanceSession.subject_id == payload.subject_id,
        AttendanceSession.status == "active",
    ).first()

    if existing:
        # Get faculty name who started this session
        existing_faculty = db.query(Faculty).filter(
            Faculty.id == existing.faculty_id
        ).first()
        faculty_name = existing_faculty.full_name if existing_faculty else "Another faculty"

        # Check if it's the SAME faculty rejoining
        is_same_faculty = existing.faculty_id == faculty_id

        return {
            "session_id": existing.id,
            "token": existing.token,
            "class_id": existing.class_id,
            "subject_id": existing.subject_id,
            "started_at": existing.started_at.isoformat(),
            "status": "active",
            "is_existing": True,
            "is_same_faculty": is_same_faculty,
            "started_by": faculty_name,
        }

    token = secrets.token_urlsafe(16)

    from datetime import timedelta
    auto_end_at = None
    if payload.duration_minutes:
        auto_end_at = datetime.now() + timedelta(minutes=payload.duration_minutes)

    session = AttendanceSession(
        class_id=payload.class_id,
        subject_id=payload.subject_id,
        faculty_id=faculty_id,
        token=token,
        status="active",
        started_at=datetime.now(),
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    return {
        "session_id": session.id,
        "token": token,
        "class_id": session.class_id,
        "subject_id": session.subject_id,
        "started_at": session.started_at.isoformat(),
        "status": session.status,
    }


@router.post("/sessions/{session_id}/refresh-token/")
def refresh_session_token(session_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user['role'] not in ['faculty', 'admin']:
        raise HTTPException(status_code=403, detail="Access denied")
    session = db.query(AttendanceSession).filter(
        AttendanceSession.id == session_id,
        AttendanceSession.status == "active",
    ).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found or ended")
    session.token = secrets.token_urlsafe(16)
    db.commit()
    return {"token": session.token}


@router.post("/sessions/{session_id}/end/")
def end_session(session_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user['role'] not in ['faculty', 'admin']:
        raise HTTPException(status_code=403, detail="Access denied")

    session = db.query(AttendanceSession).filter(
        AttendanceSession.id == session_id
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    if session.status == "ended":
        raise HTTPException(status_code=400, detail="Session already ended")

    session.status = "ended"
    session.ended_at = datetime.now()
    db.commit()

    # Count how many marked attendance
    count = db.query(Attendance).filter(
        Attendance.session_id == session_id
    ).count()

    return {
        "message": "Session ended successfully",
        "session_id": session_id,
        "total_attendance_marked": count,
        "ended_at": session.ended_at.isoformat(),
    }


@router.get("/session/{session_id}")
def get_session_attendance(session_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user['role'] not in ['faculty', 'admin']:
        raise HTTPException(status_code=403, detail="Access denied")

    session = db.query(AttendanceSession).filter(
        AttendanceSession.id == session_id
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    records = db.query(Attendance).filter(
        Attendance.session_id == session_id
    ).all()

    result = []
    for record in records:
        student = db.query(Student).filter(
            Student.id == record.student_id
        ).first()

        result.append({
            "id": record.id,
            "student_id": record.student_id,
            "full_name": student.full_name if student else "Unknown",
            "register_number": student.register_number if student else "",
            "status": record.status,
            "timestamp": record.timestamp.strftime("%H:%M") if record.timestamp else "",
            "remarks": record.remarks,
        })

    return {
        "session_id": session_id,
        "status": session.status,
        "total": len(result),
        "records": result,
    }


# ============================================================================
# STUDENT MARKS ATTENDANCE BY QR SCAN
# ============================================================================

@router.get("/active-for-student/{student_id}")
def get_active_session_for_student(student_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    """Check if there's an active session for the student's class"""
    if current_user['role'] not in ['student', 'faculty', 'admin']:
        raise HTTPException(status_code=403, detail="Access denied")
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        return {"active": False}

    dept = db.query(Department).filter(
        Department.code.ilike(student.department)
    ).first()
    if not dept:
        return {"active": False}

    cls = db.query(ClassModel).filter(
        ClassModel.department_id == dept.id,
        ClassModel.year == student.year,
        ClassModel.section == student.section,
    ).first()
    if not cls:
        return {"active": False}

    session = db.query(AttendanceSession).filter(
        AttendanceSession.class_id == cls.id,
        AttendanceSession.status == "active",
    ).first()

    if not session:
        return {"active": False}

    subject = db.query(Subject).filter(Subject.id == session.subject_id).first()
    faculty = db.query(Faculty).filter(Faculty.id == session.faculty_id).first()

    return {
        "active": True,
        "session_id": session.id,
        "token": session.token,
        "subject_name": subject.name if subject else "Unknown",
        "faculty_name": faculty.full_name if faculty else "Faculty",
    }


@router.post("/mark/")
def mark_attendance(
    payload: dict,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Student scans QR to mark attendance"""

    token = payload.get("token")
    student_id = payload.get("student_id")

    if not token or not student_id:
        raise HTTPException(status_code=400, detail="token and student_id are required")

    # ✅ Students can only mark their own attendance
    if current_user['role'] == 'student':
        own_student_id = current_user.get('student_id')
        if own_student_id and int(student_id) != int(own_student_id):
            raise HTTPException(
                status_code=403,
                detail="You can only mark your own attendance."
            )

    # Find active session with this token
    session = db.query(AttendanceSession).filter(
        AttendanceSession.token == token,
        AttendanceSession.status == "active",
    ).first()

    if not session:
        raise HTTPException(status_code=400, detail="Invalid or expired session token")

   # ✅ Check student exists and has a valid user account
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    # ✅ Check student's user account still exists (handles deleted students)
    if student.user_id:
        from app.models.user import User
        user = db.query(User).filter(User.id == student.user_id).first()
        if not user:
            raise HTTPException(
                status_code=401,
                detail="Account no longer exists. Please log in again."
            )

   # ✅ Check student belongs to the correct class for this session
    dept = db.query(Department).filter(
        Department.code == student.department
    ).first()
    if not dept:
        raise HTTPException(status_code=403, detail="Student department not found")

   
    cls = db.query(ClassModel).filter(
        ClassModel.id == session.class_id
    ).first()
    if cls and dept:
        if cls.department_id != dept.id or cls.year != student.year or cls.section != student.section:
            raise HTTPException(
                status_code=403,
                detail="You are not enrolled in this class"
            )

    # Check not already marked
    already_marked = db.query(Attendance).filter(
        Attendance.session_id == session.id,
        Attendance.student_id == student_id,
    ).first()

    if already_marked:
        raise HTTPException(status_code=400, detail="Attendance already marked for this session")

    # Mark attendance
    attendance = Attendance(
        session_id=session.id,
        student_id=student_id,
        status="present",
        date=datetime.now().date(),
        timestamp=datetime.now(),
    )

    db.add(attendance)
    db.commit()

    subject = db.query(Subject).filter(Subject.id == session.subject_id).first()

    return {
        "message": "Attendance marked successfully",
        "student_id": student_id,
        "full_name": student.full_name,
        "status": "present",
        "time": datetime.now().strftime("%H:%M"),
        "subject_name": subject.name if subject else "",
    }


# ============================================================================
# REPORTS
# ============================================================================

@router.get("/reports/")
def get_attendance_reports(
    class_id: int,
    subject_id: int,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user['role'] not in ['faculty', 'admin', 'principal']:
        raise HTTPException(status_code=403, detail="Access denied")

    # Get only ENDED sessions filtered by date range
    from datetime import timedelta
    session_query = db.query(AttendanceSession).filter(
        AttendanceSession.class_id == class_id,
        AttendanceSession.subject_id == subject_id,
        AttendanceSession.status == "ended",
    )
    if from_date:
        try:
            session_query = session_query.filter(
                AttendanceSession.started_at >= datetime.strptime(from_date, "%Y-%m-%d")
            )
        except ValueError:
            pass
    if to_date:
        try:
            session_query = session_query.filter(
                AttendanceSession.started_at < datetime.strptime(to_date, "%Y-%m-%d") + timedelta(days=1)
            )
        except ValueError:
            pass
    sessions = session_query.all()

    session_ids = [s.id for s in sessions]
    total_sessions = len(session_ids)

    # Get only students belonging to this class
    cls = db.query(ClassModel).filter(ClassModel.id == class_id).first()
    if not cls:
        return {"total_sessions": total_sessions, "reports": []}

    dept = db.query(Department).filter(Department.id == cls.department_id).first()
    if not dept:
        return {"total_sessions": total_sessions, "reports": []}

    students = db.query(Student).filter(
        Student.department.ilike(dept.code),
        Student.year == cls.year,
        Student.section == cls.section,
    ).all()

    reports = []
    for student in students:
        present = db.query(Attendance).filter(
            Attendance.student_id == student.id,
            Attendance.session_id.in_(session_ids),
            Attendance.status == "present",
        ).count()

        absent = total_sessions - present
        percentage = round((present / total_sessions * 100), 1) if total_sessions > 0 else 0

        reports.append({
            "student_id": student.id,
            "full_name": student.full_name,
            "register_number": student.register_number,
            "present": present,
            "absent": absent,
            "total": total_sessions,
            "percentage": percentage,
        })

    return {
        "total_sessions": total_sessions,
        "reports": reports,
    }


# ============================================================================
# MANUAL ATTENDANCE
# ============================================================================

@router.post("/manual/")
def submit_manual_attendance(
    payload: ManualAttendanceRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    if current_user['role'] not in ['faculty', 'admin']:
        raise HTTPException(status_code=403, detail="Faculty access required")

    # ✅ Check active session exists for the class
    # Get session_id from first record if provided
    session_id = getattr(payload, 'session_id', None)
    if not session_id and payload.records:
        # Try to find active session via student's class
        first_student = db.query(Student).filter(
            Student.id == payload.records[0].student_id
        ).first()
        if first_student:
            dept = db.query(Department).filter(
                Department.code.ilike(first_student.department)
            ).first()
            if dept:
                cls = db.query(ClassModel).filter(
                    ClassModel.department_id == dept.id,
                    ClassModel.year == first_student.year,
                    ClassModel.section == first_student.section,
                ).first()
                if cls:
                    active = db.query(AttendanceSession).filter(
                        AttendanceSession.class_id == cls.id,
                        AttendanceSession.status == "active",
                    ).first()
                    if not active:
                        raise HTTPException(
                            status_code=400,
                            detail="No active session for this class. Start a session first before marking attendance."
                        )

    added = 0

    # Bulk-load all needed data upfront
    record_student_ids = list({r.student_id for r in payload.records})
    students_map = {
        s.id: s for s in db.query(Student).filter(Student.id.in_(record_student_ids)).all()
    }
    all_depts = db.query(Department).all()
    dept_map = {d.code.lower(): d for d in all_depts}
    active_sessions = db.query(AttendanceSession).filter(
        AttendanceSession.status == "active"
    ).all()
    active_session_by_class = {s.class_id: s for s in active_sessions}
    already_marked_set = set()
    if active_sessions:
        active_session_ids = [s.id for s in active_sessions]
        marked_records = db.query(Attendance).filter(
            Attendance.session_id.in_(active_session_ids),
            Attendance.student_id.in_(record_student_ids),
        ).all()
        already_marked_set = {(a.session_id, a.student_id) for a in marked_records}

    for record in payload.records:
        student = students_map.get(record.student_id)
        if not student:
            continue

        dept = dept_map.get((student.department or '').lower())
        if not dept:
            continue

        cls = db.query(ClassModel).filter(
            ClassModel.department_id == dept.id,
            ClassModel.year == student.year,
            ClassModel.section == student.section,
        ).first()
        if not cls:
            continue

        active_session = active_session_by_class.get(cls.id)
        if not active_session:
            continue

        if (active_session.id, record.student_id) in already_marked_set:
            continue

        attendance = Attendance(
            session_id=active_session.id,
            student_id=record.student_id,
            status=record.status,
            date=datetime.now().date(),
            timestamp=datetime.now(),
            remarks="Manual entry",
        )

        db.add(attendance)
        added += 1

    db.commit()

    return {"message": f"{added} attendance records added successfully"}


# ============================================================================
# STUDENT ATTENDANCE HISTORY
# ============================================================================

@router.get("/student/{student_id}")
def get_student_attendance_stats(student_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user['role'] == 'student':
        own = db.query(Student).filter(Student.user_id == current_user['user_id']).first()
        if not own or own.id != student_id:
            raise HTTPException(status_code=403, detail="Access denied")

    # Get student to find their class
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    # Get department
    dept = db.query(Department).filter(
        Department.code.ilike(student.department)
    ).first()

    # Get class
    cls = None
    if dept:
        cls = db.query(ClassModel).filter(
            ClassModel.department_id == dept.id,
            ClassModel.year == student.year,
            ClassModel.section == student.section,
        ).first()

    # Get all ended sessions for this class (single query)
    ended_session_ids = []
    if cls:
        ended_session_ids = [
            s.id for s in db.query(AttendanceSession).filter(
                AttendanceSession.class_id == cls.id,
                AttendanceSession.status == "ended",
            ).all()
        ]
    total_sessions = len(ended_session_ids)

    # Count present — from ended sessions
    session_present = db.query(Attendance).filter(
        Attendance.student_id == student_id,
        Attendance.status == "present",
        Attendance.session_id.in_(ended_session_ids),
    ).count() if ended_session_ids else 0

    # Count manual entries (session_id == 0)
    manual_present = db.query(Attendance).filter(
        Attendance.student_id == student_id,
        Attendance.status == "present",
        Attendance.session_id == 0,
    ).count()

    present = session_present + manual_present
    absent = max(total_sessions - session_present, 0)
    total = total_sessions + manual_present
    percentage = round((present / total * 100), 1) if total > 0 else 0

    # Build subject-wise attendance
    subject_stats = []
    if cls:
        class_subjects = db.query(ClassSubject).filter(
            ClassSubject.class_id == cls.id
        ).all()

        for cs in class_subjects:
            subject = db.query(Subject).filter(Subject.id == cs.subject_id).first()
            if not subject:
                continue

            # Count ended sessions for this subject in this class
            subject_sessions = db.query(AttendanceSession).filter(
                AttendanceSession.class_id == cls.id,
                AttendanceSession.subject_id == cs.subject_id,
                AttendanceSession.status == "ended",
            ).all()
            subject_session_ids = [s.id for s in subject_sessions]
            subject_total = len(subject_session_ids)

            if subject_total == 0:
                continue

            subject_present = db.query(Attendance).filter(
                Attendance.student_id == student_id,
                Attendance.session_id.in_(subject_session_ids),
                Attendance.status == "present",
            ).count()

            subject_pct = round((subject_present / subject_total * 100), 1)

            subject_stats.append({
                "subject_name": subject.name,
                "attended": subject_present,
                "total": subject_total,
                "percentage": subject_pct,
            })

    percentage = round((present / total * 100), 1) if total > 0 else 0

    return {
        "overall_percentage": percentage,
        "total_classes": total,
        "attended": present,
        "absent": absent,
        "subjects": subject_stats,
    }


@router.get("/student/{student_id}/history")
def get_student_attendance_history(student_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user['role'] == 'student':
        own = db.query(Student).filter(Student.user_id == current_user['user_id']).first()
        if not own or own.id != student_id:
            raise HTTPException(status_code=403, detail="Access denied")

    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        return {"records": []}

    # Get student's class
    dept = db.query(Department).filter(
        Department.code.ilike(student.department)
    ).first()

    cls = None
    if dept:
        cls = db.query(ClassModel).filter(
            ClassModel.department_id == dept.id,
            ClassModel.year == student.year,
            ClassModel.section == student.section,
        ).first()

    result = []

    # Get all ENDED sessions for this class
    if cls:
        all_sessions = db.query(AttendanceSession).filter(
            AttendanceSession.class_id == cls.id,
            AttendanceSession.status == "ended",
        ).order_by(AttendanceSession.started_at.desc()).limit(50).all()

        # Bulk-load subjects and attendance records — eliminates N+1
        session_ids = [s.id for s in all_sessions]
        subject_ids = list({s.subject_id for s in all_sessions})

        subjects_map = {
            s.id: s for s in db.query(Subject).filter(
                Subject.id.in_(subject_ids)
            ).all()
        }

        attendance_map = {
            a.session_id: a for a in db.query(Attendance).filter(
                Attendance.session_id.in_(session_ids),
                Attendance.student_id == student_id,
            ).all()
        }

        for session in all_sessions:
            subject = subjects_map.get(session.subject_id)
            subject_name = subject.name if subject else "Unknown"

            attendance = attendance_map.get(session.id)
            status = attendance.status if attendance else "absent"

            result.append({
                "id": session.id,
                "subject": subject_name,
                "date": str(session.started_at.date()),
                "status": status,
                "remarks": attendance.remarks if attendance else None,
                "timestamp": attendance.timestamp.isoformat() if attendance and attendance.timestamp else session.started_at.isoformat(),
            })

    # Also include manual entries (session_id=0)
    manual_records = db.query(Attendance).filter(
        Attendance.student_id == student_id,
        Attendance.session_id == 0,
    ).all()

    for r in manual_records:
        result.append({
            "id": r.id,
            "subject": "Manual Entry",
            "date": str(r.date),
            "status": r.status,
            "remarks": r.remarks,
            "timestamp": r.timestamp.isoformat() if r.timestamp else str(r.date),
        })

    # Sort by date descending
    result.sort(key=lambda x: x['timestamp'], reverse=True)

    return {"records": result}