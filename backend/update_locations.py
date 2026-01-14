import sqlite3
from datetime import datetime

conn = sqlite3.connect('inspectra.db')
c = conn.cursor()

print("=" * 70)
print("UPDATING LOCATIONS TO MATCH SPECIFICATION")
print("=" * 70)

# 1. Deactivate all existing locations
c.execute("UPDATE locations SET is_active = 0")
print("\n✓ Deactivated all existing locations")

# 2. Define the correct locations
correct_locations = [
    ("Process Area", "Main process equipment area"),
    ("Utility Area", "Utility and support systems area"),
    ("Main Deck", "Main deck platform area"),
    ("Wellhead Area", "Wellhead and drilling area"),
    ("Offsite Facilities", "Offsite support facilities")
]

# 3. Insert or update these locations
for name, description in correct_locations:
    # Check if exists
    c.execute("SELECT id FROM locations WHERE name = ?", (name,))
    existing = c.fetchone()
    
    if existing:
        # Update and reactivate
        c.execute("""
            UPDATE locations 
            SET description = ?, is_active = 1, updated_at = ? 
            WHERE name = ?
        """, (description, datetime.now(), name))
        print(f"✓ Reactivated: {name}")
    else:
        # Insert new
        c.execute("""
            INSERT INTO locations (name, description, is_active, created_at, updated_at)
            VALUES (?, ?, 1, ?, ?)
        """, (name, description, datetime.now(), datetime.now()))
        print(f"✓ Added: {name}")

conn.commit()

# 4. Verify
print("\n" + "=" * 70)
print("ACTIVE LOCATIONS IN SYSTEM")
print("=" * 70)

c.execute("SELECT name, description FROM locations WHERE is_active = 1 ORDER BY name")
active_locations = c.fetchall()

for i, (name, desc) in enumerate(active_locations, 1):
    print(f"{i}. {name}")
    print(f"   └─ {desc}")

print(f"\n✓ Total active locations: {len(active_locations)}")

conn.close()

print("\n" + "=" * 70)
print("✅ LOCATIONS UPDATED SUCCESSFULLY!")
print("=" * 70)
