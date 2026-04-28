# File: app/routes/ssm_routes.py  (FULL REPLACE — v3 activity-based)
# ─────────────────────────────────────────────────────────────────────────────
# All SSM endpoints
# Student adds individual entries anytime throughout semester
# Mentor fills evaluation fields separately
# ─────────────────────────────────────────────────────────────────────────────

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, Any
from datetime import datetime
import json

from app.services.deps import get_db, get_current_user
from app.models.ssm import SSMSubmission, SSMEntry, SSMMentorInput, SSMReview
from app.models.student import Student
from app.models.faculty import Faculty
from app.services.ssm_scoring import (
    calculate_full_score, score_entry, ENTRY_CONFIG
)

router = APIRouter(prefix="/ssm", tags=["SSM Performance"])


# ── Helpers ───────────────────────────────────────────────────────────────────

def _get_or_create_submission(student_id: int, db: Session) -> SSMSubmission:
    sub = db.query(SSMSubmission).filter(
        SSMSubmission.student_id == student_id
    ).first()
    if not sub:
        sub = SSMSubmission(student_id=student_id, status="active")
        db.add(sub)
        db.commit()
        db.refresh(sub)
    return sub


def _recalculate(submission_id: int, db: Session):
    """Recalculate and save scores for a submission."""
    sub = db.query(SSMSubmission).filter(SSMSubmission.id == submission_id).first()
    if not sub: return

    entries = db.query(SSMEntry).filter(SSMEntry.submission_id == submission_id).all()
    mentor_input = db.query(SSMMentorInput).filter(
        SSMMentorInput.submission_id == submission_id).first()

    result = calculate_full_score(entries, mentor_input)

    sub.total_score = result["total"]
    sub.star_rating = result["stars"]
    sub.score_breakdown = json.dumps(result)
    sub.updated_at = datetime.now()
    db.commit()
    return result


def _entry_to_dict(e: SSMEntry) -> dict:
    details = {}
    try:
        if e.details: details = json.loads(e.details)
    except Exception:
        pass
    cfg = ENTRY_CONFIG.get(e.entry_type, {})
    return {
        "id": e.id,
        "submission_id": e.submission_id,
        "category": e.category,
        "entry_type": e.entry_type,
        "entry_label": cfg.get("label", e.entry_type),
        "details": details,
        "score": e.score,
        "proof_id": e.proof_id,
        "proof_required": bool(cfg.get("proof_required", True)),
        "proof_status": e.proof_status,
        "entry_status": e.entry_status,
        "added_at": e.added_at.isoformat() if e.added_at else None,
    }


def _submission_to_dict(sub: SSMSubmission, db: Session) -> dict:
    entries = db.query(SSMEntry).filter(
        SSMEntry.submission_id == sub.id
    ).order_by(SSMEntry.added_at.desc()).all()

    mentor_input = db.query(SSMMentorInput).filter(
        SSMMentorInput.submission_id == sub.id).first()

    reviews = db.query(SSMReview).filter(
        SSMReview.submission_id == sub.id
    ).order_by(SSMReview.id.desc()).all()

    breakdown = {}
    try:
        if sub.score_breakdown:
            breakdown = json.loads(sub.score_breakdown)
    except Exception:
        pass

    return {
        "id": sub.id,
        "student_id": sub.student_id,
        "total_score": sub.total_score,
        "star_rating": sub.star_rating,
        "score_breakdown": breakdown,
        "status": sub.status,
        "academic_year": sub.academic_year,
        "entries": [_entry_to_dict(e) for e in entries],
        "mentor_input": _mentor_to_dict(mentor_input) if mentor_input else None,
        "reviews": [
            {
                "id": r.id, "reviewer_role": r.reviewer_role,
                "reviewer_name": r.reviewer_name, "status": r.status,
                "remarks": r.remarks,
                "reviewed_at": r.reviewed_at.isoformat() if r.reviewed_at else None,
            }
            for r in reviews
        ],
        "submitted_at": sub.submitted_at.isoformat() if sub.submitted_at else None,
        "updated_at": sub.updated_at.isoformat() if sub.updated_at else None,
    }


def _mentor_to_dict(m: SSMMentorInput) -> dict:
    if not m: return {}
    return {
        "id": m.id,
        "mentor_name": m.mentor_name,
        "mentor_feedback": m.mentor_feedback,
        "hod_feedback": m.hod_feedback,
        "tech_skill_level": m.tech_skill_level,
        "soft_skill_level": m.soft_skill_level,
        "placement_outcome": m.placement_outcome,
        "discipline_conduct": m.discipline_conduct,
        "punctuality_level": m.punctuality_level,
        "dress_code": m.dress_code,
        "dept_event_contribution": m.dept_event_contribution,
        "social_media_level": m.social_media_level,
        "updated_at": m.updated_at.isoformat() if m.updated_at else None,
    }


# ============================================================================
# PYDANTIC SCHEMAS
# ============================================================================

class AddEntryRequest(BaseModel):
    student_id: int
    entry_type: str
    details: dict


class UpdateEntryRequest(BaseModel):
    details: dict


class MentorInputRequest(BaseModel):
    student_id: int
    mentor_feedback: Optional[str] = None
    hod_feedback: Optional[str] = None
    tech_skill_level: Optional[str] = None
    soft_skill_level: Optional[str] = None
    placement_outcome: Optional[str] = None
    discipline_conduct: Optional[str] = None
    punctuality_level: Optional[str] = None
    dress_code: Optional[str] = None
    dept_event_contribution: Optional[str] = None
    social_media_level: Optional[str] = None


class ReviewRequest(BaseModel):
    submission_id: int
    status: str
    remarks: Optional[str] = None


# ============================================================================
# 1. GET STUDENT RESULT (or create empty submission)
# ============================================================================

@router.get("/result/{student_id}")
def get_result(
    student_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    sub = db.query(SSMSubmission).filter(
        SSMSubmission.student_id == student_id
    ).first()

    if not sub:
        return {"has_submission": False, "submission": None}

    return {"has_submission": True, "submission": _submission_to_dict(sub, db)}


# ============================================================================
# 2. ADD ENTRY (student adds activity)
# ============================================================================

@router.post("/entry/add")
def add_entry(
    payload: AddEntryRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Student adds a new activity entry anytime during semester."""

    # Verify student
    student = db.query(Student).filter(Student.id == payload.student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    if current_user["role"] == "student":
        if student.user_id != current_user["user_id"]:
            raise HTTPException(status_code=403, detail="Access denied")

    # Validate entry type
    config = ENTRY_CONFIG.get(payload.entry_type)
    if not config:
        raise HTTPException(
            status_code=400,
            detail=f"Unknown entry type '{payload.entry_type}'. "
                   f"Valid types: {list(ENTRY_CONFIG.keys())}"
        )

    # Get or create submission
    sub = _get_or_create_submission(payload.student_id, db)

    # Check if submission is locked
    if sub.status in ["hod_approved"]:
        raise HTTPException(
            status_code=400,
            detail="Score is already finalized. Cannot add entries."
        )
    # If submitted/mentor_approved → reopen to active (student can always update)
    if sub.status in ["submitted", "mentor_approved", "mentor_rejected"]:
        sub.status = "active"
        db.commit()

    # Calculate score for this entry
    entry_score = score_entry(payload.entry_type, payload.details)

    # Create entry
    entry = SSMEntry(
        submission_id=sub.id,
        student_id=payload.student_id,
        category=config["category"],
        entry_type=payload.entry_type,
        details=json.dumps(payload.details),
        score=entry_score,
        proof_required=1 if config.get("proof_required", True) else 0,
        proof_status="pending" if config.get("proof_required", True) else "not_required",
        entry_status="pending_proof" if config.get("proof_required", True) else "verified",
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)

    # Recalculate total score
    result = _recalculate(sub.id, db)

    return {
        "message": "Entry added",
        "entry": _entry_to_dict(entry),
        "new_score": result["total"] if result else sub.total_score,
        "star_rating": result["stars"] if result else sub.star_rating,
    }


# ============================================================================
# 3. UPDATE ENTRY
# ============================================================================

@router.put("/entry/{entry_id}")
def update_entry(
    entry_id: int,
    payload: UpdateEntryRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    entry = db.query(SSMEntry).filter(SSMEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")

    sub = db.query(SSMSubmission).filter(
        SSMSubmission.id == entry.submission_id).first()
    if sub and sub.status == "hod_approved":
        raise HTTPException(status_code=400, detail="Score is finalized")

    entry.details = json.dumps(payload.details)
    entry.score = score_entry(entry.entry_type, payload.details)
    entry.updated_at = datetime.now()
    db.commit()

    result = _recalculate(entry.submission_id, db)

    return {
        "message": "Entry updated",
        "entry": _entry_to_dict(entry),
        "new_score": result["total"] if result else 0,
    }


# ============================================================================
# 4. DELETE ENTRY
# ============================================================================

@router.delete("/entry/{entry_id}")
def delete_entry(
    entry_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    entry = db.query(SSMEntry).filter(SSMEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")

    sub = db.query(SSMSubmission).filter(
        SSMSubmission.id == entry.submission_id).first()
    if sub and sub.status == "hod_approved":
        raise HTTPException(status_code=400, detail="Score is finalized")

    submission_id = entry.submission_id
    db.delete(entry)
    db.commit()

    result = _recalculate(submission_id, db)

    return {
        "message": "Entry deleted",
        "new_score": result["total"] if result else 0,
    }


# ============================================================================
# 5. LINK PROOF TO ENTRY (called after proof upload)
# ============================================================================

@router.put("/entry/{entry_id}/proof")
def link_proof(
    entry_id: int,
    payload: dict,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    entry = db.query(SSMEntry).filter(SSMEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")

    entry.proof_id = payload.get("proof_id")
    entry.proof_status = payload.get("proof_status", "pending")

    # Update entry status
    ps = entry.proof_status
    if ps == "valid":
        entry.entry_status = "verified"
    elif ps in ["review", "pending"]:
        entry.entry_status = "pending_proof"
    elif ps == "invalid":
        entry.entry_status = "rejected"

    db.commit()
    return {"message": "Proof linked", "proof_status": entry.proof_status}


# ============================================================================
# 6. SUBMIT FOR APPROVAL
# ============================================================================

@router.post("/submit/{submission_id}")
def submit_for_approval(
    submission_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    sub = db.query(SSMSubmission).filter(SSMSubmission.id == submission_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Submission not found")

    if sub.status == "hod_approved":
        raise HTTPException(status_code=400, detail="Already finalized")

    entries = db.query(SSMEntry).filter(
        SSMEntry.submission_id == submission_id).all()

    if not entries:
        raise HTTPException(
            status_code=400,
            detail="Please add at least one activity before submitting"
        )

    sub.status = "submitted"
    sub.submitted_at = datetime.now()
    db.commit()

    return {"message": "Submitted for mentor review", "status": "submitted"}


# ============================================================================
# 7. GET RESULT (already defined above)
# ============================================================================

@router.get("/submissions")
def list_submissions(
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ["faculty", "admin", "principal"]:
        raise HTTPException(status_code=403, detail="Access denied")

    query = db.query(SSMSubmission)
    if status:
        query = query.filter(SSMSubmission.status == status)

    result = []
    for sub in query.order_by(SSMSubmission.updated_at.desc()).all():
        student = db.query(Student).filter(Student.id == sub.student_id).first()
        entry = _submission_to_dict(sub, db)
        entry["student_name"] = student.full_name if student else "Unknown"
        entry["register_number"] = student.register_number if student else ""
        entry["department"] = student.department if student else ""
        entry["year"] = student.year if student else ""
        result.append(entry)

    return result


# ============================================================================
# 8. MENTOR INPUT (mentor fills their evaluation fields)
# ============================================================================

@router.post("/mentor-input")
def save_mentor_input(
    payload: MentorInputRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ["faculty", "admin"]:
        raise HTTPException(status_code=403, detail="Only faculty can fill mentor input")

    student = db.query(Student).filter(Student.id == payload.student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    sub = _get_or_create_submission(payload.student_id, db)

    faculty = db.query(Faculty).filter(
        Faculty.user_id == current_user["user_id"]).first()
    mentor_name = faculty.full_name if faculty else "Mentor"

    # Get or create mentor input
    mi = db.query(SSMMentorInput).filter(
        SSMMentorInput.submission_id == sub.id).first()

    if not mi:
        mi = SSMMentorInput(
            submission_id=sub.id,
            student_id=payload.student_id,
            mentor_id=current_user["user_id"],
            mentor_name=mentor_name,
        )
        db.add(mi)

    # Update fields
    fields = [
        "mentor_feedback", "hod_feedback", "tech_skill_level",
        "soft_skill_level", "placement_outcome", "discipline_conduct",
        "punctuality_level", "dress_code", "dept_event_contribution",
        "social_media_level",
    ]
    for f in fields:
        v = getattr(payload, f)
        if v is not None:
            setattr(mi, f, v)

    mi.updated_at = datetime.now()
    db.commit()

    # Recalculate with mentor input
    result = _recalculate(sub.id, db)

    return {
        "message": "Mentor input saved",
        "mentor_input": _mentor_to_dict(mi),
        "new_score": result["total"] if result else 0,
    }


# ============================================================================
# 9. MENTOR REVIEW (approve/reject submission)
# ============================================================================

@router.post("/review/mentor")
def mentor_review(
    payload: ReviewRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ["faculty", "admin"]:
        raise HTTPException(status_code=403, detail="Only faculty can review")

    sub = db.query(SSMSubmission).filter(
        SSMSubmission.id == payload.submission_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Not found")

    if sub.status != "submitted":
        raise HTTPException(
            status_code=400,
            detail=f"Status is '{sub.status}', not pending review"
        )

    if payload.status not in ["approved", "rejected"]:
        raise HTTPException(status_code=400, detail="Must be approved or rejected")

    faculty = db.query(Faculty).filter(
        Faculty.user_id == current_user["user_id"]).first()

    db.add(SSMReview(
        submission_id=sub.id,
        reviewer_role="mentor",
        reviewer_id=current_user["user_id"],
        reviewer_name=faculty.full_name if faculty else "Mentor",
        status=payload.status,
        remarks=payload.remarks,
        reviewed_at=datetime.now(),
    ))

    sub.status = "mentor_approved" if payload.status == "approved" else "active"
    db.commit()

    return {"message": f"Mentor {payload.status}", "new_status": sub.status}


# ============================================================================
# 10. HOD REVIEW (final lock)
# ============================================================================

@router.post("/review/hod")
def hod_review(
    payload: ReviewRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ["faculty", "admin"]:
        raise HTTPException(status_code=403, detail="Only HOD can do final review")

    sub = db.query(SSMSubmission).filter(
        SSMSubmission.id == payload.submission_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Not found")

    if sub.status != "mentor_approved":
        raise HTTPException(
            status_code=400,
            detail=f"Must be mentor-approved first (status: {sub.status})"
        )

    if payload.status not in ["approved", "rejected"]:
        raise HTTPException(status_code=400, detail="Must be approved or rejected")

    faculty = db.query(Faculty).filter(
        Faculty.user_id == current_user["user_id"]).first()

    db.add(SSMReview(
        submission_id=sub.id,
        reviewer_role="hod",
        reviewer_id=current_user["user_id"],
        reviewer_name=faculty.full_name if faculty else "HOD",
        status=payload.status,
        remarks=payload.remarks,
        reviewed_at=datetime.now(),
    ))

    sub.status = "hod_approved" if payload.status == "approved" else "active"
    db.commit()

    return {
        "message": f"HOD {payload.status}. Score is final.",
        "new_status": sub.status,
        "final_score": sub.total_score,
    }


# ============================================================================
# 11. ENTRY CONFIG (for frontend to know what fields each type needs)
# ============================================================================

@router.get("/entry-config")
def get_entry_config(current_user: dict = Depends(get_current_user)):
    """Returns all valid entry types with their categories and labels."""
    return {
        k: {
            "category": v["category"],
            "label": v["label"],
            "proof_required": v.get("proof_required", True),
        }
        for k, v in ENTRY_CONFIG.items()
    }