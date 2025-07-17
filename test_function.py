import json
import requests
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Supabase configuration
url = 'https://yccjlkcxqybxqewzchen.supabase.co'
service_role_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljY2psa2N4cXlieHFld3pjaGVuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODg3NTMyNSwiZXhwIjoyMDY0NDUxMzI1fQ.VhGeceplsOLsyWhz324oGqyIYdI8GTYOnUQglqi_xic'

headers = {
    'apikey': service_role_key,
    'Authorization': f'Bearer {service_role_key}',
    'Content-Type': 'application/json',
}

# Test if get_user_conversations function exists
print("Testing get_user_conversations function...")
test_user_id = '12345678-1234-1234-1234-123456789012'  # dummy UUID
response = requests.post(
    f'{url}/rest/v1/rpc/get_user_conversations',
    headers=headers,
    json={'user_id': test_user_id}
)
print(f'Function test Status: {response.status_code}')
print(f'Function test Response: {response.text}')

# Check the schema to see what functions are available
print("\nChecking available functions in schema...")
response = requests.get(
    f'{url}/rest/v1/',
    headers=headers
)

if response.status_code == 200:
    schema = response.json()
    if 'paths' in schema:
        rpc_functions = []
        for path in schema['paths']:
            if path.startswith('/rpc/'):
                rpc_functions.append(path.replace('/rpc/', ''))
        
        print(f"Available RPC functions: {rpc_functions}")
    else:
        print("No paths found in schema")
else:
    print(f"Failed to get schema: {response.status_code}")
    print(response.text)