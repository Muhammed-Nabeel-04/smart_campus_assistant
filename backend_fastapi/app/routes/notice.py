from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.models.notice import Notice
from app.services.deps import get_db

router = APIRouter(prefix="/notices", tags=["Notices"])

@router.post("/")
def create_notice(title: str, content: str, target_role: str, db: Session = Depends(get_db)):
    notice = Notice(title=title, content=content, target_role=target_role)
    db.add(notice)
    db.commit()
    db.refresh(notice)
    return notice

@router.get("/")
def get_notices(db: Session = Depends(get_db)):
    return db.query(Notice).all()

@router.get("/all")
def get_all_notices(db: Session = Depends(get_db)):

    notices = db.query(Notice).order_by(Notice.id.desc()).all()

    result = []

    for n in notices:
        result.append({
            "title": n.title,
            "message": n.message
        })

    return result