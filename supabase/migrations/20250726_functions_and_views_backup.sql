-- ======================================================================
-- Supabase Functions and Views Backup
-- Generated: 2025-07-26
-- Purpose: Backup of all RPC functions and views from production database
-- ======================================================================

-- ======================================================================
-- SECURITY FUNCTIONS
-- ======================================================================

-- Function: log_security_event
-- Purpose: Log security-related events for audit trail
CREATE OR REPLACE FUNCTION public.log_security_event(
    p_action text, 
    p_resource_type text, 
    p_resource_id text DEFAULT NULL::text, 
    p_metadata jsonb DEFAULT NULL::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $function$
BEGIN
    INSERT INTO security_audit_log (
        user_id,
        action,
        resource_type,
        resource_id,
        ip_address,
        user_agent,
        metadata
    ) VALUES (
        auth.uid(),
        p_action,
        p_resource_type,
        p_resource_id,
        inet_client_addr(),
        current_setting('request.headers', true)::json->>'user-agent',
        p_metadata
    );
END;
$function$;

-- Function: check_rate_limit
-- Purpose: Check if user has exceeded rate limit for an action
CREATE OR REPLACE FUNCTION public.check_rate_limit(
    user_id uuid, 
    action_type text, 
    max_requests integer, 
    time_window_minutes integer
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $function$
DECLARE
    request_count integer;
BEGIN
    -- Count recent requests
    SELECT COUNT(*)
    INTO request_count
    FROM rate_limits
    WHERE user_id = check_rate_limit.user_id
      AND action = action_type
      AND created_at > NOW() - (time_window_minutes || ' minutes')::interval;
    
    -- Check if limit exceeded
    IF request_count >= max_requests THEN
        RETURN false;
    END IF;
    
    -- Log this request
    INSERT INTO rate_limits (user_id, action, created_at)
    VALUES (check_rate_limit.user_id, action_type, NOW());
    
    RETURN true;
END;
$function$;

-- Function: anonymize_user_data
-- Purpose: Anonymize user data for GDPR compliance
CREATE OR REPLACE FUNCTION public.anonymize_user_data(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'auth'
AS $function$
BEGIN
    -- SECURITY FIX: Only allow users to anonymize their own data
    IF (SELECT auth.uid()) != target_user_id THEN
        RAISE EXCEPTION 'ACCESS DENIED: You can only anonymize your own data';
    END IF;
    
    -- Proceed with anonymization
    UPDATE public.user_profiles
    SET 
        username = 'deleted_user_' || EXTRACT(epoch FROM now())::text,
        display_name = 'Deleted User',
        avatar_url = NULL,
        bio = NULL,
        data_classification = 'anonymized'
    WHERE id = target_user_id;
    
    UPDATE public.posts
    SET 
        caption = '[Content Deleted]',
        location_name = NULL,
        latitude = NULL,
        longitude = NULL
    WHERE user_id = target_user_id;
    
    DELETE FROM public.messages WHERE sender_id = target_user_id;
    
    -- Log the security event
    PERFORM public.log_security_event(
        target_user_id,
        'data_anonymization',
        'User data anonymized',
        NULL, NULL, 
        jsonb_build_object('user_id', target_user_id, 'anonymized_at', now()),
        'high'
    );
END;
$function$;

-- Function: export_user_data
-- Purpose: Export user data for GDPR data portability
CREATE OR REPLACE FUNCTION public.export_user_data(target_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $function$
DECLARE
    user_data jsonb;
    posts_data jsonb;
    messages_data jsonb;
BEGIN
    -- Only allow users to export their own data
    IF (SELECT auth.uid()) != target_user_id THEN
        RAISE EXCEPTION 'Access denied: You can only export your own data';
    END IF;
    
    -- Export user profile
    SELECT jsonb_build_object(
        'profile', row_to_json(up.*)
    ) INTO user_data
    FROM public.user_profiles up
    WHERE up.id = target_user_id;
    
    -- Export posts
    SELECT jsonb_agg(row_to_json(p.*)) INTO posts_data
    FROM public.posts p
    WHERE p.user_id = target_user_id;
    
    -- Export messages
    SELECT jsonb_agg(row_to_json(m.*)) INTO messages_data
    FROM public.messages m
    WHERE m.sender_id = target_user_id;
    
    -- Log the export
    PERFORM public.log_security_event(
        target_user_id,
        'data_export',
        'User requested data export',
        NULL, NULL,
        jsonb_build_object('user_id', target_user_id, 'exported_at', now()),
        'medium'
    );
    
    RETURN jsonb_build_object(
        'user_profile', user_data,
        'posts', COALESCE(posts_data, '[]'::jsonb),
        'messages', COALESCE(messages_data, '[]'::jsonb),
        'export_timestamp', now()
    );
END;
$function$;

-- ======================================================================
-- MESSAGING FUNCTIONS
-- ======================================================================

-- Function: get_or_create_direct_conversation
-- Purpose: Get existing or create new direct conversation between two users
CREATE OR REPLACE FUNCTION public.get_or_create_direct_conversation(other_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'pg_catalog'
AS $function$
DECLARE
    result_conversation_id UUID;
    current_user_id UUID;
    participant_count INT;
BEGIN
    -- Get current user ID
    current_user_id := auth.uid();
    
    -- Validate inputs
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    IF other_user_id IS NULL THEN
        RAISE EXCEPTION 'Other user ID is required';
    END IF;
    
    IF LOWER(current_user_id::text) = LOWER(other_user_id::text) THEN
        RAISE EXCEPTION 'Cannot create conversation with yourself';
    END IF;
    
    -- Ensure the other user exists in profiles (case-insensitive)
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE LOWER(id::text) = LOWER(other_user_id::text)) THEN
        RAISE EXCEPTION 'Other user does not exist in profiles table';
    END IF;
    
    -- Check if a direct conversation already exists (case-insensitive)
    SELECT DISTINCT c.id INTO result_conversation_id
    FROM conversations c
    INNER JOIN conversation_participants cp1 ON cp1.conversation_id = c.id
    INNER JOIN conversation_participants cp2 ON cp2.conversation_id = c.id
    WHERE LOWER(cp1.user_id::text) = LOWER(current_user_id::text)
    AND LOWER(cp2.user_id::text) = LOWER(other_user_id::text)
    AND LOWER(cp1.user_id::text) != LOWER(cp2.user_id::text)
    AND (c.is_group = false OR c.is_group IS NULL)
    AND (
        SELECT COUNT(*)
        FROM conversation_participants cp3
        WHERE cp3.conversation_id = c.id
    ) = 2
    LIMIT 1;

    -- If no conversation exists, create one
    IF result_conversation_id IS NULL THEN
        -- Create conversation (SECURITY DEFINER bypasses RLS)
        INSERT INTO conversations (
            created_at, 
            updated_at, 
            is_group
        ) VALUES (
            NOW(),
            NOW(),
            false
        )
        RETURNING id INTO result_conversation_id;

        -- Add both participants (SECURITY DEFINER bypasses RLS)
        INSERT INTO conversation_participants (conversation_id, user_id, joined_at, last_read_at)
        VALUES (result_conversation_id, current_user_id, NOW(), NOW());
        
        INSERT INTO conversation_participants (conversation_id, user_id, joined_at, last_read_at)
        VALUES (result_conversation_id, other_user_id, NOW(), NOW());
        
        -- Verify both participants were added
        SELECT COUNT(*) INTO participant_count
        FROM conversation_participants cp
        WHERE cp.conversation_id = result_conversation_id;
        
        IF participant_count != 2 THEN
            RAISE EXCEPTION 'Failed to add both participants. Added: %', participant_count;
        END IF;
    END IF;

    RETURN result_conversation_id;
END;
$function$;

-- Function: send_message
-- Purpose: Send a message in a conversation
CREATE OR REPLACE FUNCTION public.send_message(p_conversation_id uuid, p_content text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'pg_catalog'
AS $function$
DECLARE
    message_id UUID;
    current_user_id UUID;
BEGIN
    -- Get current user ID
    current_user_id := auth.uid();
    
    -- Validate user is participant
    IF NOT EXISTS (
        SELECT 1 FROM conversation_participants
        WHERE conversation_id = p_conversation_id
        AND user_id = current_user_id
    ) THEN
        RAISE EXCEPTION 'Not a participant in this conversation';
    END IF;
    
    -- Insert message
    INSERT INTO messages (
        conversation_id,
        sender_id,
        content,
        created_at,
        updated_at,
        is_edited,
        is_deleted
    ) VALUES (
        p_conversation_id,
        current_user_id,
        p_content,
        NOW(),
        NOW(),
        false,
        false
    )
    RETURNING id INTO message_id;
    
    -- Update conversation last message info
    UPDATE conversations
    SET 
        last_message_at = NOW(),
        last_message_preview = LEFT(p_content, 100),
        updated_at = NOW()
    WHERE id = p_conversation_id;
    
    RETURN message_id;
END;
$function$;

-- Function: mark_conversation_as_read
-- Purpose: Mark all messages in a conversation as read
CREATE OR REPLACE FUNCTION public.mark_conversation_as_read(p_conversation_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'pg_catalog'
AS $function$
DECLARE
    current_user_id UUID;
BEGIN
    -- Get current user ID
    current_user_id := auth.uid();
    
    -- Update last read timestamp
    UPDATE conversation_participants
    SET last_read_at = NOW()
    WHERE conversation_id = p_conversation_id
    AND user_id = current_user_id;
    
    -- Check if update was successful
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Not a participant in this conversation';
    END IF;
END;
$function$;

-- Function: get_user_conversations
-- Purpose: Get all direct conversations for a user
CREATE OR REPLACE FUNCTION public.get_user_conversations(user_id_param uuid)
RETURNS TABLE(
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
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT 
    c.id as conversation_id,
    c.created_at as conversation_created_at,
    c.updated_at as conversation_updated_at,
    c.last_message_at as conversation_last_message_at,
    c.last_message_preview as conversation_last_message_preview,
    cp_other.id as participant_id,
    cp_other.user_id as participant_user_id,
    cp_other.joined_at as participant_joined_at,
    cp_other.last_read_at as participant_last_read_at,
    p.username as user_username,
    p.display_name as user_display_name,
    p.avatar_url as user_avatar_url,
    p.bio as user_bio
  FROM conversations c
  INNER JOIN conversation_participants cp_self 
    ON c.id = cp_self.conversation_id 
    AND cp_self.user_id = user_id_param
    AND (cp_self.hidden_for_user IS FALSE OR cp_self.hidden_for_user IS NULL)  -- Filter out hidden conversations
  LEFT JOIN conversation_participants cp_other 
    ON c.id = cp_other.conversation_id 
    AND cp_other.user_id != user_id_param
  LEFT JOIN profiles p 
    ON cp_other.user_id = p.id
  WHERE (c.is_group = false OR c.is_group IS NULL)  -- Only direct conversations
  ORDER BY c.last_message_at DESC NULLS LAST;
END;
$function$;

-- Function: create_group_chat
-- Purpose: Create a new group conversation
CREATE OR REPLACE FUNCTION public.create_group_chat(
    group_name_param text, 
    group_description_param text DEFAULT NULL::text, 
    member_ids uuid[] DEFAULT ARRAY[]::uuid[]
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'pg_catalog'
AS $function$
DECLARE
    new_conversation_id UUID;
    current_user_id UUID;
    member_id UUID;
BEGIN
    -- 現在のユーザーIDを取得
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- 新しい会話を作成（グループチャット）
    INSERT INTO conversations (
        is_group,
        group_name,
        group_description,
        created_by,
        created_at,
        updated_at
    ) VALUES (
        true,
        group_name_param,
        group_description_param,
        current_user_id,
        NOW(),
        NOW()
    ) RETURNING id INTO new_conversation_id;
    
    -- 作成者を参加者として追加
    INSERT INTO conversation_participants (
        conversation_id,
        user_id,
        joined_at
    ) VALUES (
        new_conversation_id,
        current_user_id,
        NOW()
    );
    
    -- 指定されたメンバーを追加
    FOREACH member_id IN ARRAY member_ids
    LOOP
        -- 重複を避けるため、作成者以外のメンバーのみ追加
        IF member_id != current_user_id THEN
            INSERT INTO conversation_participants (
                conversation_id,
                user_id,
                joined_at
            ) VALUES (
                new_conversation_id,
                member_id,
                NOW()
            );
        END IF;
    END LOOP;
    
    RETURN new_conversation_id;
END;
$function$;

-- Function: get_user_group_conversations
-- Purpose: Get all group conversations for a user
CREATE OR REPLACE FUNCTION public.get_user_group_conversations(user_id_param uuid)
RETURNS TABLE(
    id uuid, 
    is_group boolean, 
    group_name text, 
    group_description text, 
    group_avatar_url text, 
    created_by uuid, 
    created_at timestamp with time zone, 
    updated_at timestamp with time zone, 
    last_message_at timestamp with time zone, 
    last_message_content text, 
    last_message_sender_id uuid, 
    last_message_sender_username text, 
    unread_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        c.id,
        c.is_group,
        c.group_name,
        c.group_description,
        c.group_avatar_url,
        c.created_by,
        c.created_at,
        c.updated_at,
        c.last_message_at,
        NULL::text as last_message_content,  -- Use NULL since column doesn't exist
        NULL::uuid as last_message_sender_id,  -- Use NULL since column doesn't exist
        NULL::text as last_message_sender_username,  -- Use NULL since we can't join
        COALESCE(unread_counts.unread_count, 0) as unread_count
    FROM conversations c
    INNER JOIN group_members gm ON gm.conversation_id = c.id
    LEFT JOIN conversation_participants cp ON cp.conversation_id = c.id AND cp.user_id = user_id_param
    LEFT JOIN (
        SELECT 
            conversation_id,
            COUNT(*) as unread_count
        FROM messages m2
        WHERE m2.sender_id != user_id_param
        AND m2.created_at > COALESCE(
            (SELECT last_read_at FROM conversation_participants 
             WHERE conversation_id = m2.conversation_id AND user_id = user_id_param), 
            '1970-01-01'::timestamp
        )
        GROUP BY conversation_id
    ) unread_counts ON unread_counts.conversation_id = c.id
    WHERE gm.user_id = user_id_param
    AND c.is_group = TRUE
    AND (cp.hidden_for_user IS FALSE OR cp.hidden_for_user IS NULL)  -- Filter out hidden group conversations
    ORDER BY c.last_message_at DESC NULLS LAST;
END;
$function$;

-- ======================================================================
-- SOCIAL FUNCTIONS
-- ======================================================================

-- Function: increment_like_count
-- Purpose: Increment like count when a post is liked
CREATE OR REPLACE FUNCTION public.increment_like_count(post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'auth'
AS $function$
BEGIN
    -- Check rate limit
    IF NOT public.check_rate_limit(auth.uid(), 'like_action', 60, 1) THEN
        RAISE EXCEPTION 'RATE_LIMIT_EXCEEDED: Too many like actions';
    END IF;
    
    UPDATE public.posts 
    SET like_count = like_count + 1 
    WHERE id = post_id;
END;
$function$;

-- Function: decrement_like_count
-- Purpose: Decrement like count when a post is unliked
CREATE OR REPLACE FUNCTION public.decrement_like_count(post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'auth'
AS $function$
BEGIN
  UPDATE public.posts 
  SET like_count = GREATEST(like_count - 1, 0)
  WHERE id = post_id;
END;
$function$;

-- Function: create_follow
-- Purpose: Create a follow relationship between users
CREATE OR REPLACE FUNCTION public.create_follow(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'auth'
AS $function$
BEGIN
    -- Check rate limit
    IF NOT public.check_rate_limit(auth.uid(), 'follow_action', 20, 60) THEN
        RAISE EXCEPTION 'RATE_LIMIT_EXCEEDED: Too many follow actions';
    END IF;
    
    INSERT INTO public.follows (follower_id, following_id)
    VALUES (auth.uid(), target_user_id);
END;
$function$;

-- Function: get_posts_with_like_status
-- Purpose: Get posts with like status for current user
CREATE OR REPLACE FUNCTION public.get_posts_with_like_status(target_user_id uuid)
RETURNS TABLE(
    id uuid, 
    user_id uuid, 
    media_url text, 
    media_type text, 
    caption text, 
    location_name text, 
    latitude double precision, 
    longitude double precision, 
    is_public boolean, 
    created_at timestamp with time zone, 
    like_count integer, 
    comment_count integer, 
    is_liked_by_me boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'auth'
AS $function$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.user_id,
    p.media_url,
    p.media_type,
    p.caption,
    p.location_name,
    p.latitude,
    p.longitude,
    p.is_public,
    p.created_at,
    p.like_count,
    p.comment_count,
    CASE 
      WHEN l.id IS NOT NULL THEN true 
      ELSE false 
    END as is_liked_by_me
  FROM public.posts p
  LEFT JOIN public.likes l ON p.id = l.post_id AND l.user_id = target_user_id
  WHERE p.is_public = true
  ORDER BY p.created_at DESC;
END;
$function$;

-- ======================================================================
-- UTILITY FUNCTIONS
-- ======================================================================

-- Function: sanitize_text_input
-- Purpose: Sanitize user input to prevent XSS and SQL injection
CREATE OR REPLACE FUNCTION public.sanitize_text_input(input_text text, max_length integer DEFAULT 1000)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $function$
BEGIN
    IF input_text IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Remove potential SQL injection patterns
    input_text := regexp_replace(input_text, '(\-\-|\;|\||\*|\/\*|\*\/)', '', 'gi');
    
    -- Remove script tags and potential XSS
    input_text := regexp_replace(input_text, '<script[^>]*>.*?</script>', '', 'gi');
    input_text := regexp_replace(input_text, 'javascript:', '', 'gi');
    input_text := regexp_replace(input_text, 'on\w+\s*=', '', 'gi');
    
    -- Limit length
    IF length(input_text) > max_length THEN
        input_text := substring(input_text, 1, max_length);
    END IF;
    
    RETURN trim(input_text);
END;
$function$;

-- Function: validate_uuid_input
-- Purpose: Validate UUID format
CREATE OR REPLACE FUNCTION public.validate_uuid_input(input_text text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $function$
BEGIN
    IF input_text IS NULL OR input_text = '' THEN
        RETURN false;
    END IF;
    
    -- Check UUID format
    IF input_text !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        RETURN false;
    END IF;
    
    RETURN true;
END;
$function$;

-- Function: cleanup_expired_data
-- Purpose: Clean up expired data based on retention policies
CREATE OR REPLACE FUNCTION public.cleanup_expired_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $function$
DECLARE
    policy_record record;
    cleanup_count integer;
BEGIN
    FOR policy_record IN 
        SELECT table_name, retention_days 
        FROM public.data_retention_policies 
        WHERE auto_delete = true
    LOOP
        CASE policy_record.table_name
            WHEN 'security_logs' THEN
                DELETE FROM public.security_logs 
                WHERE created_at < now() - (policy_record.retention_days || ' days')::interval;
                GET DIAGNOSTICS cleanup_count = ROW_COUNT;
                
            WHEN 'rate_limits' THEN
                DELETE FROM public.rate_limits 
                WHERE created_at < now() - (policy_record.retention_days || ' days')::interval;
                GET DIAGNOSTICS cleanup_count = ROW_COUNT;
        END CASE;
        
        -- Log cleanup activity
        IF cleanup_count > 0 THEN
            PERFORM public.log_security_event(
                NULL,
                'data_cleanup',
                format('Cleaned up %s records from %s', cleanup_count, policy_record.table_name),
                NULL, NULL,
                jsonb_build_object(
                    'table', policy_record.table_name,
                    'records_deleted', cleanup_count,
                    'retention_days', policy_record.retention_days
                ),
                'low'
            );
        END IF;
    END LOOP;
END;
$function$;

-- ======================================================================
-- TRIGGERS
-- ======================================================================

-- Function: update_conversation_last_message
-- Purpose: Update conversation when new message is sent
CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'pg_catalog'
AS $function$
BEGIN
  UPDATE conversations
  SET 
    last_message_at = NEW.created_at,
    last_message_preview = NEW.content
  WHERE id = NEW.conversation_id;
  
  RETURN NEW;
END;
$function$;

-- Create trigger for message updates
DROP TRIGGER IF EXISTS update_conversation_on_new_message ON messages;
CREATE TRIGGER update_conversation_on_new_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_last_message();

-- Function: manage_conversation_participant_deletion
-- Purpose: Clean up conversation when last participant leaves
CREATE OR REPLACE FUNCTION public.manage_conversation_participant_deletion()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'pg_catalog'
AS $function$
BEGIN
  -- Check if this is the last participant
  IF NOT EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = OLD.conversation_id
    AND user_id != OLD.user_id
  ) THEN
    -- Delete the conversation if no participants left
    DELETE FROM conversations WHERE id = OLD.conversation_id;
  END IF;
  
  RETURN OLD;
END;
$function$;

-- Create trigger for participant deletion
DROP TRIGGER IF EXISTS manage_participant_deletion ON conversation_participants;
CREATE TRIGGER manage_participant_deletion
    AFTER DELETE ON conversation_participants
    FOR EACH ROW
    EXECUTE FUNCTION manage_conversation_participant_deletion();

-- ======================================================================
-- VIEWS
-- ======================================================================

-- View: user_conversations_view
-- Purpose: View for accessing user conversations with participant info
CREATE OR REPLACE VIEW public.user_conversations_view AS
SELECT 
    c.id AS conversation_id,
    c.created_at AS conversation_created_at,
    c.updated_at AS conversation_updated_at,
    c.last_message_at,
    c.last_message_preview,
    cp.id AS participant_id,
    cp.user_id AS participant_user_id,
    cp.joined_at AS participant_joined_at,
    cp.last_read_at AS participant_last_read_at,
    p.username AS user_username,
    p.display_name AS user_display_name,
    p.avatar_url AS user_avatar_url,
    p.bio AS user_bio,
    (auth.uid())::text AS current_user_id
FROM conversations c
JOIN conversation_participants cp ON c.id = cp.conversation_id
JOIN profiles p ON cp.user_id = p.id
WHERE c.id IN (
    SELECT conversation_id
    FROM conversation_participants
    WHERE user_id = auth.uid() 
    AND (hidden_for_user IS FALSE OR hidden_for_user IS NULL)
) 
AND cp.user_id <> auth.uid()
ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC;

-- View: accessible_conversation_participants
-- Purpose: View for accessing conversation participants with security
CREATE OR REPLACE VIEW public.accessible_conversation_participants AS
SELECT DISTINCT 
    id,
    conversation_id,
    user_id,
    joined_at,
    last_read_at
FROM conversation_participants cp
WHERE EXISTS (
    SELECT 1
    FROM conversation_participants cp_check
    WHERE cp_check.conversation_id = cp.conversation_id 
    AND cp_check.user_id = auth.uid()
);