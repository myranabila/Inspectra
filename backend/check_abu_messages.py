"""
Check messages for abu user
"""
import requests

BASE_URL = "http://127.0.0.1:8000"

# Login as abu
print("Logging in as abu...")
login_response = requests.post(
    f"{BASE_URL}/auth/login",
    json={"username": "abu", "password": "abu123"}
)

if login_response.status_code != 200:
    print(f"❌ Login failed: {login_response.text}")
    exit(1)

token = login_response.json()["access_token"]
user_info = login_response.json().get("user", {})
print(f"✓ Logged in as: {user_info.get('full_name', 'abu')}")
print(f"  User ID: {user_info.get('id')}")
print(f"  Role: {user_info.get('role')}")

headers = {"Authorization": f"Bearer {token}"}

# Get all messages for abu
print("\nFetching messages for abu...")
messages_response = requests.get(
    f"{BASE_URL}/messaging/my-messages",
    headers=headers
)

if messages_response.status_code != 200:
    print(f"❌ Failed to get messages: {messages_response.text}")
    exit(1)

messages = messages_response.json()
print(f"\n{'='*60}")
print(f"ABU'S MESSAGES ({len(messages)} total)")
print(f"{'='*60}")

if not messages:
    print("No messages found for abu")
else:
    for i, msg in enumerate(messages, 1):
        print(f"\nMessage {i}:")
        print(f"  ID: {msg['id']}")
        print(f"  From: {msg.get('sender_name', 'Unknown')}")
        print(f"  To: {msg.get('receiver_name', 'Unknown')}")
        print(f"  Subject: {msg.get('subject', '(No subject)')}")
        print(f"  Content: {msg.get('content', '')[:50]}...")
        print(f"  Status: {msg['status']}")
        print(f"  Created: {msg.get('created_at', 'Unknown')}")

# Get unread count
unread_response = requests.get(
    f"{BASE_URL}/messaging/unread-count",
    headers=headers
)

if unread_response.status_code == 200:
    unread_count = unread_response.json()["unread_count"]
    print(f"\n{'='*60}")
    print(f"Unread messages: {unread_count}")
    print(f"{'='*60}")
