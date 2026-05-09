import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "Smart Campus Assistant"
    DEBUG: bool = True
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./campus.db")
    
    # Redis / Celery
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    
    # OCR Settings
    TESSERACT_CMD: str = r'E:\1 MyApps\tesseract.exe'
    
    # Uploads
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "uploads")
    
    # Security
    TOTP_ENCRYPTION_KEY: str = os.getenv("TOTP_ENCRYPTION_KEY", "nniAbFyqQ66g1YqlSvYPAyDMxPRkeXgLnFwFiRa_Esg=")
    
    class Config:
        env_file = ".env"

settings = Settings()
