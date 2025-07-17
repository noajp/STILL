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

# Read the migration file
with open('/Users/nakanotakanori/Dev/STILL/supabase/migrations/20250117000001_create_get_user_conversations_function.sql', 'r') as f:
    migration_sql = f.read()

print("Migration SQL to execute:")
print(migration_sql)
print("\n" + "="*50 + "\n")

# Since we can't execute SQL directly through REST API, let's use psql with the connection string
import subprocess
import os

# Construct the psql command
# Note: In a real environment, you'd use environment variables for the password
db_url = "postgresql://postgres.yccjlkcxqybxqewzchen:O4K5gJZvv6qjKzAj@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres"

# Save the SQL to a temporary file
temp_sql_file = '/tmp/migration.sql'
with open(temp_sql_file, 'w') as f:
    f.write(migration_sql)

try:
    # Execute the SQL using psql
    result = subprocess.run(
        ['psql', db_url, '-f', temp_sql_file],
        capture_output=True,
        text=True,
        timeout=30
    )
    
    print(f"psql exit code: {result.returncode}")
    print(f"stdout: {result.stdout}")
    print(f"stderr: {result.stderr}")
    
    if result.returncode == 0:
        print("Migration executed successfully!")
    else:
        print("Migration failed!")
        
except subprocess.TimeoutExpired:
    print("psql command timed out")
except FileNotFoundError:
    print("psql command not found. Trying alternative method...")
    
    # Alternative: try to execute through a simple SQL execution function
    # Create a simple function to execute SQL if possible
    simple_sql_exec = '''
    DO $$
    BEGIN
        DROP FUNCTION IF EXISTS get_user_conversations(uuid);
        
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
        AS $func$
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
        $func$;
        
        GRANT EXECUTE ON FUNCTION get_user_conversations(uuid) TO authenticated;
    END;
    $$;
    '''
    
    print("Trying to execute SQL through alternative method...")
    print("This approach may not work with REST API limitations.")
    
finally:
    # Clean up temp file
    if os.path.exists(temp_sql_file):
        os.remove(temp_sql_file)

# Test the function after execution
print("\nTesting the function...")
test_user_id = 'd4376fa8-91ca-410f-af5f-49d391f20ec3'  # real user ID from the data
response = requests.post(
    f'{url}/rest/v1/rpc/get_user_conversations',
    headers=headers,
    json={'user_id': test_user_id}
)
print(f'Function test Status: {response.status_code}')
print(f'Function test Response: {response.text}')