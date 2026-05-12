import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "Smart Campus Assistant"
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./campus.db")
    
    # Redis / Celery
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    
    # OCR Settings
    TESSERACT_CMD: str = os.getenv("TESSERACT_CMD", r'E:\1 MyApps\tesseract.exe')
    
    # Uploads
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "uploads")
    
    # Security (No hardcoded defaults in source code)
    SECRET_KEY: str | None = os.getenv("SECRET_KEY")
    TOTP_ENCRYPTION_KEY: str | None = os.getenv("TOTP_ENCRYPTION_KEY")
    
    class Config:
        env_file = ".env"

settings = Settings()

# ── Validate Security Configuration ──
if not settings.SECRET_KEY or not settings.TOTP_ENCRYPTION_KEY:
    if settings.DEBUG:
        import warnings
        if not settings.SECRET_KEY:
            settings.SECRET_KEY = "insecure_dev_secret_key"
            warnings.warn("⚠️  SECRET_KEY not set. Using insecure default for development.")
        if not settings.TOTP_ENCRYPTION_KEY:
            settings.TOTP_ENCRYPTION_KEY = "nniAbFyqQ66g1YqlSvYPAyDMxPRkeXgLnFwFiRa_Esg=" # This is a placeholder, still bad but allows dev
            warnings.warn("⚠️  TOTP_ENCRYPTION_KEY not set. Using insecure default for development.")
    else:
        # Strictly require secrets in production
        missing = []
        if not settings.SECRET_KEY: missing.append("SECRET_KEY")
        if not settings.TOTP_ENCRYPTION_KEY: missing.append("TOTP_ENCRYPTION_KEY")
        raise RuntimeError(f"❌ Critical Security Error: Missing environment variables: {', '.join(missing)}")
