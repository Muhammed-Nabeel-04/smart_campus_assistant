from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from app.database import Base
from datetime import datetime

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)

    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    type = Column(String, default="info")  # info, warning, urgent, announcement

    target_role = Column(String, nullable=True)        # "student", "faculty", "all"
    target_class_id = Column(Integer, nullable=True)
    target_department_id = Column(Integer, nullable=True)

    sent_by = Column(Integer, ForeignKey("faculty.id"), nullable=True)

    created_at = Column(DateTime, default=datetime.now)