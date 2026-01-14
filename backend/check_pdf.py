import sqlite3

conn = sqlite3.connect('inspectra.db')
c = conn.cursor()

print("=" * 70)
print("VERIFYING PDF PATH")
print("=" * 70)

title_query = "Separator Inspection - SEP-638-C"
c.execute("SELECT id, title, status, pdf_report_path FROM inspections WHERE title = ?", (title_query,))
row = c.fetchone()

if row:
    print(f"ID: {row[0]}")
    print(f"Title: {row[1]}")
    print(f"Status: {row[2]}")
    print(f"PDF Path: '{row[3]}'")
else:
    print(f"❌ Inspection '{title_query}' NOT FOUND!")

conn.close()
