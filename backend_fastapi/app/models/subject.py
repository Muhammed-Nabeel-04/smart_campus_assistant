from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from app.database import Base

class Subject(Base):
    __tablename__ = "subjects"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    code = Column(String, nullable=False, unique=True)
    department = Column(String, nullable=True)  # AIDS, CSE, ECE, etc.
    year = Column(String, nullable=True)         # "1st Year", "2nd Year", etc.
    semester = Column(Integer, nullable=True)    # 1-8
    credits = Column(Integer, default=3)
    type = Column(String, default="Theory")      # Theory, Lab, Project
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)