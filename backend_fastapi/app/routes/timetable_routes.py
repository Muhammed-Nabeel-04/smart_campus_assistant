from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date
import json

from app.services.deps import get_db, get_current_user
from app.models.timetable import TimetableSlot, TimetablePDF
from app.models.faculty import Faculty
from app.models.subject import Subject
from app.models.class_model import ClassModel
from app.models.department import Department
from app.models.student import Student
from app.models.user import User

router = APIRouter(prefix="/timetable", tags=["Timetable"])

DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

# ── Pydantic Models ───────────────────────────────────────────

class SlotCreate(BaseModel):
    class_id:   int
    subject_id: int
    faculty_id: int
    day_of_week: str
    start_time:  str
    end_time:    str
    room: Optional[str] = None

class PDFUpload(BaseModel):
    class_id:  int
    file_data: str   # base64
    file_name: str

# ── Helper ────────────────────────────────────────────────────

def _slot_to_dict(slot: TimetableSlot, db: Session) -> dict:
    subject = db.query(Subject).filter(Subject.id == slot.subject_id).first()
    faculty = db.query(Faculty).filter(Faculty.id == slot.faculty_id).first()
    faculty_user = db.query(User).filter(
        User.id == faculty.user_id
    ).first() if faculty else None
    cls = db.query(ClassModel).filter(ClassModel.id == slot.class_id).first()

    return {
        "id":           slot.id,
        "day_of_week":  slot.day_of_week,
        "start_time":   slot.start_time,
        "end_time":     slot.end_time,
        "room":         slot.room,
        "subject_id":   slot.subject_id,
        "subject_name": subject.name if subject else "Unknown",
        "subject_code": subject.code if subject else "",
        "faculty_id":   slot.faculty_id,
        "faculty_name": faculty_user.name if faculty_user else "Unknown",
        "class_id":     slot.class_id,
        "class_name":   f"{cls.year} Sec {cls.section}" if cls else "Unknown",
    }

def _minutes_from_midnight(time_str: str) -> int:
    """Convert 'HH:MM' to minutes from midnight."""
    try:
        h, m = time_str.split(":")
        return int(h) * 60 + int(m)
    except Exception:
        return 0

def _get_next_slot(slots: list, db: Session) -> Optional[dict]:
    """Find next upcoming slot from now."""
    now = datetime.now()
    today = now.strftime("%A")  # "Monday", "Tuesday" etc.
    current_minutes = now.hour * 60 + now.minute

    day_order = {d: i for i, d in enumerate(DAYS)}
    today_idx = day_order.get(today, 0)

    best_slot = None
    best_delta = float('inf')

    for slot in slots:
        slot_day_idx = day_order.get(slot.day_of_week, 0)
        slot_minutes = _minutes_from_midnight(slot.start_time)

        # Days until this slot
        if slot_day_idx > today_idx:
            days_ahead = slot_day_idx - today_idx
        elif slot_day_idx == today_idx and slot_minutes > current_minutes:
            days_ahead = 0
        else:
            days_ahead = 7 - today_idx + slot_day_idx

        delta = days_ahead * 1440 + slot_minutes - current_minutes
        if delta < best_delta:
            best_delta = delta
            best_slot = slot

    if best_slot is None:
        return None

    result = _slot_to_dict(best_slot, db)
    result["minutes_until"] = int(best_delta)
    result["starts_today"] = best_delta < 1440
    return result

# ============================================================================
# HOD ENDPOINTS
# ============================================================================

@router.post("/slots")
def create_slot(
    payload: SlotCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Allow HOD (admin) OR CC faculty
    if current_user["role"] == "admin":
        dept = db.query(Department).filter(
            Department.hod_user_id == current_user["user_id"]
        ).first()
        if not dept:
            raise HTTPException(status_code=403, detail="HOD access required")
    elif current_user["role"] == "faculty":
        # Must be CC for this specific class
        faculty = db.query(Faculty).filter(
            Faculty.user_id == current_user["user_id"],
            Faculty.is_cc == True,
            Faculty.cc_class_id == payload.class_id,
        ).first()
        if not faculty:
            raise HTTPException(
                status_code=403,
                detail="Only the Class Coordinator can manage this timetable"
            )
    else:
        raise HTTPException(status_code=403, detail="Access denied")

    dept = db.query(Department).filter(
        Department.hod_user_id == current_user["user_id"]
    ).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")

    if payload.day_of_week not in DAYS:
        raise HTTPException(status_code=400, detail="Invalid day")

    # Check duplicate slot for same class+day+time
    existing = db.query(TimetableSlot).filter(
        TimetableSlot.class_id   == payload.class_id,
        TimetableSlot.day_of_week == payload.day_of_week,
        TimetableSlot.start_time  == payload.start_time,
    ).first()
    if existing:
        raise HTTPException(
            status_code=400,
            detail="A slot already exists for this class at this time"
        )

    slot = TimetableSlot(
        department_id = dept.id,
        class_id      = payload.class_id,
        subject_id    = payload.subject_id,
        faculty_id    = payload.faculty_id,
        day_of_week   = payload.day_of_week,
        start_time    = payload.start_time,
        end_time      = payload.end_time,
        room          = payload.room,
    )
    db.add(slot)
    db.commit()
    db.refresh(slot)
    return {"message": "Slot added", "id": slot.id}


@router.delete("/slots/{slot_id}")
def delete_slot(
    slot_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    slot = db.query(TimetableSlot).filter(TimetableSlot.id == slot_id).first()
    if not slot:
        raise HTTPException(status_code=404, detail="Slot not found")

    if current_user["role"] == "admin":
        pass  # HOD can always delete
    elif current_user["role"] == "faculty":
        faculty = db.query(Faculty).filter(
            Faculty.user_id == current_user["user_id"],
            Faculty.is_cc == True,
            Faculty.cc_class_id == slot.class_id,
        ).first()
        if not faculty:
            raise HTTPException(status_code=403, detail="Only the CC can modify this timetable")
    else:
        raise HTTPException(status_code=403, detail="Access denied")

    slot = db.query(TimetableSlot).filter(TimetableSlot.id == slot_id).first()
    if not slot:
        raise HTTPException(status_code=404, detail="Slot not found")

    db.delete(slot)
    db.commit()
    return {"message": "Slot deleted"}


@router.post("/pdf")
def upload_pdf(
    payload: PDFUpload,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="HOD access required")

    dept = db.query(Department).filter(
        Department.hod_user_id == current_user["user_id"]
    ).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")

    # Remove old PDF for this class
    db.query(TimetablePDF).filter(
        TimetablePDF.class_id == payload.class_id
    ).delete()

    pdf = TimetablePDF(
        department_id = dept.id,
        class_id      = payload.class_id,
        file_data     = payload.file_data,
        file_name     = payload.file_name,
    )
    db.add(pdf)
    db.commit()
    return {"message": "PDF uploaded successfully"}


@router.delete("/pdf/{class_id}")
def delete_pdf(
    class_id: int,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="HOD access required")

    db.query(TimetablePDF).filter(
        TimetablePDF.class_id == class_id
    ).delete()
    db.commit()
    return {"message": "PDF deleted"}

# ============================================================================
# SHARED ENDPOINTS
# ============================================================================

@router.get("/class/{class_id}")
def get_class_timetable(
    class_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    slots = db.query(TimetableSlot).filter(
        TimetableSlot.class_id == class_id
    ).all()

    # Group by day
    result = {day: [] for day in DAYS}
    for slot in slots:
        result[slot.day_of_week].append(_slot_to_dict(slot, db))

    # Sort each day by start_time
    for day in DAYS:
        result[day].sort(key=lambda s: _minutes_from_midnight(s["start_time"]))

    # Get PDF if exists
    pdf = db.query(TimetablePDF).filter(
        TimetablePDF.class_id == class_id
    ).first()

    return {
        "slots":    result,
        "has_pdf":  pdf is not None,
        "pdf_name": pdf.file_name if pdf else None,
    }


@router.get("/pdf/{class_id}")
def get_pdf(
    class_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    pdf = db.query(TimetablePDF).filter(
        TimetablePDF.class_id == class_id
    ).first()
    if not pdf:
        raise HTTPException(status_code=404, detail="No PDF found")
    return {
        "file_data": pdf.file_data,
        "file_name": pdf.file_name,
        "uploaded_at": pdf.uploaded_at.isoformat(),
    }


@router.get("/faculty/{faculty_id}")
def get_faculty_timetable(
    faculty_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    slots = db.query(TimetableSlot).filter(
        TimetableSlot.faculty_id == faculty_id
    ).all()

    result = {day: [] for day in DAYS}
    for slot in slots:
        result[slot.day_of_week].append(_slot_to_dict(slot, db))

    for day in DAYS:
        result[day].sort(key=lambda s: _minutes_from_midnight(s["start_time"]))

    return {"schedule": result}


@router.get("/next-slot/faculty/{faculty_id}")
def get_next_slot_faculty(
    faculty_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    slots = db.query(TimetableSlot).filter(
        TimetableSlot.faculty_id == faculty_id
    ).all()
    next_slot = _get_next_slot(slots, db)
    return next_slot or {}


@router.get("/next-slot/student/{student_id}")
def get_next_slot_student(
    student_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    dept = db.query(Department).filter(
        Department.code.ilike(student.department)
    ).first()
    if not dept:
        return {}

    cls = db.query(ClassModel).filter(
        ClassModel.department_id == dept.id,
        ClassModel.year          == student.year,
        ClassModel.section       == student.section,
    ).first()
    if not cls:
        return {}

    slots = db.query(TimetableSlot).filter(
        TimetableSlot.class_id == cls.id
    ).all()
    next_slot = _get_next_slot(slots, db)
    return next_slot or {}

@router.get("/class/{class_id}/grid")
def get_class_timetable_grid(
    class_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Returns timetable as a grid: {day: {period: slot_data}}"""
    slots = db.query(TimetableSlot).filter(
        TimetableSlot.class_id == class_id
    ).all()

    grid = {}
    for slot in slots:
        day = slot.day_of_week
        if day not in grid:
            grid[day] = {}
        # Find period number from start time
        grid[day][slot.start_time] = _slot_to_dict(slot, db)

    return {"grid": grid}

@router.get("/faculty/{faculty_id}/cc-class")
def get_cc_class(
    faculty_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get CC faculty's assigned class info"""
    faculty = db.query(Faculty).filter(Faculty.id == faculty_id).first()
    if not faculty or not faculty.is_cc or not faculty.cc_class_id:
        return {"is_cc": False}

    cls = db.query(ClassModel).filter(ClassModel.id == faculty.cc_class_id).first()
    dept = db.query(Department).filter(Department.id == cls.department_id).first() if cls else None

    return {
        "is_cc": True,
        "cc_class_id": faculty.cc_class_id,
        "class_name": f"{cls.year} Sec {cls.section}" if cls else "",
        "year": cls.year if cls else "",
        "section": cls.section if cls else "",
        "department": dept.code if dept else "",
        "department_name": dept.name if dept else "",
    }