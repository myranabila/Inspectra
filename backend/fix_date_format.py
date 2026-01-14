import sqlite3
import os

def fix_date_formats():
    path = 'inspectra.db'
    if not os.path.exists(path):
        print("DB not found")
        return

    conn = sqlite3.connect(path)
    cursor = conn.cursor()
    
    print("Fixing Date formats in database...")
    
    # Fix scheduled_date (Column is Date, but DateTime string was inserted)
    # SQLite SUBSTR(str, start, length). Start is 1-indexed.
    cursor.execute("""
        UPDATE inspections 
        SET scheduled_date = SUBSTR(scheduled_date, 1, 10) 
        WHERE LENGTH(scheduled_date) > 10
    """)
    print(f"Updated {cursor.rowcount} scheduled_date rows.")
    
    # Fix completion_date
    cursor.execute("""
        UPDATE inspections 
        SET completion_date = SUBSTR(completion_date, 1, 10) 
        WHERE LENGTH(completion_date) > 10
    """)
    print(f"Updated {cursor.rowcount} completion_date rows.")
    
    conn.commit()
    conn.close()
    print("Dates fixed.")

if __name__ == "__main__":
    fix_date_formats()
