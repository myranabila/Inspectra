"""
Clear all inspection data from the database
Keeps user accounts intact
"""
import sqlite3
import os

db_path = 'inspectra.db'

if not os.path.exists(db_path):
    print(f"❌ Database not found: {db_path}")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

print("=" * 60)
print("CLEARING ALL INSPECTION DATA")
print("=" * 60)

# Check current inspection count
cursor.execute("SELECT COUNT(*) FROM inspections")
inspection_count = cursor.fetchone()[0]
print(f"\nCurrent inspections: {inspection_count}")

if inspection_count == 0:
    print("\n✅ Database is already clean - no inspections found")
    conn.close()
    exit(0)

# Confirm deletion
print(f"\n⚠️  This will DELETE ALL {inspection_count} inspections!")
print("    Users will NOT be deleted")
print("    This action CANNOT be undone")

response = input("\nType 'DELETE ALL' to confirm: ")

if response != 'DELETE ALL':
    print("\n❌ Cancelled - no data was deleted")
    conn.close()
    exit(0)

print("\n🗑️  Deleting all inspections...")

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
    
    # Show user count (should be unchanged)
    cursor.execute("SELECT COUNT(*) FROM users")
    user_count = cursor.fetchone()[0]
    print(f"✅ Users preserved: {user_count}")
    
    print("\n" + "=" * 60)
    print("DATABASE RESET COMPLETE")
    print("=" * 60)
    print("\n✅ All inspection data has been cleared")
    print("✅ User accounts are intact")
    print("✅ Ready for fresh inspections")
    
except Exception as e:
    conn.rollback()
    print(f"\n❌ Error: {e}")
    print("Database rolled back - no changes made")

finally:
    conn.close()
