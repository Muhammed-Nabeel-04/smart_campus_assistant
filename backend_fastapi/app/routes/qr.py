from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import uuid

from app.services.deps import get_db
from app.models.attendance_session import AttendanceSession
from app.models.session_token import SessionToken
from app.models.attendance import Attendance

router = APIRouter(prefix="/qr", tags=["QR Attendance"])


# ----------------------------
# START SESSION (1 per class)
# ----------------------------
@router.post("/start-session")
def start_session(course: str, faculty_id: int, db: Session = Depends(get_db)):
    session = AttendanceSession(
        course=course,
        faculty_id=faculty_id,
        started_at=datetime.utcnow(),
        ends_at=datetime.utcnow() + timedelta(hours=1)
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    return {
        "session_id": session.id,
        "message": "Class session started"
    }


# ----------------------------
# REFRESH TOKEN (Every 3 sec)
# ----------------------------
@router.post("/refresh-token")
def refresh_token(session_id: int, db: Session = Depends(get_db)):
    session = db.query(AttendanceSession).filter(
        AttendanceSession.id == session_id
    ).first()

    if not session:
        raise HTTPException(status_code=400, detail="Session not found")

    if datetime.utcnow() > session.ends_at:
        raise HTTPException(status_code=400, detail="Session ended")

    token = uuid.uuid4().hex[:6]

    token_entry = SessionToken(
        session_id=session_id,
        token=token,
        expires_at=datetime.utcnow() + timedelta(minutes=2)
    )

    db.add(token_entry)
    db.commit()

    return {
        "session_id": session_id,
        "token": token
    }


# ----------------------------
# SCAN QR
# ----------------------------
from pydantic import BaseModel

class ScanQRRequest(BaseModel):
    session_id: int
    token: str
    student_id: int


@router.post("/scan")
def scan_qr(payload: ScanQRRequest, db: Session = Depends(get_db)):

    token_entry = db.query(SessionToken).filter(
        SessionToken.session_id == payload.session_id,
        SessionToken.token == payload.token
    ).first()

    if not token_entry:
        raise HTTPException(status_code=400, detail="Invalid QR code")

    if datetime.utcnow() > token_entry.expires_at:
        raise HTTPException(status_code=400, detail="QR expired")

    # 🔥 Get session separately
    session = db.query(AttendanceSession).filter(
        AttendanceSession.id == payload.session_id
    ).first()

    if not session:
        raise HTTPException(status_code=400, detail="Session not found")

    existing = db.query(Attendance).filter(
        Attendance.student_id == payload.student_id,
        Attendance.date == datetime.utcnow().date()
    ).first()

    if existing:
        raise HTTPException(status_code=400, detail="Attendance already marked")

    attendance = Attendance(
        student_id=payload.student_id,
        course=session.course,
        session_type="morning",
        date=datetime.utcnow().date(),
        status="present"
    )

    db.add(attendance)
    db.commit()

    return {
        "message": "Attendance marked successfully",
        "course": session.course
    }