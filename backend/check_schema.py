from sqlalchemy import inspect
from db import engine

inspector = inspect(engine)

print('Tables:', inspector.get_table_names())
print('\nMessages table exists:', 'messages' in inspector.get_table_names())

if 'messages' in inspector.get_table_names():
    cols = inspector.get_columns('messages')
    print('\nMessages table columns:')
    for col in cols:
        print(f'  {col["name"]}: {col["type"]} (nullable={col.get("nullable", "?")})')
