from sqlalchemy import Column, Integer, String, ForeignKey
from app.database import Base

class ClassSubject(Base):
    __tablename__ = "class_subjects"

    id = Column(Integer, primary_key=True, index=True)
    class_id = Column(Integer, ForeignKey("classes.id"), nullable=False)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False)
    semester = Column(String, nullable=False)