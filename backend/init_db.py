import sys
# Removed hardcoded path

from db import engine, Base
import models

print("Creating database tables...")
Base.metadata.create_all(bind=engine)
print("✓ All tables created successfully!")

# List all tables
from sqlalchemy import inspect
inspector = inspect(engine)
tables = inspector.get_table_names()
print(f"\nTables in database: {tables}")
