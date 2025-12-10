from db import SessionLocal
from models import Inspection, User

db = SessionLocal()
try:
    inspections = db.query(Inspection).all()
    print(f'\nTotal inspections in database: {len(inspections)}')
    print('\nLast 5 inspections:')
    for i in inspections[-5:]:
        print(f'  ID: {i.id}, Title: {i.title}, Inspector ID: {i.inspector_id}, Status: {i.status.value}')
    
    print('\nAll users:')
    users = db.query(User).all()
    for u in users:
        print(f'  ID: {u.id}, Username: {u.username}, Role: {u.role.value}')
finally:
    db.close()
