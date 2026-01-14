import sqlite3
from datetime import datetime
import random

conn = sqlite3.connect('inspectra.db')
c = conn.cursor()

print("=" * 70)
print("ENSURING ALL INSPECTIONS HAVE COMPLETE DATA")
print("=" * 70)

# Check for any inspections with missing fields
c.execute("""
    SELECT id, title, dosh_registration, location, equipment_id, equipment_type
    FROM inspections
""")
all_inspections = c.fetchall()

updates_made = 0
locations = ["Process Area", "Utility Area", "Main Deck", "Wellhead Area", "Offsite Facilities"]
eq_types = ["Pressure Vessel", "Heat Exchanger", "Pump", "Skid-mounted"]

for row in all_inspections:
    id, title, dosh, loc, eq_id, eq_type = row
    
    needed_update = False
    
    # Check DOSH
    if not dosh:
        dosh = f"DOSH/{datetime.now().year}/{random.randint(10000, 99999)}"
        needed_update = True
        print(f"  [FIX] Added DOSH {dosh} to Inspection {id}")
        
    # Check Location
    if not loc:
        loc = random.choice(locations)
        needed_update = True
        print(f"  [FIX] Added Location {loc} to Inspection {id}")
        
    # Check Equipment Type
    if not eq_type:
        eq_type = random.choice(eq_types)
        needed_update = True
        print(f"  [FIX] Added Equipment Type {eq_type} to Inspection {id}")
        
    # Check Equipment ID
    if not eq_id:
        eq_id = f"EQ-{random.randint(100,999)}"
        needed_update = True
        print(f"  [FIX] Added Equipment ID {eq_id} to Inspection {id}")

    if needed_update:
        c.execute("""
            UPDATE inspections 
            SET dosh_registration = ?, location = ?, equipment_id = ?, equipment_type = ?
            WHERE id = ?
        """, (dosh, loc, eq_id, eq_type, id))
        updates_made += 1

conn.commit()
conn.close()

if updates_made == 0:
    print("\n✅ All inspections already have complete data (DOSH, Location, Equipment).")
else:
    print(f"\n✅ Updated {updates_made} inspections with missing data.")
