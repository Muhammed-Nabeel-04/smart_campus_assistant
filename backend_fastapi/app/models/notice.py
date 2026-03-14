from sqlalchemy import Column, Integer, String
from app.database import Base

class Notice(Base):
    __tablename__ = "notices"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    content = Column(String)
    target_role = Column(String)  # student / faculty / all
