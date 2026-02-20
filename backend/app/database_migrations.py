"""数据库迁移管理模块

自动检测并应用数据库结构变更
"""

import sqlite3
from pathlib import Path

from app.database import engine


class DatabaseMigration:
    """数据库迁移管理器"""

    def __init__(self) -> None:
        self.db_path = self._get_db_path()

    def _get_db_path(self) -> Path:
        """获取数据库文件路径"""
        # 从 engine url 解析路径
        url = str(engine.url)
        if url.startswith("sqlite+aiosqlite:///"):
            path = url.replace("sqlite+aiosqlite:///", "")
            return Path(path)
        if url.startswith("sqlite:///"):
            path = url.replace("sqlite:///", "")
            return Path(path)
        msg = f"Unsupported database URL: {url}"
        raise ValueError(msg)

    def _column_exists(self, table: str, column: str) -> bool:
        """检查列是否存在"""
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.cursor()
        cursor.execute(f"PRAGMA table_info({table})")
        columns = [col[1] for col in cursor.fetchall()]
        conn.close()
        return column in columns

    def _add_column(self, table: str, column: str, col_type: str, default: str | None = None) -> None:
        """添加列到表"""
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.cursor()

        if default is not None:
            sql = f"ALTER TABLE {table} ADD COLUMN {column} {col_type} DEFAULT {default}"
        else:
            sql = f"ALTER TABLE {table} ADD COLUMN {column} {col_type}"

        cursor.execute(sql)
        conn.commit()
        conn.close()
        print(f"✅ Added column '{column}' to table '{table}'")

    def migrate(self):
        """执行所有待处理的迁移"""
        if not self.db_path.exists():
            print("Database does not exist yet, skipping migrations")
            return

        # 迁移记录
        migrations = [
            ("users", "ai_auto_title", "BOOLEAN", "0"),
            # 未来新增字段在这里添加
            # ("users", "new_field", "TEXT", None),
        ]

        pending = [
            (table, column, col_type, default)
            for table, column, col_type, default in migrations
            if not self._column_exists(table, column)
        ]

        if not pending:
            return

        print(f"Checking migrations for: {self.db_path}")
        for table, column, col_type, default in pending:
            self._add_column(table, column, col_type, default)
        print(f"Applied {len(pending)} migration(s)")


def run_migrations():
    """运行数据库迁移"""
    migration = DatabaseMigration()
    migration.migrate()
