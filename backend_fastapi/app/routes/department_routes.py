from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.services.deps import get_db
from app.models.department import Department

router = APIRouter(prefix="/departments", tags=["Departments"])

@router.get("/")
def get_departments(db: Session = Depends(get_db)):
    departments = db.query(Department).all()
    return [
        {
            "id": d.id,
            "name": d.name,
            "code": d.code
        }
        for d in departments
    ]