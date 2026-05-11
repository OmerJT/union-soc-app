#!/usr/bin/env python3
import urllib.request
import json
import time

BASE_URL = 'http://127.0.0.1:8000/api'

# Test registration with unique username
timestamp = int(time.time())
username = f'testuser{timestamp}'

print(f"Testing Registration with username: {username}...")
register_data = {
    'username': username,
    'email': f'{username}@example.com',
    'password': 'Password123!',
    'first_name': 'Test',
    'last_name': 'User',
    'up_number': 'UP654321',
    'role': 'user'
}

try:
    req = urllib.request.Request(
        f'{BASE_URL}/auth/register/',
        data=json.dumps(register_data).encode('utf-8'),
        headers={'Content-Type': 'application/json'},
        method='POST'
    )
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode('utf-8'))
        print(f"Status Code: {response.status}")
        print(f"Response: {json.dumps(data, indent=2)}")
        
        # Test login
        print(f"\nTesting Login with {username}...")
        login_data = {
            'username': username,
            'password': 'Password123!'
        }
        login_req = urllib.request.Request(
            f'{BASE_URL}/auth/login/',
            data=json.dumps(login_data).encode('utf-8'),
            headers={'Content-Type': 'application/json'},
            method='POST'
        )
        with urllib.request.urlopen(login_req) as login_response:
            login_data_resp = json.loads(login_response.read().decode('utf-8'))
            print(f"Login Status: {login_response.status}")
            print(f"Login Response: {json.dumps(login_data_resp, indent=2)}")
            
except urllib.error.HTTPError as e:
    error_body = e.read().decode('utf-8')
    print(f"Status Code: {e.code}")
    print(f"Error Body: {error_body}")
    try:
        error_data = json.loads(error_body)
        print(f"Error (JSON): {json.dumps(error_data, indent=2)}")
    except:
        print(f"(Could not parse as JSON)")
