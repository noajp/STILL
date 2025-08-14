--======================================================================
-- MARK: - Refactored Conversation Management Migration
-- Purpose: Break down complex conversation functions into smaller, focused units
-- Path: supabase/migrations/20250813_000003_refactor_conversation_management.sql
--======================================================================

-- Function to find existing conversation between users
CREATE OR REPLACE FUNCTION public.find_existing_conversation(
    p_user1_id uuid,
    p_user2_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_conversation_id uuid;
BEGIN
    -- Validate input
    IF p_user1_id IS NULL OR p_user2_id IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Find existing direct conversation between two users
    SELECT c.id INTO v_conversation_id
    FROM conversations c
    WHERE c.is_group = false
    AND EXISTS (
        SELECT 1 FROM conversation_participants cp1
        WHERE cp1.conversation_id = c.id 
        AND cp1.user_id = p_user1_id
    )
    AND EXISTS (
        SELECT 1 FROM conversation_participants cp2
        WHERE cp2.conversation_id = c.id 
        AND cp2.user_id = p_user2_id
    )
    LIMIT 1;
    
    RETURN v_conversation_id;
END;
$$;

-- Function to create a new conversation
CREATE OR REPLACE FUNCTION public.create_new_conversation(
    p_participants uuid[],
    p_is_group boolean DEFAULT false,
    p_name text DEFAULT NULL,
    p_description text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_conversation_id uuid;
    v_participant_id uuid;
BEGIN
    -- Validate input
    IF p_participants IS NULL OR array_length(p_participants, 1) < 2 THEN
        RAISE EXCEPTION 'A conversation requires at least 2 participants';
    END IF;
    
    -- For direct messages, ensure only 2 participants
    IF NOT p_is_group AND array_length(p_participants, 1) != 2 THEN
        RAISE EXCEPTION 'Direct conversations must have exactly 2 participants';
    END IF;
    
    -- Create the conversation
    INSERT INTO conversations (is_group, name, description)
    VALUES (p_is_group, p_name, p_description)
    RETURNING id INTO v_conversation_id;
    
    -- Add participants
    FOREACH v_participant_id IN ARRAY p_participants
    LOOP
        INSERT INTO conversation_participants (conversation_id, user_id)
        VALUES (v_conversation_id, v_participant_id);
    END LOOP;
    
    -- Log conversation creation
    PERFORM public.log_security_event(
        auth.uid(),
        'conversation_created',
        format('Created %s conversation %s with %s participants', 
               CASE WHEN p_is_group THEN 'group' ELSE 'direct' END,
               v_conversation_id,
               array_length(p_participants, 1)),
        NULL, NULL,
        jsonb_build_object(
            'conversation_id', v_conversation_id,
            'is_group', p_is_group,
            'participant_count', array_length(p_participants, 1)
        ),
        'low'
    );
    
    RETURN v_conversation_id;
END;
$$;

-- Function to reset conversation visibility for participants
CREATE OR REPLACE FUNCTION public.reset_conversation_visibility(
    p_conversation_id uuid,
    p_user_ids uuid[] DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- If no specific users provided, reset for all participants
    IF p_user_ids IS NULL THEN
        UPDATE conversation_participants
        SET 
            is_hidden = false,
            hidden_at = NULL
        WHERE conversation_id = p_conversation_id;
    ELSE
        -- Reset for specific users only
        UPDATE conversation_participants
        SET 
            is_hidden = false,
            hidden_at = NULL
        WHERE conversation_id = p_conversation_id
        AND user_id = ANY(p_user_ids);
    END IF;
END;
$$;

-- Function to get conversations with metadata
CREATE OR REPLACE FUNCTION public.get_conversations_with_metadata(
    p_user_id uuid,
    p_conversation_type text DEFAULT 'all'  -- 'all', 'direct', 'group'
)
RETURNS TABLE (
    conversation_id uuid,
    is_group boolean,
    name text,
    description text,
    created_at timestamptz,
    last_message_at timestamptz,
    last_message_preview text,
    unread_count bigint,
    participant_count bigint,
    is_hidden boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id AS conversation_id,
        c.is_group,
        c.name,
        c.description,
        c.created_at,
        c.last_message_at,
        LEFT(m.content, 100) AS last_message_preview,
        COUNT(DISTINCT um.id) FILTER (WHERE um.is_read = false) AS unread_count,
        COUNT(DISTINCT cp.user_id) AS participant_count,
        cp_user.is_hidden
    FROM conversations c
    INNER JOIN conversation_participants cp_user 
        ON cp_user.conversation_id = c.id 
        AND cp_user.user_id = p_user_id
        AND cp_user.is_hidden = false
    LEFT JOIN conversation_participants cp 
        ON cp.conversation_id = c.id
    LEFT JOIN messages m 
        ON m.id = c.last_message_id
    LEFT JOIN messages um 
        ON um.conversation_id = c.id 
        AND um.created_at > cp_user.last_read_at
        AND um.sender_id != p_user_id
    WHERE 
        (p_conversation_type = 'all' OR 
         (p_conversation_type = 'direct' AND c.is_group = false) OR
         (p_conversation_type = 'group' AND c.is_group = true))
    GROUP BY 
        c.id, c.is_group, c.name, c.description, 
        c.created_at, c.last_message_at, m.content, 
        cp_user.is_hidden
    ORDER BY 
        c.last_message_at DESC NULLS LAST;
END;
$$;

-- Refactored get_or_create_direct_conversation function
CREATE OR REPLACE FUNCTION public.get_or_create_direct_conversation(
    p_other_user_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_current_user_id uuid;
    v_conversation_id uuid;
BEGIN
    -- Get current user
    v_current_user_id := auth.uid();
    
    IF v_current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    IF p_other_user_id IS NULL THEN
        RAISE EXCEPTION 'Other user ID cannot be null';
    END IF;
    
    IF v_current_user_id = p_other_user_id THEN
        RAISE EXCEPTION 'Cannot create conversation with yourself';
    END IF;
    
    -- Check if other user exists
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = p_other_user_id) THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Try to find existing conversation
    v_conversation_id := public.find_existing_conversation(v_current_user_id, p_other_user_id);
    
    -- If conversation exists, unhide it for current user and return
    IF v_conversation_id IS NOT NULL THEN
        PERFORM public.reset_conversation_visibility(
            v_conversation_id, 
            ARRAY[v_current_user_id]::uuid[]
        );
        RETURN v_conversation_id;
    END IF;
    
    -- Create new conversation
    v_conversation_id := public.create_new_conversation(
        ARRAY[v_current_user_id, p_other_user_id]::uuid[],
        false  -- not a group conversation
    );
    
    RETURN v_conversation_id;
END;
$$;

-- Simplified get_user_conversations function
CREATE OR REPLACE FUNCTION public.get_user_conversations(p_user_id uuid)
RETURNS TABLE (
    conversation_id uuid,
    is_group boolean,
    name text,
    description text,
    created_at timestamptz,
    last_message_at timestamptz,
    last_message_preview text,
    unread_count bigint,
    participant_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gcm.conversation_id,
        gcm.is_group,
        gcm.name,
        gcm.description,
        gcm.created_at,
        gcm.last_message_at,
        gcm.last_message_preview,
        gcm.unread_count,
        gcm.participant_count
    FROM public.get_conversations_with_metadata(p_user_id, 'direct') gcm;
END;
$$;

-- Simplified get_user_group_conversations function
CREATE OR REPLACE FUNCTION public.get_user_group_conversations(p_user_id uuid)
RETURNS TABLE (
    conversation_id uuid,
    name text,
    description text,
    created_at timestamptz,
    last_message_at timestamptz,
    last_message_preview text,
    unread_count bigint,
    member_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gcm.conversation_id,
        gcm.name,
        gcm.description,
        gcm.created_at,
        gcm.last_message_at,
        gcm.last_message_preview,
        gcm.unread_count,
        gcm.participant_count AS member_count
    FROM public.get_conversations_with_metadata(p_user_id, 'group') gcm;
END;
$$;

-- Grant appropriate permissions
GRANT EXECUTE ON FUNCTION public.find_existing_conversation TO service_role;
GRANT EXECUTE ON FUNCTION public.create_new_conversation TO authenticated;
GRANT EXECUTE ON FUNCTION public.reset_conversation_visibility TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_conversations_with_metadata TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_direct_conversation TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_conversations TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_group_conversations TO authenticated;

-- Add comments for documentation
COMMENT ON FUNCTION public.find_existing_conversation IS 'Find existing direct conversation between two users';
COMMENT ON FUNCTION public.create_new_conversation IS 'Create a new conversation with specified participants';
COMMENT ON FUNCTION public.reset_conversation_visibility IS 'Reset conversation visibility for specified users';
COMMENT ON FUNCTION public.get_conversations_with_metadata IS 'Get conversations with full metadata for a user';
COMMENT ON FUNCTION public.get_or_create_direct_conversation IS 'Get or create a direct conversation with another user';
COMMENT ON FUNCTION public.get_user_conversations IS 'Get all direct conversations for a user';
COMMENT ON FUNCTION public.get_user_group_conversations IS 'Get all group conversations for a user';