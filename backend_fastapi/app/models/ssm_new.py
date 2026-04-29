# File: app/models/ssm_new.py  (FULL REPLACE — replaces all old ssm.py + ssm_proof.py)
# ─────────────────────────────────────────────────────────────────────────────
# Ported from standalone SSM app, adapted for campus app:
#   - SQLite (no MySQL enums — use String)
#   - Campus auth (Student/Faculty tables, not single users table)
#   - Mentor = CC faculty of student's class
# ─────────────────────────────────────────────────────────────────────────────

from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Text, ForeignKey
from app.database import Base
from datetime import datetime


# ─── SSM FORM (one per student per academic year) ─────────────────────────────

class SSMForm(Base):
    __tablename__ = "ssm_forms"

    id            = Column(Integer, primary_key=True, index=True)
    student_id    = Column(Integer, nullable=False, index=True)  # FK → students.id
    mentor_id     = Column(Integer, nullable=True)               # FK → faculty.id (CC)
    hod_id        = Column(Integer, nullable=True)               # FK → faculty.id

    academic_year = Column(String(9), default="2025-2026")
    # draft → submitted → mentor_review → hod_review → approved | rejected
    status        = Column(String(20), default="draft")

    mentor_remarks   = Column(Text, nullable=True)
    hod_remarks      = Column(Text, nullable=True)
    rejection_reason = Column(Text, nullable=True)

    submitted_at  = Column(DateTime, nullable=True)
    approved_at   = Column(DateTime, nullable=True)
    created_at    = Column(DateTime, default=datetime.now)
    updated_at    = Column(DateTime, default=datetime.now, onupdate=datetime.now)


# ─── CATEGORY 1: ACADEMIC ─────────────────────────────────────────────────────

class AcademicData(Base):
    __tablename__ = "ssm_academic_data"

    id      = Column(Integer, primary_key=True)
    form_id = Column(Integer, ForeignKey("ssm_forms.id", ondelete="CASCADE"), unique=True)

    # Student fills
    internal_gpa    = Column(Float, nullable=True)
    university_gpa  = Column(Float, nullable=True)
    has_arrear      = Column(Boolean, default=False)
    attendance_pct  = Column(Float, nullable=True)
    project_status  = Column(String(30), default="none")
    # none | concept | partial | fully_completed

    # Mentor fills
    mentor_feedback = Column(String(20), nullable=True)  # average | good | excellent

    # HOD fills
    hod_feedback    = Column(String(20), nullable=True)  # average | good | excellent


# ─── CATEGORY 2: STUDENT DEVELOPMENT ─────────────────────────────────────────

class DevelopmentData(Base):
    __tablename__ = "ssm_development_data"

    id      = Column(Integer, primary_key=True)
    form_id = Column(Integer, ForeignKey("ssm_forms.id", ondelete="CASCADE"), unique=True)

    # Student fills
    nptel_tier                 = Column(String(20), default="none")
    # none | participated | completed | elite | elite_plus
    online_cert_count          = Column(Integer, default=0)
    internship_duration        = Column(String(20), default="none")
    # none | participation | 1to2weeks | 2to4weeks | 4weeks_plus
    competition_result         = Column(String(20), default="none")
    # none | participated | finalist | winner
    publication_type           = Column(String(20), default="none")
    # none | prototype | conference | patent
    professional_programs_count= Column(Integer, default=0)


# ─── CATEGORY 3: SKILL & READINESS ───────────────────────────────────────────

class SkillData(Base):
    __tablename__ = "ssm_skill_data"

    id      = Column(Integer, primary_key=True)
    form_id = Column(Integer, ForeignKey("ssm_forms.id", ondelete="CASCADE"), unique=True)

    # Mentor rates
    technical_skill = Column(String(20), nullable=True)  # basic | good | excellent
    soft_skill      = Column(String(20), nullable=True)  # average | good | excellent
    team_management = Column(String(20), nullable=True)  # limited | good | excellent

    # Student fills
    placement_training_pct = Column(Float, default=0.0)
    placement_lpa          = Column(Float, default=0.0)
    higher_studies         = Column(Boolean, default=False)
    industry_interactions  = Column(Integer, default=0)
    research_papers_count  = Column(Integer, default=0)
    innovation_level       = Column(String(20), default="none")
    # none | minor | proposed | implemented


# ─── CATEGORY 4: DISCIPLINE ───────────────────────────────────────────────────

class DisciplineData(Base):
    __tablename__ = "ssm_discipline_data"

    id      = Column(Integer, primary_key=True)
    form_id = Column(Integer, ForeignKey("ssm_forms.id", ondelete="CASCADE"), unique=True)

    # Mentor rates
    discipline_level  = Column(String(20), default="no_violations")
    # no_violations | minor | major
    dress_code_level  = Column(String(30), default="consistent")
    # consistent | highly_regular | generally_follows
    dept_contribution = Column(String(30), default="none")
    # none | minor_idea | proposed_useful | implemented_impactful
    social_media_level= Column(String(30), default="none")
    # none | minimal | occasional | participates_shares | regularly_contributes | active_creates

    # From academic
    attendance_pct    = Column(Float, default=0.0)
    late_entries      = Column(Boolean, default=False)


# ─── CATEGORY 5: LEADERSHIP ───────────────────────────────────────────────────

class LeadershipData(Base):
    __tablename__ = "ssm_leadership_data"

    id      = Column(Integer, primary_key=True)
    form_id = Column(Integer, ForeignKey("ssm_forms.id", ondelete="CASCADE"), unique=True)

    # Student fills (mentor confirms)
    formal_role         = Column(String(20), default="none")
    # none | class_level | dept_level | college_level
    event_leadership    = Column(String(20), default="none")
    # none | assisted | led_1 | led_2plus
    community_leadership= Column(String(20), default="none")
    # none | minimal | active | led_project

    # Mentor rates
    innovation_initiative      = Column(String(20), default="none")
    # none | minor | proposed | implemented
    team_management_leadership = Column(String(20), nullable=True)
    # limited | good | excellent


# ─── CALCULATED SCORE ─────────────────────────────────────────────────────────

class CalculatedScore(Base):
    __tablename__ = "ssm_calculated_scores"

    id      = Column(Integer, primary_key=True)
    form_id = Column(Integer, ForeignKey("ssm_forms.id", ondelete="CASCADE"), unique=True)

    academic_score    = Column(Float, default=0)
    development_score = Column(Float, default=0)
    skill_score       = Column(Float, default=0)
    discipline_score  = Column(Float, default=0)
    leadership_score  = Column(Float, default=0)
    grand_total       = Column(Float, default=0)
    star_rating       = Column(Integer, default=0)
    calculated_at     = Column(DateTime, default=datetime.now)


# ─── STUDENT ACTIVITY (one per activity submission) ───────────────────────────

class StudentActivity(Base):
    """
    Each activity the student adds throughout the semester.
    When mentor approves → _patch_form_data() updates the SSMForm category data.
    """
    __tablename__ = "student_activities"

    id         = Column(Integer, primary_key=True, index=True)
    form_id    = Column(Integer, ForeignKey("ssm_forms.id", ondelete="CASCADE"), nullable=False, index=True)
    student_id = Column(Integer, nullable=False, index=True)

    # Category and type
    category      = Column(String(20), nullable=False)
    # academic | development | skill | leadership
    activity_type = Column(String(30), nullable=False)
    # gpa_update | project | nptel | online_cert | internship | competition |
    # publication | prof_program | placement | higher_study | industry_int |
    # research | formal_role | event_org | community

    # Academic fields
    internal_gpa    = Column(Float, nullable=True)
    university_gpa  = Column(Float, nullable=True)
    attendance_pct  = Column(Float, nullable=True)
    has_arrear      = Column(Boolean, nullable=True)
    project_status  = Column(String(30), nullable=True)

    # Development fields
    nptel_tier          = Column(String(20), nullable=True)
    platform_name       = Column(String(100), nullable=True)
    course_name         = Column(String(200), nullable=True)
    internship_company  = Column(String(200), nullable=True)
    internship_duration = Column(String(20), nullable=True)
    competition_name    = Column(String(200), nullable=True)
    competition_result  = Column(String(20), nullable=True)
    publication_title   = Column(String(200), nullable=True)
    publication_type    = Column(String(20), nullable=True)
    program_name        = Column(String(200), nullable=True)

    # Skill fields
    placement_company   = Column(String(200), nullable=True)
    placement_lpa       = Column(Float, nullable=True)
    higher_study_exam   = Column(String(100), nullable=True)
    higher_study_score  = Column(String(50), nullable=True)
    industry_org        = Column(String(200), nullable=True)
    research_title      = Column(String(200), nullable=True)
    research_journal    = Column(String(200), nullable=True)

    # Leadership fields
    role_name       = Column(String(200), nullable=True)
    role_level      = Column(String(20), nullable=True)
    event_name      = Column(String(200), nullable=True)
    event_level     = Column(String(20), nullable=True)
    community_org   = Column(String(200), nullable=True)
    community_level = Column(String(20), nullable=True)

    # Document (base64 stored in DB for campus app)
    file_data         = Column(Text, nullable=True)       # base64
    file_name         = Column(String(255), nullable=True)
    file_type         = Column(String(10), nullable=True) # pdf | jpg | png
    file_size_kb      = Column(Integer, nullable=True)
    ocr_extracted_text= Column(Text, nullable=True)

    # Verification
    ocr_status    = Column(String(20), default="pending")
    # pending | valid | review | failed
    ocr_note      = Column(Text, nullable=True)
    mentor_status = Column(String(20), default="pending")
    # pending | approved | rejected | not_required
    mentor_note   = Column(Text, nullable=True)

    submitted_at = Column(DateTime, default=datetime.now)
    verified_at  = Column(DateTime, nullable=True)
