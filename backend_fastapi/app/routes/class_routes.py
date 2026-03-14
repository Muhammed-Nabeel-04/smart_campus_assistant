from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.services.deps import get_db
from app.models.class_model import ClassModel
from app.models.department import Department

router = APIRouter(prefix="/classes", tags=["Classes"])

@router.get("/")
def get_classes(department_id: int, db: Session = Depends(get_db)):
    
    # Check department exists
    dept = db.query(Department).filter(Department.id == department_id).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")

    classes = db.query(ClassModel).filter(
        ClassModel.department_id == department_id
    ).all()

    return [
        {
            "id": c.id,
            "year": c.year,
            "section": c.section,
            "current_semester": c.current_semester,
            "department_id": c.department_id,
            "display": f"{c.year} - Section {c.section}"
        }
        for c in classes
    ]