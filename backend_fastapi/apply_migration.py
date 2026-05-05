import sqlite3
import os

db_path = os.path.join(os.getcwd(), 'campus.db')

def migrate():
    print(f"Connecting to database at: {db_path}")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("Adding 'used_by_name' column to 'onboarding_tokens' table...")
        cursor.execute("ALTER TABLE onboarding_tokens ADD COLUMN used_by_name VARCHAR")
        conn.commit()
        print("✅ Column added successfully!")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e).lower():
            print("ℹ️ Column already exists, skipping.")
        else:
            print(f"❌ Error: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()
