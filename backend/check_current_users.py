import sqlite3

# Connect to the database
conn = sqlite3.connect('inspectra.db')
cursor = conn.cursor()

# Get all users
cursor.execute("SELECT id, username, role, email FROM users")
users = cursor.fetchall()

print("Current users in database:")
print("-" * 60)
for user in users:
    print(f"ID: {user[0]}, Username: {user[1]}, Role: {user[2]}, Email: {user[3]}")

conn.close()
