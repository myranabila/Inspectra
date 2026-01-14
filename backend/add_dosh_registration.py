"""
Add dosh_registration column to inspections table
Run this migration to add DOSH registration field
"""

from db import get_db, engine
from sqlalchemy import text

def add_dosh_registration_column():
    """Add dosh_registration column to inspections table"""
    
    with engine.connect() as conn:
        # Check if column exists
        result = conn.execute(text("PRAGMA table_info(inspections)"))
        columns = [row[1] for row in result]
        
        if 'dosh_registration' not in columns:
            print("Adding dosh_registration column...")
            try:
                conn.execute(text("""
                    ALTER TABLE inspections 
                    ADD COLUMN dosh_registration VARCHAR(100)
                """))
                conn.commit()
                print("✅ Successfully added dosh_registration column")
            except Exception as e:
                print(f"❌ Error adding column: {e}")
        else:
            print("✅ dosh_registration column already exists")

if __name__ == "__main__":
    add_dosh_registration_column()
