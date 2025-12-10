"""
Migration script to add equipment_id and equipment_type columns to inspections table
Run this script to update the database schema
"""

import sqlite3
import os

# Database path
DB_PATH = os.path.join(os.path.dirname(__file__), "inspectra.db")

def add_equipment_fields():
    """Add equipment_id and equipment_type columns to inspections table"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        # Check if columns already exist
        cursor.execute("PRAGMA table_info(inspections)")
        columns = [column[1] for column in cursor.fetchall()]
        
        # Add equipment_id if it doesn't exist
        if 'equipment_id' not in columns:
            print("Adding equipment_id column...")
            cursor.execute("""
                ALTER TABLE inspections 
                ADD COLUMN equipment_id VARCHAR(100)
            """)
            print("✓ equipment_id column added")
        else:
            print("✓ equipment_id column already exists")
        
        # Add equipment_type if it doesn't exist
        if 'equipment_type' not in columns:
            print("Adding equipment_type column...")
            cursor.execute("""
                ALTER TABLE inspections 
                ADD COLUMN equipment_type VARCHAR(200)
            """)
            print("✓ equipment_type column added")
        else:
            print("✓ equipment_type column already exists")
        
        conn.commit()
        print("\n✅ Database migration completed successfully!")
        
    except sqlite3.Error as e:
        print(f"❌ Database error: {e}")
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    print("=" * 60)
    print("Database Migration: Add Equipment Fields")
    print("=" * 60)
    print(f"Database: {DB_PATH}")
    print()
    
    add_equipment_fields()
