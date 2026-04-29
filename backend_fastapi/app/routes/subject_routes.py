from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.services.deps import get_db
from app.models.subject import Subject
from app.models.class_subject import ClassSubject
from app.models.class_model import ClassModel
from app.models.department import Department

router = APIRouter(prefix="/subjects", tags=["Subjects"])

@router.get("/")
def get_subjects(class_id: int, db: Session = Depends(get_db)):

    # Check class exists
    cls = db.query(ClassModel).filter(ClassModel.id == class_id).first()
    if not cls:
        raise HTTPException(status_code=404, detail="Class not found")

    # 1. Try to get subjects linked to this class specifically
    class_subjects = db.query(ClassSubject).filter(
        ClassSubject.class_id == class_id
    ).all()

    if class_subjects:
        result = []
        for cs in class_subjects:
            subject = db.query(Subject).filter(Subject.id == cs.subject_id).first()
            if subject:
                result.append({
                    "id": subject.id,
                    "name": subject.name,
                    "code": subject.code,
                    "credits": subject.credits,
                    "type": subject.type,
                    "semester": cs.semester
                })
        return result

    # 2. FALLBACK: If no links, fetch all subjects for this Dept + Year + Semester
    dept = db.query(Department).filter(Department.id == cls.department_id).first()
    if not dept:
        return []

    # Extract semester number from "Semester X" string
    sem_num = 1
    if cls.current_semester:
        import re
        match = re.search(r'\d+', cls.current_semester)
        if match:
            sem_num = int(match.group())

    subjects = db.query(Subject).filter(
        Subject.department == dept.code,
        Subject.year == cls.year,
        Subject.semester == sem_num
    ).all()

    return [{
        "id": s.id,
        "name": s.name,
        "code": s.code,
        "credits": s.credits,
        "type": s.type,
        "semester": f"Semester {s.semester}"
    } for s in subjects]