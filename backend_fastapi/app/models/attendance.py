from sqlalchemy import Column, Integer, String, DateTime, Date, ForeignKey, Boolean
from app.database import Base
from datetime import datetime

class Attendance(Base):
    __tablename__ = "attendance"

    id = Column(Integer, primary_key=True, index=True)

    session_id = Column(Integer, ForeignKey("attendance_sessions.id"), nullable=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False)

    status = Column(String, default="present")  # present, absent, late
    is_manual = Column(Boolean, default=False)

    date = Column(Date, default=lambda: datetime.now().date())
    timestamp = Column(DateTime, default=datetime.now)
    remarks = Column(String, nullable=True)