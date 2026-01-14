import sqlite3

conn = sqlite3.connect('inspectra.db')
c = conn.cursor()

print("=" * 70)
print("VERIFYING SPECIFIC INSPECTION")
print("=" * 70)

title_query = "Skid-mounted Inspection - SKD-376-A"
c.execute("SELECT * FROM inspections WHERE title = ?", (title_query,))
row = c.fetchone()

if row:
    # Get column names
    col_names = [description[0] for description in c.description]
    data = dict(zip(col_names, row))
    
    print(f"\nFOUND INSPECTION: {title_query}")
    print("-" * 30)
    print(f"ID: {data.get('id')}")
    print(f"Equipment ID: '{data.get('equipment_id')}'")
    print(f"Equipment Type: '{data.get('equipment_type')}'")
    print(f"Location: '{data.get('location')}'")
    print(f"DOSH Registration: '{data.get('dosh_registration')}'")
    
    if not data.get('equipment_id'):
        print("\n❌ Equipment ID is missing in DB!")
    if not data.get('equipment_type'):
        print("\n❌ Equipment Type is missing in DB!")
    if not data.get('dosh_registration'):
        print("\n❌ DOSH Registration is missing in DB!")
else:
    print(f"\n❌ Inspection '{title_query}' NOT FOUND in database!")

conn.close()
