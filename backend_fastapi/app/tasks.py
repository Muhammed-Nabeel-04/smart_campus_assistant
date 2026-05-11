from datetime import datetime
from app.celery_app import celery_app
from app.database import SessionLocal
from app.models.attendance_session import AttendanceSession

@celery_app.task(name="app.tasks.auto_end_session_task")
def auto_end_session_task(session_id: int):
    db = SessionLocal()
    try:
        session = db.query(AttendanceSession).filter(
            AttendanceSession.id == session_id,
            AttendanceSession.status == "active"
        ).first()
        
        if session:
            # Check if it really should end
            if session.auto_end_at and datetime.now() >= session.auto_end_at:
                session.status = "ended"
                session.ended_at = datetime.now()
                db.commit()
                return f"Session {session_id} auto-ended."
            return f"Session {session_id} not yet expired or already ended."
        return f"Session {session_id} not found or inactive."
    except Exception as e:
        print(f"Error auto-ending session {session_id}: {e}")
        return f"Error: {str(e)}"
    finally:
        db.close()
