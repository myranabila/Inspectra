"""
Comprehensive Database Fix Script
This script will:
1. Backup existing database
2. Recreate all tables with proper schema
3. Restore user data
4. Create sample data
5. Verify messaging functionality
"""
import os
import shutil
from datetime import datetime, timedelta, date
import random

from db import SessionLocal, engine
import models
from sqlalchemy import inspect

print("=" * 70)
print("DATABASE FIX SCRIPT")
print("=" * 70)

# Step 1: Backup existing database
print("\n[Step 1] Backing up existing database...")
if os.path.exists('inspectra.db'):
    backup_name = f'inspectra_backup_{datetime.now().strftime("%Y%m%d_%H%M%S")}.db'
    shutil.copy('inspectra.db', backup_name)
    print(f"✓ Database backed up to: {backup_name}")
else:
    print("  No existing database found - will create new one")

# Step 2: Get existing users before recreating
print("\n[Step 2] Saving existing user data...")
db = SessionLocal()
existing_users = []
try:
    users = db.query(models.User).all()
    for user in users:
        existing_users.append({
            'username': user.username,
            'password_hash': user.password_hash,
            'full_name': user.full_name,
            'email': user.email,
            'role': user.role,
            'phone': user.phone
        })
    print(f"✓ Saved {len(existing_users)} users")
except Exception as e:
    print(f"  Could not read existing users: {e}")
finally:
    db.close()

# Step 3: Drop and recreate all tables
print("\n[Step 3] Recreating database schema...")
models.Base.metadata.drop_all(bind=engine)
print("  ✓ Dropped all tables")

models.Base.metadata.create_all(bind=engine)
print("  ✓ Created all tables")

# Verify tables
inspector = inspect(engine)
tables = inspector.get_table_names()
print(f"  ✓ Tables created: {', '.join(tables)}")

# Check messages table specifically
if 'messages' in tables:
    cols = [col['name'] for col in inspector.get_columns('messages')]
    print(f"  ✓ Messages table columns: {', '.join(cols)}")

# Step 4: Restore users
print("\n[Step 4] Restoring users...")
db = SessionLocal()
user_map = {}  # old username -> new user object

try:
    if existing_users:
        for user_data in existing_users:
            new_user = models.User(
                username=user_data['username'],
                password_hash=user_data['password_hash'],
                full_name=user_data['full_name'],
                email=user_data['email'],
                role=user_data['role'],
                phone=user_data['phone']
            )
            db.add(new_user)
            db.flush()
            user_map[user_data['username']] = new_user
        
        db.commit()
        print(f"✓ Restored {len(existing_users)} users")
    else:
        # Create default users if none exist
        print("  No users found - creating default users...")
        
        # Use argon2 for password hashing
        from argon2 import PasswordHasher
        ph = PasswordHasher()
        
        default_users = [
            {
                'username': 'manager',
                'password_hash': ph.hash('manager123'),
                'full_name': 'System Manager',
                'email': 'manager@inspectra.com',
                'role': models.RoleEnum.manager,
                'phone': '0123456789'
            },
            {
                'username': 'adam',
                'password_hash': ph.hash('adam123'),
                'full_name': 'adam khasim',
                'email': 'adam@inspectra.com',
                'role': models.RoleEnum.inspector,
                'phone': '0123456780'
            },
            {
                'username': 'ali',
                'password_hash': ph.hash('ali123'),
                'full_name': 'ali abu',
                'email': 'ali@inspectra.com',
                'role': models.RoleEnum.inspector,
                'phone': '0123456781'
            },
            {
                'username': 'abu',
                'password_hash': ph.hash('abu123'),
                'full_name': 'abuabu',
                'email': 'abu@inspectra.com',
                'role': models.RoleEnum.inspector,
                'phone': '0123456782'
            }
        ]
        
        for user_data in default_users:
            new_user = models.User(**user_data)
            db.add(new_user)
            db.flush()
            user_map[user_data['username']] = new_user
        
        db.commit()
        print(f"✓ Created {len(default_users)} default users")
        
except Exception as e:
    db.rollback()
    print(f"❌ Error restoring users: {e}")
    raise

# Step 5: Create sample inspections and reports
print("\n[Step 5] Creating sample data...")

inspection_titles = [
    "Building A Inspection", "Office Safety Audit", "Electrical Inspection",
    "Fire Safety Check", "HVAC System Review", "Plumbing Inspection",
    "Structural Assessment", "Security System Audit", "Rooftop Safety Inspection",
    "Emergency Exit Verification"
]

locations = [
    "Main Building - Floor 1", "Office Complex - Tower A", "Warehouse District",
    "Factory Floor B", "Server Room - Level 3", "Parking Garage", 
    "Building C - Basement", "Retail Area", "Storage Facility"
]

try:
    # Get inspectors
    inspectors = [u for u in user_map.values() if u.role == models.RoleEnum.inspector]
    
    if not inspectors:
        inspectors = db.query(models.User).filter(
            models.User.role == models.RoleEnum.inspector
        ).all()
    
    if inspectors:
        # Create inspections
        today = date.today()
        statuses = list(models.InspectionStatusEnum)
        
        for i in range(30):
            status = random.choice(statuses)
            scheduled = today - timedelta(days=random.randint(0, 60))
            
            inspection = models.Inspection(
                title=random.choice(inspection_titles),
                location=random.choice(locations),
                status=status,
                scheduled_date=scheduled,
                completion_date=scheduled + timedelta(days=random.randint(1, 7)) if status == models.InspectionStatusEnum.completed else None,
                notes=f"Inspection notes for {random.choice(inspection_titles).lower()}",
                inspector_id=random.choice(inspectors).id
            )
            db.add(inspection)
        
        db.commit()
        
        inspection_count = db.query(models.Inspection).count()
        print(f"✓ Created {inspection_count} inspections")
        
        # Create some reports
        inspections = db.query(models.Inspection).limit(15).all()
        for inspection in inspections:
            report = models.Report(
                title=f"Report for {inspection.title}",
                inspection_id=inspection.id,
                status=random.choice(list(models.ReportStatusEnum)),
                content=f"Detailed findings for {inspection.title}",
                findings="Sample findings and observations",
                recommendations="Recommended actions and improvements",
                created_by=inspection.inspector_id
            )
            db.add(report)
        
        db.commit()
        report_count = db.query(models.Report).count()
        print(f"✓ Created {report_count} reports")
    
except Exception as e:
    db.rollback()
    print(f"❌ Error creating sample data: {e}")

# Step 6: Test messaging functionality
print("\n[Step 6] Testing messaging functionality...")

try:
    users = db.query(models.User).all()
    if len(users) >= 2:
        sender = users[0]
        receiver = users[1]
        
        # Create test message
        test_message = models.Message(
            sender_id=sender.id,
            receiver_id=receiver.id,
            subject="Database Migration Test",
            content="This is a test message to verify the messaging system works after database migration.",
            status=models.MessageStatusEnum.unread
        )
        
        db.add(test_message)
        db.commit()
        db.refresh(test_message)
        
        print(f"✓ Test message created (ID: {test_message.id})")
        print(f"  From: {sender.full_name} ({sender.username})")
        print(f"  To: {receiver.full_name} ({receiver.username})")
        
        # Verify we can read it back
        msg = db.query(models.Message).filter(
            models.Message.id == test_message.id
        ).first()
        
        if msg:
            print(f"✓ Message verified: '{msg.subject}'")
        
        # Test reminder
        inspections = db.query(models.Inspection).first()
        if inspections:
            test_reminder = models.Reminder(
                inspection_id=inspections.id,
                user_id=receiver.id,
                title="Test Reminder",
                message="This is a test reminder",
                remind_at=datetime.now() + timedelta(hours=1),
                status=models.ReminderStatusEnum.pending
            )
            db.add(test_reminder)
            db.commit()
            print(f"✓ Test reminder created (ID: {test_reminder.id})")
        
except Exception as e:
    db.rollback()
    print(f"❌ Error testing messaging: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()

# Step 7: Final verification
print("\n[Step 7] Final verification...")
db = SessionLocal()

try:
    user_count = db.query(models.User).count()
    inspection_count = db.query(models.Inspection).count()
    report_count = db.query(models.Report).count()
    message_count = db.query(models.Message).count()
    reminder_count = db.query(models.Reminder).count()
    
    print(f"\n{'=' * 70}")
    print("DATABASE SUMMARY")
    print(f"{'=' * 70}")
    print(f"Users:       {user_count}")
    print(f"Inspections: {inspection_count}")
    print(f"Reports:     {report_count}")
    print(f"Messages:    {message_count}")
    print(f"Reminders:   {reminder_count}")
    print(f"{'=' * 70}")
    
    print("\n✅ DATABASE FIX COMPLETED SUCCESSFULLY!")
    print("\nYou can now:")
    print("  1. Start backend: python -m uvicorn main:app --reload --port 8000")
    print("  2. Run Flutter app: flutter run -d chrome")
    print("  3. Test messaging between users")
    
except Exception as e:
    print(f"❌ Verification error: {e}")
finally:
    db.close()
