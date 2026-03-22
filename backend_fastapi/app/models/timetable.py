from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text
from datetime import datetime
from app.database import Base

class TimetableSlot(Base):
    __tablename__ = "timetable_slots"

    id            = Column(Integer, primary_key=True, index=True)
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=False)
    class_id      = Column(Integer, ForeignKey("classes.id"), nullable=False)
    subject_id    = Column(Integer, ForeignKey("subjects.id"), nullable=False)
    faculty_id    = Column(Integer, ForeignKey("faculty.id"), nullable=False)
    day_of_week   = Column(String, nullable=False)  # "Monday"..."Saturday"
    start_time    = Column(String, nullable=False)  # "09:00"
    end_time      = Column(String, nullable=False)  # "10:00"
    room          = Column(String, nullable=True)
    created_at    = Column(DateTime, default=datetime.utcnow)

class TimetablePDF(Base):
    __tablename__ = "timetable_pdfs"

    id            = Column(Integer, primary_key=True, index=True)
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=False)
    class_id      = Column(Integer, ForeignKey("classes.id"), nullable=False)
    file_data     = Column(Text, nullable=False)  # base64 encoded PDF
    file_name     = Column(String, nullable=False)
    uploaded_at   = Column(DateTime, default=datetime.utcnow)