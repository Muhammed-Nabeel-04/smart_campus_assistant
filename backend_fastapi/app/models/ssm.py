# File: app/models/ssm.py
from sqlalchemy import Column, Integer, String, Float, DateTime, Text
from app.database import Base
from datetime import datetime

class SSMSubmission(Base):
    __tablename__ = "ssm_submissions"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, nullable=False, index=True)

    form_data = Column(Text, nullable=True)       # JSON: all 29 fields saved
    total_score = Column(Float, default=0.0)       # 0–500
    star_rating = Column(Integer, default=0)       # 0–5
    score_breakdown = Column(Text, nullable=True)  # JSON breakdown

    # draft → submitted → mentor_approved/rejected → hod_approved/rejected
    status = Column(String, default="draft")

    submitted_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)


class SSMReview(Base):
    __tablename__ = "ssm_reviews"

    id = Column(Integer, primary_key=True, index=True)
    submission_id = Column(Integer, nullable=False, index=True)

    reviewer_role = Column(String, nullable=False)   # mentor | hod
    reviewer_id = Column(Integer, nullable=False)
    reviewer_name = Column(String, nullable=True)

    status = Column(String, nullable=False)          # approved | rejected
    remarks = Column(String, nullable=True)
    reviewed_at = Column(DateTime, default=datetime.now)
