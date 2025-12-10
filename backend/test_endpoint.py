import requests

# Test health endpoint
try:
    response = requests.get("http://localhost:8000/health")
    print(f"Health endpoint status: {response.status_code}")
    print(f"Health response: {response.json()}")
except Exception as e:
    print(f"Health endpoint error: {e}")

# Test login endpoint
try:
    response = requests.post(
        "http://localhost:8000/auth/login",
        json={"username": "adam", "password": "adampass"}
    )
    print(f"\nLogin endpoint status: {response.status_code}")
    print(f"Login response: {response.json()}")
except Exception as e:
    print(f"\nLogin endpoint error: {e}")
