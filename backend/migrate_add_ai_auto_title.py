"""Migration script to add ai_auto_title column to users table"""

import sqlite3
from pathlib import Path


def migrate():
    """Add ai_auto_title column to users table"""
    # Try multiple possible database locations
    possible_paths = [
        Path(__file__).parent / "intestine_assistant.db",
        Path(__file__).parent / "data" / "app.db",
        Path(__file__).parent.parent / "intestine_assistant.db",
    ]

    db_path = None
    for path in possible_paths:
        if path.exists():
            db_path = path
            break

    if not db_path:
        print("Database not found. Searched locations:")
        for path in possible_paths:
            print(f"  - {path}")
        return

    print(f"Found database at: {db_path}")

    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()

    # Check if column already exists
    cursor.execute("PRAGMA table_info(users)")
    columns = [col[1] for col in cursor.fetchall()]

    if "ai_auto_title" in columns:
        print("Column 'ai_auto_title' already exists in users table")
    else:
        # Add the new column with default value False (0)
        cursor.execute(
            "ALTER TABLE users ADD COLUMN ai_auto_title BOOLEAN DEFAULT 0"
        )
        conn.commit()
        print("Successfully added 'ai_auto_title' column to users table")

    conn.close()


if __name__ == "__main__":
    migrate()
