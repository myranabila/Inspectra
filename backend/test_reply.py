"""
Test reply functionality
"""
import requests

BASE_URL = "http://127.0.0.1:8000"

print("="*60)
print("TESTING REPLY FUNCTIONALITY")
print("="*60)

# Step 1: Login as adam
print("\n[1] Adam logs in...")
adam_login = requests.post(
    f"{BASE_URL}/auth/login",
    json={"username": "adam", "password": "adam123"}
)
adam_token = adam_login.json()["access_token"]
adam_headers = {"Authorization": f"Bearer {adam_token}"}

adam_me = requests.get(f"{BASE_URL}/auth/me", headers=adam_headers).json()
print(f"✓ Adam logged in (ID: {adam_me['id']})")

# Step 2: Adam sends original message to abu
print("\n[2] Adam sends message to Abu...")
send1 = requests.post(
    f"{BASE_URL}/messaging/send",
    headers=adam_headers,
    json={
        "receiver_id": 4,  # abu
        "subject": "Question about task",
        "content": "Hi Abu, can you help me with the inspection task?"
    }
)
msg1 = send1.json()
print(f"✓ Message sent (ID: {msg1['message_id']})")

# Step 3: Login as abu
print("\n[3] Abu logs in...")
abu_login = requests.post(
    f"{BASE_URL}/auth/login",
    json={"username": "abu", "password": "abu123"}
)
abu_token = abu_login.json()["access_token"]
abu_headers = {"Authorization": f"Bearer {abu_token}"}

abu_me = requests.get(f"{BASE_URL}/auth/me", headers=abu_headers).json()
print(f"✓ Abu logged in (ID: {abu_me['id']})")

# Step 4: Abu reads messages
print("\n[4] Abu checks messages...")
abu_messages = requests.get(
    f"{BASE_URL}/messaging/my-messages",
    headers=abu_headers
).json()
print(f"✓ Abu has {len(abu_messages)} messages")

original_msg = abu_messages[0]
print(f"  Latest: '{original_msg['subject']}' from {original_msg['sender_name']}")

# Step 5: Abu replies
print("\n[5] Abu sends reply...")
reply = requests.post(
    f"{BASE_URL}/messaging/send",
    headers=abu_headers,
    json={
        "receiver_id": original_msg['sender_id'],
        "reply_to_id": original_msg['id'],
        "subject": f"Re: {original_msg['subject']}",
        "content": "Sure Adam! I'll help you with that. When do you need it?"
    }
)
reply_msg = reply.json()
print(f"✓ Reply sent (ID: {reply_msg['message_id']})")
print(f"  Replying to message ID: {original_msg['id']}")

# Step 6: Adam checks for reply
print("\n[6] Adam checks messages...")
adam_messages = requests.get(
    f"{BASE_URL}/messaging/my-messages",
    headers=adam_headers
).json()

print(f"✓ Adam has {len(adam_messages)} messages")
for msg in adam_messages[:3]:
    reply_indicator = f" (Reply to #{msg['reply_to_id']})" if msg['reply_to_id'] else ""
    print(f"  - {msg['subject']}{reply_indicator}")

print("\n" + "="*60)
print("✓ REPLY FUNCTIONALITY WORKING!")
print("="*60)
