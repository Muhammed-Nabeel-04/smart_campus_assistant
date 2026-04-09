# File: app/routes/ssm_routes.py  (REPLACE the old version entirely)
# ─────────────────────────────────────────────────────────────────────────────
# SSM — Student Success Matrix  (Dhaanish iTech, AY 2025-26)
# Total: 500 points across 5 categories (each max 100)
# Star rating: 250-299=1⭐ | 300-349=2⭐ | 350-399=3⭐ | 400-449=4⭐ | 450+=5⭐
# ─────────────────────────────────────────────────────────────────────────────

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import json

from app.services.deps import get_db, get_current_user
from app.models.ssm import SSMSubmission, SSMReview
from app.models.student import Student
from app.models.faculty import Faculty

router = APIRouter(prefix="/ssm", tags=["SSM Performance"])


# ============================================================================
# PYDANTIC SCHEMA  — one big form with all 25 fields
# ============================================================================

class SaveFormRequest(BaseModel):
    student_id: int

    # Category 1: Academic Performance
    iat_gpa: Optional[float] = None
    university_gpa: Optional[float] = None
    attendance_pct: Optional[float] = None
    mentor_feedback: Optional[str] = None      # Excellent / Good / Average
    hod_feedback: Optional[str] = None         # Excellent / Good / Average
    project_status: Optional[str] = None       # Fully Completed / Partial / Concept
    consistency_index: Optional[float] = None

    # Category 2: Student Development Activities
    nptel_level: Optional[str] = None          # Elite+Silver / Elite / Completed / Participated
    online_cert_count: Optional[int] = None
    internship_duration: Optional[str] = None  # 4weeks+ / 2-4weeks / 1-2weeks / Participation
    competition_result: Optional[str] = None   # Winner / Finalist / Participation
    publication_type: Optional[str] = None     # Patent / Conference / Prototype
    skill_programs: Optional[int] = None

    # Category 3: Skill, Professional Readiness & Research
    tech_skill_level: Optional[str] = None     # Excellent / Good / Basic
    soft_skill_level: Optional[str] = None     # Excellent / Good / Average
    placement_readiness: Optional[float] = None
    placement_outcome: Optional[str] = None    # 15+LPA / 10-14LPA / 7.5-9.9LPA / <7.5LPA
    industry_interactions: Optional[int] = None
    research_papers: Optional[int] = None
    innovation_level: Optional[str] = None     # Implemented / Proposed

    # Category 4: Discipline & Contribution
    discipline_conduct: Optional[str] = None   # Exemplary / Minor Issues / Issues
    punctuality_level: Optional[str] = None    # ge95NoLate / 90-94 / 85-89
    dress_code: Optional[str] = None           # 100% Adherence / Highly Regular / General
    dept_event_contribution: Optional[str] = None  # Impactful / Useful / Minor
    social_media_level: Optional[str] = None   # ActiveCreator / Regular / Shares / Occasional / Minimal

    # Category 5: Leadership Roles & Initiatives
    leadership_role: Optional[str] = None      # College / Department / Class
    event_leadership: Optional[str] = None     # Led2+ / Led1 / Assisted
    team_management: Optional[str] = None      # Excellent / Good / Limited
    innovation_initiative: Optional[str] = None  # Implemented / Proposed / Minor
    community_leadership: Optional[str] = None  # Led / Active / Minimal


class ReviewRequest(BaseModel):
    submission_id: int
    status: str
    remarks: Optional[str] = None


# ============================================================================
# SCORING ENGINE  (out of 500 total, 100 per category)
# ============================================================================

def calculate_ssm_score(f: SaveFormRequest) -> dict:
    bd = {}

    # ── Category 1: Academic Performance (max 100) ────────────────────────
    c1 = 0

    g = f.iat_gpa or 0
    p = 15 if g >= 9 else (10 if g >= 8 else (5 if g >= 7 else 0))
    bd["1_1_iat_gpa"] = {"label": "Internal Assessment GPA", "value": g, "points": p, "max": 15}
    c1 += p

    g = f.university_gpa or 0
    p = 15 if g >= 9 else (10 if g >= 8 else (5 if g >= 7 else 0))
    bd["1_2_uni_gpa"] = {"label": "University Exam GPA", "value": g, "points": p, "max": 15}
    c1 += p

    a = f.attendance_pct or 0
    p = 15 if a >= 95 else (10 if a >= 90 else (5 if a >= 85 else 0))
    bd["1_3_attendance"] = {"label": "Attendance & Academic Discipline", "value": a, "points": p, "max": 15}
    c1 += p

    mf = f.mentor_feedback or ""
    p = 15 if mf == "Excellent" else (10 if mf == "Good" else (5 if mf == "Average" else 0))
    bd["1_4_mentor"] = {"label": "Mentor Feedback", "value": mf, "points": p, "max": 15}
    c1 += p

    hf = f.hod_feedback or ""
    p = 15 if hf == "Excellent" else (10 if hf == "Good" else (5 if hf == "Average" else 0))
    bd["1_5_hod"] = {"label": "HoD Feedback", "value": hf, "points": p, "max": 15}
    c1 += p

    ps = f.project_status or ""
    p = 15 if ps == "Fully Completed" else (10 if ps == "Partial" else (5 if ps == "Concept" else 0))
    bd["1_6_project"] = {"label": "Project (Beyond Curriculum)", "value": ps, "points": p, "max": 15}
    c1 += p

    ci = f.consistency_index or 0
    p = 15 if ci >= 95 else (10 if ci >= 90 else (5 if ci >= 85 else 0))
    bd["1_7_consistency"] = {"label": "Academic Consistency Index", "value": ci, "points": p, "max": 15}
    c1 += p

    cat1 = min(c1, 100)

    # ── Category 2: Student Development Activities (max 100) ──────────────
    c2 = 0

    nl = f.nptel_level or ""
    p = 20 if nl in ["Elite+Silver", "Elite+Gold", "Top5%"] else (15 if nl == "Elite" else (10 if nl == "Completed" else (5 if nl == "Participated" else 0)))
    bd["2_1_nptel"] = {"label": "NPTEL/SWAYAM Certifications", "value": nl, "points": p, "max": 20}
    c2 += p

    oc = f.online_cert_count or 0
    p = 15 if oc >= 3 else (10 if oc == 2 else (5 if oc >= 1 else 0))
    bd["2_2_online_cert"] = {"label": "Industry Online Certifications", "value": oc, "points": p, "max": 15}
    c2 += p

    iid = f.internship_duration or ""
    p = 20 if iid == "4weeks+" else (15 if iid == "2-4weeks" else (10 if iid == "1-2weeks" else (5 if iid == "Participation" else 0)))
    bd["2_3_internship"] = {"label": "Internship / In-plant Training", "value": iid, "points": p, "max": 20}
    c2 += p

    cr = f.competition_result or ""
    p = 20 if cr == "Winner" else (10 if cr == "Finalist" else (5 if cr == "Participation" else 0))
    bd["2_4_competition"] = {"label": "Technical Competitions / Hackathons", "value": cr, "points": p, "max": 20}
    c2 += p

    pt = f.publication_type or ""
    p = 15 if pt == "Patent" else (10 if pt == "Conference" else (5 if pt == "Prototype" else 0))
    bd["2_5_publication"] = {"label": "Publications / Patents / Product", "value": pt, "points": p, "max": 15}
    c2 += p

    sp = f.skill_programs or 0
    p = 15 if sp >= 3 else (10 if sp == 2 else (5 if sp >= 1 else 0))
    bd["2_6_skill_programs"] = {"label": "Professional Skill Development", "value": sp, "points": p, "max": 15}
    c2 += p

    cat2 = min(c2, 100)

    # ── Category 3: Skill, Prof. Readiness & Research (max 100) ──────────
    c3 = 0

    ts = f.tech_skill_level or ""
    p = 20 if ts == "Excellent" else (10 if ts == "Good" else (5 if ts == "Basic" else 0))
    bd["3_1_tech_skill"] = {"label": "Technical Skill Competency", "value": ts, "points": p, "max": 20}
    c3 += p

    ss = f.soft_skill_level or ""
    p = 20 if ss == "Excellent" else (10 if ss == "Good" else (5 if ss == "Average" else 0))
    bd["3_2_soft_skill"] = {"label": "Soft Skills & Communication", "value": ss, "points": p, "max": 20}
    c3 += p

    pr = f.placement_readiness or 0
    p = 20 if pr >= 95 else (10 if pr >= 80 else (5 if pr >= 75 else 0))
    bd["3_3_placement_ready"] = {"label": "Placement Readiness & Training", "value": pr, "points": p, "max": 20}
    c3 += p

    po = f.placement_outcome or ""
    p = 20 if po == "15+LPA" else (15 if po == "10-14LPA" else (10 if po == "7.5-9.9LPA" else (5 if po == "<7.5LPA" else 0)))
    bd["3_4_placement_out"] = {"label": "Placement Outcome / Career", "value": po, "points": p, "max": 20}
    c3 += p

    ii = f.industry_interactions or 0
    p = 20 if ii >= 3 else (10 if ii == 2 else (5 if ii >= 1 else 0))
    bd["3_5_industry"] = {"label": "Industry Interaction & Exposure", "value": ii, "points": p, "max": 20}
    c3 += p

    rp = f.research_papers or 0
    p = 10 if rp >= 3 else (5 if rp >= 1 else 0)
    bd["3_6_research"] = {"label": "Research Paper Reading", "value": rp, "points": p, "max": 10}
    c3 += p

    il = f.innovation_level or ""
    p = 10 if il == "Implemented" else (5 if il == "Proposed" else 0)
    bd["3_7_innovation"] = {"label": "Innovation / Idea Contribution", "value": il, "points": p, "max": 10}
    c3 += p

    cat3 = min(c3, 100)

    # ── Category 4: Discipline & Contribution (max 100) ───────────────────
    c4 = 0

    dc = f.discipline_conduct or ""
    p = 20 if dc == "Exemplary" else (10 if dc == "Minor Issues" else 0)
    bd["4_1_discipline"] = {"label": "Discipline & Code of Conduct", "value": dc, "points": p, "max": 20}
    c4 += p

    pl = f.punctuality_level or ""
    p = 15 if pl == "ge95NoLate" else (10 if pl == "90-94" else (5 if pl == "85-89" else 0))
    bd["4_2_punctuality"] = {"label": "Attendance & Punctuality Discipline", "value": pl, "points": p, "max": 15}
    c4 += p

    dd = f.dress_code or ""
    p = 15 if dd == "100% Adherence" else (10 if dd == "Highly Regular" else (5 if dd == "General" else 0))
    bd["4_3_dress_code"] = {"label": "Dress Code & Professional Appearance", "value": dd, "points": p, "max": 15}
    c4 += p

    de = f.dept_event_contribution or ""
    p = 25 if de == "Impactful" else (15 if de == "Useful" else (5 if de == "Minor" else 0))
    bd["4_4_dept_events"] = {"label": "Contribution to Department Events", "value": de, "points": p, "max": 25}
    c4 += p

    sm = f.social_media_level or ""
    p = (25 if sm == "ActiveCreator" else 20 if sm == "Regular" else
         15 if sm == "Shares" else 10 if sm == "Occasional" else
         5 if sm == "Minimal" else 0)
    bd["4_5_social"] = {"label": "Social Media & Promotional Activities", "value": sm, "points": p, "max": 25}
    c4 += p

    cat4 = min(c4, 100)

    # ── Category 5: Leadership Roles & Initiatives (max 100) ──────────────
    c5 = 0

    lr = f.leadership_role or ""
    p = 15 if lr == "College" else (10 if lr == "Department" else (5 if lr == "Class" else 0))
    bd["5_1_leadership"] = {"label": "Formal Leadership Roles", "value": lr, "points": p, "max": 15}
    c5 += p

    el = f.event_leadership or ""
    p = 15 if el == "Led2+" else (10 if el == "Led1" else (5 if el == "Assisted" else 0))
    bd["5_2_event_lead"] = {"label": "Event Leadership & Coordination", "value": el, "points": p, "max": 15}
    c5 += p

    tm = f.team_management or ""
    p = 15 if tm == "Excellent" else (10 if tm == "Good" else (5 if tm == "Limited" else 0))
    bd["5_3_team"] = {"label": "Team Management & Collaboration", "value": tm, "points": p, "max": 15}
    c5 += p

    ini = f.innovation_initiative or ""
    p = 25 if ini == "Implemented" else (15 if ini == "Proposed" else (5 if ini == "Minor" else 0))
    bd["5_4_innovation"] = {"label": "Innovation & Initiative", "value": ini, "points": p, "max": 25}
    c5 += p

    cl = f.community_leadership or ""
    p = 25 if cl == "Led" else (15 if cl == "Active" else (5 if cl == "Minimal" else 0))
    bd["5_5_community"] = {"label": "Social / Community Leadership", "value": cl, "points": p, "max": 25}
    c5 += p

    cat5 = min(c5, 100)

    # ── Total & Stars ──────────────────────────────────────────────────────
    total = cat1 + cat2 + cat3 + cat4 + cat5

    stars = (5 if total >= 450 else 4 if total >= 400 else
             3 if total >= 350 else 2 if total >= 300 else
             1 if total >= 250 else 0)

    label = {5: "Excellent", 4: "Very Good", 3: "Good",
             2: "Average", 1: "Below Average", 0: "Not Rated Yet"}.get(stars, "")

    bd["_summary"] = {
        "cat1": cat1, "cat2": cat2, "cat3": cat3, "cat4": cat4, "cat5": cat5,
        "total": total, "stars": stars, "label": label,
    }

    return {"total_score": float(total), "star_rating": stars,
            "category_label": label, "breakdown": bd}


# ============================================================================
# HELPERS
# ============================================================================

def _sub_to_dict(sub: SSMSubmission, db: Session) -> dict:
    bd = {}
    try:
        if sub.score_breakdown:
            bd = json.loads(sub.score_breakdown)
    except Exception:
        pass

    form_data = {}
    try:
        if hasattr(sub, 'form_data') and sub.form_data:
            form_data = json.loads(sub.form_data)
    except Exception:
        pass

    reviews = db.query(SSMReview).filter(SSMReview.submission_id == sub.id).all()

    return {
        "id": sub.id,
        "student_id": sub.student_id,
        "total_score": sub.total_score,
        "star_rating": sub.star_rating,
        "score_breakdown": bd,
        "status": sub.status,
        "form_data": form_data,
        "submitted_at": sub.submitted_at.isoformat() if sub.submitted_at else None,
        "updated_at": sub.updated_at.isoformat() if sub.updated_at else None,
        "reviews": [
            {"id": r.id, "reviewer_role": r.reviewer_role,
             "reviewer_name": r.reviewer_name, "status": r.status,
             "remarks": r.remarks,
             "reviewed_at": r.reviewed_at.isoformat() if r.reviewed_at else None}
            for r in reviews
        ],
    }


# ============================================================================
# ENDPOINTS
# ============================================================================

@router.post("/save")
def save_form(payload: SaveFormRequest, db: Session = Depends(get_db),
              current_user: dict = Depends(get_current_user)):
    student = db.query(Student).filter(Student.id == payload.student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    if current_user["role"] == "student" and student.user_id != current_user["user_id"]:
        raise HTTPException(status_code=403, detail="Access denied")

    sub = db.query(SSMSubmission).filter(
        SSMSubmission.student_id == payload.student_id,
        SSMSubmission.status.in_(["draft", "mentor_rejected"]),
    ).order_by(SSMSubmission.id.desc()).first()

    if not sub:
        sub = SSMSubmission(student_id=payload.student_id, status="draft")
        db.add(sub); db.commit(); db.refresh(sub)

    if sub.status not in ["draft", "mentor_rejected"]:
        raise HTTPException(status_code=400, detail=f"Cannot edit status '{sub.status}'")

    form_dict = {k: v for k, v in payload.dict().items() if k != "student_id" and v is not None}
    sub.form_data = json.dumps(form_dict)

    result = calculate_ssm_score(payload)
    sub.total_score = result["total_score"]
    sub.star_rating = result["star_rating"]
    sub.score_breakdown = json.dumps(result["breakdown"])

    db.commit(); db.refresh(sub)
    return {
        "message": "Form saved",
        "submission": _sub_to_dict(sub, db),
        "score_preview": {
            "total": result["total_score"],
            "stars": result["star_rating"],
            "label": result["category_label"],
            "summary": result["breakdown"]["_summary"],
        },
    }


@router.post("/submit/{submission_id}")
def submit_for_approval(submission_id: int, db: Session = Depends(get_db),
                        current_user: dict = Depends(get_current_user)):
    sub = db.query(SSMSubmission).filter(SSMSubmission.id == submission_id).first()
    if not sub: raise HTTPException(status_code=404, detail="Not found")
    if sub.status not in ["draft", "mentor_rejected"]:
        raise HTTPException(status_code=400, detail=f"Cannot submit, status: {sub.status}")
    sub.status = "submitted"; sub.submitted_at = datetime.now()
    db.commit()
    return {"message": "Submitted for mentor review", "status": "submitted"}


@router.get("/result/{student_id}")
def get_result(student_id: int, db: Session = Depends(get_db),
               current_user: dict = Depends(get_current_user)):
    sub = db.query(SSMSubmission).filter(
        SSMSubmission.student_id == student_id
    ).order_by(SSMSubmission.id.desc()).first()
    if not sub: return {"has_submission": False, "submission": None}
    return {"has_submission": True, "submission": _sub_to_dict(sub, db)}


@router.get("/submissions")
def list_submissions(status: Optional[str] = None, db: Session = Depends(get_db),
                     current_user: dict = Depends(get_current_user)):
    if current_user["role"] not in ["faculty", "admin", "principal"]:
        raise HTTPException(status_code=403, detail="Access denied")
    query = db.query(SSMSubmission)
    if status: query = query.filter(SSMSubmission.status == status)
    result = []
    for sub in query.order_by(SSMSubmission.id.desc()).all():
        student = db.query(Student).filter(Student.id == sub.student_id).first()
        entry = _sub_to_dict(sub, db)
        entry["student_name"] = student.full_name if student else "Unknown"
        entry["register_number"] = student.register_number if student else ""
        entry["department"] = student.department if student else ""
        entry["year"] = student.year if student else ""
        result.append(entry)
    return result


@router.post("/review/mentor")
def mentor_review(payload: ReviewRequest, db: Session = Depends(get_db),
                  current_user: dict = Depends(get_current_user)):
    if current_user["role"] not in ["faculty", "admin"]:
        raise HTTPException(status_code=403, detail="Only faculty can review")
    sub = db.query(SSMSubmission).filter(SSMSubmission.id == payload.submission_id).first()
    if not sub: raise HTTPException(status_code=404, detail="Not found")
    if sub.status != "submitted":
        raise HTTPException(status_code=400, detail=f"Not pending review (status: {sub.status})")
    if payload.status not in ["approved", "rejected"]:
        raise HTTPException(status_code=400, detail="Must be approved or rejected")
    faculty = db.query(Faculty).filter(Faculty.user_id == current_user["user_id"]).first()
    db.add(SSMReview(submission_id=sub.id, reviewer_role="mentor",
                     reviewer_id=current_user["user_id"],
                     reviewer_name=faculty.full_name if faculty else "Faculty",
                     status=payload.status, remarks=payload.remarks, reviewed_at=datetime.now()))
    sub.status = "mentor_approved" if payload.status == "approved" else "mentor_rejected"
    db.commit()
    return {"message": f"Mentor {payload.status}", "new_status": sub.status}


@router.post("/review/hod")
def hod_review(payload: ReviewRequest, db: Session = Depends(get_db),
               current_user: dict = Depends(get_current_user)):
    if current_user["role"] not in ["faculty", "admin"]:
        raise HTTPException(status_code=403, detail="Only HOD can do final review")
    sub = db.query(SSMSubmission).filter(SSMSubmission.id == payload.submission_id).first()
    if not sub: raise HTTPException(status_code=404, detail="Not found")
    if sub.status != "mentor_approved":
        raise HTTPException(status_code=400, detail=f"Must be mentor-approved first (status: {sub.status})")
    if payload.status not in ["approved", "rejected"]:
        raise HTTPException(status_code=400, detail="Must be approved or rejected")
    faculty = db.query(Faculty).filter(Faculty.user_id == current_user["user_id"]).first()
    db.add(SSMReview(submission_id=sub.id, reviewer_role="hod",
                     reviewer_id=current_user["user_id"],
                     reviewer_name=faculty.full_name if faculty else "HOD",
                     status=payload.status, remarks=payload.remarks, reviewed_at=datetime.now()))
    sub.status = "hod_approved" if payload.status == "approved" else "hod_rejected"
    db.commit()
    return {"message": f"HOD {payload.status} — score is final.",
            "new_status": sub.status, "final_score": sub.total_score}


@router.delete("/submission/{submission_id}")
def delete_submission(submission_id: int, db: Session = Depends(get_db),
                      current_user: dict = Depends(get_current_user)):
    sub = db.query(SSMSubmission).filter(SSMSubmission.id == submission_id).first()
    if not sub: raise HTTPException(status_code=404, detail="Not found")
    if sub.status != "draft": raise HTTPException(status_code=400, detail="Only drafts can be deleted")
    db.delete(sub); db.commit()
    return {"message": "Deleted"}
