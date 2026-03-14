from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from app.database import Base
from datetime import datetime

class Complaint(Base):
    __tablename__ = "complaints"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False)

    category = Column(String, nullable=False)   # Academic, Infrastructure, etc.
    priority = Column(String, default="Medium") # Low, Medium, High, Critical
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)

    status = Column(String, default="pending")  # pending, in_progress, resolved, rejected
    admin_response = Column(String, nullable=True)
    resolved_at = Column(DateTime, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)