"""
Add reply_to_id column to messages table
"""
from sqlalchemy import create_engine, text

engine = create_engine('sqlite:///inspectra.db')

with engine.connect() as conn:
    try:
        # Check if column exists
        result = conn.execute(text("PRAGMA table_info(messages)"))
        columns = [row[1] for row in result]
        
        if 'reply_to_id' not in columns:
            # Add the column
            conn.execute(text("ALTER TABLE messages ADD COLUMN reply_to_id INTEGER"))
            conn.commit()
            print("✓ Added reply_to_id column to messages table")
        else:
            print("✓ reply_to_id column already exists")
            
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
