"""
数据库迁移脚本：添加用户AI配置字段

运行方式：python migrate_add_ai_config.py

此脚本会在users表中添加以下字段：
- ai_api_key: 用户自定义的AI API密钥
- ai_api_url: 用户自定义的AI API URL
- ai_model: 用户自定义的AI模型名称
"""
import sqlite3
import os

def migrate():
    db_path = os.path.join(os.path.dirname(__file__), 'backend', 'intestine_assistant.db')

    if not os.path.exists(db_path):
        print(f"数据库文件不存在: {db_path}")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        cursor.execute("PRAGMA table_info(users)")
        columns = [col[1] for col in cursor.fetchall()]

        migrations = []

        if 'ai_api_key' not in columns:
            migrations.append("ALTER TABLE users ADD COLUMN ai_api_key VARCHAR(255)")
            print("添加字段: ai_api_key")

        if 'ai_api_url' not in columns:
            migrations.append("ALTER TABLE users ADD COLUMN ai_api_url VARCHAR(500)")
            print("添加字段: ai_api_url")

        if 'ai_model' not in columns:
            migrations.append("ALTER TABLE users ADD COLUMN ai_model VARCHAR(100)")
            print("添加字段: ai_model")

        if migrations:
            for sql in migrations:
                cursor.execute(sql)
            conn.commit()
            print("迁移完成!")
        else:
            print("所有字段已存在，无需迁移。")

    except Exception as e:
        print(f"迁移失败: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()
