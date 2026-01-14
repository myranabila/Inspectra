import requests
import json
from datetime import datetime

# Login as Adam
token = requests.post('http://127.0.0.1:8000/auth/login', json={
    'username': 'adam',
    'password': 'adam123'
}).json()['access_token']

# Get tasks
tasks = requests.get('http://127.0.0.1:8000/dashboard/my-tasks', 
                     headers={'Authorization': f'Bearer {token}'}).json()

print(f"Total tasks: {len(tasks)}\n")

# Filter like the frontend does
active_tasks = [t for t in tasks if t['status'] not in ['completed', 'pending_review']]
print(f"Active tasks (after filter): {len(active_tasks)}\n")

# Categorize by priority
now = datetime.now()
categories = {
    'OVERDUE': [],
    'URGENT': [],
    'SOON': [],
    'UPCOMING': []
}

for task in active_tasks:
    due_date_str = task.get('scheduled_date')
    if not due_date_str:
        continue
    
    due_date = datetime.fromisoformat(due_date_str)
    difference = due_date - now
    
    if difference.total_seconds() < 0:
        categories['OVERDUE'].append(task['title'])
    elif difference.total_seconds() < 24 * 3600:
        categories['URGENT'].append(task['title'])
    elif difference.days < 7:
        categories['SOON'].append(task['title'])
    else:
        categories['UPCOMING'].append(task['title'])

# Print results
for category, task_list in categories.items():
    print(f"{category}: {len(task_list)} tasks")
    for task_title in task_list[:3]:  # Show first 3
        print(f"  - {task_title}")
    if len(task_list) > 3:
        print(f"  ... and {len(task_list) - 3} more")
    print()
