import sqlite3

conn = sqlite3.connect('inspectra.db')
cursor = conn.cursor()

# Get table schema
cursor.execute("PRAGMA table_info(inspections)")
columns = cursor.fetchall()

print("Inspections table schema:")
print("-" * 80)
for col in columns:
    print(f"{col[1]:30} {col[2]:15} NULL={not col[3]} DEFAULT={col[4]}")

conn.close()
