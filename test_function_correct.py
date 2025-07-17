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

# Test if get_user_conversations function exists with correct parameter name
print("Testing get_user_conversations function with user_id_param...")
test_user_id = '12345678-1234-1234-1234-123456789012'  # dummy UUID
response = requests.post(
    f'{url}/rest/v1/rpc/get_user_conversations',
    headers=headers,
    json={'user_id_param': test_user_id}
)
print(f'Function test Status: {response.status_code}')
print(f'Function test Response: {response.text}')

# Try without any parameters to see the error message
print("\nTrying without parameters...")
response = requests.post(
    f'{url}/rest/v1/rpc/get_user_conversations',
    headers=headers,
    json={}
)
print(f'No params Status: {response.status_code}')
print(f'No params Response: {response.text}')

# Try the original parameter name
print("\nTrying with original user_id parameter...")
response = requests.post(
    f'{url}/rest/v1/rpc/get_user_conversations',
    headers=headers,
    json={'user_id': test_user_id}
)
print(f'Original param Status: {response.status_code}')
print(f'Original param Response: {response.text}')

# Create a fresh version of the function with proper parameter naming
print("\nAttempting to create/update the function...")

# First, try to use the SQL editor endpoint directly (this might not work with REST API)
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

GRANT EXECUTE ON FUNCTION get_user_conversations(uuid) TO authenticated;
'''

# This won't work with REST API but let's try anyway
try:
    # Check if there's an SQL endpoint
    response = requests.post(
        f'{url}/rest/v1/sql',
        headers=headers,
        json={'query': function_sql}
    )
    print(f'SQL execution Status: {response.status_code}')
    print(f'SQL execution Response: {response.text}')
except Exception as e:
    print(f'SQL execution failed: {e}')

print("\nDone with function testing.")