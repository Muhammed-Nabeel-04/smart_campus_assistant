from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.services.deps import get_db
from app.models.subject import Subject
from app.models.class_subject import ClassSubject
from app.models.class_model import ClassModel

router = APIRouter(prefix="/subjects", tags=["Subjects"])

@router.get("/")
def get_subjects(class_id: int, db: Session = Depends(get_db)):

    # Check class exists
    cls = db.query(ClassModel).filter(ClassModel.id == class_id).first()
    if not cls:
        raise HTTPException(status_code=404, detail="Class not found")

    # Get subjects linked to this class
    class_subjects = db.query(ClassSubject).filter(
        ClassSubject.class_id == class_id
    ).all()

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