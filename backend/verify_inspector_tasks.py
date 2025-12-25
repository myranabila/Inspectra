"""
Final verification - Check if inspector can see assigned tasks
"""
import requests

BASE_URL = "http://localhost:8000"

# Login as inspector (abu)
print("Testing Inspector Dashboard...")
print("=" * 60)

login = requests.post(f"{BASE_URL}/auth/login", json={"username": "abu", "password": "abu123"})
if login.status_code == 200:
    token = login.json()['access_token']
    print("✓ Inspector logged in successfully")
    
    # Get tasks
    tasks = requests.get(f"{BASE_URL}/dashboard/my-tasks", headers={"Authorization": f"Bearer {token}"})
    
    if tasks.status_code == 200:
        task_list = tasks.json()
        print(f"\n✓ Inspector has {len(task_list)} task(s):\n")
        
        for task in task_list:
            print(f"Task ID: {task.get('id')}")
            print(f"  Title: {task.get('title')}")
            print(f"  Location: {task.get('location')}")
            print(f"  Equipment: {task.get('equipment_id')} ({task.get('equipment_type')})")
            print(f"  Status: {task.get('status')}")
            print(f"  Scheduled: {task.get('scheduled_date')}")
            print(f"  Scope Requirements:")
            print(f"    - External Visual: {task.get('require_external')}")
            print(f"    - Weld Visual: {task.get('require_weld')}")
            print(f"    - Internal Visual: {task.get('require_internal')}")
            print(f"    - Thickness: {task.get('require_thickness')}")
            print()
        
        if len(task_list) > 0:
            print("=" * 60)
            print("✓✓✓ SUCCESS! Task assignment workflow is working!")
            print("=" * 60)
        else:
            print("⚠ No tasks found for inspector")
    else:
        print(f"✗ Failed to get tasks: {tasks.text}")
else:
    print(f"✗ Login failed: {login.text}")
