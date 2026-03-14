from sqlalchemy import Column, Integer, String, DateTime, Text
from app.database import Base
from datetime import datetime

class Faculty(Base):
    __tablename__ = "faculty"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, unique=True, index=True)

    full_name = Column(String, nullable=False)
    employee_id = Column(String, unique=True, index=True, nullable=False)
    department = Column(String, nullable=False)

    phone_number = Column(String, nullable=True)
    email = Column(String, nullable=True)

    # JSON array: [{"year":"1st Year","department":"CSE","section":"A"}, ...]
    assigned_classes = Column(Text, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)