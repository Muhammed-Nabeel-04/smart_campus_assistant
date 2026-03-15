from app.database import engine, Base
import app.models.user, app.models.student, app.models.faculty
import app.models.subject, app.models.department, app.models.class_model
import app.models.class_subject, app.models.attendance, app.models.attendance_session
import app.models.complaint, app.models.notification, app.models.onboarding_token
import app.models.session_token, app.models.faq, app.models.notice

from passlib.hash import bcrypt
from passlib.context import CryptContext
from datetime import datetime
import sqlite3

# ── Create all tables ─────────────────────────────────────────
Base.metadata.create_all(bind=engine)
print('✅ All tables created!')

# ── Migrations ────────────────────────────────────────────────
conn = sqlite3.connect('campus.db')

MIGRATIONS = [
    ('faculty',        'ALTER TABLE faculty ADD COLUMN assigned_classes TEXT'),
    ('subjects',       'ALTER TABLE subjects ADD COLUMN department TEXT'),
    ('subjects',       'ALTER TABLE subjects ADD COLUMN year TEXT'),
    ('subjects',       'ALTER TABLE subjects ADD COLUMN semester TEXT'),
    ('session_tokens', 'ALTER TABLE session_tokens ADD COLUMN user_id INTEGER'),
]

for label, sql in MIGRATIONS:
    try:
        conn.execute(sql)
        conn.commit()
        print(f'✅ Migration: {label}')
    except Exception:
        pass  # Already exists — skip

print('✅ Migrations done!')

# ── Create Principal Account ──────────────────────────────────
bcrypt_ctx = CryptContext(schemes=["bcrypt"])

cursor = conn.cursor()
cursor.execute("SELECT id FROM users WHERE role = 'principal'")
if not cursor.fetchone():
    hashed = bcrypt_ctx.hash("principal@123")
    cursor.execute(
        "INSERT INTO users (name, email, password, role, created_at) VALUES (?, ?, ?, ?, ?)",
        ("Principal", "principal@college.edu", hashed, "principal", datetime.utcnow().isoformat())
    )
    conn.commit()
    print("✅ Principal account created!")
    print("   Email: principal@college.edu")
    print("   Password: principal@123")
else:
    print("✅ Principal account already exists")

conn.close()

print()
print('🎉 Setup complete! Start the server.')