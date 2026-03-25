from sqlalchemy import Column, Integer, String, DateTime, Boolean
from app.database import Base
from datetime import datetime, timedelta

class OnboardingToken(Base):
    __tablename__ = "onboarding_tokens"

    id = Column(Integer, primary_key=True, index=True)
    token = Column(String, unique=True, index=True, nullable=False)
    role = Column(String, nullable=False)       # "student" or "faculty"
    target_id = Column(Integer, nullable=False) # student_id or faculty_id

    used = Column(Boolean, default=False)
    used_at = Column(DateTime, nullable=True)

    expiry_time = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.now)