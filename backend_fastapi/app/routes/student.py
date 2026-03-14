from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.models.student import Student
from app.services.deps import get_db

router = APIRouter(prefix="/students", tags=["Students"])

@router.post("/")
def create_student(user_id: int, department: str, year: str, db: Session = Depends(get_db)):
    student = Student(user_id=user_id, department=department, year=year)
    db.add(student)
    db.commit()
    db.refresh(student)
    return student

@router.get("/")
def get_students(db: Session = Depends(get_db)):
    return db.query(Student).all()
