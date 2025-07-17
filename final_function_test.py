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

print("=== Final Function Test ===")
print("Testing get_user_conversations function after manual execution...")
print()

# Test with the actual user ID from the database
test_user_id = 'd4376fa8-91ca-410f-af5f-49d391f20ec3'  # real user ID from the data

# Test the function
response = requests.post(
    f'{url}/rest/v1/rpc/get_user_conversations',
    headers=headers,
    json={'user_id': test_user_id}
)

print(f'Function Status: {response.status_code}')
print(f'Function Response: {response.text}')

if response.status_code == 200:
    print("\n✅ SUCCESS: Function is working correctly!")
    try:
        data = response.json()
        print(f"Number of conversations returned: {len(data)}")
        
        if data:
            print("\nSample conversation data:")
            for i, conv in enumerate(data[:2]):  # Show first 2 conversations
                print(f"  Conversation {i+1}:")
                print(f"    ID: {conv.get('id')}")
                print(f"    Created: {conv.get('created_at')}")
                print(f"    Last Message: {conv.get('last_message_at')}")
                print(f"    Participants: {conv.get('participant_count')}")
                print(f"    Preview: {conv.get('last_message_preview')}")
                print()
    except json.JSONDecodeError:
        print("Response is not valid JSON")
        
elif response.status_code == 404:
    print("\n❌ ERROR: Function not found or has wrong parameters")
    print("This means the function needs to be manually created in Supabase Dashboard")
    print("Please follow the instructions in manual_sql_execution_instructions.md")
    
else:
    print(f"\n❌ ERROR: Unexpected response - {response.status_code}")
    print("Please check the function implementation")

print("\n=== End Test ===")

# Also test if we can get conversation participants
print("\nTesting conversation participants...")
response = requests.get(
    f'{url}/rest/v1/conversation_participants?user_id=eq.{test_user_id}',
    headers=headers
)
print(f'Participants Status: {response.status_code}')
if response.status_code == 200:
    participants = response.json()
    print(f"User participates in {len(participants)} conversations")
else:
    print(f'Participants Error: {response.text}')