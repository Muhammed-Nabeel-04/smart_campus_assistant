from sqlalchemy import Column, Integer, String
from app.database import Base

class FAQ(Base):
    __tablename__ = "faq"

    id = Column(Integer, primary_key=True, index=True)
    question = Column(String)
    answer = Column(String)
