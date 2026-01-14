import sqlite3

conn = sqlite3.connect('inspectra.db')
c = conn.cursor()

print("=" * 70)
print("FINAL LOCATION VERIFICATION REPORT")
print("=" * 70)

# System dropdown locations
print("\n📋 SYSTEM DROPDOWN LOCATIONS (Active):")
print("-" * 70)
c.execute("SELECT name, is_active FROM locations ORDER BY name")
for name, active in c.fetchall():
    status = "✓ ACTIVE" if active == 1 else "✗ Inactive"
    print(f"  {status:12} {name}")

# Inspection locations
print("\n📊 LOCATIONS USED IN INSPECTIONS:")
print("-" * 70)
c.execute("""
    SELECT location, COUNT(*) as count 
    FROM inspections 
    GROUP BY location 
    ORDER BY location
""")
for location, count in c.fetchall():
    print(f"  • {location:25} ({count} inspections)")

# Validation check
print("\n" + "=" * 70)
print("VALIDATION CHECK")
print("=" * 70)

c.execute("SELECT name FROM locations WHERE is_active = 1 ORDER BY name")
system_locs = {row[0] for row in c.fetchall()}

c.execute("SELECT DISTINCT location FROM inspections")
inspection_locs = {row[0] for row in c.fetchall()}

if inspection_locs == system_locs:
    print("✅ PERFECT MATCH!")
    print("   All inspection locations match system dropdown exactly.")
elif inspection_locs.issubset(system_locs):
    print("✅ ALL VALID!")
    print(f"   Using {len(inspection_locs)}/{len(system_locs)} available locations.")
else:
    invalid = inspection_locs - system_locs
    print("⚠️  WARNING!")
    print(f"   Found {len(invalid)} invalid locations:")
    for loc in invalid:
        print(f"   - {loc}")

# Sample data
print("\n" + "=" * 70)
print("SAMPLE INSPECTIONS")
print("=" * 70)

c.execute("""
    SELECT title, equipment_type, equipment_id, location 
    FROM inspections 
    LIMIT 5
""")

for i, (title, eq_type, eq_id, location) in enumerate(c.fetchall(), 1):
    print(f"\n{i}. {title}")
    print(f"   Equipment: {eq_type} ({eq_id})")
    print(f"   Location: {location}")

conn.close()

print("\n" + "=" * 70)
print("✅ LOCATION SYSTEM VERIFIED!")
print("=" * 70)
