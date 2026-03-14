from sqlalchemy import Column, Integer, String, DateTime, Date, ForeignKey
from app.database import Base
from datetime import datetime

class Attendance(Base):
    __tablename__ = "attendance"

    id = Column(Integer, primary_key=True, index=True)

    session_id = Column(Integer, ForeignKey("attendance_sessions.id"), nullable=False)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False)

    status = Column(String, default="present")  # present, absent, late

    date = Column(Date, default=datetime.utcnow().date)
    timestamp = Column(DateTime, default=datetime.utcnow)
    remarks = Column(String, nullable=True)