"""
Migration script to add thread_id column to messages table
and populate existing messages with thread IDs
"""
import sqlite3
from pathlib import Path

def add_thread_id_column():
    db_path = Path(__file__).parent / "inspectra.db"
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Check if column already exists
        cursor.execute("PRAGMA table_info(messages)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'thread_id' not in columns:
            print("Adding thread_id column to messages table...")
            cursor.execute("""
                ALTER TABLE messages 
                ADD COLUMN thread_id VARCHAR(100)
            """)
            conn.commit()
            print("✓ Added thread_id column")
        else:
            print("✓ thread_id column already exists")
        
        # Populate thread_id for existing messages
        print("\nPopulating thread_id for existing messages...")
        
        # Get all messages
        cursor.execute("""
            SELECT id, inspection_id, sender_id, receiver_id 
            FROM messages 
            WHERE thread_id IS NULL
        """)
        messages = cursor.fetchall()
        
        updated_count = 0
        for msg_id, inspection_id, sender_id, receiver_id in messages:
            # Generate thread_id
            user_ids = sorted([sender_id, receiver_id])
            if inspection_id:
                thread_id = f"inspection_{inspection_id}_user_{user_ids[0]}_{user_ids[1]}"
            else:
                thread_id = f"user_{user_ids[0]}_{user_ids[1]}"
            
            # Update message
            cursor.execute("""
                UPDATE messages 
                SET thread_id = ? 
                WHERE id = ?
            """, (thread_id, msg_id))
            updated_count += 1
        
        conn.commit()
        print(f"✓ Updated {updated_count} messages with thread_id")
        
        # Create index for better performance
        print("\nCreating index on thread_id...")
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_messages_thread_id 
            ON messages(thread_id)
        """)
        conn.commit()
        print("✓ Created index on thread_id")
        
        print("\n✅ Migration completed successfully!")
        
    except sqlite3.Error as e:
        print(f"❌ Error: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    add_thread_id_column()
