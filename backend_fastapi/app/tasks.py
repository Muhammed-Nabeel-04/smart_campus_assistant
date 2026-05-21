import asyncio
import logging
from datetime import datetime
from app.database import SessionLocal
from app.models.attendance_session import AttendanceSession

logger = logging.getLogger("app.tasks")

async def auto_end_session_task(session_id: int, delay_seconds: int):
    """
    Background task to auto-end an attendance session after a delay.
    No Redis/Celery required. Uses asyncio.sleep.
    """
    if delay_seconds <= 0:
        return

    logger.info(f"Scheduling auto-end for session {session_id} in {delay_seconds}s")
    
    # Wait for the duration
    await asyncio.sleep(delay_seconds)
    
    db = SessionLocal()
    try:
        session = db.query(AttendanceSession).filter(
            AttendanceSession.id == session_id,
            AttendanceSession.status == "active"
        ).first()
        
        if session:
            # Check if it should still end (maybe it was ended manually)
            if session.auto_end_at and datetime.now() >= session.auto_end_at:
                session.status = "ended"
                session.ended_at = datetime.now()
                db.commit()
                logger.info(f"Session {session_id} auto-ended successfully.")
            else:
                logger.info(f"Session {session_id} already ended or time updated.")
    except Exception as e:
        logger.error(f"Error auto-ending session {session_id}: {e}")
    finally:
        db.close()
