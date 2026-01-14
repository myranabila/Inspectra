import requests
import json

# Test the my-tasks endpoint
response = requests.get(
    "http://127.0.0.1:8000/dashboard/my-tasks",
    headers={"Authorization": "Bearer test"}  # This will fail auth but shows the endpoint structure
)

print("Status:", response.status_code)

# If it's an auth error, that's expected. But let's also check directly from database
import sqlite3

conn = sqlite3.connect('inspectra.db')
c = conn.cursor()

print("\nSample Inspection Data (First inspection):")
print("=" * 70)

c.execute('''SELECT 
    id, title, equipment_id, equipment_type, location, 
    dosh_registration, report_number, status
FROM inspections LIMIT 1''')

row = c.fetchone()
if row:
    print(f"ID: {row[0]}")
    print(f"Title: {row[1]}")
    print(f"Equipment ID: {row[2]}")
    print(f"Equipment Type: {row[3]}")
    print(f"Location: {row[4]}")
    print(f"DOSH Registration: {row[5]}")
    print(f"Report Number: {row[6]}")
    print(f"Status: {row[7]}")
else:
    print("No inspections found!")

conn.close()
