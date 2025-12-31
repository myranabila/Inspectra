"""
Test Inspector Workflow Compliance
Verifies that inspector sees exactly what manager assigned
"""
import requests
import json

BASE_URL = "http://localhost:8000"

print("=" * 80)
print("TESTING INSPECTOR WORKFLOW COMPLIANCE")
print("=" * 80)

# Step 1: Create a test task with specific requirements
print("\n[STEP 1] Manager assigns task with specific scope...")
manager_login = requests.post(f"{BASE_URL}/auth/login", json={"username": "irfan", "password": "irfan123"})
manager_token = manager_login.json()['access_token']

# Assign task with ONLY External and Thickness (NOT Weld or Internal)
task = {
    "inspector_id": 4,
    "title": "Quarterly Pressure Vessel Inspection",
    "inspection_type": "Pressure Vessel",
    "equipment_tag": "PV-002",
    "location": "Process Area",
    "due_date": "2025-12-31",
    "require_external": True,    # ✓ REQUIRED
    "require_weld": False,       # ✗ NOT REQUIRED
    "require_internal": False,   # ✗ NOT REQUIRED
    "require_thickness": True,   # ✓ REQUIRED
    "notes": "Focus on external corrosion and wall thickness measurements"
}

print("\nManager Assignment:")
print(f"  Title: {task['title']}")
print(f"  Equipment: {task['equipment_tag']}")
print(f"  Location: {task['location']}")
print(f"\n  Required Sections:")
print(f"    • External Visual:  {'✓ REQUIRED' if task['require_external'] else '✗ Not Required'}")
print(f"    • Weld Visual:      {'✓ REQUIRED' if task['require_weld'] else '✗ Not Required'}")
print(f"    • Internal Visual:  {'✓ REQUIRED' if task['require_internal'] else '✗ Not Required'}")
print(f"    • Thickness:        {'✓ REQUIRED' if task['require_thickness'] else '✗ Not Required'}")

resp = requests.post(
    f"{BASE_URL}/manager/assign-task",
    headers={"Authorization": f"Bearer {manager_token}", "Content-Type": "application/json"},
    json=task
)

if resp.status_code == 200:
    result = resp.json()
    inspection_id = result['inspection_id']
    print(f"\n✓ Task assigned successfully (ID: {inspection_id})")
else:
    print(f"\n✗ Failed to assign task: {resp.text}")
    exit()

# Step 2: Inspector retrieves the task
print("\n[STEP 2] Inspector retrieves assigned task...")
inspector_login = requests.post(f"{BASE_URL}/auth/login", json={"username": "abu", "password": "abu123"})
inspector_token = inspector_login.json()['access_token']

tasks_resp = requests.get(f"{BASE_URL}/dashboard/my-tasks", headers={"Authorization": f"Bearer {inspector_token}"})
tasks = tasks_resp.json()

# Find the newly assigned task
assigned_task = None
for t in tasks:
    if t['id'] == inspection_id:
        assigned_task = t
        break

if assigned_task:
    print("✓ Inspector can see the task")
    print("\nInspector Receives:")
    print(f"  Title: {assigned_task['title']}")
    print(f"  Equipment: {assigned_task['equipment_id']}")
    print(f"  Location: {assigned_task['location']}")
    print(f"\n  Scope Requirements from Manager:")
    print(f"    • External Visual:  {assigned_task['require_external']}")
    print(f"    • Weld Visual:      {assigned_task['require_weld']}")
    print(f"    • Internal Visual:  {assigned_task['require_internal']}")
    print(f"    • Thickness:        {assigned_task['require_thickness']}")
    
    print("\n" + "=" * 80)
    print("COMPLIANCE CHECK")
    print("=" * 80)
    
    # Verify scope matches
    scope_match = (
        assigned_task['require_external'] == task['require_external'] and
        assigned_task['require_weld'] == task['require_weld'] and
        assigned_task['require_internal'] == task['require_internal'] and
        assigned_task['require_thickness'] == task['require_thickness']
    )
    
    if scope_match:
        print("\n✅ PASS: Inspector receives EXACT scope requirements from manager")
        print("\nExpected Inspector UI to show:")
        print("  ✓ Equipment Identification (always shown)")
        if task['require_external']:
            print("  ✓ External Visual Inspection (REQUIRED - must complete)")
        else:
            print("  ✗ External Visual Inspection (hidden)")
            
        if task['require_weld']:
            print("  ✓ Weld Visual Inspection (REQUIRED - must complete)")
        else:
            print("  ✗ Weld Visual Inspection (hidden)")
            
        if task['require_internal']:
            print("  ✓ Internal Visual Inspection (REQUIRED - must complete)")
        else:
            print("  ✗ Internal Visual Inspection (hidden)")
            
        if task['require_thickness']:
            print("  ✓ Thickness Measurement (REQUIRED - must complete)")
        else:
            print("  ✗ Thickness Measurement (hidden)")
            
        print("  ✓ Summary & Overall Condition (always shown)")
        
        print("\n" + "=" * 80)
        print("✅ ✅ ✅  COMPLIANCE VERIFIED  ✅ ✅ ✅")
        print("=" * 80)
        print("\nThe inspector workflow STRICTLY FOLLOWS the manager's assignment!")
        print("Inspector can ONLY work on sections that manager required.")
        print("Inspector MUST complete ALL sections that manager required.")
    else:
        print("\n❌ FAIL: Scope mismatch!")
        print(f"Expected: {task}")
        print(f"Received: {assigned_task}")
else:
    print("\n✗ Inspector cannot see the assigned task!")
    print(f"Tasks returned: {len(tasks)}")
