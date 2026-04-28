import os
import shutil
import sqlite3
from app.models.onboarding_token import OnboardingToken
from app.models.session_token import SessionToken
from app.models.timetable import TimetableSlot, TimetablePDF

# ── 1. Clear pycache ──────────────────────────────────────────────
for root, dirs, files in os.walk('.'):
    for d in dirs:
        if d == '__pycache__':
            shutil.rmtree(os.path.join(root, d))
print('✅ Pycache cleared!')

# ── 2. Delete or clean database ───────────────────────────────────
if os.path.exists('campus.db'):
    try:
        # Try full delete first
        os.remove('campus.db')
        print('✅ campus.db deleted!')
    except PermissionError:
        # Server is running — just clean the data instead
        print('⚠️  campus.db is locked (server running). Cleaning data instead...')
        conn = sqlite3.connect('campus.db')
        conn.execute("DELETE FROM users WHERE role='faculty'")
        conn.execute("DELETE FROM faculty")
        conn.execute("DELETE FROM students")
        conn.execute("DELETE FROM attendance")
        conn.execute("DELETE FROM attendance_sessions")
        conn.execute("DELETE FROM notifications")
        conn.execute("DELETE FROM complaints")
        conn.execute("DELETE FROM timetable_slots")
        conn.execute("DELETE FROM timetable_pdfs")
        conn.execute("DELETE FROM ssm_entries")
        conn.execute("DELETE FROM ssm_mentor_inputs")
        conn.execute("DELETE FROM ssm_reviews")
        conn.execute("DELETE FROM ssm_proofs")
        conn.execute("DELETE FROM ssm_submissions")
        conn.execute("DELETE FROM ssm_submissions")
        conn.execute("DELETE FROM ssm_reviews")
        conn.execute("DELETE FROM ssm_proofs")
        conn.execute("DELETE FROM ssm_submissions")
        conn.execute("DELETE FROM ssm_reviews")
        conn.commit()
        conn.close()
        print('✅ All data cleaned!')
else:
    print('⚠️  campus.db not found, skipping...')

print()
print('Next: uvicorn app.main:app --host 0.0.0.0 --port 8000')
print('Then: python db_setup.py')