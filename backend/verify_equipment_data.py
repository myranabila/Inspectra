import sqlite3

conn = sqlite3.connect('inspectra.db')
c = conn.cursor()

print("=" * 70)
print("EQUIPMENT DATA VERIFICATION")
print("=" * 70)

# Check completeness
c.execute("""
    SELECT 
        COUNT(*) as total,
        COUNT(equipment_id) as has_tag,
        COUNT(equipment_type) as has_type,
        COUNT(location) as has_location
    FROM inspections
""")

total, has_tag, has_type, has_location = c.fetchone()

print(f"\n✅ DATA COMPLETENESS:")
print(f"   Total Inspections: {total}")
print(f"   With Equipment Tag: {has_tag}/{total}")
print(f"   With Equipment Type: {has_type}/{total}")
print(f"   With Location: {has_location}/{total}")

if total == has_tag == has_type == has_location:
    print(f"\n✅ PERFECT! All {total} inspections have complete data!")
else:
    print(f"\n⚠️  MISSING DATA DETECTED!")


# Verify location-specific equipment types
print("\n" + "=" * 70)
print("LOCATION-SPECIFIC EQUIPMENT TYPES")
print("=" * 70)

c.execute("""
    SELECT location, equipment_type, COUNT(*) as count
    FROM inspections
    GROUP BY location, equipment_type
    ORDER BY location, equipment_type
""")

current_location = None
for location, eq_type, count in c.fetchall():
    if location != current_location:
        print(f"\n📍 {location}:")
        current_location = location
    print(f"   • {eq_type:30} ({count} inspections)")

# Sample detailed records
print("\n" + "=" * 70)
print("SAMPLE INSPECTION DETAILS")
print("=" * 70)

c.execute("""
    SELECT title, equipment_type, equipment_id, location, dosh_registration
    FROM inspections
    LIMIT 5
""")

for i, (title, eq_type, eq_id, location, dosh) in enumerate(c.fetchall(), 1):
    print(f"\n{i}. {title}")
    print(f"   Equipment Type: {eq_type}")
    print(f"   Equipment Tag: {eq_id}")
    print(f"   Location: {location}")
    print(f"   DOSH: {dosh}")

conn.close()

print("\n" + "=" * 70)
print("✅ VERIFICATION COMPLETE!")
print("=" * 70)
