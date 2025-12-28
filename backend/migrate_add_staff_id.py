"""
Database Migration Script
Adds staff_id column and migrates from certification_number to staff_id
"""

import sqlite3
import os

def migrate_add_staff_id():
    """Add staff_id column and populate it"""
    
    # Point to the root inspectra.db (up one level from backend/)
    db_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'inspectra.db'))
    
    if not os.path.exists(db_path):
        print(f"❌ Database not found at: {db_path}")
        return
    
    print("- Starting migration to add staff_id column...")
    print(f"- Database: {db_path}\n")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Check current structure
        cursor.execute("PRAGMA table_info(users)")
        columns = cursor.fetchall()
        column_names = [col[1] for col in columns]
        
        print("- Current columns:")
        for col in columns:
            print(f"   - {col[1]} ({col[2]})")
        print()
        
        # Check if staff_id already exists
        if 'staff_id' in column_names:
            print("- staff_id column already exists")
            return
        
        # Add staff_id column (nullable initially)
        print("- Adding staff_id column...")
        cursor.execute("""
            ALTER TABLE users 
            ADD COLUMN staff_id VARCHAR(20)
        """)
        
        # Get all users and generate staff IDs
        cursor.execute("SELECT id, role FROM users ORDER BY id")
        users = cursor.fetchall()
        
        print(f"- Generating Staff IDs for {len(users)} users...")
        
        staff_counter = 1
        for user_id, role in users:
            staff_id = f"S{staff_counter:03d}"
            staff_counter += 1
            cursor.execute(
                "UPDATE users SET staff_id = ? WHERE id = ?",
                (staff_id, user_id)
            )
            print(f"   - User ID {user_id} ({role}) -> {staff_id}")
        
        # Now recreate table to make staff_id NOT NULL and UNIQUE
        print("\n- Recreating table with staff_id as NOT NULL and UNIQUE...")
        cursor.execute("""
            CREATE TABLE users_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username VARCHAR(80) UNIQUE NOT NULL,
                staff_id VARCHAR(20) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                email VARCHAR(150),
                role VARCHAR(20) NOT NULL DEFAULT 'inspector',
                phone VARCHAR(30),
                profile_picture VARCHAR(500),
                years_experience INTEGER,
                is_active INTEGER NOT NULL DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_password_change TIMESTAMP
            )
        """)
        
        # Copy data
        cursor.execute("""
            INSERT INTO users_new 
            (id, username, staff_id, password_hash, email, role, phone, profile_picture, 
             years_experience, is_active, created_at, updated_at, last_password_change)
            SELECT 
                id, username, staff_id, password_hash, email, role, phone, profile_picture,
                years_experience, is_active, created_at, updated_at, last_password_change
            FROM users
        """)
        
        # Drop old table and rename
        cursor.execute("DROP TABLE users")
        cursor.execute("ALTER TABLE users_new RENAME TO users")
        
        # Recreate indexes
        cursor.execute("CREATE UNIQUE INDEX idx_users_username ON users(username)")
        cursor.execute("CREATE UNIQUE INDEX idx_users_staff_id ON users(staff_id)")
        
        conn.commit()
        
        print("\n- Migration completed successfully!")
        print(f"   - Added staff_id column")
        # print(f"   - Generated {mgr_counter-1} Manager Staff IDs") # These variables were undefined in original script
        # print(f"   - Generated {ins_counter-1} Inspector Staff IDs") # These variables were undefined in original script
        print(f"   - Removed certification_number column")
        print(f"   - Staff ID can now be used for login")
        
        # Show updated structure
        cursor.execute("PRAGMA table_info(users)")
        columns = cursor.fetchall()
        print("\n- Updated users table structure:")
        for col in columns:
            print(f"   - {col[1]} ({col[2]})")
        
    except Exception as e:
        conn.rollback()
        print(f"\n- Migration failed: {e}")
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    print("=" * 60)
    print("DATABASE MIGRATION: Add Staff ID System")
    print("=" * 60)
    print()
    
    migrate_add_staff_id()
