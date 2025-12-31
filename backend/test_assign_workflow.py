import requests
import json
from datetime import datetime, timedelta

# Base URL
BASE_URL = "http://localhost:8000"

print("=" * 60)
print("TESTING TASK ASSIGNMENT WORKFLOW")
print("=" * 60)

# Step 1: Create manager user if doesn't exist
print("\n[STEP 1] Ensuring manager user exists...")
import sqlite3
from argon2 import PasswordHasher

conn = sqlite3.connect('inspectra.db')
cursor = conn.cursor()

# Check if irfan exists
cursor.execute("SELECT id FROM users WHERE username = 'irfan'")
if not cursor.fetchone():
    print("Creating manager user 'irfan'...")
    ph = PasswordHasher()
    cursor.execute("""
        INSERT INTO users (username, staff_id, password_hash, email, role, phone)
        VALUES (?, ?, ?, ?, ?, ?)
    """, ('irfan', 'STF10001', ph.hash('irfan123'), 'irfan@ipetro.com', 'manager', '0123451234'))
    conn.commit()
    print("✓ Manager user created")
else:
    print("✓ Manager user already exists")

conn.close()

# Step 2: Login as Manager (irfan)
print("\n[STEP 2] Logging in as Manager (irfan)...")
login_response = requests.post(
    f"{BASE_URL}/auth/login",
    json={"username": "irfan", "password": "irfan123"}
)
print(f"Login Status: {login_response.status_code}")
if login_response.status_code == 200:
    manager_token = login_response.json().get("access_token")
    print(f"✓ Manager Token: {manager_token[:20]}...")
else:
    print(f"✗ Login Failed: {login_response.text}")
    exit()

# Step 3: Get list of inspectors
print("\n[STEP 3] Fetching inspectors list...")
inspectors_response = requests.get(
    f"{BASE_URL}/manager/inspectors",
    headers={"Authorization": f"Bearer {manager_token}"}
)
print(f"Inspectors API Status: {inspectors_response.status_code}")
if inspectors_response.status_code == 200:
    inspectors = inspectors_response.json()
    print(f"✓ Found {len(inspectors)} inspectors")
    if inspectors:
        inspector = inspectors[0]
        inspector_id = inspector['id']
        inspector_name = inspector['username']
        print(f"  - Using inspector: {inspector_name} (ID: {inspector_id})")
    else:
        print("✗ No inspectors found!")
        exit()
else:
    print(f"✗ Failed to fetch inspectors: {inspectors_response.text}")
    exit()

# Step 4: Assign a task
print("\n[STEP 4] Assigning task to inspector...")
task_data = {
    "inspector_id": inspector_id,
    "title": "Test Pressure Vessel Inspection",
    "inspection_type": "Pressure Vessel",
    "equipment_tag": "PV-001",
    "location": "Process Area",
    "due_date": (datetime.now() + timedelta(days=7)).strftime("%Y-%m-%d"),
    "require_external": True,
    "require_weld": True,
    "require_internal": False,
    "require_thickness": True,
    "initial_conditions": "Good condition",
    "notes": "Test assignment from workflow verification"
}

print(f"Task Data:")
for key, value in task_data.items():
    print(f"  - {key}: {value}")

assign_response = requests.post(
    f"{BASE_URL}/manager/assign-task",
    headers={
        "Authorization": f"Bearer {manager_token}",
        "Content-Type": "application/json"
    },
    json=task_data
)

print(f"\nAssign Task API Status: {assign_response.status_code}")
if assign_response.status_code == 200:
    result = assign_response.json()
    print(f"✓ Task assigned successfully!")
    print(f"  - Inspection ID: {result.get('inspection_id')}")
    print(f"  - Inspector: {result.get('inspector')}")
    print(f"  - Status: {result.get('status')}")
    inspection_id = result.get('inspection_id')
else:
    print(f"✗ Task assignment failed!")
    print(f"Status Code: {assign_response.status_code}")
    print(f"Response Text: {assign_response.text}")
    try:
        print(f"Response JSON: {json.dumps(assign_response.json(), indent=2)}")
    except:
        pass
    exit()

# Step 5: Login as Inspector
print(f"\n[STEP 5] Logging in as Inspector ({inspector_name})...")
inspector_login_response = requests.post(
    f"{BASE_URL}/auth/login",
    json={"username": inspector_name, "password": f"{inspector_name}123"}
)
print(f"Inspector Login Status: {inspector_login_response.status_code}")
if inspector_login_response.status_code == 200:
    inspector_token = inspector_login_response.json().get("access_token")
    print(f"✓ Inspector Token: {inspector_token[:20]}...")
else:
    print(f"✗ Inspector Login Failed: {inspector_login_response.text}")
    exit()

# Step 6: Check if inspector can see the task
print(f"\n[STEP 6] Checking inspector's tasks...")
tasks_response = requests.get(
    f"{BASE_URL}/dashboard/my-tasks",
    headers={"Authorization": f"Bearer {inspector_token}"}
)
print(f"My Tasks API Status: {tasks_response.status_code}")
if tasks_response.status_code == 200:
    tasks = tasks_response.json()
    print(f"✓ Inspector has {len(tasks)} total tasks")
    
    # Find the newly assigned task
    new_task = None
    for task in tasks:
        if task.get('id') == inspection_id:
            new_task = task
            break
    
    if new_task:
        print(f"\n✓✓✓ SUCCESS! Inspector can see the assigned task!")
        print(f"Task Details:")
        print(f"  - ID: {new_task.get('id')}")
        print(f"  - Title: {new_task.get('title')}")
        print(f"  - Location: {new_task.get('location')}")
        print(f"  - Equipment: {new_task.get('equipment_id')} ({new_task.get('equipment_type')})")
        print(f"  - Status: {new_task.get('status')}")
        print(f"  - Scope Requirements:")
        print(f"    * External: {new_task.get('require_external')}")
        print(f"    * Weld: {new_task.get('require_weld')}")
        print(f"    * Internal: {new_task.get('require_internal')}")
        print(f"    * Thickness: {new_task.get('require_thickness')}")
    else:
        print(f"\n✗✗✗ PROBLEM: Inspector cannot see the newly assigned task!")
        print(f"Expected Inspection ID: {inspection_id}")
        print(f"Tasks returned: {len(tasks)}")
        if tasks:
            print(f"Task IDs in response: {[t.get('id') for t in tasks]}")
else:
    print(f"✗ Failed to fetch inspector's tasks: {tasks_response.text}")

print("\n" + "=" * 60)
print("WORKFLOW TEST COMPLETE")
print("=" * 60)
