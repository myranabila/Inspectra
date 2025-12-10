import requests

# Test login as adam
login_response = requests.post(
    'http://127.0.0.1:8000/auth/login',
    json={'username': 'adam', 'password': 'adam123'}
)

if login_response.status_code == 200:
    token = login_response.json()['access_token']
    print(f'✅ Login successful, token: {token[:20]}...')
    
    # Get my tasks
    tasks_response = requests.get(
        'http://127.0.0.1:8000/dashboard/my-tasks',
        headers={'Authorization': f'Bearer {token}'}
    )
    
    if tasks_response.status_code == 200:
        tasks = tasks_response.json()
        print(f'\n✅ My Tasks returned successfully')
        print(f'Total tasks: {len(tasks)}')
        
        # Check if task 76 is in the list
        task_76 = next((t for t in tasks if t['id'] == 76), None)
        if task_76:
            print(f'\n✅ Task 76 found!')
            print(f'  Title: {task_76["title"]}')
            print(f'  Status: {task_76["status"]}')
            print(f'  Scheduled: {task_76.get("scheduled_date")}')
        else:
            print('\n❌ Task 76 NOT found in returned tasks!')
            print(f'Task IDs returned: {[t["id"] for t in tasks]}')
            
        print('\nLast 3 tasks:')
        for task in tasks[-3:]:
            print(f"  - ID: {task['id']}, Title: {task['title']}, Status: {task['status']}")
    else:
        print(f'\n❌ My Tasks failed: {tasks_response.status_code}')
        print(tasks_response.text)
else:
    print(f'❌ Login failed: {login_response.status_code}')
    print(login_response.text)
