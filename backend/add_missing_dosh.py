import sqlite3
from datetime import datetime
import random

conn = sqlite3.connect('inspectra.db')
c = conn.cursor()

print("=" * 70)
print("ADDING DOSH NUMBERS TO INSPECTIONS")
print("=" * 70)

# Check current status
c.execute("""
    SELECT COUNT(*) as total,
           COUNT(CASE WHEN dosh_registration IS NULL OR dosh_registration = '' THEN 1 END) as missing
    FROM inspections
""")

total, missing = c.fetchone()

print(f"\nCurrent Status:")
print(f"  Total Inspections: {total}")
print(f"  Missing DOSH Numbers: {missing}")
print(f"  Already Have DOSH: {total - missing}")

if missing == 0:
    print("\n✅ All inspections already have DOSH numbers!")
    conn.close()
    exit(0)

# Get inspections without DOSH numbers
c.execute("""
    SELECT id, title, equipment_type 
    FROM inspections 
    WHERE dosh_registration IS NULL OR dosh_registration = ''
""")

inspections_to_update = c.fetchall()

print(f"\n📝 Adding DOSH numbers to {len(inspections_to_update)} inspections...")

year = datetime.now().year
updated_count = 0

for inspection_id, title, eq_type in inspections_to_update:
    # Generate unique DOSH number
    dosh_number = f"DOSH/{year}/{random.randint(10000, 99999)}"
    
    # Update the inspection
    c.execute("""
        UPDATE inspections 
        SET dosh_registration = ?,
            updated_at = ?
        WHERE id = ?
    """, (dosh_number, datetime.now(), inspection_id))
    
    updated_count += 1
    print(f"  ✓ Added {dosh_number} to: {title[:50]}")

conn.commit()

# Verify
c.execute("""
    SELECT COUNT(*) as total,
           COUNT(CASE WHEN dosh_registration IS NULL OR dosh_registration = '' THEN 1 END) as missing
    FROM inspections
""")

total, missing = c.fetchone()

print(f"\n" + "=" * 70)
print(f"✅ UPDATED {updated_count} INSPECTIONS")
print("=" * 70)
print(f"\nFinal Status:")
print(f"  Total Inspections: {total}")
print(f"  With DOSH Numbers: {total - missing}")
print(f"  Missing DOSH: {missing}")

if missing == 0:
    print("\n✅ SUCCESS! All inspections now have DOSH registration numbers!")
else:
    print(f"\n⚠️  WARNING: {missing} inspections still missing DOSH numbers")

# Show sample
print(f"\n" + "=" * 70)
print("SAMPLE DOSH NUMBERS")
print("=" * 70)

c.execute("""
    SELECT title, equipment_type, dosh_registration 
    FROM inspections 
    LIMIT 5
""")

for i, (title, eq_type, dosh) in enumerate(c.fetchall(), 1):
    print(f"\n{i}. {title[:45]}")
    print(f"   Equipment: {eq_type}")
    print(f"   DOSH: {dosh}")

conn.close()

print(f"\n" + "=" * 70)
print("✅ OPERATION COMPLETE!")
print("=" * 70)
