from db import SessionLocal
import models

db = SessionLocal()
users = db.query(models.User).all()

print("\nUsers in database:")
for u in users:
    print(f"  Username: {u.username}, Role: {u.role}, ID: {u.id}")
    print(f"  Password hash: {u.password_hash[:50]}...")

db.close()
