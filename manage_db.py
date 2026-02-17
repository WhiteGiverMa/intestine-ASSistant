import sqlite3
import os

db_path = "backend/intestine_assistant.db"

if not os.path.exists(db_path):
    print(f"数据库文件不存在: {db_path}")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

print("=" * 60)
print("肠道健康助手 - 数据库管理工具")
print("=" * 60)

# 显示所有用户
print("\n当前用户列表:")
print("-" * 60)
cursor.execute("SELECT id, email, nickname, created_at FROM users")
users = cursor.fetchall()

if users:
    for i, user in enumerate(users, 1):
        print(f"{i}. ID: {user[0]}")
        print(f"   邮箱: {user[1]}")
        print(f"   昵称: {user[2]}")
        print(f"   创建时间: {user[3]}")
        print("-" * 60)
else:
    print("暂无用户")

# 显示统计信息
print("\n数据统计:")
cursor.execute("SELECT COUNT(*) FROM users")
print(f"  用户总数: {cursor.fetchone()[0]}")

cursor.execute("SELECT COUNT(*) FROM bowel_records")
print(f"  排便记录: {cursor.fetchone()[0]}")

cursor.execute("SELECT COUNT(*) FROM ai_analyses")
print(f"  AI分析: {cursor.fetchone()[0]}")

print("\n" + "=" * 60)
print("操作选项:")
print("  1. 删除特定用户 (需要用户ID)")
print("  2. 清空所有用户数据")
print("  3. 删除整个数据库文件")
print("  0. 退出")
print("=" * 60)

choice = input("\n请选择操作 (0-3): ").strip()

if choice == "1":
    user_id = input("请输入要删除的用户ID: ").strip()
    if user_id:
        # 删除关联数据
        cursor.execute("DELETE FROM bowel_records WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM ai_analyses WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM reminders WHERE user_id = ?", (user_id,))
        cursor.execute("DELETE FROM users WHERE id = ?", (user_id,))
        conn.commit()
        print(f"\n已删除用户 {user_id} 及其所有关联数据")
    else:
        print("\n无效的用户ID")

elif choice == "2":
    confirm = input("确认清空所有用户数据? (yes/no): ").strip().lower()
    if confirm == "yes":
        cursor.execute("DELETE FROM bowel_records")
        cursor.execute("DELETE FROM ai_analyses")
        cursor.execute("DELETE FROM reminders")
        cursor.execute("DELETE FROM users")
        conn.commit()
        print("\n已清空所有用户数据")
    else:
        print("\n操作已取消")

elif choice == "3":
    confirm = input("确认删除整个数据库文件? 这将删除所有数据! (yes/no): ").strip().lower()
    if confirm == "yes":
        conn.close()
        os.remove(db_path)
        print(f"\n已删除数据库文件: {db_path}")
        print("下次启动服务时会自动创建新的空数据库")
    else:
        print("\n操作已取消")

else:
    print("\n已退出")

if conn:
    conn.close()
