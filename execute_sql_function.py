import json
import requests
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Supabase configuration
url = 'https://yccjlkcxqybxqewzchen.supabase.co'
service_role_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljY2psa2N4cXlieHFld3pjaGVuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODg3NTMyNSwiZXhwIjoyMDY0NDUxMzI1fQ.VhGeceplsOLsyWhz324oGqyIYdI8GTYOnUQglqi_xic'

# Create the function SQL
function_sql = '''
CREATE OR REPLACE FUNCTION get_user_conversations(user_id uuid)
RETURNS TABLE (
    id uuid,
    created_at timestamptz,
    updated_at timestamptz,
    last_message_at timestamptz,
    last_message_preview text,
    participant_count bigint,
    participants json
) 
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.created_at,
        c.updated_at,
        c.last_message_at,
        c.last_message_preview,
        COUNT(cp.user_id) as participant_count,
        json_agg(
            json_build_object(
                'id', p.id,
                'username', p.username,
                'display_name', p.display_name,
                'avatar_url', p.avatar_url
            )
        ) as participants
    FROM conversations c
    JOIN conversation_participants cp ON c.id = cp.conversation_id
    JOIN profiles p ON cp.user_id = p.id
    WHERE c.id IN (
        SELECT conversation_id 
        FROM conversation_participants 
        WHERE user_id = get_user_conversations.user_id
    )
    GROUP BY c.id, c.created_at, c.updated_at, c.last_message_at, c.last_message_preview
    ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC;
END;
$$;
'''

# Grant permission SQL
grant_sql = '''
GRANT EXECUTE ON FUNCTION get_user_conversations(uuid) TO authenticated;
'''

# Try to execute the function creation using multiple approaches
headers = {
    'apikey': service_role_key,
    'Authorization': f'Bearer {service_role_key}',
    'Content-Type': 'application/json',
}

# Try a simpler approach - create a function to execute raw SQL
test_query = 'SELECT version();'

# Method 1: Try to create a custom function that can execute SQL
create_exec_function = '''
CREATE OR REPLACE FUNCTION exec_sql(sql text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    EXECUTE sql;
    RETURN 'Success';
END;
$$;
'''

print("Attempting to create exec_sql function...")
response = requests.post(
    f'{url}/rest/v1/rpc/exec_sql',
    headers=headers,
    json={'sql': create_exec_function}
)
print(f'Create exec_sql Status: {response.status_code}')
print(f'Create exec_sql Response: {response.text}')

# Method 2: Try direct approach with a simple query
print("\nTrying direct query...")
response = requests.post(
    f'{url}/rest/v1/rpc/version',
    headers=headers,
    json={}
)
print(f'Version Status: {response.status_code}')
print(f'Version Response: {response.text}')

# Method 3: Try using the REST API to check available functions
print("\nChecking available functions...")
response = requests.get(
    f'{url}/rest/v1/',
    headers=headers
)
print(f'Schema Status: {response.status_code}')
print(f'Schema Response: {response.text[:500]}...')  # Truncate for readability

# Method 4: Create a simple function to test if we can create functions at all
simple_function = '''
CREATE OR REPLACE FUNCTION test_function()
RETURNS text
LANGUAGE sql
AS $$
SELECT 'Hello World';
$$;
'''

print("\nTrying to create a simple test function...")
# Check if we can see any existing functions
response = requests.get(
    f'{url}/rest/v1/rpc/test_function',
    headers=headers
)
print(f'Test function Status: {response.status_code}')
print(f'Test function Response: {response.text}')

print("\nDone with execution attempts.")