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

    print("🚀 Starting migration...")

    # 1. Update student_activities table
    try:
        cursor.execute("PRAGMA table_info(student_activities)")
        cols = [c[1] for c in cursor.fetchall()]
        
        if 'file_data' in cols and 'file_path' not in cols:
            print("📦 Migrating student_activities: adding file_path...")
            cursor.execute("ALTER TABLE student_activities ADD COLUMN file_path TEXT")
            cursor.execute("ALTER TABLE student_activities ADD COLUMN file_type TEXT")
            cursor.execute("ALTER TABLE student_activities ADD COLUMN file_size_kb INTEGER")
            print("✅ Added file_path to student_activities")
    except Exception as e:
        print(f"⚠️ Error migrating student_activities: {e}")

    # 2. Update timetable_pdfs table
    try:
        cursor.execute("PRAGMA table_info(timetable_pdfs)")
        cols = [c[1] for c in cursor.fetchall()]
        
        if 'file_data' in cols and 'file_path' not in cols:
            print("📦 Migrating timetable_pdfs: adding file_path...")
            cursor.execute("ALTER TABLE timetable_pdfs ADD COLUMN file_path TEXT")
            print("✅ Added file_path to timetable_pdfs")
    except Exception as e:
        print(f"⚠️ Error migrating timetable_pdfs: {e}")

    conn.commit()
    conn.close()
    print("✨ Migration complete!")

if __name__ == "__main__":
    migrate()
