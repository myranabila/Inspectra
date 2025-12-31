"""
Direct test of assign_task function to see the actual error
"""
import sys
sys.path.insert(0, 'c:\\workshop2\\Inspectra\\backend')

from db import SessionLocal
from manager import AssignTaskRequest, assign_task
from datetime import datetime

db = SessionLocal()

try:
    request = AssignTaskRequest(
        inspector_id=4,
        title="Test Task",
        inspection_type="Pressure Vessel",
        equipment_tag="PV-001",
        location="Process Area",
        due_date="2025-12-31",
        require_external=True,
        require_weld=False,
        require_internal=False,
        require_thickness=False
    )
    
    print("Calling assign_task...")
    result = assign_task(request, db)
    print(f"Success! Result: {result}")
    
except Exception as e:
    print(f"\n❌ ERROR: {type(e).__name__}: {str(e)}")
    import traceback
    print("\nFull traceback:")
    traceback.print_exc()
    
finally:
    db.close()
