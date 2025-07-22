-- ======================================================================
-- Fix get_user_conversations function to match Swift code expectations
-- Migration: 20250120000001_fix_get_user_conversations_function
-- ======================================================================

-- Drop the existing function
DROP FUNCTION IF EXISTS get_user_conversations(uuid);

-- Create the function with the correct return format that matches Swift ConversationData struct
CREATE OR REPLACE FUNCTION get_user_conversations(user_id_param uuid)
RETURNS TABLE (
    conversation_id uuid,
    conversation_created_at timestamp with time zone,
    conversation_updated_at timestamp with time zone,
    conversation_last_message_at timestamp with time zone,
    conversation_last_message_preview text,
    participant_id uuid,
    participant_user_id uuid,
    participant_joined_at timestamp with time zone,
    participant_last_read_at timestamp with time zone,
    user_username text,
    user_display_name text,
    user_avatar_url text,
    user_bio text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as conversation_id,
        c.created_at as conversation_created_at,
        c.updated_at as conversation_updated_at,
        c.last_message_at as conversation_last_message_at,
        c.last_message_preview as conversation_last_message_preview,
        cp.id as participant_id,
        cp.user_id as participant_user_id,
        cp.joined_at as participant_joined_at,
        cp.last_read_at as participant_last_read_at,
        p.username as user_username,
        p.display_name as user_display_name,
        p.avatar_url as user_avatar_url,
        p.bio as user_bio
    FROM conversations c
    INNER JOIN conversation_participants cp ON cp.conversation_id = c.id
    INNER JOIN profiles p ON p.id = cp.user_id
    WHERE c.id IN (
        SELECT conversation_id 
        FROM conversation_participants 
        WHERE user_id = user_id_param
    )
    AND (c.is_group = FALSE OR c.is_group IS NULL)  -- Only return direct conversations
    ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_conversations(uuid) TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION get_user_conversations(uuid) IS 'Returns all direct conversations for a user with full participant details. Each row represents a participant in a conversation, so conversations with multiple participants will have multiple rows.';