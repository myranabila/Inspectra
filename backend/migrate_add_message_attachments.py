"""
Manual migration script to add attachment columns to the messages table for file/photo sharing support.
"""
import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), 'inspectra.db')

ALTERS = [
    "ALTER TABLE messages ADD COLUMN attachment_url VARCHAR(500)",
    "ALTER TABLE messages ADD COLUMN attachment_type VARCHAR(50)",
    "ALTER TABLE messages ADD COLUMN attachment_name VARCHAR(255)"
]

def migrate():
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found at: {DB_PATH}")
        return
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    for stmt in ALTERS:
        try:
            cursor.execute(stmt)
            print(f"✓ Executed: {stmt}")
        except sqlite3.OperationalError as e:
            if 'duplicate column name' in str(e):
                print(f"Already exists: {stmt}")
            else:
                print(f"Error: {e}")
    conn.commit()
    conn.close()
    print("\n✅ Migration complete. Database is ready for attachments.")

if __name__ == "__main__":
    migrate()
