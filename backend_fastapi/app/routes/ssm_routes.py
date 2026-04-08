# File: app/routes/ssm_routes.py
# ─────────────────────────────────────────────────────────
# SSM (Student Score Management) — All API endpoints
# Prefix: /ssm
# ─────────────────────────────────────────────────────────

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import json

from app.services.deps import get_db, get_current_user
from app.models.ssm import SSMSubmission, SSMActivity, SSMReview
from app.models.student import Student
from app.models.faculty import Faculty
from app.models.user import User

router = APIRouter(prefix="/ssm", tags=["SSM Performance"])


# ============================================================================
# PYDANTIC SCHEMAS
# ============================================================================

class SaveFormRequest(BaseModel):
    student_id: int
    gpa: Optional[float] = None
    attendance_input: Optional[float] = None


class AddActivityRequest(BaseModel):
    submission_id: int
    type: str                        # internship | certificate | project | achievement
    title: str
    description: Optional[str] = None
    duration: Optional[str] = None
    organization: Optional[str] = None
    proof_file_name: Optional[str] = None
    proof_file_data: Optional[str] = None   # base64


class ReviewRequest(BaseModel):
    submission_id: int
    status: str                      # approved | rejected
    remarks: Optional[str] = None


# ============================================================================
# SCORING ENGINE
# ============================================================================

def calculate_score(submission: SSMSubmission, activities: List[SSMActivity]) -> dict:
    """
    Scoring Rules (max 100 points):
    ─────────────────────────────────
    GPA >= 9.0            → 15 pts
    GPA 8.0–8.99          → 10 pts
    GPA 7.0–7.99          →  5 pts
    GPA < 7.0             →  0 pts

    Attendance >= 90%     → 15 pts
    Attendance 75–89%     → 10 pts
    Attendance 60–74%     →  5 pts
    Attendance < 60%      →  0 pts

    Each Internship       → 20 pts  (max 1 = 20 pts)
    Each Project          → 15 pts  (max 2 = 30 pts)
    Certificates >= 3     → 15 pts  (bonus for 3+)
    Each Certificate 1–2  →  5 pts each

    Max possible: 15+15+20+30+15 = 95 → normalised to 100
    """
    breakdown = {}
    score = 0.0

    # ── GPA ──────────────────────────────────────────────
    gpa = submission.gpa or 0.0
    if gpa >= 9.0:
        gpa_pts = 15
    elif gpa >= 8.0:
        gpa_pts = 10
    elif gpa >= 7.0:
        gpa_pts = 5
    else:
        gpa_pts = 0
    score += gpa_pts
    breakdown["gpa"] = {"value": gpa, "points": gpa_pts, "max": 15}

    # ── Attendance ────────────────────────────────────────
    att = submission.attendance_input or 0.0
    if att >= 90:
        att_pts = 15
    elif att >= 75:
        att_pts = 10
    elif att >= 60:
        att_pts = 5
    else:
        att_pts = 0
    score += att_pts
    breakdown["attendance"] = {"value": att, "points": att_pts, "max": 15}

    # ── Activities ────────────────────────────────────────
    internships = [a for a in activities if a.type == "internship"]
    projects    = [a for a in activities if a.type == "project"]
    certs       = [a for a in activities if a.type == "certificate"]
    achievements = [a for a in activities if a.type == "achievement"]

    # Internship: 20 pts per, capped at 1 (20 max)
    intern_pts = min(len(internships), 1) * 20
    score += intern_pts
    breakdown["internship"] = {"count": len(internships), "points": intern_pts, "max": 20}

    # Project: 15 pts per, capped at 2 (30 max)
    project_pts = min(len(projects), 2) * 15
    score += project_pts
    breakdown["project"] = {"count": len(projects), "points": project_pts, "max": 30}

    # Certificates: 5 pts each for first 2, +15 bonus if >= 3
    if len(certs) >= 3:
        cert_pts = 15
    else:
        cert_pts = len(certs) * 5
    score += cert_pts
    breakdown["certificate"] = {"count": len(certs), "points": cert_pts, "max": 15}

    # Achievements: 3 pts each, max 5 achievements (15 max)
    ach_pts = min(len(achievements), 5) * 3
    score += ach_pts
    breakdown["achievement"] = {"count": len(achievements), "points": ach_pts, "max": 15}

    # Cap at 100
    total = min(round(score, 1), 100.0)

    # Star rating
    if total >= 85:
        stars = 5
    elif total >= 70:
        stars = 4
    elif total >= 55:
        stars = 3
    elif total >= 40:
        stars = 2
    else:
        stars = 1

    # Category label
    label_map = {5: "Excellent", 4: "Very Good", 3: "Good", 2: "Average", 1: "Needs Improvement"}

    return {
        "total_score": total,
        "star_rating": stars,
        "category": label_map[stars],
        "breakdown": breakdown,
    }


# ============================================================================
# HELPER
# ============================================================================

def _submission_to_dict(sub: SSMSubmission, activities: list, reviews: list) -> dict:
    breakdown = {}
    try:
        if sub.score_breakdown:
            breakdown = json.loads(sub.score_breakdown)
    except Exception:
        pass

    return {
        "id": sub.id,
        "student_id": sub.student_id,
        "gpa": sub.gpa,
        "attendance_input": sub.attendance_input,
        "total_score": sub.total_score,
        "star_rating": sub.star_rating,
        "score_breakdown": breakdown,
        "status": sub.status,
        "submitted_at": sub.submitted_at.isoformat() if sub.submitted_at else None,
        "created_at": sub.created_at.isoformat() if sub.created_at else None,
        "updated_at": sub.updated_at.isoformat() if sub.updated_at else None,
        "activities": [_activity_to_dict(a) for a in activities],
        "reviews": [_review_to_dict(r) for r in reviews],
    }


def _activity_to_dict(a: SSMActivity) -> dict:
    return {
        "id": a.id,
        "submission_id": a.submission_id,
        "type": a.type,
        "title": a.title,
        "description": a.description,
        "duration": a.duration,
        "organization": a.organization,
        "score": a.score,
        "proof_file_name": a.proof_file_name,
        "has_proof": a.proof_file_data is not None,
        "created_at": a.created_at.isoformat() if a.created_at else None,
    }


def _review_to_dict(r: SSMReview) -> dict:
    return {
        "id": r.id,
        "submission_id": r.submission_id,
        "reviewer_role": r.reviewer_role,
        "reviewer_id": r.reviewer_id,
        "reviewer_name": r.reviewer_name,
        "status": r.status,
        "remarks": r.remarks,
        "reviewed_at": r.reviewed_at.isoformat() if r.reviewed_at else None,
    }


def _get_or_create_submission(student_id: int, db: Session) -> SSMSubmission:
    sub = db.query(SSMSubmission).filter(
        SSMSubmission.student_id == student_id,
        SSMSubmission.status.in_(["draft", "mentor_rejected"]),
    ).order_by(SSMSubmission.id.desc()).first()

    if not sub:
        sub = SSMSubmission(student_id=student_id, status="draft")
        db.add(sub)
        db.commit()
        db.refresh(sub)
    return sub


# ============================================================================
# 1. SAVE / UPDATE FORM (GPA + Attendance)
# ============================================================================

@router.post("/save")
def save_form(
    payload: SaveFormRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Create or update the student's draft SSM form."""
    # Verify student exists
    student = db.query(Student).filter(Student.id == payload.student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    # Students can only update their own submission
    if current_user["role"] == "student":
        if student.user_id != current_user["user_id"]:
            raise HTTPException(status_code=403, detail="Access denied")

    sub = _get_or_create_submission(payload.student_id, db)

    if sub.status not in ["draft", "mentor_rejected"]:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot edit a submission with status '{sub.status}'. "
                   "Wait for rejection or create a new one."
        )

    if payload.gpa is not None:
        if payload.gpa < 0 or payload.gpa > 10:
            raise HTTPException(status_code=400, detail="GPA must be between 0 and 10")
        sub.gpa = payload.gpa

    if payload.attendance_input is not None:
        if payload.attendance_input < 0 or payload.attendance_input > 100:
            raise HTTPException(status_code=400, detail="Attendance must be 0–100")
        sub.attendance_input = payload.attendance_input

    # Recalculate score
    activities = db.query(SSMActivity).filter(SSMActivity.submission_id == sub.id).all()
    result = calculate_score(sub, activities)
    sub.total_score = result["total_score"]
    sub.star_rating = result["star_rating"]
    sub.score_breakdown = json.dumps(result["breakdown"])

    db.commit()
    db.refresh(sub)

    reviews = db.query(SSMReview).filter(SSMReview.submission_id == sub.id).all()
    return {
        "message": "Form saved",
        "submission": _submission_to_dict(sub, activities, reviews),
    }


# ============================================================================
# 2. ADD ACTIVITY
# ============================================================================

@router.post("/activity")
def add_activity(
    payload: AddActivityRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Add an internship / certificate / project / achievement to the submission."""
    sub = db.query(SSMSubmission).filter(SSMSubmission.id == payload.submission_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Submission not found")

    if sub.status not in ["draft", "mentor_rejected"]:
        raise HTTPException(status_code=400, detail="Cannot modify a submitted form")

    valid_types = ["internship", "certificate", "project", "achievement"]
    if payload.type not in valid_types:
        raise HTTPException(status_code=400, detail=f"Type must be one of: {valid_types}")

    activity = SSMActivity(
        submission_id=sub.id,
        type=payload.type,
        title=payload.title,
        description=payload.description,
        duration=payload.duration,
        organization=payload.organization,
        proof_file_name=payload.proof_file_name,
        proof_file_data=payload.proof_file_data,
    )
    db.add(activity)
    db.commit()
    db.refresh(activity)

    # Recalculate score
    all_activities = db.query(SSMActivity).filter(SSMActivity.submission_id == sub.id).all()
    result = calculate_score(sub, all_activities)
    sub.total_score = result["total_score"]
    sub.star_rating = result["star_rating"]
    sub.score_breakdown = json.dumps(result["breakdown"])
    db.commit()

    return {
        "message": "Activity added",
        "activity": _activity_to_dict(activity),
        "new_score": result["total_score"],
        "star_rating": result["star_rating"],
    }


# ============================================================================
# 3. DELETE ACTIVITY
# ============================================================================

@router.delete("/activity/{activity_id}")
def delete_activity(
    activity_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    activity = db.query(SSMActivity).filter(SSMActivity.id == activity_id).first()
    if not activity:
        raise HTTPException(status_code=404, detail="Activity not found")

    sub = db.query(SSMSubmission).filter(SSMSubmission.id == activity.submission_id).first()
    if sub and sub.status not in ["draft", "mentor_rejected"]:
        raise HTTPException(status_code=400, detail="Cannot modify a submitted form")

    db.delete(activity)
    db.commit()

    # Recalculate
    if sub:
        all_activities = db.query(SSMActivity).filter(SSMActivity.submission_id == sub.id).all()
        result = calculate_score(sub, all_activities)
        sub.total_score = result["total_score"]
        sub.star_rating = result["star_rating"]
        sub.score_breakdown = json.dumps(result["breakdown"])
        db.commit()

    return {"message": "Activity deleted"}


# ============================================================================
# 4. CALCULATE SCORE (manual trigger)
# ============================================================================

@router.post("/calculate/{submission_id}")
def calculate(
    submission_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    sub = db.query(SSMSubmission).filter(SSMSubmission.id == submission_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Submission not found")

    activities = db.query(SSMActivity).filter(SSMActivity.submission_id == sub.id).all()
    result = calculate_score(sub, activities)

    sub.total_score = result["total_score"]
    sub.star_rating = result["star_rating"]
    sub.score_breakdown = json.dumps(result["breakdown"])
    db.commit()

    return result


# ============================================================================
# 5. SUBMIT FOR APPROVAL
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

    if sub.status not in ["draft", "mentor_rejected"]:
        raise HTTPException(status_code=400, detail=f"Cannot submit — current status is '{sub.status}'")

    # Validate minimum data
    if sub.gpa is None:
        raise HTTPException(status_code=400, detail="GPA is required before submitting")

    sub.status = "submitted"
    sub.submitted_at = datetime.now()
    db.commit()

    return {"message": "Submitted for mentor review", "status": "submitted"}


# ============================================================================
# 6. MENTOR REVIEW
# ============================================================================

@router.post("/review/mentor")
def mentor_review(
    payload: ReviewRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ["faculty", "admin"]:
        raise HTTPException(status_code=403, detail="Only faculty/mentors can review")

    sub = db.query(SSMSubmission).filter(SSMSubmission.id == payload.submission_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Submission not found")

    if sub.status != "submitted":
        raise HTTPException(status_code=400, detail=f"Submission is not pending mentor review (status: {sub.status})")

    if payload.status not in ["approved", "rejected"]:
        raise HTTPException(status_code=400, detail="Status must be 'approved' or 'rejected'")

    # Get reviewer info
    faculty = db.query(Faculty).filter(Faculty.user_id == current_user["user_id"]).first()
    reviewer_name = faculty.full_name if faculty else "Faculty"

    review = SSMReview(
        submission_id=sub.id,
        reviewer_role="mentor",
        reviewer_id=current_user["user_id"],
        reviewer_name=reviewer_name,
        status=payload.status,
        remarks=payload.remarks,
        reviewed_at=datetime.now(),
    )
    db.add(review)

    sub.status = "mentor_approved" if payload.status == "approved" else "mentor_rejected"
    db.commit()

    return {
        "message": f"Mentor {payload.status} the submission",
        "new_status": sub.status,
    }


# ============================================================================
# 7. HOD REVIEW
# ============================================================================

@router.post("/review/hod")
def hod_review(
    payload: ReviewRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ["faculty", "admin"]:
        raise HTTPException(status_code=403, detail="Only HOD can do final review")

    sub = db.query(SSMSubmission).filter(SSMSubmission.id == payload.submission_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Submission not found")

    if sub.status != "mentor_approved":
        raise HTTPException(
            status_code=400,
            detail=f"Submission must be mentor-approved first (status: {sub.status})"
        )

    if payload.status not in ["approved", "rejected"]:
        raise HTTPException(status_code=400, detail="Status must be 'approved' or 'rejected'")

    faculty = db.query(Faculty).filter(Faculty.user_id == current_user["user_id"]).first()
    reviewer_name = faculty.full_name if faculty else "HOD"

    review = SSMReview(
        submission_id=sub.id,
        reviewer_role="hod",
        reviewer_id=current_user["user_id"],
        reviewer_name=reviewer_name,
        status=payload.status,
        remarks=payload.remarks,
        reviewed_at=datetime.now(),
    )
    db.add(review)

    sub.status = "hod_approved" if payload.status == "approved" else "hod_rejected"
    db.commit()

    return {
        "message": f"HOD {payload.status} the submission. Score is now final.",
        "new_status": sub.status,
        "final_score": sub.total_score if payload.status == "approved" else None,
    }


# ============================================================================
# 8. GET STUDENT RESULT / SUBMISSION
# ============================================================================

@router.get("/result/{student_id}")
def get_result(
    student_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Returns the most recent submission for a student."""
    sub = db.query(SSMSubmission).filter(
        SSMSubmission.student_id == student_id
    ).order_by(SSMSubmission.id.desc()).first()

    if not sub:
        # Return empty draft info
        return {
            "has_submission": False,
            "submission": None,
            "message": "No submission yet",
        }

    activities = db.query(SSMActivity).filter(SSMActivity.submission_id == sub.id).all()
    reviews = db.query(SSMReview).filter(SSMReview.submission_id == sub.id).all()

    return {
        "has_submission": True,
        "submission": _submission_to_dict(sub, activities, reviews),
    }


# ============================================================================
# 9. GET ALL SUBMISSIONS (Faculty / HOD review list)
# ============================================================================

@router.get("/submissions")
def list_submissions(
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """List all submissions — for faculty/HOD review screens."""
    if current_user["role"] not in ["faculty", "admin", "principal"]:
        raise HTTPException(status_code=403, detail="Access denied")

    query = db.query(SSMSubmission)
    if status:
        query = query.filter(SSMSubmission.status == status)

    submissions = query.order_by(SSMSubmission.id.desc()).all()

    result = []
    for sub in submissions:
        activities = db.query(SSMActivity).filter(SSMActivity.submission_id == sub.id).all()
        reviews = db.query(SSMReview).filter(SSMReview.submission_id == sub.id).all()

        # Get student name
        student = db.query(Student).filter(Student.id == sub.student_id).first()
        entry = _submission_to_dict(sub, activities, reviews)
        entry["student_name"] = student.full_name if student else "Unknown"
        entry["register_number"] = student.register_number if student else ""
        entry["department"] = student.department if student else ""
        entry["year"] = student.year if student else ""
        result.append(entry)

    return result


# ============================================================================
# 10. GET PROOF FILE (download)
# ============================================================================

@router.get("/activity/{activity_id}/proof")
def get_proof(
    activity_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    activity = db.query(SSMActivity).filter(SSMActivity.id == activity_id).first()
    if not activity or not activity.proof_file_data:
        raise HTTPException(status_code=404, detail="Proof file not found")

    return {
        "file_name": activity.proof_file_name,
        "file_data": activity.proof_file_data,  # base64
    }


# ============================================================================
# 11. DELETE SUBMISSION (only drafts)
# ============================================================================

@router.delete("/submission/{submission_id}")
def delete_submission(
    submission_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    sub = db.query(SSMSubmission).filter(SSMSubmission.id == submission_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Submission not found")

    if sub.status != "draft":
        raise HTTPException(status_code=400, detail="Only draft submissions can be deleted")

    # Delete activities
    db.query(SSMActivity).filter(SSMActivity.submission_id == sub.id).delete()
    db.delete(sub)
    db.commit()

    return {"message": "Submission deleted"}
