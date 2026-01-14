
import sqlite3
import os

db_path = 'inspectra.db'

if not os.path.exists(db_path):
    print(f"❌ Database not found: {db_path}")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

print("=" * 60)
print("FORCE CLEARING ALL INSPECTION DATA")
print("=" * 60)

try:
    # Delete all inspections
    cursor.execute("DELETE FROM inspections")
    deleted_count = cursor.rowcount
    
    # Reset auto-increment counter
    cursor.execute("DELETE FROM sqlite_sequence WHERE name='inspections'")
    
    conn.commit()
    
    print(f"\n✅ Successfully deleted {deleted_count} inspections")
    
    # Verify deletion
    cursor.execute("SELECT COUNT(*) FROM inspections")
    remaining = cursor.fetchone()[0]
    print(f"✅ Remaining inspections: {remaining}")
    
except Exception as e:
    conn.rollback()
    print(f"\n❌ Error: {e}")
finally:
    conn.close()
