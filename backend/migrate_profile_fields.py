"""
Migration script to add profile management fields to users table
"""

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Database configuration
DATABASE_URL = "sqlite:///./inspectra.db"

def migrate_add_profile_fields():
    """Add new profile fields to users table"""
    engine = create_engine(DATABASE_URL)
    Session = sessionmaker(bind=engine)
    session = Session()
    
    try:
        print("🔄 Starting profile fields migration...")
        
        # Check if columns already exist
        result = session.execute(text("PRAGMA table_info(users)"))
        columns = [row[1] for row in result]
        
        migrations_needed = []
        
        # Add profile_picture column if it doesn't exist
        if 'profile_picture' not in columns:
            migrations_needed.append("ALTER TABLE users ADD COLUMN profile_picture VARCHAR(500)")
        
        # Add certification_number column if it doesn't exist
        if 'certification_number' not in columns:
            migrations_needed.append("ALTER TABLE users ADD COLUMN certification_number VARCHAR(100)")
        
        # Add years_experience column if it doesn't exist
        if 'years_experience' not in columns:
            migrations_needed.append("ALTER TABLE users ADD COLUMN years_experience INTEGER")
        
        # Add is_active column if it doesn't exist
        if 'is_active' not in columns:
            migrations_needed.append("ALTER TABLE users ADD COLUMN is_active INTEGER DEFAULT 1 NOT NULL")
        
        # Add updated_at column if it doesn't exist
        if 'updated_at' not in columns:
            migrations_needed.append("ALTER TABLE users ADD COLUMN updated_at TIMESTAMP")
        
        # Add last_password_change column if it doesn't exist
        if 'last_password_change' not in columns:
            migrations_needed.append("ALTER TABLE users ADD COLUMN last_password_change TIMESTAMP")
        
        if not migrations_needed:
            print("✅ All profile fields already exist. No migration needed.")
            return
        
        # Execute migrations
        for migration in migrations_needed:
            print(f"   Executing: {migration}")
            session.execute(text(migration))
        
        # Set default values for existing users
        if 'is_active' in [m.split()[5] for m in migrations_needed if 'is_active' in m]:
            session.execute(text("UPDATE users SET is_active = 1 WHERE is_active IS NULL"))
        
        session.commit()
        
        print(f"✅ Migration completed successfully!")
        print(f"   - Added {len(migrations_needed)} new fields to users table")
        
        # Show updated table structure
        result = session.execute(text("PRAGMA table_info(users)"))
        print("\n📊 Updated users table structure:")
        for row in result:
            print(f"   - {row[1]} ({row[2]})")
            
    except Exception as e:
        session.rollback()
        print(f"❌ Migration failed: {str(e)}")
        raise
    finally:
        session.close()

if __name__ == "__main__":
    migrate_add_profile_fields()
