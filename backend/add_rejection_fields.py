"""
Database Migration: Add Rejection Fields to Inspections Table
Adds rejection_reason, rejection_feedback, rejection_count, last_rejected_at columns
Also adds 'revision_required' status to InspectionStatusEnum
"""

import sqlite3
from pathlib import Path

# Database path
DB_PATH = Path(__file__).parent / "inspectra.db"

def migrate():
    print("=" * 80)
    print("Database Migration: Add Rejection Fields")
    print("=" * 80)
    print(f"Database: {DB_PATH}\n")
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        # Check existing columns
        cursor.execute("PRAGMA table_info(inspections)")
        columns = [col[1] for col in cursor.fetchall()]
        
        # Add rejection_reason column
        if 'rejection_reason' not in columns:
            print("Adding 'rejection_reason' column...")
            cursor.execute("""
                ALTER TABLE inspections 
                ADD COLUMN rejection_reason VARCHAR(500)
            """)
            print("✓ rejection_reason column added")
        else:
            print("✓ rejection_reason column already exists")
        
        # Add rejection_feedback column
        if 'rejection_feedback' not in columns:
            print("Adding 'rejection_feedback' column...")
            cursor.execute("""
                ALTER TABLE inspections 
                ADD COLUMN rejection_feedback TEXT
            """)
            print("✓ rejection_feedback column added")
        else:
            print("✓ rejection_feedback column already exists")
        
        # Add rejection_count column
        if 'rejection_count' not in columns:
            print("Adding 'rejection_count' column...")
            cursor.execute("""
                ALTER TABLE inspections 
                ADD COLUMN rejection_count INTEGER DEFAULT 0 NOT NULL
            """)
            print("✓ rejection_count column added")
        else:
            print("✓ rejection_count column already exists")
        
        # Add last_rejected_at column
        if 'last_rejected_at' not in columns:
            print("Adding 'last_rejected_at' column...")
            cursor.execute("""
                ALTER TABLE inspections 
                ADD COLUMN last_rejected_at TIMESTAMP
            """)
            print("✓ last_rejected_at column added")
        else:
            print("✓ last_rejected_at column already exists")
        
        conn.commit()
        print("\n✅ Database migration completed successfully!")
        print("\nNote: The 'revision_required' status value is now available")
        print("in InspectionStatusEnum. Update existing records as needed.")
        
    except sqlite3.Error as e:
        print(f"\n❌ Error during migration: {e}")
        conn.rollback()
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()
