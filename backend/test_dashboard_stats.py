
import requests
import json
from datetime import datetime

# Base URL
BASE_URL = "http://localhost:8000"

print("=" * 60)
print("TESTING DASHBOARD STATS FILTERING")
print("=" * 60)

# Step 1: Login as Manager (irfan)
print("\n[STEP 1] Logging in as Manager (irfan)...")
try:
    login_response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"username": "irfan", "password": "irfan123"}
    )
    if login_response.status_code == 200:
        manager_token = login_response.json().get("access_token")
        print(f"✓ Manager Token: {manager_token[:20]}...")
    else:
        print(f"✗ Login Failed: {login_response.text}")
        print("Note: If 'irfan' doesn't exist, this test will fail. Please run test_assign_workflow.py first to create the user if needed.")
        exit()
except Exception as e:
    print(f"Error connecting to server: {e}")
    exit()

# Step 2: Get Dashboard Stats for 'today'
print("\n[STEP 2] Fetching Dashboard Stats for 'today'...")
stats_response = requests.get(
    f"{BASE_URL}/dashboard/stats",
    params={"period": "today"},
    headers={"Authorization": f"Bearer {manager_token}"}
)

print(f"Stats API Status: {stats_response.status_code}")
if stats_response.status_code == 200:
    stats = stats_response.json()
    print("✓ Stats received:")
    print(json.dumps(stats, indent=2))
    
    # Check if counts are 0 as expected by the user (assuming no data for today)
    # The user said: "i expected that the overview of inspection's count will be all '0'"
    
    total = stats.get('total_inspections', -1)
    scheduled = stats.get('scheduled', -1)
    completed = stats.get('completed', -1)
    
    print(f"\nVerifying counts for TODAY ({datetime.now().date()}):")
    print(f"Total: {total}")
    print(f"Scheduled: {scheduled}")
    print(f"Completed: {completed}")
    
    if total == 0 and scheduled == 0 and completed == 0:
        print("\n✓ PASS: All counts are 0 as expected for today (assuming no tasks today).")
    else:
        print("\n! INFO: Counts are NOT 0. This might be correct if you truly have tasks today.")
        print("If you are sure there are no tasks today, then something is still wrong.")

else:
    print(f"✗ Failed to fetch stats: {stats_response.text}")

print("\n" + "=" * 60)
print("TEST COMPLETE")
print("=" * 60)
