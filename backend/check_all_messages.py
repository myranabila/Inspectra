"""
Check all messages in database
"""
from db import SessionLocal
import models

db = SessionLocal()

print("="*60)
print("ALL MESSAGES IN DATABASE")
print("="*60)

messages = db.query(models.Message).all()

if not messages:
    print("\nNo messages found in database!")
else:
    print(f"\nTotal messages: {len(messages)}\n")
    
    for msg in messages:
        sender = db.query(models.User).filter(models.User.id == msg.sender_id).first()
        receiver = db.query(models.User).filter(models.User.id == msg.receiver_id).first()
        
        print(f"Message ID: {msg.id}")
        print(f"  From: {sender.full_name if sender else 'Unknown'} (ID: {msg.sender_id})")
        print(f"  To: {receiver.full_name if receiver else 'Unknown'} (ID: {msg.receiver_id})")
        print(f"  Subject: {msg.subject or '(No subject)'}")
        print(f"  Content: {msg.content[:50]}...")
        print(f"  Status: {msg.status}")
        print(f"  Created: {msg.created_at}")
        print()

db.close()

# Also check users
print("="*60)
print("ALL USERS")
print("="*60)

db = SessionLocal()
users = db.query(models.User).all()

for user in users:
    print(f"ID: {user.id}, Username: {user.username}, Name: {user.full_name}, Role: {user.role}")

db.close()
