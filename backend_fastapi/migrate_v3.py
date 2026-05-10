import sqlite3
import os

def migrate():
    db_path = os.path.join("backend_fastapi", "campus.db")
    if not os.path.exists(db_path):
        db_path = "campus.db"
    
    if not os.path.exists(db_path):
        print(f"❌ Database not found at {db_path}")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🚀 Starting migration v3 (Attendance Session auto_end_at)...")

    try:
        cursor.execute("PRAGMA table_info(attendance_sessions)")
        cols = [c[1] for c in cursor.fetchall()]
        
        if 'auto_end_at' not in cols:
            print("📦 Adding auto_end_at column to attendance_sessions...")
            cursor.execute("ALTER TABLE attendance_sessions ADD COLUMN auto_end_at DATETIME")
            print("✅ Column added successfully.")
        else:
            print("ℹ️ auto_end_at column already exists.")
    except Exception as e:
        print(f"⚠️ Error migrating attendance_sessions: {e}")

    conn.commit()
    conn.close()
    print("✨ Migration v3 complete!")

if __name__ == "__main__":
    migrate()
