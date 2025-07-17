# Manual SQL Function Execution Instructions

## Background
The `get_user_conversations` function exists in the database but appears to be referencing a non-existent table (`user_profiles` instead of `profiles`). We need to manually execute the SQL function creation through the Supabase dashboard.

## Steps to Execute

1. **Access Supabase Dashboard**
   - Go to https://supabase.com/dashboard
   - Navigate to your project: `yccjlkcxqybxqewzchen`

2. **Open SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Create a new query

3. **Execute the Following SQL**

```sql
-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_user_conversations(uuid);

-- Create the corrected function
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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_conversations(uuid) TO authenticated;
```

4. **Click "Run" to execute the SQL**

5. **Test the Function**
   - You can test it with a query like:
   ```sql
   SELECT * FROM get_user_conversations('d4376fa8-91ca-410f-af5f-49d391f20ec3');
   ```

## What This Function Does

The `get_user_conversations` function:
- Takes a user ID as input
- Returns all conversations the user is participating in
- Includes participant count and details for each conversation
- Orders results by last message time (most recent first)
- Aggregates participant information as JSON

## Database Tables Used

- `conversations`: Main conversation records
- `conversation_participants`: Links users to conversations
- `profiles`: User profile information

## Expected Result

After execution, the function should work correctly and resolve the messaging feature bugs in the iOS app.