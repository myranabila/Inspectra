import requests
import json

BASE_URL = "http://localhost:8000"

# Login as manager
login_resp = requests.post(f"{BASE_URL}/auth/login", json={"username": "irfan", "password": "irfan123"})
print(f"Login: {login_resp.status_code}")

if login_resp.status_code == 200:
    token = login_resp.json()['access_token']
    
    # Try to assign task with minimal data
    task = {
        "inspector_id": 4,  # abu's ID
        "title": "Test Task",
        "inspection_type": "Pressure Vessel",
        "equipment_tag": "PV-001",
        "location": "Process Area",
        "due_date": "2025-12-31",
        "require_external": True,
        "require_weld": False,
        "require_internal": False,
        "require_thickness": False
    }
    
    print(f"\nSending task: {json.dumps(task, indent=2)}")
    
    resp = requests.post(
        f"{BASE_URL}/manager/assign-task",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        json=task
    )
    
    print(f"\nResponse Status: {resp.status_code}")
    print(f"Response: {resp.text}")
