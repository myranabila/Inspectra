import sqlite3
import os
from datetime import datetime

# Define database path
DB_FILE = 'inspectra.db'

def main():
    if not os.path.exists(DB_FILE):
        print(f"Error: {DB_FILE} not found.")
        return

    try:
        # Use timeout to avoid locking if server is running
        conn = sqlite3.connect(DB_FILE, timeout=10)
        cursor = conn.cursor()

        # 1. Find a valid inspector ID
        cursor.execute("SELECT id FROM users WHERE role='inspector' LIMIT 1")
        row = cursor.fetchone()
        if not row:
            print("Error: No inspector found. Please ensure users exist.")
            return
        inspector_id = row[0]

        # 2. Data to insert (Equipment Type, Defect, Quantity)
        # Using exact keywords that map to colors in the DefectFrequencyChart
        data = [
            ('Reactor', 'Corrosion', 3),       # Orange
            ('Reactor', 'Crack', 2),           # Red
            ('Storage Tank', 'Leakage', 3),    # Blue
            ('Storage Tank', 'Corrosion', 1),  # Orange
            ('Piping', 'Corrosion', 5),        # Orange
            ('Piping', 'Mechanical Damage', 2),# Purple
            ('Heat Exchanger', 'Corrosion', 2),# Orange
            ('Heat Exchanger', 'Other', 1),    # Grey
        ]

        print("Generating analytics sample data...")
        today = datetime.now().strftime('%Y-%m-%d')
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        count = 0
        for equipment, defect, qty in data:
            for i in range(qty):
                cursor.execute("""
                    INSERT INTO inspections (
                        title, equipment_type, status,
                        external_finding, weld_finding, internal_finding, thickness_finding,
                        completion_date, scheduled_date, inspector_id,
                        require_external, require_weld, require_internal, require_thickness,
                        created_at, updated_at, rejection_count
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    f"Analytics Data - {equipment} {i+1}",
                    equipment, 'completed', 
                    defect, 'Nil', 'Nil', 'Nil', # Inserting defect into 'external_finding' (mapped to defect_type)
                    today, today, inspector_id,
                    1, 0, 0, 0, # Scope
                    now, now, 0
                ))
                count += 1

        conn.commit()
        conn.close()
        print(f"Success! Inserted {count} completed inspections for analytics graph.")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
