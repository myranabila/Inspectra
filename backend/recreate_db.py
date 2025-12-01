"""
Recreate database tables including Messages and Reminders
"""
from db import engine
import models

print("Dropping all tables...")
models.Base.metadata.drop_all(bind=engine)

print("Creating all tables...")
models.Base.metadata.create_all(bind=engine)

print("✓ Database tables recreated successfully!")

# Verify
from sqlalchemy import inspect
inspector = inspect(engine)
tables = inspector.get_table_names()
print(f"\nTables created: {tables}")

if 'messages' in tables:
    cols = inspector.get_columns('messages')
    print(f"\nMessages table has {len(cols)} columns:")
    for col in cols:
        print(f"  - {col['name']}: {col['type']}")
