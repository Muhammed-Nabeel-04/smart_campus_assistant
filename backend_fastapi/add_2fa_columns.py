import sqlite3
import os

db_path = os.path.join(os.path.dirname(__file__), 'campus.db')

def migrate():
    print(f"Connecting to database at: {db_path}")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Add is_2fa_enabled
    try:
        print("Adding 'is_2fa_enabled' column to 'users' table...")
        cursor.execute("ALTER TABLE users ADD COLUMN is_2fa_enabled BOOLEAN DEFAULT 0")
        conn.commit()
        print("✅ is_2fa_enabled added successfully!")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e).lower():
            print("ℹ️ is_2fa_enabled already exists, skipping.")
        else:
            print(f"❌ Error: {e}")

    # Add totp_secret
    try:
        print("Adding 'totp_secret' column to 'users' table...")
        cursor.execute("ALTER TABLE users ADD COLUMN totp_secret TEXT")
        conn.commit()
        print("✅ totp_secret added successfully!")
    except sqlite3.OperationalError as e:
        if "duplicate column name" in str(e).lower():
            print("ℹ️ totp_secret already exists, skipping.")
        else:
            print(f"❌ Error: {e}")

    finally:
        conn.close()

if __name__ == "__main__":
    migrate()
