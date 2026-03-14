# File: app/models/student.py
from sqlalchemy import Column, Integer, String, DateTime
from app.database import Base
from datetime import datetime

class Student(Base):
    __tablename__ = "students"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=True, index=True)

    # Basic Info
    full_name = Column(String, nullable=False)
    register_number = Column(String, unique=True, index=True, nullable=False)

    # Academic Info
    department = Column(String, nullable=False)
    year = Column(String, nullable=False)
    section = Column(String, nullable=False)

    # Personal Info
    date_of_birth = Column(String, nullable=True)
    blood_group = Column(String, nullable=True)
    gender = Column(String, nullable=True)
    residential_type = Column(String, default="Day Scholar")

    # Contact Info
    phone_number = Column(String, nullable=True)
    email = Column(String, nullable=True)
    address = Column(String, nullable=True)

    # Parent Details
    parent_name = Column(String, nullable=True)
    parent_phone = Column(String, nullable=True)
    parent_email = Column(String, nullable=True)
    parent_relationship = Column(String, nullable=True) # ✅ Added

    # Residential Details
    room_number = Column(String, nullable=True) # ✅ Added
    hostel_name = Column(String, nullable=True) # ✅ Added

    # Emergency Contact
    emergency_contact_name = Column(String, nullable=True) # ✅ Added
    emergency_contact_phone = Column(String, nullable=True) # ✅ Added
    medical_conditions = Column(String, nullable=True) # ✅ Added

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)