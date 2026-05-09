from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text
from app.database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)  
    role = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.now) 

    # 2FA
    is_2fa_enabled = Column(Boolean, default=False)
    totp_secret = Column(Text, nullable=True)
 