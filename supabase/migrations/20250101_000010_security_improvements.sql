-- ======================================================================
-- Migration: 20250101_000010_security_improvements.sql
-- Purpose: Security improvements and RLS policy updates
-- Dependencies: multiple tables
-- ======================================================================


-- 1. Drop potentially unsafe security definer view
DROP VIEW IF EXISTS user_conversations_view;

-- 2. Add missing indexes for foreign keys (performance & security)
CREATE INDEX IF NOT EXISTS idx_article_views_user_id ON article_views(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_favorites_post_id ON favorites(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_post_id ON likes(post_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_user_id ON messages(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_related_user_id ON notifications(related_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_related_post_id ON notifications(related_post_id);

-- 3. Improve RLS policy performance by optimizing auth.uid() calls
-- Update profiles policies for better performance
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- More performant profile policies
CREATE POLICY "Public profiles viewable by everyone" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING ((SELECT auth.uid()) = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK ((SELECT auth.uid()) = id);

-- 4. Improve posts security
DROP POLICY IF EXISTS "Posts are viewable by everyone" ON posts;
CREATE POLICY "Posts are viewable by everyone" ON posts
    FOR SELECT USING (true);

-- 5. Add additional security for sensitive operations
CREATE POLICY "Users can only delete own posts" ON posts
    FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- 6. Improve notifications security
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- 7. Improve follows security
DROP POLICY IF EXISTS "Users can view follows they are involved in" ON follows;
CREATE POLICY "Users can view follows they are involved in" ON follows
    FOR SELECT USING (
        (SELECT auth.uid()) = follower_id OR 
        (SELECT auth.uid()) = following_id
    );

-- 8. Add security logging table for audit trail
CREATE TABLE IF NOT EXISTS security_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB
);

-- Enable RLS on audit log
ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;

-- Only service role can access audit logs
CREATE POLICY "Service role only access" ON security_audit_log
    FOR ALL USING (false);

-- Grant service role access
GRANT ALL ON security_audit_log TO service_role;

-- 9. Create function to log security events
CREATE OR REPLACE FUNCTION log_security_event(
    p_action TEXT,
    p_resource_type TEXT,
    p_resource_id TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

-- 10. Add rate limiting table
CREATE TABLE IF NOT EXISTS rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    action_type TEXT NOT NULL,
    count INTEGER DEFAULT 1,
    window_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for rate limiting queries
CREATE INDEX IF NOT EXISTS idx_rate_limits_user_action ON rate_limits(user_id, action_type, window_start);

-- Enable RLS
ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;

-- Users can only see their own rate limit data
CREATE POLICY "Users can view own rate limits" ON rate_limits
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- Service role can manage rate limits
CREATE POLICY "Service can manage rate limits" ON rate_limits
    FOR ALL USING (true);

-- Grant permissions
GRANT SELECT ON rate_limits TO authenticated;
GRANT ALL ON rate_limits TO service_role;

-- Comments for documentation
COMMENT ON TABLE security_audit_log IS 'Audit trail for security-sensitive operations';
COMMENT ON TABLE rate_limits IS 'Rate limiting data for API protection';
