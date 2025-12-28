import sqlite3
import os

db_path = 'inspectra.db'
if not os.path.exists(db_path):
    print(f"Database not found at {db_path}")
    exit()

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    cursor.execute("SELECT id, username, staff_id, role, is_active FROM users")
    users = cursor.fetchall()
    print(f"Found {len(users)} users:")
    for u in users:
        print(u)
except Exception as e:
    print(f"Error: {e}")
finally:
    conn.close()
