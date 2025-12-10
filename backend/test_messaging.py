"""
Test script to verify messaging functionality
"""
import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def test_login_and_message():
    print("=" * 60)
    print("TESTING MESSAGING SYSTEM")
    print("=" * 60)
    
    # Step 1: Login as manager
    print("\n1. Logging in as manager...")
    login_response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"username": "manager", "password": "manager123"}
    )
    
    if login_response.status_code != 200:
        print(f"❌ Login failed: {login_response.text}")
        return
    
    token = login_response.json()["access_token"]
    print(f"✓ Login successful! Token: {token[:20]}...")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Step 2: Get all users
    print("\n2. Getting list of users...")
    users_response = requests.get(
        f"{BASE_URL}/messaging/users",
        headers=headers
    )
    
    if users_response.status_code != 200:
        print(f"❌ Failed to get users: {users_response.text}")
        return
    
    users = users_response.json()
    print(f"✓ Found {len(users)} users:")
    for user in users:
        print(f"  - ID: {user['id']}, Username: {user['username']}, Role: {user['role']}")
    
    if not users:
        print("❌ No users found!")
        return
    
    # Step 3: Send message to first user
    receiver = users[0]
    print(f"\n3. Sending message to {receiver['username']}...")
    
    message_data = {
        "receiver_id": receiver['id'],
        "subject": "Test Message",
        "content": "This is a test message from the messaging system"
    }
    
    print(f"Request data: {json.dumps(message_data, indent=2)}")
    
    send_response = requests.post(
        f"{BASE_URL}/messaging/send",
        headers=headers,
        json=message_data
    )
    
    print(f"Response status: {send_response.status_code}")
    print(f"Response body: {send_response.text}")
    
    if send_response.status_code == 200:
        result = send_response.json()
        print(f"✓ Message sent successfully!")
        print(f"  - Message ID: {result['message_id']}")
        print(f"  - Sent to: {result['sent_to']}")
        print(f"  - Sent at: {result['sent_at']}")
    else:
        print(f"❌ Failed to send message: {send_response.text}")
        return
    
    # Step 4: Check messages as receiver
    print(f"\n4. Logging in as {receiver['username']}...")
    receiver_login = requests.post(
        f"{BASE_URL}/auth/login",
        json={"username": receiver['username'], "password": f"{receiver['username']}123"}
    )
    
    if receiver_login.status_code != 200:
        print(f"❌ Receiver login failed: {receiver_login.text}")
        return
    
    receiver_token = receiver_login.json()["access_token"]
    receiver_headers = {"Authorization": f"Bearer {receiver_token}"}
    
    messages_response = requests.get(
        f"{BASE_URL}/messaging/my-messages",
        headers=receiver_headers
    )
    
    if messages_response.status_code == 200:
        messages = messages_response.json()
        print(f"✓ Receiver has {len(messages)} messages")
        if messages:
            latest = messages[0]
            print(f"  Latest message:")
            print(f"    - From: {latest['sender_name']}")
            print(f"    - Subject: {latest['subject']}")
            print(f"    - Content: {latest['content']}")
            print(f"    - Status: {latest['status']}")
    else:
        print(f"❌ Failed to get messages: {messages_response.text}")
    
    print("\n" + "=" * 60)
    print("TEST COMPLETED")
    print("=" * 60)

if __name__ == "__main__":
    test_login_and_message()
