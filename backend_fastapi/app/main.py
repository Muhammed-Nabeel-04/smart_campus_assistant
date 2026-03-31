from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base

# ── Import ALL models before create_all so tables are registered ──
import app.models.user
import app.models.student
import app.models.faculty
import app.models.subject
import app.models.department
import app.models.class_model
import app.models.class_subject
import app.models.attendance
import app.models.attendance_session
import app.models.complaint
import app.models.notification
import app.models.onboarding_token
import app.models.session_token
import app.models.faq
import app.models.notice

# ── Create FastAPI app ──
app = FastAPI(title="Smart Campus Assistant API")

# ── Create tables ──
Base.metadata.create_all(bind=engine)

# ── CORS ──
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Startup event ──
@app.on_event("startup")
def startup():
    # Auto-migrate: add new columns to existing tables
    from sqlalchemy import inspect, text
    with engine.connect() as conn:
        inspector = inspect(engine)

        # Departments: timetable_days
        dept_cols = [c['name'] for c in inspector.get_columns('departments')]
        if 'timetable_days' not in dept_cols:
            conn.execute(text("ALTER TABLE departments ADD COLUMN timetable_days TEXT"))
            conn.commit()
            print("✅ Added timetable_days column to departments table")

        # Students: add columns that were added later
        stu_cols = [c['name'] for c in inspector.get_columns('students')]
        new_stu_cols = [
            'parent_relationship', 'hostel_name', 'room_number',
            'emergency_contact_name', 'emergency_contact_phone',
            'medical_conditions',
        ]
        for col in new_stu_cols:
            if col not in stu_cols:
                conn.execute(text(f"ALTER TABLE students ADD COLUMN {col} TEXT"))
                print(f"✅ Added {col} column to students table")
        conn.commit()

    print("🚀 Smart Campus API started")

# ── Routes imports ──
from app.routes.auth import router as auth_router
from app.routes.onboarding import router as onboarding_router
from app.routes.faculty import router as faculty_router
from app.routes.faculty_routes import router as faculty_routes_router
from app.routes.department_routes import router as department_router
from app.routes.class_routes import router as class_router
from app.routes.subject_routes import router as subject_router
from app.routes.students_crud import router as students_crud_router
from app.routes.student_profile_routes import router as student_profile_router
from app.routes.attendance_routes import router as attendance_router
from app.routes.notification_routes import router as notification_router
from app.routes.complaint_routes import router as complaint_router
from app.routes.admin_routes import router as admin_router
from app.routes.hod_setup_routes import router as hod_router
from app.routes.principal_setup_routes import router as principal_setup_router
from app.routes.principal_routes import router as principal_router

from app.models.timetable import TimetableSlot, TimetablePDF
from app.routes.timetable_routes import router as timetable_router

# ── Auth dependency ──
from app.services.deps import get_current_user

# ── Public routes ──
app.include_router(auth_router)
app.include_router(onboarding_router)
app.include_router(department_router)
app.include_router(class_router)
app.include_router(subject_router)

# ── Protected routes ──
app.include_router(
    faculty_routes_router,
    dependencies=[Depends(get_current_user)]
)
app.include_router(
    students_crud_router,
    dependencies=[Depends(get_current_user)]
)
app.include_router(
    student_profile_router,
    dependencies=[Depends(get_current_user)]
)
app.include_router(
    attendance_router,
    dependencies=[Depends(get_current_user)]
)
app.include_router(
    notification_router,
    dependencies=[Depends(get_current_user)]
)
app.include_router(
    complaint_router,
    dependencies=[Depends(get_current_user)]
)
app.include_router(
    admin_router,
    dependencies=[Depends(get_current_user)]
)
app.include_router(
    hod_router,
    dependencies=[Depends(get_current_user)]
)
app.include_router(
    principal_setup_router,
    dependencies=[Depends(get_current_user)]
)
app.include_router(
    principal_router,
    dependencies=[Depends(get_current_user)]
)
app.include_router(timetable_router)

# ── Root route ──
@app.get("/")
def root():
    return {"status": "Smart Campus API Running", "version": "2.0"}