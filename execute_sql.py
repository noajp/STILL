import json
import requests
import sys

# Supabase configuration
url = 'https://yccjlkcxqybxqewzchen.supabase.co'
service_role_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljY2psa2N4cXlieHFld3pjaGVuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODg3NTMyNSwiZXhwIjoyMDY0NDUxMzI1fQ.VhGeceplsOLsyWhz324oGqyIYdI8GTYOnUQglqi_xic'

# Read the SQL file
with open('/Users/nakanotakanori/Dev/STILL/get_user_conversations.sql', 'r') as f:
    sql = f.read()

# Try to execute raw SQL using the raw SQL endpoint
response = requests.post(
    f'{url}/rest/v1/rpc/pg_eval',
    headers={
        'apikey': service_role_key,
        'Authorization': f'Bearer {service_role_key}',
        'Content-Type': 'application/json',
    },
    json={'query': sql}
)

print(f'Status Code: {response.status_code}')
print(f'Response: {response.text}')

# If that doesn't work, try the SQL API directly
if response.status_code != 200:
    print('Trying SQL API...')
    response = requests.post(
        f'{url}/sql',
        headers={
            'apikey': service_role_key,
            'Authorization': f'Bearer {service_role_key}',
            'Content-Type': 'application/json',
        },
        json={'query': sql}
    )
    
    print(f'SQL API Status Code: {response.status_code}')
    print(f'SQL API Response: {response.text}')