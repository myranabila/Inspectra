"""
Create proper exhibition tasks using the Manager API workflow.
This ensures tasks are created exactly as a manager would create them.
"""
import requests
import random
from datetime import datetime, timedelta

# Backend API configuration
BASE_URL = "http://127.0.0.1:8000"

# Login as manager to get authentication token
def get_manager_token():
    response = requests.post(f"{BASE_URL}/auth/login", json={
        "username": "irfan",
        "password": "irfan123"  # Password format is username123
    })
    if response.status_code == 200:
        return response.json()["access_token"]
    else:
        raise Exception(f"Login failed: {response.text}")

# Get list of inspectors
def get_inspectors(token):
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/manager/inspectors", headers=headers)
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"Failed to get inspectors: {response.text}")

# Assign a task using the proper API
def assign_task(token, task_data):
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.post(f"{BASE_URL}/manager/assign-task", 
                            headers=headers, 
                            json=task_data)
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"Failed to assign task: {response.text}")

def create_tasks():
    print("=" * 60)
    print("CREATING PROPER EXHIBITION TASKS")
    print("=" * 60)
    
    # Login as manager
    print("\n[1/3] Logging in as manager...")
    token = get_manager_token()
    print("✅ Manager authenticated")
    
    # Get inspectors
    print("\n[2/3] Fetching inspectors...")
    inspectors = get_inspectors(token)
    
    # Find Adam, Ali, Abu
    inspector_map = {insp['username']: insp['id'] for insp in inspectors}
    adam_id = inspector_map['adam']
    ali_id = inspector_map['ali']
    abu_id = inspector_map['abu']
    print(f"✅ Found inspectors: Adam ({adam_id}), Ali ({ali_id}), Abu ({abu_id})")
    
    # VALID equipment types from the system (DoshConfig.dart / models.py)
    equipment_types = [
        "Reactor",
        "Pressure Vessel", 
        "Heat Exchanger",
        "Storage Tank",
        "Tower"
    ]
    
    # VALID locations from the system (assign_task_page.dart)
    locations = [
        "Process Area",
        "Utility Area",
        "Main Deck",
        "Wellhead Area",
        "Offsite Facilities"
    ]
    
    # Equipment by location mapping (from assign_task_page.dart)
    equipment_by_location = {
        'Process Area': ['Pressure Vessel', 'Reactor', 'Heat Exchanger'],
        'Utility Area': ['Pressure Vessel'],
        'Main Deck': ['Pressure Vessel'],
        'Wellhead Area': ['Pressure Vessel'],
        'Offsite Facilities': ['Pressure Vessel'],
    }
    
    dosh_prefixes = ["PMT", "BTL", "KDR", "JHK"]
    
    notes_templates = [
        "Please focus on corrosion near the nozzle.",
        "Check for recent weld repairs.",
        "Verify nameplate data against previous records.",
        "Ensure all safety valves are accessible.",
        "Inspect for insulation damage.",
        "Standard periodical inspection required.",
        "Client reported minor vibration, investigate thoroughly.",
        "Visual inspection only, no NDT required."
    ]
    
    # Distribution: Adam (16), Ali (10), Abu (4)
    assignments = [
        (adam_id, 16, "Adam"),
        (ali_id, 10, "Ali"),
        (abu_id, 4, "Abu")
    ]
    
    print("\n[3/3] Creating tasks...")
    current_date = datetime.now()
    total_created = 0
    
    for inspector_id, count, name in assignments:
        for i in range(count):
            # Randomize location first
            location = random.choice(locations)
            
            # Pick equipment type that is valid for this location
            valid_types = equipment_by_location.get(location, ['Pressure Vessel'])
            eq_type = random.choice(valid_types)
            
            # Generate proper equipment tag based on type
            type_prefix = {
                'Reactor': 'R',
                'Pressure Vessel': 'V',
                'Heat Exchanger': 'E',
                'Storage Tank': 'T',
                'Tower': 'C'
            }.get(eq_type, 'V')
            
            tag_num = f"{type_prefix}-{random.randint(100, 999)}"
            title = f"{eq_type} Inspection - {tag_num}"
            dosh_num = f"{random.choice(dosh_prefixes)}/{random.randint(1000, 9999)}/{random.randint(10, 99)}"
            note = random.choice(notes_templates)
            
            # Date distribution
            rand_val = random.random()
            if rand_val < 0.2:
                days_offset = random.randint(-7, -1)  # Overdue
            elif rand_val < 0.4:
                days_offset = 0  # Today
            elif rand_val < 0.7:
                days_offset = random.randint(1, 5)  # This week
            else:
                days_offset = random.randint(6, 14)  # Later
                
            due_date = (current_date + timedelta(days=days_offset)).strftime('%Y-%m-%d')
            
            # Randomize scope
            require_external = True  # Always required
            require_weld = random.choice([True, False])
            require_internal = random.choice([True, False])
            require_thickness = False  # Deprecated
            
            # Create task via API
            task_data = {
                "inspector_id": inspector_id,
                "title": title,
                "inspection_type": eq_type,
                "location": location,
                "equipment_tag": tag_num,
                "dosh_registration": dosh_num,
                "due_date": due_date,
                "require_external": require_external,
                "require_weld": require_weld,
                "require_internal": require_internal,
                "require_thickness": require_thickness,
                "notes": note
            }
            
            try:
                result = assign_task(token, task_data)
                total_created += 1
                print(f"  ✅ Task #{total_created}: {result['inspection_id_display']} → {name}")
            except Exception as e:
                print(f"  ❌ Failed to create task for {name}: {e}")
    
    print("\n" + "=" * 60)
    print(f"✅ SUCCESSFULLY CREATED {total_created} TASKS")
    print("=" * 60)
    print("\nDistribution:")
    print(f"  • Adam: 16 tasks")
    print(f"  • Ali: 10 tasks")
    print(f"  • Abu: 4 tasks")
    print("\nAll tasks are now visible in:")
    print("  • Manager Dashboard (All Tasks)")
    print("  • Inspector 'My Tasks' (Pending)")

if __name__ == "__main__":
    create_tasks()
