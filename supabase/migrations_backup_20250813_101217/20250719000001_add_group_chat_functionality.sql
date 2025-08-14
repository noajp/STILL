-- ======================================================================
-- Group Chat Database Schema for STILL
-- Purpose: Add group chat functionality to existing messaging system
-- Migration: 20250719000001_add_group_chat_functionality
-- ======================================================================

-- Update conversations table to support group chats
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS is_group BOOLEAN DEFAULT FALSE;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS group_name TEXT;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS group_description TEXT;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS group_avatar_url TEXT;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- Create group_members table to handle multiple participants
CREATE TABLE IF NOT EXISTS group_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

-- Enable RLS for group_members
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- RLS policies for group_members
CREATE POLICY "Users can view group members of groups they belong to" ON group_members
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM group_members gm2 
            WHERE gm2.conversation_id = group_members.conversation_id
        )
    );

CREATE POLICY "Group admins can manage members" ON group_members
    FOR ALL USING (
        auth.uid() IN (
            SELECT user_id FROM group_members gm2 
            WHERE gm2.conversation_id = group_members.conversation_id 
            AND gm2.role = 'admin'
        )
    );

-- Function to create a group chat
CREATE OR REPLACE FUNCTION create_group_chat(
    group_name_param TEXT,
    group_description_param TEXT DEFAULT NULL,
    member_ids UUID[] DEFAULT ARRAY[]::UUID[]
) RETURNS UUID AS $$
DECLARE
    new_conversation_id UUID;
    member_id UUID;
BEGIN
    -- Create the conversation
    INSERT INTO conversations (is_group, group_name, group_description, created_by)
    VALUES (TRUE, group_name_param, group_description_param, auth.uid())
    RETURNING id INTO new_conversation_id;
    
    -- Add the creator as an admin
    INSERT INTO group_members (conversation_id, user_id, role)
    VALUES (new_conversation_id, auth.uid(), 'admin');
    
    -- Add other members
    FOREACH member_id IN ARRAY member_ids
    LOOP
        INSERT INTO group_members (conversation_id, user_id, role)
        VALUES (new_conversation_id, member_id, 'member')
        ON CONFLICT (conversation_id, user_id) DO NOTHING;
    END LOOP;
    
    RETURN new_conversation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add member to group
CREATE OR REPLACE FUNCTION add_group_member(
    conversation_id_param UUID,
    user_id_param UUID
) RETURNS BOOLEAN AS $$
BEGIN
    -- Check if current user is admin of the group
    IF NOT EXISTS (
        SELECT 1 FROM group_members 
        WHERE conversation_id = conversation_id_param 
        AND user_id = auth.uid() 
        AND role = 'admin'
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Add the member
    INSERT INTO group_members (conversation_id, user_id, role)
    VALUES (conversation_id_param, user_id_param, 'member')
    ON CONFLICT (conversation_id, user_id) DO NOTHING;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove member from group
CREATE OR REPLACE FUNCTION remove_group_member(
    conversation_id_param UUID,
    user_id_param UUID
) RETURNS BOOLEAN AS $$
BEGIN
    -- Check if current user is admin or removing themselves
    IF NOT (
        auth.uid() = user_id_param OR 
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE conversation_id = conversation_id_param 
            AND user_id = auth.uid() 
            AND role = 'admin'
        )
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Remove the member
    DELETE FROM group_members 
    WHERE conversation_id = conversation_id_param 
    AND user_id = user_id_param;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's group conversations
CREATE OR REPLACE FUNCTION get_user_group_conversations(user_id_param uuid)
RETURNS TABLE (
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
) AS $$
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
        c.last_message_content,
        c.last_message_sender_id,
        lmu.username as last_message_sender_username,
        COALESCE(unread_counts.unread_count, 0) as unread_count
    FROM conversations c
    INNER JOIN group_members gm ON gm.conversation_id = c.id
    LEFT JOIN profiles lmu ON lmu.id = c.last_message_sender_id
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
    ORDER BY c.last_message_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update existing get_user_conversations to exclude group chats
CREATE OR REPLACE FUNCTION get_user_conversations(user_id_param uuid)
RETURNS TABLE (
    id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    last_message_at timestamp with time zone,
    last_message_content text,
    last_message_sender_id uuid,
    other_user_id uuid,
    other_user_username text,
    other_user_avatar_url text,
    unread_count bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        c.id,
        c.created_at,
        c.updated_at,
        c.last_message_at,
        c.last_message_content,
        c.last_message_sender_id,
        other_users.id as other_user_id,
        other_users.username as other_user_username,
        other_users.avatar_url as other_user_avatar_url,
        COALESCE(unread_counts.unread_count, 0) as unread_count
    FROM conversations c
    INNER JOIN conversation_participants cp1 ON cp1.conversation_id = c.id
    INNER JOIN conversation_participants cp2 ON cp2.conversation_id = c.id
    INNER JOIN profiles other_users ON other_users.id = cp2.user_id
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
    WHERE cp1.user_id = user_id_param
    AND cp2.user_id != user_id_param
    AND (c.is_group = FALSE OR c.is_group IS NULL)
    ORDER BY c.last_message_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;