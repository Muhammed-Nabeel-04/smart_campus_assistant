from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.models.faq import FAQ
from app.services.deps import get_db

router = APIRouter(prefix="/faq", tags=["FAQ"])

@router.post("/")
def add_faq(question: str, answer: str, db: Session = Depends(get_db)):
    faq = FAQ(question=question, answer=answer)
    db.add(faq)
    db.commit()
    db.refresh(faq)
    return faq

@router.get("/")
def get_faqs(db: Session = Depends(get_db)):
    return db.query(FAQ).all()
