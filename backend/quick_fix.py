"""Quick fix - just recreate tables and test"""
from db import SessionLocal, engine
import models
from sqlalchemy import inspect

print("Recreating tables...")
models.Base.metadata.drop_all(bind=engine)
models.Base.metadata.create_all(bind=engine)

inspector = inspect(engine)
tables = inspector.get_table_names()
print(f"Tables: {tables}")

if 'messages' in tables:
    cols = [c['name'] for c in inspector.get_columns('messages')]
    print(f"Messages columns: {cols}")
    print("✓ Messages table created successfully!")
else:
    print("❌ Messages table missing!")
