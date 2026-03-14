from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.services.deps import get_db
from app.models.attendance import Attendance
from app.models.student import Student
from app.models.user import User # ✅ Added User model import

router = APIRouter(tags=["Attendance"])

# =========================
# SUMMARY ENDPOINT
# =========================
@router.get("/student/{student_id}")
def get_student_attendance(student_id: int, db: Session = Depends(get_db)):

    records = db.query(Attendance).filter(
        Attendance.student_id == student_id
    ).all()

    total_classes = len(records)

    if total_classes == 0:
        return {
            "total_classes": 0,
            "present_count": 0,
            "attendance_percentage": 0,
            "category": "No Data"
        }

    present_count = len([r for r in records if r.status == "present"])

    percentage = (present_count / total_classes) * 100

    if percentage < 60:
        category = "Danger"
    elif percentage <= 85:
        category = "Normal"
    else:
        category = "Excellent"

    return {
        "total_classes": total_classes,
        "present_count": present_count,
        "attendance_percentage": round(percentage, 2),
        "category": category
    }


# =========================
# HISTORY ENDPOINT
# =========================
@router.get("/student/{student_id}/history")
def get_attendance_history(student_id: int, db: Session = Depends(get_db)):

    records = db.query(Attendance).filter(
        Attendance.student_id == student_id
    ).order_by(Attendance.date.desc()).all()

    history = [
        {
            "date": r.date.strftime("%Y-%m-%d"),
            "course": r.course,
            "session_type": r.session_type,
            "status": r.status
        }
        for r in records
    ]

    return {
        "student_id": student_id,
        "total_records": len(history),
        "history": history
    }

@router.get("/course/{course}")
def get_course_attendance(course: str, db: Session = Depends(get_db)):

    records = db.query(Attendance).filter(
        Attendance.course == course
    ).all()

    result = []

    for r in records:

        student = db.query(Student).filter(Student.id == r.student_id).first()
        user = None

        if student:
            user = db.query(User).filter(User.id == student.user_id).first()

        result.append({
            "student_name": user.name if user else "Unknown",
            "course": r.course,
            "date": r.date.strftime("%Y-%m-%d") if r.date else None,
            "status": r.status
        })

    return result
# =========================
# SESSION ATTENDANCE ENDPOINT
# =========================
@router.get("/session/{session_id}")
def get_session_attendance(session_id: int, db: Session = Depends(get_db)):

    records = db.query(Attendance).filter(
        Attendance.session_id == session_id
    ).all()

    result = []

    # ✅ Upgraded Loop: Fetches User table for the actual name
    for r in records:
        student = db.query(Student).filter(Student.id == r.student_id).first()
        
        user = None
        if student:
            user = db.query(User).filter(User.id == student.user_id).first()

        result.append({
            "student_id": r.student_id,
            "student_name": user.name if user else "Unknown",
            "course": r.course,
            "date": r.date.strftime("%Y-%m-%d") if r.date else None,
            "status": r.status
        })

    return result