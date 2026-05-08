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
    
    class Config:
        env_file = ".env"

settings = Settings()
