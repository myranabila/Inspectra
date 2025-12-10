"""
Migration script to update inspection statuses from old values to new values.
This updates:
- in_progress -> scheduled
- revision_required -> rejected
"""

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import sys

# Database configuration
DATABASE_URL = "sqlite:///./inspectra.db"

def migrate_statuses():
    """Migrate old status values to new values"""
    engine = create_engine(DATABASE_URL)
    Session = sessionmaker(bind=engine)
    session = Session()
    
    try:
        # Update in_progress to scheduled
        result1 = session.execute(
            text("UPDATE inspections SET status = 'scheduled' WHERE status = 'in_progress'")
        )
        in_progress_count = result1.rowcount
        
        # Update revision_required to rejected
        result2 = session.execute(
            text("UPDATE inspections SET status = 'rejected' WHERE status = 'revision_required'")
        )
        revision_required_count = result2.rowcount
        
        session.commit()
        
        print(f"✅ Migration completed successfully!")
        print(f"   - Updated {in_progress_count} records from 'in_progress' to 'scheduled'")
        print(f"   - Updated {revision_required_count} records from 'revision_required' to 'rejected'")
        print(f"   - Total records migrated: {in_progress_count + revision_required_count}")
        
        # Show current status distribution
        result = session.execute(
            text("SELECT status, COUNT(*) as count FROM inspections GROUP BY status")
        )
        print("\n📊 Current status distribution:")
        for row in result:
            print(f"   - {row[0]}: {row[1]}")
            
    except Exception as e:
        session.rollback()
        print(f"❌ Migration failed: {str(e)}")
        sys.exit(1)
    finally:
        session.close()

if __name__ == "__main__":
    print("🔄 Starting status migration...")
    migrate_statuses()
