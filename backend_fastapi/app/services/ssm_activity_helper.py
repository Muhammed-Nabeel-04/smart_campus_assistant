# File: app/services/ssm_activity_helper.py
# OCR verification + _patch_form_data() — ported from standalone app

import io
import re
from datetime import datetime
from sqlalchemy.orm import Session

from app.models.ssm_new import (
    SSMForm, AcademicData, DevelopmentData, SkillData,
    DisciplineData, LeadershipData, StudentActivity
)


# ── OCR VERIFICATION ──────────────────────────────────────────────────────────

def run_ocr_verify(file_data_bytes: bytes, file_type: str, student_name: str):
    """Returns (ocr_text, ocr_status, ocr_note)."""
    ocr_text = None
    ext = f".{file_type.lower()}"

    if ext in {".jpg", ".jpeg", ".png"}:
        try:
            import pytesseract
            from PIL import Image
            img = Image.open(io.BytesIO(file_data_bytes))
            ocr_text = pytesseract.image_to_string(img)[:2000]
        except Exception:
            return None, "review", "Image OCR unavailable — mentor will verify."

    elif ext == ".pdf":
        try:
            import pdfplumber
            pages = []
            with pdfplumber.open(io.BytesIO(file_data_bytes)) as pdf:
                for page in pdf.pages[:4]:
                    t = page.extract_text()
                    if t:
                        pages.append(t.strip())
            ocr_text = "\n".join(pages)[:2000]
            if not ocr_text.strip():
                return None, "review", "Scanned PDF — mentor will verify."
        except Exception:
            return None, "review", "PDF read error — mentor will verify."

    if not ocr_text:
        return None, "review", "Could not extract text — mentor will verify."

    text_lower = ocr_text.lower()
    name_parts = [p for p in student_name.lower().split() if len(p) > 2]
    name_match = any(part in text_lower for part in name_parts)

    has_date = bool(re.search(r'\b(202[0-7])\b', ocr_text))

    platforms = [
        "coursera", "udemy", "nptel", "swayam", "linkedin", "google",
        "aws", "microsoft", "infosys", "tcs", "nasscom", "cisco",
        "oracle", "ibm", "internshala", "simplilearn", "edx",
    ]
    known_platform = any(p in text_lower for p in platforms)

    checks = {"name_match": name_match, "has_date": has_date, "known_platform": known_platform}
    passed = sum(checks.values())

    if not name_match:
        return ocr_text, "failed", f"Student name not found in document. Re-upload a clearer scan. {checks}"
    if passed == 3:
        return ocr_text, "valid", "All checks passed."
    return ocr_text, "review", f"Partial checks — mentor will verify. {checks}"


# ── PATCH FORM DATA (called on mentor approve) ────────────────────────────────

def patch_form_data(activity: StudentActivity, db: Session):
    """
    When mentor approves an activity, patch the underlying SSMForm
    category data so scoring engine calculates correctly.
    """
    form = db.query(SSMForm).filter(SSMForm.id == activity.form_id).first()
    if not form:
        return

    acad = db.query(AcademicData).filter(AcademicData.form_id == form.id).first()
    dev  = db.query(DevelopmentData).filter(DevelopmentData.form_id == form.id).first()
    skill= db.query(SkillData).filter(SkillData.form_id == form.id).first()
    disc = db.query(DisciplineData).filter(DisciplineData.form_id == form.id).first()
    lead = db.query(LeadershipData).filter(LeadershipData.form_id == form.id).first()

    atype = activity.activity_type

    # ── Academic ──────────────────────────────────────────────────────────────
    if atype == "gpa_update" and acad:
        if activity.internal_gpa   is not None: acad.internal_gpa   = activity.internal_gpa
        if activity.university_gpa is not None: acad.university_gpa = activity.university_gpa
        if activity.attendance_pct is not None:
            acad.attendance_pct = activity.attendance_pct
            if disc: disc.attendance_pct = activity.attendance_pct
        if activity.has_arrear     is not None: acad.has_arrear     = activity.has_arrear

    elif atype == "project" and acad:
        if activity.project_status:
            acad.project_status = activity.project_status

    # ── Development ───────────────────────────────────────────────────────────
    elif atype == "nptel" and dev:
        tier_order = ["participated", "completed", "elite", "elite_plus"]
        current = dev.nptel_tier or "none"
        new_tier = activity.nptel_tier
        if new_tier and new_tier in tier_order:
            c_idx = tier_order.index(current) if current in tier_order else -1
            n_idx = tier_order.index(new_tier)
            if n_idx > c_idx:
                dev.nptel_tier = new_tier

    elif atype == "online_cert" and dev:
        dev.online_cert_count = (dev.online_cert_count or 0) + 1

    elif atype == "internship" and dev:
        dur_order = ["participation", "1to2weeks", "2to4weeks", "4weeks_plus"]
        current = dev.internship_duration or "none"
        new_dur = activity.internship_duration
        if new_dur and new_dur in dur_order:
            c_idx = dur_order.index(current) if current in dur_order else -1
            n_idx = dur_order.index(new_dur)
            if n_idx > c_idx:
                dev.internship_duration = new_dur

    elif atype == "competition" and dev:
        res_order = ["participated", "finalist", "winner"]
        current = dev.competition_result or "none"
        new_res = activity.competition_result
        if new_res and new_res in res_order:
            c_idx = res_order.index(current) if current in res_order else -1
            n_idx = res_order.index(new_res)
            if n_idx > c_idx:
                dev.competition_result = new_res

    elif atype == "publication" and dev:
        pub_order = ["prototype", "conference", "patent"]
        current = dev.publication_type or "none"
        new_pub = activity.publication_type
        if new_pub and new_pub in pub_order:
            c_idx = pub_order.index(current) if current in pub_order else -1
            n_idx = pub_order.index(new_pub)
            if n_idx > c_idx:
                dev.publication_type = new_pub

    elif atype == "prof_program" and dev:
        dev.professional_programs_count = (dev.professional_programs_count or 0) + 1

    # ── Skill ─────────────────────────────────────────────────────────────────
    elif atype == "placement" and skill:
        if activity.placement_lpa:
            if (skill.placement_lpa or 0) < activity.placement_lpa:
                skill.placement_lpa = activity.placement_lpa

    elif atype == "higher_study" and skill:
        skill.higher_studies = True

    elif atype == "industry_int" and skill:
        skill.industry_interactions = (skill.industry_interactions or 0) + 1

    elif atype == "research" and skill:
        skill.research_papers_count = (skill.research_papers_count or 0) + 1

    # ── Leadership ────────────────────────────────────────────────────────────
    elif atype == "formal_role" and lead:
        role_order = ["class_level", "dept_level", "college_level"]
        current = lead.formal_role or "none"
        new_role = activity.role_level
        if new_role and new_role in role_order:
            c_idx = role_order.index(current) if current in role_order else -1
            n_idx = role_order.index(new_role)
            if n_idx > c_idx:
                lead.formal_role = new_role

    elif atype == "event_org" and lead:
        ev_order = ["assisted", "led_1", "led_2plus"]
        ev_map = {"dept": "led_1", "college": "led_1", "inter_college": "led_2plus", "national": "led_2plus"}
        mapped = ev_map.get(activity.event_level or "", "assisted")
        current = lead.event_leadership or "none"
        c_idx = ev_order.index(current) if current in ev_order else -1
        n_idx = ev_order.index(mapped) if mapped in ev_order else -1
        if n_idx > c_idx:
            lead.event_leadership = mapped

    elif atype == "community" and lead:
        comm_order = ["minimal", "active", "led_project"]
        comm_map = {"local": "minimal", "district": "active", "state": "active", "national": "led_project"}
        mapped = comm_map.get(activity.community_level or "", "minimal")
        current = lead.community_leadership or "none"
        c_idx = comm_order.index(current) if current in comm_order else -1
        n_idx = comm_order.index(mapped) if mapped in comm_order else -1
        if n_idx > c_idx:
            lead.community_leadership = mapped

    db.commit()


# ── GET OR CREATE FORM ────────────────────────────────────────────────────────

def get_or_create_form(student_id: int, mentor_id: int, db: Session) -> SSMForm:
    """Get current academic year form, auto-create if none exists."""
    academic_year = "2025-2026"  # TODO: read from system settings

    form = db.query(SSMForm).filter(
        SSMForm.student_id == student_id,
        SSMForm.academic_year == academic_year,
    ).first()

    if not form:
        form = SSMForm(
            student_id=student_id,
            mentor_id=mentor_id,
            academic_year=academic_year,
            status="draft",
        )
        db.add(form)
        db.flush()

        db.add(AcademicData(form_id=form.id))
        db.add(DevelopmentData(form_id=form.id))
        db.add(SkillData(form_id=form.id))
        db.add(DisciplineData(form_id=form.id))
        db.add(LeadershipData(form_id=form.id))
        db.commit()
        db.refresh(form)

    return form


# ── SERIALIZE ACTIVITY ────────────────────────────────────────────────────────

def serialize_activity(act: StudentActivity, include_student_name: str = None) -> dict:
    data = {k: v for k, v in {
        "internal_gpa": act.internal_gpa, "university_gpa": act.university_gpa,
        "attendance_pct": act.attendance_pct, "has_arrear": act.has_arrear,
        "project_status": act.project_status, "nptel_tier": act.nptel_tier,
        "platform_name": act.platform_name, "course_name": act.course_name,
        "internship_company": act.internship_company,
        "internship_duration": act.internship_duration,
        "competition_name": act.competition_name,
        "competition_result": act.competition_result,
        "publication_title": act.publication_title,
        "publication_type": act.publication_type,
        "program_name": act.program_name,
        "placement_company": act.placement_company, "placement_lpa": act.placement_lpa,
        "higher_study_exam": act.higher_study_exam,
        "industry_org": act.industry_org, "research_title": act.research_title,
        "role_name": act.role_name, "role_level": act.role_level,
        "event_name": act.event_name, "event_level": act.event_level,
        "community_org": act.community_org, "community_level": act.community_level,
    }.items() if v is not None}

    result = {
        "id": act.id, "form_id": act.form_id, "student_id": act.student_id,
        "category": act.category, "activity_type": act.activity_type,
        "ocr_status": act.ocr_status, "ocr_note": act.ocr_note,
        "mentor_status": act.mentor_status, "mentor_note": act.mentor_note,
        "has_file": act.file_data is not None,
        "filename": act.file_name,
        "submitted_at": act.submitted_at.isoformat() if act.submitted_at else None,
        "verified_at": act.verified_at.isoformat() if act.verified_at else None,
        "data": data,
    }
    if include_student_name:
        result["student_name"] = include_student_name
    return result
