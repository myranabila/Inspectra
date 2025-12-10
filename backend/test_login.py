import requests
import json

# Test login directly
url = "http://127.0.0.1:8000/auth/login"
data = {"username": "manager", "password": "manager123"}

print(f"Testing login to: {url}")
print(f"With credentials: {data}")

try:
    response = requests.post(url, json=data)
    print(f"\nStatus Code: {response.status_code}")
    print(f"Response: {response.text}")
    
    if response.status_code == 200:
        print("\n✅ Login successful!")
    else:
        print("\n❌ Login failed!")
except Exception as e:
    print(f"\n❌ Error: {e}")
