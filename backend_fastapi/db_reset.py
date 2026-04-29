import os
import shutil
import sqlite3

# ── 1. Clear pycache ──────────────────────────────────────────────
# We use a try-except because on Windows these folders are often locked
# by the IDE or other background processes.
for root, dirs, files in os.walk('.'):
    for d in dirs:
        if d == '__pycache__':
            path = os.path.join(root, d)
            try:
                shutil.rmtree(path)
            except Exception as e:
                print(f'⚠️  Could not clear {path}: {e}')
print('✅ Pycache clear attempt finished!')

# ── 2. Delete or clean database ───────────────────────────────────
DB_NAME = 'campus.db'
if os.path.exists(DB_NAME):
    try:
        # Try full delete first
        os.remove(DB_NAME)
        print(f'✅ {DB_NAME} deleted!')
    except PermissionError:
        # Server is likely running — clean data instead
        print(f'⚠️  {DB_NAME} is locked. Cleaning all tables instead...')
        try:
            conn = sqlite3.connect(DB_NAME)
            cursor = conn.cursor()
            
            # Get all table names
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = [row[0] for row in cursor.fetchall() if row[0] != 'sqlite_sequence']
            
            # Clean each table
            for table in tables:
                cursor.execute(f"DELETE FROM {table}")
                print(f"   - Cleaned {table}")
                
            conn.commit()
            conn.close()
            print('✅ All database tables cleaned!')
        except Exception as e:
            print(f'❌ Failed to clean database: {e}')
else:
    print(f'⚠️  {DB_NAME} not found, skipping...')

print()
print('Next: uvicorn app.main:app --host 0.0.0.0 --port 8000')
print('Then: python db_setup.py')