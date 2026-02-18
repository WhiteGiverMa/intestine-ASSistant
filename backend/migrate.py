import sqlite3
from datetime import datetime
from collections import defaultdict

LID_CHARS = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

def encode_sequence(num: int) -> str:
    result = []
    for _ in range(4):
        result.append(LID_CHARS[num % 62])
        num //= 62
    return ''.join(reversed(result))

def generate_lid_from_date(record_date: str, sequence: int) -> str:
    date_obj = datetime.strptime(record_date, '%Y-%m-%d')
    yy = str(date_obj.year)[-2:]
    mmdd = f'{date_obj.month:02d}{date_obj.day:02d}'
    seq_str = encode_sequence(sequence)
    return f'L{yy}{mmdd}{seq_str}'

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

if 'lid' not in cols:
    c.execute('ALTER TABLE bowel_records ADD COLUMN lid VARCHAR(12)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_bowel_records_lid ON bowel_records(lid)')
    conn.commit()
    print('Added lid column')
else:
    print('lid column already exists')

c.execute('''
    SELECT id, user_id, record_date, created_at
    FROM bowel_records
    ORDER BY user_id, record_date, created_at
''')
all_records = c.fetchall()
print(f'Found {len(all_records)} total records')

user_date_records = defaultdict(list)
for record_id, user_id, record_date, created_at in all_records:
    user_date_records[(user_id, record_date)].append((record_id, created_at))

updated_count = 0
for (user_id, record_date), records in user_date_records.items():
    records.sort(key=lambda x: x[1] if x[1] else '')
    for sequence, (record_id, _) in enumerate(records):
        new_lid = generate_lid_from_date(record_date, sequence)
        c.execute('UPDATE bowel_records SET lid = ? WHERE id = ?', (new_lid, record_id))
        updated_count += 1

if updated_count > 0:
    conn.commit()
    print(f'Regenerated LIDs for {updated_count} records')

c.execute('SELECT id, lid, record_date FROM bowel_records ORDER BY record_date DESC, lid LIMIT 10')
print('\nSample LIDs:')
for row in c.fetchall():
    print(f'  {row[0][:8]}... -> {row[1]} (date: {row[2]})')

conn.close()
