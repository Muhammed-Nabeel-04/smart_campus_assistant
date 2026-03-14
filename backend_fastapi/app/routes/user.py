from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from app.models.user import User
from app.services.deps import get_db

router = APIRouter(prefix="/users", tags=["Users"])

@router.post("/")
def create_user(name: str, email: str, role: str, db: Session = Depends(get_db)):
    user = User(name=name, email=email, role=role)
    db.add(user)
    try:
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Email already exists")

    return user

@router.get("/")
def get_users(db: Session = Depends(get_db)):
    return db.query(User).all()
