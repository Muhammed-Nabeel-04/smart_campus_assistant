import json
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.services.deps import get_db
from app.models.department import Department

router = APIRouter(prefix="/departments", tags=["Departments"])

@router.get("/")
def get_departments(db: Session = Depends(get_db)):
    departments = db.query(Department).all()
    result = []
    for d in departments:
        try:
            sections = json.loads(d.sections or '{}')
            if isinstance(sections, list):
                years = ["1st Year", "2nd Year", "3rd Year", "4th Year"]
                sections = {year: sections for year in years}
        except Exception:
            sections = {}
        result.append({
            "id": d.id,
            "name": d.name,
            "code": d.code,
            "sections_by_year": sections,
        })
    return result