import sqlite3

conn = sqlite3.connect('intestine_assistant.db')
c = conn.cursor()
c.execute('PRAGMA table_info(bowel_records)')
cols = [x[1] for x in c.fetchall()]
print('Columns:', cols)

if 'is_no_bowel' not in cols:
    c.execute('ALTER TABLE bowel_records ADD COLUMN is_no_bowel BOOLEAN DEFAULT 0')
    conn.commit()
    print('Added is_no_bowel column')
else:
    print('is_no_bowel column already exists')

conn.close()
