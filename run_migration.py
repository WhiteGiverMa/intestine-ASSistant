import sqlite3
import os

script_dir = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(script_dir, 'backend', 'intestine_assistant.db')

if not os.path.exists(db_path):
    db_path = os.path.join(script_dir, 'intestine_assistant.db')

if not os.path.exists(db_path):
    print("ERROR: Database file not found")
    exit(1)

print(f"Database path: {db_path}")

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    cursor.execute("PRAGMA table_info(bowel_records)")
    columns = [col[1] for col in cursor.fetchall()]

    if 'is_no_bowel' in columns:
        print("is_no_bowel column already exists")
    else:
        cursor.execute("ALTER TABLE bowel_records ADD COLUMN is_no_bowel BOOLEAN DEFAULT 0")
        conn.commit()
        print("Successfully added is_no_bowel column")

    cursor.execute("PRAGMA table_info(bowel_records)")
    columns = [col[1] for col in cursor.fetchall()]
    print(f"Current columns: {columns}")

except Exception as e:
    print(f"Migration failed: {e}")
    conn.rollback()
finally:
    conn.close()
