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

# Check available tables
print("Checking available tables...")
tables_to_check = ['conversations', 'conversation_participants', 'profiles', 'user_profiles', 'messages']

for table in tables_to_check:
    print(f"\nChecking table: {table}")
    response = requests.get(
        f'{url}/rest/v1/{table}?limit=1',
        headers=headers
    )
    print(f'Status: {response.status_code}')
    if response.status_code == 200:
        print(f'Table exists - sample: {response.text[:200]}...')
    else:
        print(f'Table error: {response.text}')

# Check the schema more thoroughly
print("\n\nChecking full schema...")
response = requests.get(
    f'{url}/rest/v1/',
    headers=headers
)

if response.status_code == 200:
    schema = response.json()
    if 'definitions' in schema:
        print("\nAvailable table definitions:")
        for table_name in schema['definitions'].keys():
            print(f"- {table_name}")
            
        # Check if profiles table exists and its structure
        if 'profiles' in schema['definitions']:
            print("\nProfiles table structure:")
            profiles_def = schema['definitions']['profiles']
            if 'properties' in profiles_def:
                for prop, details in profiles_def['properties'].items():
                    print(f"  - {prop}: {details.get('type', 'unknown')}")
    else:
        print("No definitions found in schema")
        
    # Check paths for table endpoints
    if 'paths' in schema:
        table_paths = []
        for path in schema['paths']:
            if not path.startswith('/rpc/') and path != '/':
                table_paths.append(path.replace('/', ''))
        
        print(f"\nAvailable table endpoints: {table_paths}")
else:
    print(f"Failed to get schema: {response.status_code}")
    print(response.text)