import secrets
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime, timedelta
from app.services.deps import get_db
from app.models.attendance_session import AttendanceSession
from app.models.attendance import Attendance

router = APIRouter(prefix="/qr", tags=["QR Attendance"])

class QRScanRequest(BaseModel):
    session_id: int
    token: str
    student_id: int

@router.post("/start-session")
def start_session(
    course: str,
    faculty_id: int,
    db: Session = Depends(get_db)
):
    token = secrets.token_hex(8)
    
    # ✅ Updated block using started_at and ends_at (5-minute expiry)
    session = AttendanceSession(
        course=course,
        faculty_id=faculty_id,
        token=token,
        started_at=datetime.utcnow(),
        ends_at=datetime.utcnow() + timedelta(minutes=5)
    )
    
    db.add(session)
    db.commit()
    db.refresh(session)
    return {
        "session_id": session.id,
        "token": token,
        "message": "Class session started"
    }

@router.post("/refresh-token")
def refresh_token(
    session_id: int,
    db: Session = Depends(get_db)
):
    session = db.query(AttendanceSession).filter(
        AttendanceSession.id == session_id
    ).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    token = secrets.token_hex(8)
    session.token = token
    db.commit()
    return {
        "session_id": session.id,
        "token": token,
        "message": "Token refreshed"
    }

@router.post("/scan")
def scan_qr(
    payload: QRScanRequest,
    db: Session = Depends(get_db)
):
    session = db.query(AttendanceSession).filter(
        AttendanceSession.id == payload.session_id,
        AttendanceSession.token == payload.token
    ).first()
    if not session:
        raise HTTPException(status_code=400, detail="Invalid QR code")
    if datetime.utcnow() > session.ends_at:
        raise HTTPException(status_code=400, detail="QR code expired")
        
    existing = db.query(Attendance).filter(
        Attendance.student_id == payload.student_id,
        Attendance.session_id == payload.session_id
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="Attendance already marked")
        
    attendance = Attendance(
        student_id=payload.student_id,
        session_id=session.id,   # ADD
        course=session.course,
        session_type="morning",
        date=session.started_at.date(), # ✅ Switched from created_at to started_at to match your new model!
        status="present"
    )
    db.add(attendance)
    db.commit()
    
    return {
        "message": "Attendance marked successfully",
        "course": session.course,
        "date": session.started_at.date()
    }