"""
Simple test to check messaging database issue
"""
from db import SessionLocal, engine
import models
from sqlalchemy import inspect

print("=" * 60)
print("DATABASE CHECK")
print("=" * 60)

# Create tables
print("\n1. Creating all tables...")
models.Base.metadata.create_all(bind=engine)
print("✓ Tables created")

# Check schema
inspector = inspect(engine)
tables = inspector.get_table_names()
print(f"\n2. Tables in database: {tables}")

# Check messages table
if 'messages' in tables:
    cols = [col['name'] for col in inspector.get_columns('messages')]
    print(f"\n3. Messages table columns: {cols}")
else:
    print("\n3. ❌ Messages table NOT FOUND!")

# Try to insert a test message
db = SessionLocal()
try:
    # Get users
    users = db.query(models.User).all()
    print(f"\n4. Found {len(users)} users in database")
    
    if len(users) >= 2:
        sender = users[0]
        receiver = users[1]
        
        print(f"\n5. Creating test message from {sender.username} to {receiver.username}...")
        
        test_msg = models.Message(
            sender_id=sender.id,
            receiver_id=receiver.id,
            subject="Database Test",
            content="Testing message creation",
            status=models.MessageStatusEnum.unread
        )
        
        db.add(test_msg)
        db.commit()
        db.refresh(test_msg)
        
        print(f"✓ Message created with ID: {test_msg.id}")
        
        # Read it back
        msg = db.query(models.Message).filter(models.Message.id == test_msg.id).first()
        print(f"✓ Message retrieved: '{msg.subject}' from {msg.sender_id} to {msg.receiver_id}")
        
        print("\n" + "=" * 60)
        print("✓ DATABASE IS WORKING CORRECTLY!")
        print("=" * 60)
    else:
        print("❌ Not enough users in database")
        
except Exception as e:
    print(f"\n❌ ERROR: {type(e).__name__}: {str(e)}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
