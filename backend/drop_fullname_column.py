"""
Database Migration Script
Drops the full_name column from users table
Run this after updating all code to use username instead of full_name
"""

import sqlite3
import os

def migrate_drop_fullname():
    """Drop full_name column from users table"""
    
    db_path = os.path.join(os.path.dirname(__file__), 'inspectra.db')
    
    if not os.path.exists(db_path):
        print(f"❌ Database not found at: {db_path}")
        return
    
    print("🔄 Starting migration to drop full_name column...")
    print(f"📁 Database: {db_path}\n")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Check if full_name column exists
        cursor.execute("PRAGMA table_info(users)")
        columns = cursor.fetchall()
        column_names = [col[1] for col in columns]
        
        if 'full_name' not in column_names:
            print("✅ full_name column does not exist - migration not needed")
            return
        
        print("📋 Current columns in users table:")
        for col in columns:
            print(f"   - {col[1]} ({col[2]})")
        print()
        
        # SQLite doesn't support DROP COLUMN directly for old versions
        # We need to:
        # 1. Create new table without full_name
        # 2. Copy data
        # 3. Drop old table
        # 4. Rename new table
        
        print("🔨 Creating new users table without full_name...")
        
        # Create new table structure (without full_name)
        cursor.execute("""
            CREATE TABLE users_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username VARCHAR(80) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                email VARCHAR(150),
                role VARCHAR(20) NOT NULL DEFAULT 'inspector',
                phone VARCHAR(30),
                profile_picture VARCHAR(500),
                certification_number VARCHAR(100),
                years_experience INTEGER,
                is_active INTEGER NOT NULL DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_password_change TIMESTAMP
            )
        """)
        
        print("📦 Copying data from old table to new table...")
        
        # Copy data (excluding full_name)
        cursor.execute("""
            INSERT INTO users_new 
            (id, username, password_hash, email, role, phone, profile_picture, 
             certification_number, years_experience, is_active, created_at, 
             updated_at, last_password_change)
            SELECT 
                id, username, password_hash, email, role, phone, profile_picture,
                certification_number, years_experience, is_active, created_at,
                updated_at, last_password_change
            FROM users
        """)
        
        rows_copied = cursor.rowcount
        print(f"✅ Copied {rows_copied} user records")
        
        print("🗑️  Dropping old users table...")
        cursor.execute("DROP TABLE users")
        
        print("✏️  Renaming new table to users...")
        cursor.execute("ALTER TABLE users_new RENAME TO users")
        
        # Recreate indexes
        print("🔧 Creating indexes...")
        cursor.execute("CREATE UNIQUE INDEX idx_users_username ON users(username)")
        
        conn.commit()
        
        print("\n✅ Migration completed successfully!")
        print(f"   - Removed full_name column from users table")
        print(f"   - All {rows_copied} user records migrated")
        print(f"   - System now uses username as the display name")
        
        # Show updated structure
        cursor.execute("PRAGMA table_info(users)")
        columns = cursor.fetchall()
        print("\n📋 Updated users table structure:")
        for col in columns:
            print(f"   - {col[1]} ({col[2]})")
        
    except Exception as e:
        conn.rollback()
        print(f"\n❌ Migration failed: {e}")
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    print("=" * 60)
    print("DATABASE MIGRATION: Drop full_name Column")
    print("=" * 60)
    print()
    
    response = input("⚠️  This will permanently remove the full_name column.\n   Continue? (yes/no): ")
    
    if response.lower() in ['yes', 'y']:
        migrate_drop_fullname()
    else:
        print("❌ Migration cancelled")
