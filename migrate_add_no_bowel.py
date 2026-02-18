"""
数据库迁移脚本：添加 is_no_bowel 字段

运行方式：python migrate_add_no_bowel.py
"""

import sqlite3
import os

def migrate():
    db_path = os.path.join(os.path.dirname(__file__), 'backend', 'intestine_assistant.db')

    if not os.path.exists(db_path):
        db_path = os.path.join(os.path.dirname(__file__), 'intestine_assistant.db')

    if not os.path.exists(db_path):
        print("错误：找不到数据库文件")
        return

    print(f"数据库路径: {db_path}")

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        cursor.execute("PRAGMA table_info(bowel_records)")
        columns = [col[1] for col in cursor.fetchall()]

        if 'is_no_bowel' in columns:
            print("is_no_bowel 字段已存在，无需迁移")
        else:
            cursor.execute("ALTER TABLE bowel_records ADD COLUMN is_no_bowel BOOLEAN DEFAULT 0")
            conn.commit()
            print("成功添加 is_no_bowel 字段")

        cursor.execute("PRAGMA table_info(bowel_records)")
        columns = [col[1] for col in cursor.fetchall()]
        print(f"当前字段: {columns}")

    except Exception as e:
        print(f"迁移失败: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()
