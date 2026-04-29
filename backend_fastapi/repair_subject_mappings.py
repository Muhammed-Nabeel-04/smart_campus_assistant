import sqlite3
import os

# Path to your database
DB_PATH = 'backend_fastapi/campus.db'

def repair_mappings():
    if not os.path.exists(DB_PATH):
        print(f"Error: Database not found at {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    print("--- Repairing Subject-to-Section Mappings ---")

    # 1. Get all subjects
    cursor.execute("SELECT id, name, department, year, semester FROM subjects")
    subjects = cursor.fetchall()
    
    links_added = 0

    for sub_id, sub_name, dept_code, year, semester in subjects:
        # Find the department ID from the code
        cursor.execute("SELECT id FROM departments WHERE code = ?", (dept_code,))
        dept_row = cursor.fetchone()
        if not dept_row:
            continue
        dept_id = dept_row[0]

        # Find all classes (sections) for this department and year
        cursor.execute("SELECT id, section FROM classes WHERE department_id = ? AND year = ?", (dept_id, year))
        classes = cursor.fetchall()

        for class_id, section in classes:
            # Check if link already exists
            cursor.execute("SELECT id FROM class_subjects WHERE class_id = ? AND subject_id = ?", (class_id, sub_id))
            if not cursor.fetchone():
                # Add the missing link
                sem_str = f"Semester {semester}"
                cursor.execute("INSERT INTO class_subjects (class_id, subject_id, semester) VALUES (?, ?, ?)", 
                               (class_id, sub_id, sem_str))
                print(f"Linked: [{sub_name}] -> [Year: {year}, Sec: {section}]")
                links_added += 1

    conn.commit()
    conn.close()
    print(f"--- Done! Added {links_added} missing links. ---")

if __name__ == "__main__":
    repair_mappings()
