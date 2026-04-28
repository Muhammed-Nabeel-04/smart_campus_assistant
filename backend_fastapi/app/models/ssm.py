# File: app/models/ssm.py  (FULL REPLACE)
# ─────────────────────────────────────────────────────────────────────────────
# New activity-based SSM architecture
#
# ssm_submissions  → one per student per semester (tracks overall state)
# ssm_entries      → one per activity added (NPTEL, internship, etc.)
# ssm_reviews      → mentor/HOD review records
# ssm_mentor_input → mentor fills their own evaluation fields
# ssm_proofs       → stays in ssm_proof.py (unchanged)
# ─────────────────────────────────────────────────────────────────────────────

from sqlalchemy import Column, Integer, String, Float, DateTime, Text, ForeignKey
from app.database import Base
from datetime import datetime


class SSMSubmission(Base):
    """One per student. Tracks overall score and workflow status."""
    __tablename__ = "ssm_submissions"

    id              = Column(Integer, primary_key=True, index=True)
    student_id      = Column(Integer, nullable=False, index=True, unique=True)
    # unique=True ensures one submission per student — entries accumulate

    # Computed totals (recalculated on every entry add/remove)
    total_score     = Column(Float, default=0.0)      # 0–500
    star_rating     = Column(Integer, default=0)       # 0–5
    score_breakdown = Column(Text, nullable=True)      # JSON per category

    # Workflow
    # active → submitted → mentor_approved → hod_approved
    # mentor_rejected/hod_rejected → back to active
    status          = Column(String, default="active")

    academic_year   = Column(String, default="2025-26")
    semester        = Column(String, nullable=True)     # "Odd" | "Even"

    submitted_at    = Column(DateTime, nullable=True)
    created_at      = Column(DateTime, default=datetime.now)
    updated_at      = Column(DateTime, default=datetime.now, onupdate=datetime.now)


class SSMEntry(Base):
    """
    One per activity the student adds.
    Student can add multiple entries throughout the semester.
    Each entry maps to one SSM criterion.
    """
    __tablename__ = "ssm_entries"

    id              = Column(Integer, primary_key=True, index=True)
    submission_id   = Column(Integer, ForeignKey("ssm_submissions.id"),
                             nullable=False, index=True)
    student_id      = Column(Integer, nullable=False, index=True)

    # ── What kind of activity ────────────────────────────────────────────────
    category        = Column(Integer, nullable=False)    # 1–5
    entry_type      = Column(String, nullable=False)
    # Valid types:
    # Cat 1: iat_gpa, university_gpa, attendance, project, consistency_index
    # Cat 2: nptel, online_cert, internship, competition, publication, skill_program
    # Cat 3: placement_readiness, industry_interaction, research_paper, innovation
    # Cat 5: leadership_role, event_leadership, team_management,
    #         innovation_initiative, community_leadership
    # (Cat 4 = mentor-only, no student entries)

    # ── Flexible details (JSON per type) ─────────────────────────────────────
    details         = Column(Text, nullable=True)
    # Examples:
    # nptel:        {"level": "Elite", "course": "Python", "duration": "8 weeks"}
    # internship:   {"duration": "4weeks+", "company": "TCS", "role": "Intern"}
    # competition:  {"result": "Winner", "event": "Smart India Hackathon"}
    # iat_gpa:      {"gpa": 8.5}

    # ── Score ─────────────────────────────────────────────────────────────────
    score           = Column(Float, default=0.0)

    # ── Proof ─────────────────────────────────────────────────────────────────
    proof_id        = Column(Integer, ForeignKey("ssm_proofs.id"), nullable=True)
    proof_required  = Column(Integer, default=1)    # 1=yes, 0=no
    proof_status    = Column(String, default="pending")
    # pending | valid | review | invalid | not_required

    # ── Entry status ──────────────────────────────────────────────────────────
    # pending_proof | verified | rejected | approved
    entry_status    = Column(String, default="pending_proof")

    added_at        = Column(DateTime, default=datetime.now)
    updated_at      = Column(DateTime, default=datetime.now, onupdate=datetime.now)


class SSMMentorInput(Base):
    """
    Mentor fills evaluation fields for a student.
    Separate from student-added entries.
    Can be updated multiple times during semester.
    """
    __tablename__ = "ssm_mentor_inputs"

    id              = Column(Integer, primary_key=True, index=True)
    submission_id   = Column(Integer, ForeignKey("ssm_submissions.id"),
                             nullable=False, index=True)
    student_id      = Column(Integer, nullable=False, index=True)
    mentor_id       = Column(Integer, nullable=False)    # faculty user_id
    mentor_name     = Column(String, nullable=True)

    # Category 1 — Mentor evaluates
    mentor_feedback = Column(String, nullable=True)   # Excellent/Good/Average
    hod_feedback    = Column(String, nullable=True)   # Excellent/Good/Average

    # Category 3 — Mentor evaluates
    tech_skill_level  = Column(String, nullable=True)  # Excellent/Good/Basic
    soft_skill_level  = Column(String, nullable=True)  # Excellent/Good/Average
    placement_outcome = Column(String, nullable=True)  # 15+LPA / etc.

    # Category 4 — Institution evaluates
    discipline_conduct = Column(String, nullable=True)  # Exemplary/Minor Issues
    punctuality_level  = Column(String, nullable=True)  # ge95NoLate/90-94/85-89
    dress_code         = Column(String, nullable=True)  # 100%/Highly Regular/General
    dept_event_contribution = Column(String, nullable=True)
    social_media_level = Column(String, nullable=True)

    updated_at      = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    created_at      = Column(DateTime, default=datetime.now)


class SSMReview(Base):
    """Mentor/HOD formal review of the submission."""
    __tablename__ = "ssm_reviews"

    id              = Column(Integer, primary_key=True, index=True)
    submission_id   = Column(Integer, ForeignKey("ssm_submissions.id"),
                             nullable=False, index=True)
    reviewer_role   = Column(String, nullable=False)    # mentor | hod
    reviewer_id     = Column(Integer, nullable=False)
    reviewer_name   = Column(String, nullable=True)
    status          = Column(String, nullable=False)    # approved | rejected
    remarks         = Column(String, nullable=True)
    reviewed_at     = Column(DateTime, default=datetime.now)