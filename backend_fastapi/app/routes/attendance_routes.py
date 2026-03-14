from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, date
from app.services.deps import get_db, get_current_user
from app.models.attendance_session import AttendanceSession
from app.models.attendance import Attendance
from app.models.student import Student
from app.models.subject import Subject
from app.models.faculty import Faculty
import secrets

router = APIRouter(prefix="/attendance", tags=["Attendance"])


class StartSessionRequest(BaseModel):
    class_id: int
    subject_id: int
    faculty_id: Optional[int] = None  # Optional — extracted from JWT if not provided


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
        raise HTTPException(
            status_code=400,
            detail="An active session already exists for this class and subject"
        )

    token = secrets.token_urlsafe(16)

    session = AttendanceSession(
        class_id=payload.class_id,
        subject_id=payload.subject_id,
        faculty_id=faculty_id,
        token=token,
        status="active",
        started_at=datetime.utcnow(),
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


@router.post("/sessions/{session_id}/end/")
def end_session(session_id: int, db: Session = Depends(get_db)):

    session = db.query(AttendanceSession).filter(
        AttendanceSession.id == session_id
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    if session.status == "ended":
        raise HTTPException(status_code=400, detail="Session already ended")

    session.status = "ended"
    session.ended_at = datetime.utcnow()
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
def get_session_attendance(session_id: int, db: Session = Depends(get_db)):

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

@router.post("/mark/")
def mark_attendance(payload: dict, db: Session = Depends(get_db)):
    """Student scans QR to mark attendance"""

    token = payload.get("token")
    student_id = payload.get("student_id")

    if not token or not student_id:
        raise HTTPException(status_code=400, detail="token and student_id are required")

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
    from app.models.department import Department
    dept = db.query(Department).filter(
        Department.code == student.department
    ).first()
    if not dept:
        raise HTTPException(status_code=403, detail="Student department not found")

    from app.models.class_model import ClassModel
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
        date=datetime.utcnow().date(),
        timestamp=datetime.utcnow(),
    )

    db.add(attendance)
    db.commit()

    return {
        "message": "Attendance marked successfully",
        "student_id": student_id,
        "full_name": student.full_name,
        "status": "present",
        "time": datetime.utcnow().strftime("%H:%M"),
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
    db: Session = Depends(get_db)
):
    # Get all sessions for this class+subject
    sessions = db.query(AttendanceSession).filter(
        AttendanceSession.class_id == class_id,
        AttendanceSession.subject_id == subject_id,
    ).all()

    session_ids = [s.id for s in sessions]
    total_sessions = len(session_ids)

    # Get all students in this class
    students = db.query(Student).filter(
        Student.year != None
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
    added = 0

    for record in payload.records:
        try:
            attendance_date = datetime.fromisoformat(record.date).date() if record.date else date.today()
        except:
            attendance_date = date.today()

        attendance = Attendance(
            session_id=0,
            student_id=record.student_id,
            status=record.status,
            date=attendance_date,
            timestamp=datetime.utcnow(),
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
def get_student_attendance_stats(student_id: int, db: Session = Depends(get_db)):

    present = db.query(Attendance).filter(
        Attendance.student_id == student_id,
        Attendance.status == "present",
    ).count()

    absent = db.query(Attendance).filter(
        Attendance.student_id == student_id,
        Attendance.status == "absent",
    ).count()

    total = present + absent
    percentage = round((present / total * 100), 1) if total > 0 else 0

    return {
        "overall_percentage": percentage,
        "total_classes": total,
        "attended": present,
        "absent": absent,
        "subjects": [],
    }


@router.get("/student/{student_id}/history")
def get_student_attendance_history(student_id: int, db: Session = Depends(get_db)):

    records = db.query(Attendance).filter(
        Attendance.student_id == student_id
    ).order_by(Attendance.date.desc()).limit(50).all()

    result = []
    for r in records:
        subject_name = "Manual Entry"

        if r.session_id and r.session_id != 0:
            session = db.query(AttendanceSession).filter(
                AttendanceSession.id == r.session_id
            ).first()
            if session:
                subject = db.query(Subject).filter(
                    Subject.id == session.subject_id
                ).first()
                if subject:
                    subject_name = subject.name

        result.append({
            "id": r.id,
            "subject": subject_name,
            "date": str(r.date),
            "status": r.status,
            "remarks": r.remarks,
            "timestamp": r.timestamp.isoformat() if r.timestamp else None,
        })

    return {"records": result}