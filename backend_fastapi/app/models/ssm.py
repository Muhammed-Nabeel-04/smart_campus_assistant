# File: app/models/ssm.py
# ─────────────────────────────────────────────────────────
# SSM (Student Score Management) — Performance Module
# Three tables: ssm_submissions, ssm_activities, ssm_reviews
# ─────────────────────────────────────────────────────────

from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from app.database import Base
from datetime import datetime


class SSMSubmission(Base):
    __tablename__ = "ssm_submissions"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)

    # Academic inputs
    gpa = Column(Float, nullable=True)                  # e.g. 8.5
    attendance_input = Column(Float, nullable=True)     # e.g. 82.5 (%)

    # Computed score (0–100)
    total_score = Column(Float, default=0.0)
    star_rating = Column(Integer, default=0)            # 1–5
    score_breakdown = Column(Text, nullable=True)       # JSON breakdown string

    # Workflow status
    # draft → submitted → mentor_approved / mentor_rejected → hod_approved / hod_rejected
    status = Column(String, default="draft")

    submitted_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)


class SSMActivity(Base):
    __tablename__ = "ssm_activities"

    id = Column(Integer, primary_key=True, index=True)
    submission_id = Column(Integer, ForeignKey("ssm_submissions.id"), nullable=False, index=True)

    # type: internship | certificate | project | achievement
    type = Column(String, nullable=False)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    duration = Column(String, nullable=True)        # e.g. "3 months", "2 weeks"
    organization = Column(String, nullable=True)    # company / platform / institution

    score = Column(Float, default=0.0)              # score assigned to this activity
    proof_file_name = Column(String, nullable=True) # original filename
    proof_file_data = Column(Text, nullable=True)   # base64 encoded file (simple local storage)

    created_at = Column(DateTime, default=datetime.now)


class SSMReview(Base):
    __tablename__ = "ssm_reviews"

    id = Column(Integer, primary_key=True, index=True)
    submission_id = Column(Integer, ForeignKey("ssm_submissions.id"), nullable=False, index=True)

    reviewer_role = Column(String, nullable=False)   # mentor | hod
    reviewer_id = Column(Integer, nullable=False)    # faculty.id or user.id
    reviewer_name = Column(String, nullable=True)

    status = Column(String, nullable=False)          # approved | rejected
    remarks = Column(String, nullable=True)

    reviewed_at = Column(DateTime, default=datetime.now)
