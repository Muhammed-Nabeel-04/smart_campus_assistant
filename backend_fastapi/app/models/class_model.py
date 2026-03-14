from sqlalchemy import Column, Integer, String, ForeignKey
from app.database import Base

class ClassModel(Base):
    __tablename__ = "classes"

    id = Column(Integer, primary_key=True, index=True)
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=False)
    year = Column(String, nullable=False)
    section = Column(String, nullable=False)
    current_semester = Column(String, default="Semester 1")