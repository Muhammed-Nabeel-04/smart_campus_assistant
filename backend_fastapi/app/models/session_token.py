from sqlalchemy import Column, Integer, String, DateTime
from app.database import Base
from datetime import datetime


class SessionToken(Base):
    __tablename__ = "session_tokens"

    id = Column(Integer, primary_key=True, index=True)

    token = Column(String, unique=True, index=True)

    faculty_id = Column(Integer,nullable=True)   # ADD THIS

    expires_at = Column(DateTime)

    created_at = Column(DateTime, default=datetime.utcnow)