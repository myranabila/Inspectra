"""
Test sending message from adam to abu directly via API
"""
import requests

BASE_URL = "http://127.0.0.1:8000"

print("="*60)
print("TESTING: ADAM SENDS MESSAGE TO ABU")
print("="*60)

# Step 1: Login as adam
print("\n[1] Logging in as adam...")
adam_login = requests.post(
    f"{BASE_URL}/auth/login",
    json={"username": "adam", "password": "adam123"}
)

if adam_login.status_code != 200:
    print(f"❌ Login failed: {adam_login.text}")
    exit(1)

adam_token = adam_login.json()["access_token"]
adam_headers = {"Authorization": f"Bearer {adam_token}"}
print("✓ Adam logged in")

# Step 2: Get adam's user info
adam_me = requests.get(f"{BASE_URL}/auth/me", headers=adam_headers)
adam_info = adam_me.json()
print(f"  Adam ID: {adam_info['id']}, Name: {adam_info['full_name']}")

# Step 3: Get list of users to find abu's ID
print("\n[2] Getting list of users...")
users_response = requests.get(
    f"{BASE_URL}/messaging/users",
    headers=adam_headers
)

users = users_response.json()
print(f"✓ Found {len(users)} other users")

abu = None
for user in users:
    if user['username'] == 'abu':
        abu = user
        break

if not abu:
    print("❌ Abu not found in users list!")
    exit(1)

print(f"  Abu ID: {abu['id']}, Name: {abu['full_name']}")

# Step 4: Send message from adam to abu
print(f"\n[3] Sending message from adam (ID {adam_info['id']}) to abu (ID {abu['id']})...")

message_data = {
    "receiver_id": abu['id'],
    "subject": "Test from Adam",
    "content": "Hi Abu! This is a test message from Adam."
}

print(f"  Request: {message_data}")

send_response = requests.post(
    f"{BASE_URL}/messaging/send",
    headers=adam_headers,
    json=message_data
)

print(f"  Response status: {send_response.status_code}")
print(f"  Response: {send_response.text}")

if send_response.status_code == 200:
    result = send_response.json()
    print(f"✓ Message sent!")
    print(f"  Message ID: {result['message_id']}")
    print(f"  Sent to: {result['sent_to']}")
else:
    print(f"❌ Failed to send message!")
    exit(1)

# Step 5: Login as abu and check messages
print(f"\n[4] Logging in as abu...")
abu_login = requests.post(
    f"{BASE_URL}/auth/login",
    json={"username": "abu", "password": "abu123"}
)

if abu_login.status_code != 200:
    print(f"❌ Abu login failed: {abu_login.text}")
    exit(1)

abu_token = abu_login.json()["access_token"]
abu_headers = {"Authorization": f"Bearer {abu_token}"}
print("✓ Abu logged in")

# Get abu's info
abu_me = requests.get(f"{BASE_URL}/auth/me", headers=abu_headers)
abu_info = abu_me.json()
print(f"  Abu ID: {abu_info['id']}, Name: {abu_info['full_name']}")

# Step 6: Get abu's messages
print(f"\n[5] Getting abu's messages...")
messages_response = requests.get(
    f"{BASE_URL}/messaging/my-messages",
    headers=abu_headers
)

if messages_response.status_code != 200:
    print(f"❌ Failed to get messages: {messages_response.text}")
    exit(1)

messages = messages_response.json()
print(f"✓ Abu has {len(messages)} messages")

if messages:
    for i, msg in enumerate(messages, 1):
        print(f"\n  Message {i}:")
        print(f"    ID: {msg['id']}")
        print(f"    From: {msg['sender_name']}")
        print(f"    Subject: {msg['subject']}")
        print(f"    Content: {msg['content']}")
        print(f"    Status: {msg['status']}")
else:
    print("  ❌ No messages found!")

print("\n" + "="*60)
print("TEST COMPLETED")
print("="*60)
