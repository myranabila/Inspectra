import sqlite3

conn = sqlite3.connect('inspectra.db')
c = conn.cursor()

print("=" * 70)
print("LOCATION VALIDATION REPORT")
print("=" * 70)

# Get system locations
c.execute("SELECT name FROM locations WHERE is_active = 1 ORDER BY name")
system_locations = {row[0] for row in c.fetchall()}

print(f"\n✅ System Dropdown Locations ({len(system_locations)}):")
print("-" * 70)
for loc in sorted(system_locations):
    print(f"   • {loc}")

# Get inspection locations  
c.execute("SELECT DISTINCT location FROM inspections ORDER BY location")
inspection_locations = {row[0] for row in c.fetchall()}

print(f"\n✅ Locations Used in Inspections ({len(inspection_locations)}):")
print("-" * 70)
for loc in sorted(inspection_locations):
    in_system = "✓" if loc in system_locations else "✗"
    print(f"   {in_system} {loc}")

# Validation
print("\n" + "=" * 70)
print("VALIDATION RESULTS")
print("=" * 70)

if inspection_locations == system_locations:
    print("✅ PERFECT MATCH!")
    print("   All inspection locations match the system dropdown.")
elif inspection_locations.issubset(system_locations):
    print("✅ ALL VALID!")
    print("   All inspection locations are from the system dropdown.")
    print(f"   Using {len(inspection_locations)} out of {len(system_locations)} available locations.")
else:
    invalid = inspection_locations - system_locations
    print("⚠ WARNING!")
    print(f"   Found {len(invalid)} locations NOT in system dropdown:")
    for loc in invalid:
        print(f"   - {loc}")

# Sample inspections
print("\n" + "=" * 70)
print("SAMPLE INSPECTIONS")
print("=" * 70)
c.execute('''SELECT 
    title, equipment_type, equipment_id, location, dosh_registration, report_number 
FROM inspections LIMIT 3''')

for i, row in enumerate(c.fetchall(), 1):
    print(f"\n{i}. {row[0]}")
    print(f"   Equipment: {row[1]} ({row[2]})")
    print(f"   Location: {row[3]}")
    print(f"   DOSH: {row[4]}")
    print(f"   Report#: {row[5]}")

conn.close()
print("\n" + "=" * 70)
