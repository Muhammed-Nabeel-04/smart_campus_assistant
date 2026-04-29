# File: app/services/ssm_scoring_new.py
# Ported from standalone SSM app — scoring engine using ORM objects

from app.models.ssm_new import (
    AcademicData, DevelopmentData, SkillData, DisciplineData,
    LeadershipData, SSMForm, CalculatedScore
)
from sqlalchemy.orm import Session
from datetime import datetime


# ── CATEGORY 1: ACADEMIC (max 100) ────────────────────────────────────────────

def score_academic(data: AcademicData) -> dict:
    b = {}

    gpa = data.internal_gpa or 0
    b["1.1_internal_gpa"] = 15 if gpa >= 9 else 10 if gpa >= 8 else 5 if gpa >= 7 else 0

    u_gpa = data.university_gpa or 0
    if data.has_arrear:
        b["1.2_university_gpa"] = 0
    else:
        b["1.2_university_gpa"] = 15 if u_gpa >= 9 else 10 if u_gpa >= 8 else 5 if u_gpa >= 7 else 0

    att = data.attendance_pct or 0
    b["1.3_attendance"] = 15 if att >= 95 else 10 if att >= 90 else 5 if att >= 85 else 0

    fb_map = {"excellent": 15, "good": 10, "average": 5}
    b["1.4_mentor_feedback"] = fb_map.get(data.mentor_feedback or "", 0)
    b["1.5_hod_feedback"]    = fb_map.get(data.hod_feedback or "",    0)

    proj_map = {"fully_completed": 15, "partial": 10, "concept": 5, "none": 0}
    b["1.6_project"] = proj_map.get(data.project_status or "none", 0)

    if data.internal_gpa and data.university_gpa:
        diff = abs(data.internal_gpa - data.university_gpa)
        b["1.7_consistency"] = 15 if diff <= 0.5 else 10 if diff <= 1.0 else 5 if diff <= 1.5 else 0
    else:
        b["1.7_consistency"] = 0

    return {"total": min(sum(b.values()), 100), "breakdown": b}


# ── CATEGORY 2: DEVELOPMENT (max 100) ─────────────────────────────────────────

def score_development(data: DevelopmentData) -> dict:
    b = {}

    nptel_map = {"elite_plus": 20, "elite": 15, "completed": 10, "participated": 5, "none": 0}
    b["2.1_nptel"] = nptel_map.get(data.nptel_tier or "none", 0)

    cnt = data.online_cert_count or 0
    b["2.2_online_certs"] = 15 if cnt >= 3 else 10 if cnt == 2 else 5 if cnt == 1 else 0

    intern_map = {"4weeks_plus": 20, "2to4weeks": 15, "1to2weeks": 10, "participation": 5, "none": 0}
    b["2.3_internship"] = intern_map.get(data.internship_duration or "none", 0)

    comp_map = {"winner": 20, "finalist": 10, "participated": 5, "none": 0}
    b["2.4_competitions"] = comp_map.get(data.competition_result or "none", 0)

    pub_map = {"patent": 15, "conference": 10, "prototype": 5, "none": 0}
    b["2.5_publications"] = pub_map.get(data.publication_type or "none", 0)

    prog = data.professional_programs_count or 0
    b["2.6_professional"] = 15 if prog >= 3 else 10 if prog == 2 else 5 if prog == 1 else 0

    return {"total": min(sum(b.values()), 100), "breakdown": b}


# ── CATEGORY 3: SKILL (max 100) ────────────────────────────────────────────────

def score_skill(data: SkillData) -> dict:
    b = {}

    tech_map = {"excellent": 20, "good": 10, "basic": 5}
    b["3.1_technical_skill"] = tech_map.get(data.technical_skill or "", 0)

    soft_map = {"excellent": 20, "good": 10, "average": 5}
    b["3.2_soft_skills"] = soft_map.get(data.soft_skill or "", 0)

    pct = data.placement_training_pct or 0
    b["3.3_placement_readiness"] = 20 if pct >= 95 else 10 if pct >= 80 else 5 if pct >= 75 else 0

    if data.higher_studies:
        b["3.4_placement_outcome"] = 15
    else:
        lpa = data.placement_lpa or 0
        b["3.4_placement_outcome"] = (20 if lpa >= 15 else 15 if lpa >= 10
                                       else 10 if lpa >= 7.5 else 5 if lpa > 0 else 0)

    interactions = data.industry_interactions or 0
    b["3.5_industry"] = 20 if interactions >= 3 else 10 if interactions == 2 else 5 if interactions == 1 else 0

    papers = data.research_papers_count or 0
    b["3.6_research"] = 10 if papers >= 3 else 5 if papers >= 1 else 0

    innov_map = {"implemented": 10, "proposed": 5, "minor": 0, "none": 0}
    b["3.7_innovation"] = innov_map.get(data.innovation_level or "none", 0)

    return {"total": min(sum(b.values()), 100), "breakdown": b}


# ── CATEGORY 4: DISCIPLINE (max 100) ──────────────────────────────────────────

def score_discipline(data: DisciplineData) -> dict:
    b = {}

    disc_map = {"no_violations": 20, "minor": 10, "major": 0}
    b["4.1_discipline"] = disc_map.get(data.discipline_level or "no_violations", 0)

    att = data.attendance_pct or 0
    if att >= 95 and not data.late_entries:
        b["4.2_punctuality"] = 15
    elif att >= 90:
        b["4.2_punctuality"] = 10
    elif att >= 85:
        b["4.2_punctuality"] = 5
    else:
        b["4.2_punctuality"] = 0

    dress_map = {"consistent": 15, "highly_regular": 10, "generally_follows": 5}
    b["4.3_dress_code"] = dress_map.get(data.dress_code_level or "consistent", 0)

    contrib_map = {"implemented_impactful": 25, "proposed_useful": 15, "minor_idea": 5, "none": 0}
    b["4.4_dept_contribution"] = contrib_map.get(data.dept_contribution or "none", 0)

    social_map = {
        "active_creates": 25, "regularly_contributes": 20, "participates_shares": 15,
        "occasional": 10, "minimal": 5, "none": 0,
    }
    b["4.5_social_media"] = social_map.get(data.social_media_level or "none", 0)

    return {"total": min(sum(b.values()), 100), "breakdown": b}


# ── CATEGORY 5: LEADERSHIP (max 100) ──────────────────────────────────────────

def score_leadership(data: LeadershipData) -> dict:
    b = {}

    role_map = {"college_level": 15, "dept_level": 10, "class_level": 5, "none": 0}
    b["5.1_formal_role"] = role_map.get(data.formal_role or "none", 0)

    event_map = {"led_2plus": 15, "led_1": 10, "assisted": 5, "none": 0}
    b["5.2_event_leadership"] = event_map.get(data.event_leadership or "none", 0)

    team_map = {"excellent": 15, "good": 10, "limited": 5}
    b["5.3_team_management"] = team_map.get(data.team_management_leadership or "", 0)

    innov_map = {"implemented": 25, "proposed": 15, "minor": 5, "none": 0}
    b["5.4_innovation"] = innov_map.get(data.innovation_initiative or "none", 0)

    comm_map = {"led_project": 25, "active": 15, "minimal": 5, "none": 0}
    b["5.5_community"] = comm_map.get(data.community_leadership or "none", 0)

    return {"total": min(sum(b.values()), 100), "breakdown": b}


# ── STAR RATING ────────────────────────────────────────────────────────────────

def get_star_rating(total: float) -> int:
    if total >= 450: return 5
    if total >= 400: return 4
    if total >= 350: return 3
    if total >= 300: return 2
    if total >= 250: return 1
    return 0


# ── MASTER CALCULATE ───────────────────────────────────────────────────────────

def calculate_and_save(form_id: int, db: Session) -> dict:
    """Recalculate all 5 categories and save CalculatedScore."""
    acad = db.query(AcademicData).filter(AcademicData.form_id == form_id).first()
    dev  = db.query(DevelopmentData).filter(DevelopmentData.form_id == form_id).first()
    skill= db.query(SkillData).filter(SkillData.form_id == form_id).first()
    disc = db.query(DisciplineData).filter(DisciplineData.form_id == form_id).first()
    lead = db.query(LeadershipData).filter(LeadershipData.form_id == form_id).first()

    r_acad = score_academic(acad) if acad else {"total": 0, "breakdown": {}}
    r_dev  = score_development(dev) if dev else {"total": 0, "breakdown": {}}
    r_skill= score_skill(skill) if skill else {"total": 0, "breakdown": {}}
    r_disc = score_discipline(disc) if disc else {"total": 0, "breakdown": {}}
    r_lead = score_leadership(lead) if lead else {"total": 0, "breakdown": {}}

    grand_total = r_acad["total"] + r_dev["total"] + r_skill["total"] + r_disc["total"] + r_lead["total"]
    stars = get_star_rating(grand_total)

    sc = db.query(CalculatedScore).filter(CalculatedScore.form_id == form_id).first()
    if not sc:
        sc = CalculatedScore(form_id=form_id)
        db.add(sc)

    sc.academic_score    = r_acad["total"]
    sc.development_score = r_dev["total"]
    sc.skill_score       = r_skill["total"]
    sc.discipline_score  = r_disc["total"]
    sc.leadership_score  = r_lead["total"]
    sc.grand_total       = grand_total
    sc.star_rating       = stars
    sc.calculated_at     = datetime.now()
    db.commit()
    db.refresh(sc)

    return {
        "grand_total": grand_total, "star_rating": stars,
        "academic": r_acad["total"], "development": r_dev["total"],
        "skill": r_skill["total"], "discipline": r_disc["total"],
        "leadership": r_lead["total"],
        "breakdown": {
            "academic": r_acad["breakdown"], "development": r_dev["breakdown"],
            "skill": r_skill["breakdown"], "discipline": r_disc["breakdown"],
            "leadership": r_lead["breakdown"],
        }
    }
