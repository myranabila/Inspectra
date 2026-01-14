
import sqlite3
import random

def enrich_exhibition_data():
    conn = sqlite3.connect('inspectra.db')
    cursor = conn.cursor()

    print("Enriching inspection data...")

    # Fetch all inspection IDs
    cursor.execute("SELECT id, title, equipment_type FROM inspections")
    inspections = cursor.fetchall()

    dosh_prefixes = ["PMT", "BTL", "KDR", "JHK"]
    
    manager_notes_templates = [
        "Please focus on the corrosion near the nozzle.",
        "Check for recent weld repairs.",
        "Verify nameplate data against previous records.",
        "Ensure all safety valves are accessible.",
        "Inspect for insulation damage.",
        "Standard periodical inspection required.",
        "Client has reported minor vibration, please investigate.",
        "Visual inspection only, no NDT required today."
    ]

    for insp_id, title, eq_type in inspections:
        # Generate random DOSH number
        dosh_num = f"{random.choice(dosh_prefixes)}/{random.randint(1000, 9999)}/{random.randint(10, 99)}"
        
        # Pick a random note
        note = random.choice(manager_notes_templates)
        
        # Update the record
        cursor.execute("""
            UPDATE inspections 
            SET dosh_registration = ?,
                notes = ?
            WHERE id = ?
        """, (dosh_num, note, insp_id))

    conn.commit()
    print(f"✅ Updated {len(inspections)} inspections with DOSH numbers and Manager Notes.")
    
    # Verify Content
    print("\nSample Task Data:")
    cursor.execute("SELECT id, title, status, inspector_id, dosh_registration, notes FROM inspections LIMIT 3")
    rows = cursor.fetchall()
    for row in rows:
        print(f"ID: {row[0]} | Title: {row[1]} | Status: {row[2]} | InspID: {row[3]}")
        print(f"   > DOSH: {row[4]}")
        print(f"   > Note: {row[5]}")
        print("-" * 40)

    conn.close()

if __name__ == "__main__":
    enrich_exhibition_data()
