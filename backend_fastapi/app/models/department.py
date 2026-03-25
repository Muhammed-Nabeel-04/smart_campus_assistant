from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text
from datetime import datetime
from app.database import Base

class Department(Base):
    __tablename__ = "departments"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    code = Column(String, nullable=False, unique=True)
    hod_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_by_principal_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    sections = Column(Text, nullable=True)  # JSON array e.g. ["A","B","C"]
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    period_timings = Column(Text, nullable=True)  # JSON: [{"period":1,"start":"09:00","end":"10:00"}]
    timetable_days = Column(Text, nullable=True)  # JSON: ["Monday","Tuesday",...,"Saturday"]