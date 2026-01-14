import sqlite3

conn = sqlite3.connect('inspectra.db')
c = conn.cursor()

# Count fields
c.execute('''SELECT 
    COUNT(*) as total,
    COUNT(dosh_registration) as has_dosh,
    COUNT(report_number) as has_report_num,
    COUNT(equipment_type) as has_eq_type,
    COUNT(equipment_id) as has_eq_id,
    COUNT(location) as has_location
FROM inspections''')

print("Field Verification:")
print("-" * 60)
result = c.fetchone()
print(f"Total Inspections: {result[0]}")
print(f"Have DOSH Registration: {result[1]}")
print(f"Have Report Number: {result[2]}")
print(f"Have Equipment Type: {result[3]}")
print(f"Have Equipment ID: {result[4]}")
print(f"Have Location: {result[5]}")

# Show sample data
print("\nSample Inspections:")
print("-" * 60)
c.execute('''SELECT 
    title, 
    dosh_registration, 
    report_number, 
    equipment_type, 
    equipment_id, 
    location 
FROM inspections LIMIT 3''')

for row in c.fetchall():
    print(f"\nTitle: {row[0]}")
    print(f"  DOSH: {row[1]}")
    print(f"  Report#: {row[2]}")
    print(f"  Equipment Type: {row[3]}")
    print(f"  Equipment ID: {row[4]}")
    print(f"  Location: {row[5]}")

conn.close()
