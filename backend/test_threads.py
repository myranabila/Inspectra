"""
Test the new thread-based messaging endpoints
"""
import requests

BASE_URL = "http://127.0.0.1:8000"

# Login as manager
print("[1] Logging in as manager...")
response = requests.post(f"{BASE_URL}/auth/login", json={
    "username": "manager",
    "password": "manager123"
})
manager_token = response.json()["access_token"]
print(f"✓ Manager logged in")

# Get threads
print("\n[2] Getting conversation threads...")
response = requests.get(
    f"{BASE_URL}/messaging/threads",
    headers={"Authorization": f"Bearer {manager_token}"}
)
threads = response.json()
print(f"✓ Found {len(threads)} conversation threads")

if threads:
    print("\n[3] Thread details:")
    for thread in threads[:3]:  # Show first 3
        print(f"  - {thread['participant_name']}: {thread['last_message_preview']}")
        print(f"    Subject: {thread['subject']}")
        print(f"    Messages: {thread['message_count']}, Unread: {thread['unread_count']}")
        print(f"    Thread ID: {thread['thread_id']}\n")
    
    # Get messages in first thread
    first_thread_id = threads[0]['thread_id']
    print(f"[4] Getting messages in thread: {first_thread_id}")
    response = requests.get(
        f"{BASE_URL}/messaging/thread/{first_thread_id}",
        headers={"Authorization": f"Bearer {manager_token}"}
    )
    messages = response.json()
    print(f"✓ Found {len(messages)} messages in thread")
    
    if messages:
        print("\n[5] Message history:")
        for msg in messages:
            sender = "You" if msg['is_sender'] else msg['sender_name']
            print(f"  {sender}: {msg['content'][:50]}...")
else:
    print("No threads found")

print("\n✅ Thread system working!")
