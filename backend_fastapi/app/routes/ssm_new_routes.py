# File: app/routes/ssm_new_routes.py
# ─────────────────────────────────────────────────────────────────────────────
# All SSM endpoints — student, mentor, HOD
# Adapted for campus app:
#   - Uses SessionManager token auth (get_current_user from deps.py)
#   - Campus Student/Faculty models (not single users table)
#   - Base64 file storage (not cloud)
#   - SQLite (no MySQL enums)
# ─────────────────────────────────────────────────────────────────────────────

import base64
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.services.deps import get_db, get_current_user
from app.models.ssm_new import (
    SSMForm, AcademicData, DevelopmentData, SkillData,
    DisciplineData, LeadershipData, CalculatedScore, StudentActivity
)
from app.models.student import Student
from app.models.faculty import Faculty
from app.models.class_model import ClassModel
from app.models.department import Department
from app.services.ssm_scoring_new import calculate_and_save
from app.services.ssm_activity_helper import (
    run_ocr_verify, patch_form_data, get_or_create_form, serialize_activity
)

router = APIRouter(prefix="/ssm", tags=["SSM Performance"])

MAX_FILE_MB = 5


# ─── HELPERS ──────────────────────────────────────────────────────────────────

def _get_student(student_id: int, db: Session) -> Student:
    s = db.query(Student).filter(Student.id == student_id).first()
    if not s:
        raise HTTPException(status_code=404, detail="Student not found")
    return s


def _get_mentor_for_student(student: Student, db: Session) -> Optional[int]:
    """Get the CC faculty id for the student's class."""
    # Find department
    dept = db.query(Department).filter(Department.name == student.department).first()
    if not dept:
        return None
    
    # Find class
    cls = db.query(ClassModel).filter(
        ClassModel.department_id == dept.id,
        ClassModel.year == student.year,
        ClassModel.section == student.section
    ).first()
    
    if not cls:
        return None
        
    # Find faculty where is_cc=True and cc_class_id == cls.id
    mentor = db.query(Faculty).filter(
        Faculty.cc_class_id == cls.id,
        Faculty.is_cc == True
    ).first()
    
    return mentor.id if mentor else None


def _form_to_dict(form: SSMForm, db: Session, include_activities: bool = False) -> dict:
    sc = db.query(CalculatedScore).filter(CalculatedScore.form_id == form.id).first()
    student = db.query(Student).filter(Student.id == form.student_id).first()

    scores = None
    if sc:
        scores = {
            "academic": sc.academic_score, "development": sc.development_score,
            "skill": sc.skill_score, "discipline": sc.discipline_score,
            "leadership": sc.leadership_score, "grand_total": sc.grand_total,
            "star_rating": sc.star_rating,
        }

    result = {
        "form_id": form.id, "student_id": form.student_id,
        "student_name": student.full_name if student else "",
        "register_number": student.register_number if student else "",
        "department": student.department if student else "",
        "year": student.year if student else "",
        "section": student.section if student else "",
        "academic_year": form.academic_year,
        "status": form.status,
        "mentor_remarks": form.mentor_remarks,
        "hod_remarks": form.hod_remarks,
        "rejection_reason": form.rejection_reason,
        "submitted_at": form.submitted_at.isoformat() if form.submitted_at else None,
        "approved_at": form.approved_at.isoformat() if form.approved_at else None,
        "live_score": scores,
    }

    if include_activities:
        activities = db.query(StudentActivity).filter(
            StudentActivity.form_id == form.id
        ).order_by(StudentActivity.submitted_at.desc()).all()
        result["activities"] = [serialize_activity(a) for a in activities]
        result["total_activities"] = len(activities)

    return result


# ============================================================================
# STUDENT ENDPOINTS
# ============================================================================

@router.get("/student/dashboard")
def student_dashboard(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    student = db.query(Student).filter(Student.user_id == current_user["user_id"]).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    mentor_id = _get_mentor_for_student(student, db)
    form = get_or_create_form(student.id, mentor_id, db)

    return _form_to_dict(form, db, include_activities=True)


@router.get("/student/activities")
def get_my_activities(
    category: Optional[str] = None,
    mentor_status: Optional[str] = None,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    student = db.query(Student).filter(Student.user_id == current_user["user_id"]).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    mentor_id = _get_mentor_for_student(student, db)
    form = get_or_create_form(student.id, mentor_id, db)

    query = db.query(StudentActivity).filter(StudentActivity.form_id == form.id)
    if category:
        query = query.filter(StudentActivity.category == category)
    if mentor_status:
        query = query.filter(StudentActivity.mentor_status == mentor_status)

    total = query.count()
    activities = query.order_by(StudentActivity.submitted_at.desc()).offset(offset).limit(limit).all()

    sc = db.query(CalculatedScore).filter(CalculatedScore.form_id == form.id).first()
    live_score = None
    if sc:
        live_score = {
            "academic": sc.academic_score, "development": sc.development_score,
            "skill": sc.skill_score, "discipline": sc.discipline_score,
            "leadership": sc.leadership_score, "grand_total": sc.grand_total,
            "star_rating": sc.star_rating,
        }

    return {
        "form_id": form.id,
        "academic_year": form.academic_year,
        "status": form.status,
        "live_score": live_score,
        "total": total, "offset": offset, "limit": limit,
        "activities": [serialize_activity(a) for a in activities],
    }


@router.post("/student/activity/submit")
async def submit_activity(
    category:      str = Form(...),
    activity_type: str = Form(...),
    # Academic
    internal_gpa:   Optional[float] = Form(None),
    university_gpa: Optional[float] = Form(None),
    attendance_pct: Optional[float] = Form(None),
    has_arrear:     Optional[bool]  = Form(None),
    project_status: Optional[str]   = Form(None),
    # Development
    nptel_tier:          Optional[str] = Form(None),
    platform_name:       Optional[str] = Form(None),
    course_name:         Optional[str] = Form(None),
    internship_company:  Optional[str] = Form(None),
    internship_duration: Optional[str] = Form(None),
    competition_name:    Optional[str] = Form(None),
    competition_result:  Optional[str] = Form(None),
    publication_title:   Optional[str] = Form(None),
    publication_type:    Optional[str] = Form(None),
    program_name:        Optional[str] = Form(None),
    # Skill
    placement_company:  Optional[str]   = Form(None),
    placement_lpa:      Optional[float] = Form(None),
    higher_study_exam:  Optional[str]   = Form(None),
    higher_study_score: Optional[str]   = Form(None),
    industry_org:       Optional[str]   = Form(None),
    research_title:     Optional[str]   = Form(None),
    research_journal:   Optional[str]   = Form(None),
    # Leadership
    role_name:       Optional[str] = Form(None),
    role_level:      Optional[str] = Form(None),
    event_name:      Optional[str] = Form(None),
    event_level:     Optional[str] = Form(None),
    community_org:   Optional[str] = Form(None),
    community_level: Optional[str] = Form(None),
    # File
    file: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    student = db.query(Student).filter(Student.user_id == current_user["user_id"]).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    mentor_id = _get_mentor_for_student(student, db)
    form = get_or_create_form(student.id, mentor_id, db)

    if form.status not in ("draft", "rejected"):
        raise HTTPException(status_code=400,
            detail="Cannot add activities after submitting to mentor.")

    # File handling
    file_b64 = None
    file_name = None
    file_type_str = None
    file_size_kb = None
    ocr_status = "pending"
    ocr_note = None
    ocr_text = None

    if file and file.filename:
        contents = await file.read()
        size_kb = len(contents) // 1024

        if size_kb > MAX_FILE_MB * 1024:
            raise HTTPException(status_code=400, detail=f"File too large. Max {MAX_FILE_MB} MB.")

        ext = file.filename.rsplit(".", 1)[-1].lower()
        if ext not in {"pdf", "jpg", "jpeg", "png"}:
            raise HTTPException(status_code=400, detail="Only PDF, JPG, PNG allowed.")

        file_b64 = base64.b64encode(contents).decode()
        file_name = file.filename
        file_type_str = ext
        file_size_kb = size_kb

        ocr_text, ocr_status, ocr_note = run_ocr_verify(contents, ext, student.full_name)
    else:
        ocr_status = "valid"
        ocr_note = "No document required for this activity type."

    activity = StudentActivity(
        form_id=form.id, student_id=student.id,
        category=category, activity_type=activity_type,
        internal_gpa=internal_gpa, university_gpa=university_gpa,
        attendance_pct=attendance_pct, has_arrear=has_arrear,
        project_status=project_status, nptel_tier=nptel_tier,
        platform_name=platform_name, course_name=course_name,
        internship_company=internship_company, internship_duration=internship_duration,
        competition_name=competition_name, competition_result=competition_result,
        publication_title=publication_title, publication_type=publication_type,
        program_name=program_name, placement_company=placement_company,
        placement_lpa=placement_lpa, higher_study_exam=higher_study_exam,
        higher_study_score=higher_study_score, industry_org=industry_org,
        research_title=research_title, research_journal=research_journal,
        role_name=role_name, role_level=role_level,
        event_name=event_name, event_level=event_level,
        community_org=community_org, community_level=community_level,
        file_data=file_b64, file_name=file_name,
        file_type=file_type_str, file_size_kb=file_size_kb,
        ocr_extracted_text=ocr_text,
        ocr_status=ocr_status, ocr_note=ocr_note,
        mentor_status="pending",
        submitted_at=datetime.now(),
    )
    db.add(activity)
    db.commit()
    db.refresh(activity)

    msg_map = {
        "failed": "OCR could not verify your document. Please re-upload a clearer scan.",
        "valid":  "Document verified! Sent to mentor for final approval.",
        "review": "Document submitted. Partial OCR — mentor will verify.",
    }

    return {
        "activity_id": activity.id,
        "ocr_status": ocr_status,
        "ocr_note": ocr_note,
        "mentor_status": "pending",
        "message": msg_map.get(ocr_status, "Submitted."),
    }


@router.delete("/student/activity/{activity_id}")
def delete_activity(
    activity_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    student = db.query(Student).filter(Student.user_id == current_user["user_id"]).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    act = db.query(StudentActivity).filter(
        StudentActivity.id == activity_id,
        StudentActivity.student_id == student.id,
    ).first()
    if not act:
        raise HTTPException(status_code=404, detail="Activity not found")
    if act.mentor_status == "approved":
        raise HTTPException(status_code=400, detail="Cannot delete an approved activity")

    db.delete(act)
    db.commit()
    return {"message": "Activity deleted"}


@router.post("/student/form/{form_id}/submit")
def submit_form_for_review(
    form_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    student = db.query(Student).filter(Student.user_id == current_user["user_id"]).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    form = db.query(SSMForm).filter(
        SSMForm.id == form_id,
        SSMForm.student_id == student.id,
    ).first()
    if not form:
        raise HTTPException(status_code=404, detail="Form not found")

    if form.status not in ("draft", "rejected"):
        raise HTTPException(status_code=400, detail="Form already submitted")

    acts = db.query(StudentActivity).filter(StudentActivity.form_id == form_id).count()
    if acts == 0:
        raise HTTPException(status_code=400, detail="Add at least one activity before submitting")

    form.status = "submitted"
    form.submitted_at = datetime.now()
    db.commit()
    return {"message": "Form submitted for mentor review", "status": "submitted"}


@router.get("/student/form/{form_id}/score")
def get_score(
    form_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    student = db.query(Student).filter(Student.user_id == current_user["user_id"]).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    form = db.query(SSMForm).filter(
        SSMForm.id == form_id, SSMForm.student_id == student.id
    ).first()
    if not form:
        raise HTTPException(status_code=404, detail="Form not found")

    sc = db.query(CalculatedScore).filter(CalculatedScore.form_id == form_id).first()
    if not sc:
        raise HTTPException(status_code=404, detail="Score not calculated yet")

    return {
        "academic_year": form.academic_year, "status": form.status,
        "scores": {
            "academic": sc.academic_score, "development": sc.development_score,
            "skill": sc.skill_score, "discipline": sc.discipline_score,
            "leadership": sc.leadership_score,
            "grand_total": sc.grand_total, "star_rating": sc.star_rating,
        },
        "mentor_remarks": form.mentor_remarks,
        "hod_remarks": form.hod_remarks,
    }


# Get activity file
@router.get("/student/activity/{activity_id}/file")
def get_activity_file(
    activity_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    student = db.query(Student).filter(Student.user_id == current_user["user_id"]).first()
    role = current_user.get("role", "")

    act = db.query(StudentActivity).filter(StudentActivity.id == activity_id).first()
    if not act:
        raise HTTPException(status_code=404, detail="Not found")

    # Access control
    if role == "student" and student and act.student_id != student.id:
        raise HTTPException(status_code=403, detail="Access denied")

    if not act.file_data:
        raise HTTPException(status_code=404, detail="No file attached")

    return {
        "file_data": act.file_data,
        "file_name": act.file_name,
        "file_type": act.file_type,
    }


# ============================================================================
# MENTOR ENDPOINTS (Faculty — CC assigned to class)
# ============================================================================

def _get_faculty(user_id: int, db: Session) -> Faculty:
    f = db.query(Faculty).filter(Faculty.user_id == user_id).first()
    if not f:
        raise HTTPException(status_code=404, detail="Faculty not found")
    return f


def _get_mentor_form_ids(faculty_id: int, db: Session) -> list:
    """Get all SSMForm IDs assigned to this mentor (faculty)."""
    return [f.id for f in db.query(SSMForm).filter(SSMForm.mentor_id == faculty_id).all()]


@router.get("/mentor/pending-activities")
def mentor_pending_activities(
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="Faculty only")

    faculty = _get_faculty(current_user["user_id"], db)
    form_ids = _get_mentor_form_ids(faculty.id, db)

    if not form_ids:
        return {"total": 0, "items": []}

    query = db.query(StudentActivity).filter(
        StudentActivity.form_id.in_(form_ids),
        StudentActivity.mentor_status == "pending",
        StudentActivity.ocr_status != "failed",
    )
    total = query.count()
    activities = query.order_by(StudentActivity.submitted_at.asc()).offset(offset).limit(limit).all()

    items = []
    for a in activities:
        s = db.query(Student).filter(Student.id == a.student_id).first()
        name = s.full_name if s else "Unknown"
        items.append(serialize_activity(a, include_student_name=name))

    return {"total": total, "offset": offset, "limit": limit, "items": items}


@router.get("/mentor/dashboard")
def mentor_dashboard(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="Faculty only")

    faculty = _get_faculty(current_user["user_id"], db)
    forms = db.query(SSMForm).filter(
        SSMForm.mentor_id == faculty.id,
        SSMForm.status.in_(["submitted", "mentor_review"])
    ).all()

    pending = []
    for f in forms:
        s = db.query(Student).filter(Student.id == f.student_id).first()
        sc = db.query(CalculatedScore).filter(CalculatedScore.form_id == f.id).first()
        pending.append({
            "form_id": f.id,
            "student_name": s.full_name if s else "",
            "register_number": s.register_number if s else "",
            "academic_year": f.academic_year,
            "status": f.status,
            "submitted_at": f.submitted_at.isoformat() if f.submitted_at else None,
            "preview_score": sc.grand_total if sc else None,
            "star_rating": sc.star_rating if sc else None,
        })

    all_students = db.query(SSMForm).filter(SSMForm.mentor_id == faculty.id).count()
    pending_count = db.query(StudentActivity).filter(
        StudentActivity.form_id.in_(_get_mentor_form_ids(faculty.id, db)),
        StudentActivity.mentor_status == "pending",
    ).count()

    return {
        "mentor": faculty.full_name,
        "pending_form_reviews": pending,
        "pending_activity_count": pending_count,
        "total_students": all_students,
    }


@router.get("/mentor/form/{form_id}")
def mentor_get_form(
    form_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="Faculty only")

    faculty = _get_faculty(current_user["user_id"], db)
    form = db.query(SSMForm).filter(
        SSMForm.id == form_id, SSMForm.mentor_id == faculty.id
    ).first()
    if not form:
        raise HTTPException(status_code=404, detail="Form not found or not assigned to you")

    return _form_to_dict(form, db, include_activities=True)


class MentorReviewPayload(BaseModel):
    mentor_feedback:          str
    technical_skill:          str
    soft_skill:               str
    discipline_level:         str
    dress_code_level:         str
    dept_contribution:        str
    social_media_level:       str
    late_entries:             bool = False
    innovation_initiative:    str
    team_management_leadership: str
    remarks:                  Optional[str] = None


@router.post("/mentor/form/{form_id}/review")
def mentor_submit_review(
    form_id: int,
    payload: MentorReviewPayload,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="Faculty only")

    faculty = _get_faculty(current_user["user_id"], db)
    form = db.query(SSMForm).filter(
        SSMForm.id == form_id, SSMForm.mentor_id == faculty.id
    ).first()
    if not form:
        raise HTTPException(status_code=404, detail="Not found or not assigned to you")

    if form.status not in ("submitted", "mentor_review"):
        raise HTTPException(status_code=400, detail="Form not in reviewable state")

    # Update mentor-rated fields
    acad = db.query(AcademicData).filter(AcademicData.form_id == form_id).first()
    if acad:
        acad.mentor_feedback = payload.mentor_feedback

    skill = db.query(SkillData).filter(SkillData.form_id == form_id).first()
    if skill:
        skill.technical_skill = payload.technical_skill
        skill.soft_skill = payload.soft_skill
        skill.team_management = payload.team_management_leadership

    disc = db.query(DisciplineData).filter(DisciplineData.form_id == form_id).first()
    if disc:
        disc.discipline_level   = payload.discipline_level
        disc.dress_code_level   = payload.dress_code_level
        disc.dept_contribution  = payload.dept_contribution
        disc.social_media_level = payload.social_media_level
        disc.late_entries       = payload.late_entries

    lead = db.query(LeadershipData).filter(LeadershipData.form_id == form_id).first()
    if lead:
        lead.innovation_initiative       = payload.innovation_initiative
        lead.team_management_leadership  = payload.team_management_leadership

    form.mentor_remarks = payload.remarks
    form.status = "hod_review"
    db.commit()

    scores = calculate_and_save(form_id, db)
    return {
        "message": "Review submitted. Form moved to HOD review.",
        "updated_score": scores,
    }


@router.post("/mentor/form/{form_id}/reject")
def mentor_reject_form(
    form_id: int,
    reason: str = Query(...),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="Faculty only")

    faculty = _get_faculty(current_user["user_id"], db)
    form = db.query(SSMForm).filter(
        SSMForm.id == form_id, SSMForm.mentor_id == faculty.id
    ).first()
    if not form:
        raise HTTPException(status_code=404, detail="Not found")

    form.status = "rejected"
    form.rejection_reason = reason
    db.commit()
    return {"message": "Form rejected. Student can re-submit after corrections."}


@router.post("/mentor/activity/{activity_id}/approve")
async def approve_activity(
    activity_id: int,
    note: Optional[str] = Form(None),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="Faculty only")

    faculty = _get_faculty(current_user["user_id"], db)
    form_ids = _get_mentor_form_ids(faculty.id, db)

    act = db.query(StudentActivity).filter(
        StudentActivity.id == activity_id,
        StudentActivity.form_id.in_(form_ids),
    ).first()
    if not act:
        raise HTTPException(status_code=404, detail="Activity not found or not assigned to you")
    if act.mentor_status != "pending":
        raise HTTPException(status_code=400, detail=f"Activity already {act.mentor_status}")

    act.mentor_status = "approved"
    act.mentor_note   = note
    act.verified_at   = datetime.now()
    db.commit()

    patch_form_data(act, db)
    scores = calculate_and_save(act.form_id, db)

    return {
        "message": "Activity approved. Score updated.",
        "grand_total": scores["grand_total"],
        "star_rating": scores["star_rating"],
    }


@router.post("/mentor/activity/{activity_id}/reject")
async def reject_activity(
    activity_id: int,
    note: str = Form(...),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="Faculty only")

    faculty = _get_faculty(current_user["user_id"], db)
    form_ids = _get_mentor_form_ids(faculty.id, db)

    act = db.query(StudentActivity).filter(
        StudentActivity.id == activity_id,
        StudentActivity.form_id.in_(form_ids),
    ).first()
    if not act:
        raise HTTPException(status_code=404, detail="Not found or not yours")
    if act.mentor_status != "pending":
        raise HTTPException(status_code=400, detail=f"Already {act.mentor_status}")

    act.mentor_status = "rejected"
    act.mentor_note   = note
    act.verified_at   = datetime.now()
    db.commit()
    return {"message": "Activity rejected. Student notified."}


# ============================================================================
# HOD ENDPOINTS
# ============================================================================

def _get_hod_faculty(user_id: int, db: Session) -> Faculty:
    f = db.query(Faculty).filter(Faculty.user_id == user_id).first()
    if not f:
        raise HTTPException(
            status_code=404,
            detail="HOD Faculty profile not found."
        )

    # CRITICAL FIX: The HOD's department must match the Student's department name.
    # We find which department has this user as its HOD.
    dept = db.query(Department).filter(Department.hod_user_id == user_id).first()
    if dept:
        # Override faculty.department string with the actual department NAME for matching students
        f.department = dept.name
    else:
        # Fallback to code lookup if not explicitly assigned as HOD in Department table
        d2 = db.query(Department).filter(Department.code == f.department).first()
        if d2:
            f.department = d2.name

    return f

@router.get("/hod/dashboard")
def hod_dashboard(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="HOD only")

    hod = _get_hod_faculty(current_user["user_id"], db)
    dept = hod.department

    print(f"DEBUG HOD Dashboard: user_id={current_user['user_id']} name={hod.full_name} dept='{dept}'")

    # If department is not set for HOD, return empty
    if not dept:
        return {
            "hod": hod.full_name,
            "department": "Not Assigned",
            "pending_approvals": [],
            "approved_count": 0,
            "total_students": 0,
        }

    # All students in this department
    students = db.query(Student).filter(Student.department == dept).all()
    student_ids = [s.id for s in students]
    print(f"DEBUG HOD Dashboard: Found {len(students)} students in department '{dept}'")
    if students:
        print(f"DEBUG HOD Dashboard: First 3 student IDs: {student_ids[:3]}")

    # If no students, return early to avoid .in_([]) issues
    if not student_ids:
        return {
            "hod": hod.full_name,
            "department": dept,
            "pending_approvals": [],
            "approved_count": 0,
            "total_students": 0,
        }

    pending = db.query(SSMForm).filter(
        SSMForm.student_id.in_(student_ids),
        SSMForm.status.in_(["hod_review", "submitted", "mentor_review", "approved"])
    ).order_by(SSMForm.updated_at.desc()).all()

    approved_count = db.query(SSMForm).filter(
        SSMForm.student_id.in_(student_ids),
        SSMForm.status == "approved"
    ).count()

    pending_list = []
    for f in pending:
        s = db.query(Student).filter(Student.id == f.student_id).first()
        sc = db.query(CalculatedScore).filter(CalculatedScore.form_id == f.id).first()
        pending_list.append({
            "form_id": f.id,
            "student_id": f.student_id,
            "student_name": s.full_name if s else "Unknown",
            "register_number": s.register_number if s else "Unknown",
            "academic_year": f.academic_year,
            "status": f.status,
            "form_status": f.status, # Duplicate for UI safety
            "grand_total": sc.grand_total if sc else 0,
            "star_rating": sc.star_rating if sc else 0,
        })

    return {
        "hod": hod.full_name,
        "department": dept,
        "pending_approvals": pending_list,
        "approved_count": approved_count,
        "total_students": len(student_ids),
    }


@router.get("/hod/approved")
def get_hod_approved(
    limit: int = 100,
    offset: int = 0,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="HOD only")

    hod = _get_hod_faculty(current_user["user_id"], db)
    dept = hod.department
    if not dept:
        return {"items": []}

    forms = db.query(SSMForm).filter(
        SSMForm.status == "approved",
        SSMForm.student_id.in_(
            db.query(Student.id).filter(Student.department == dept)
        )
    ).order_by(SSMForm.updated_at.desc()).limit(limit).offset(offset).all()

    return {
        "items": [_form_to_dict(f, db) for f in forms]
    }


@router.get("/hod/all-students")
def get_hod_all_students(
    limit: int = 500,
    offset: int = 0,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="HOD only")

    hod = _get_hod_faculty(current_user["user_id"], db)
    dept = hod.department
    if not dept:
        return {"items": []}

    students = db.query(Student).filter(Student.department == dept).limit(limit).offset(offset).all()

    result = []
    for s in students:
        form = db.query(SSMForm).filter(SSMForm.student_id == s.id).first()
        sc = db.query(CalculatedScore).filter(CalculatedScore.form_id == form.id).first() if form else None
        result.append({
            "student_id": s.id,
            "student_name": s.full_name,
            "register_number": s.register_number,
            "year": s.year,
            "section": s.section,
            "form_status": form.status if form else "not_started",
            "form_id": form.id if form else None,
            "grand_total": sc.grand_total if sc else 0,
            "star_rating": sc.star_rating if sc else 0,
        })

    return {"items": result}


@router.get("/hod/form/{form_id}")
def hod_get_form(
    form_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="HOD only")

    hod = _get_hod_faculty(current_user["user_id"], db)

    form = db.query(SSMForm).filter(SSMForm.id == form_id).first()
    if not form:
        raise HTTPException(status_code=404, detail="Not found")

    # Department scope check
    student = db.query(Student).filter(Student.id == form.student_id).first()
    if not student or student.department != hod.department:
        raise HTTPException(status_code=403, detail="Access denied — different department")

    return _form_to_dict(form, db, include_activities=True)


class HODApprovalPayload(BaseModel):
    hod_feedback: str
    remarks:      Optional[str] = None
    approve:      bool = True


@router.post("/hod/form/{form_id}/approve")
def hod_approve_form(
    form_id: int,
    payload: HODApprovalPayload,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="HOD only")

    hod = _get_hod_faculty(current_user["user_id"], db)
    form = db.query(SSMForm).filter(SSMForm.id == form_id).first()
    if not form:
        raise HTTPException(status_code=404, detail="Not found")

    student = db.query(Student).filter(Student.id == form.student_id).first()
    if not student or student.department != hod.department:
        raise HTTPException(status_code=403, detail="Access denied")

    # Update HOD feedback
    acad = db.query(AcademicData).filter(AcademicData.form_id == form_id).first()
    if acad:
        acad.hod_feedback = payload.hod_feedback

    form.hod_id = hod.id
    form.hod_remarks = payload.remarks

    if payload.approve:
        if form.status != "hod_review":
            raise HTTPException(status_code=400, detail="Form not pending HOD approval")
        form.status = "approved"
        form.approved_at = datetime.now()
        scores = calculate_and_save(form_id, db)
        return {
            "message": "Form approved. Score locked.",
            "final_score": {
                "grand_total": scores["grand_total"],
                "star_rating": scores["star_rating"],
            }
        }
    else:
        form.status = "rejected"
        form.rejection_reason = payload.remarks
        db.commit()
        return {"message": "Form rejected. Student can re-submit."}


@router.get("/hod/reports/department")
def hod_dept_report(
    academic_year: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if current_user["role"] not in ("faculty", "admin"):
        raise HTTPException(status_code=403, detail="HOD only")

    hod = _get_hod_faculty(current_user["user_id"], db)
    dept = hod.department

    students = db.query(Student).filter(Student.department == dept).all()
    student_ids = [s.id for s in students]

    query = db.query(SSMForm).filter(SSMForm.student_id.in_(student_ids))
    if academic_year:
        query = query.filter(SSMForm.academic_year == academic_year)

    forms = query.all()
    data = []
    for f in forms:
        s = db.query(Student).filter(Student.id == f.student_id).first()
        sc = db.query(CalculatedScore).filter(CalculatedScore.form_id == f.id).first()
        data.append({
            "student_name": s.full_name if s else "",
            "register_number": s.register_number if s else "",
            "year": s.year if s else "",
            "section": s.section if s else "",
            "academic_year": f.academic_year,
            "status": f.status,
            "grand_total": sc.grand_total if sc else 0,
            "star_rating": sc.star_rating if sc else 0,
        })

    totals = [d["grand_total"] for d in data if d["grand_total"] > 0]
    return {
        "department": dept,
        "total_forms": len(forms),
        "approved": sum(1 for f in forms if f.status == "approved"),
        "average_score": round(sum(totals) / len(totals), 2) if totals else 0,
        "five_star": sum(1 for d in data if d["star_rating"] == 5),
        "students": data,
    }
