import sqlite3

conn = sqlite3.connect('inspectra.db')
cursor = conn.cursor()

# Get table schema
cursor.execute("PRAGMA table_info(inspections)")
columns = cursor.fetchall()

print("Inspections table has", len(columns), "columns:")
print("="  * 80)
for col in columns:
    col_id, name, type_, notnull, default, pk = col
    print(f"{name:35} {type_:20} PK={pk} NOT_NULL={notnull}")

# Check if inspection_id_display exists
has_inspection_id_display = any(col[1] == 'inspection_id_display' for col in columns)
has_report_number = any(col[1] == 'report_number' for col in columns)

print("\n" + "=" * 80)
print(f"Has 'inspection_id_display': {has_inspection_id_display}")
print(f"Has 'report_number': {has_report_number}")

conn.close()
