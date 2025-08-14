--======================================================================
-- MARK: - Rollback Migration for RPC Functions Refactoring
-- Purpose: Rollback script to restore original functions if needed
-- Path: supabase/migrations/20250813_000006_rollback_refactoring.sql
--======================================================================

-- WARNING: This is a rollback script. Only run if you need to revert the refactoring.
-- To use: Rename this file to have a newer timestamp than the refactoring migrations
-- and run it as a regular migration.

-- Restore original cleanup functions
CREATE OR REPLACE FUNCTION public.cleanup_expired_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
$$;

CREATE OR REPLACE FUNCTION public.cleanup_rate_limits_unified(retention_hours integer DEFAULT 2)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count integer;
BEGIN
    DELETE FROM public.rate_limits
    WHERE window_start < now() - (retention_hours || ' hours')::interval;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    IF deleted_count > 0 THEN
        PERFORM public.log_security_event(
            NULL,
            'rate_limit_cleanup',
            format('Cleaned up %s rate limit records older than %s hours', deleted_count, retention_hours),
            NULL, NULL,
            jsonb_build_object(
                'records_deleted', deleted_count,
                'retention_hours', retention_hours
            ),
            'low'
        );
    END IF;
    
    RETURN deleted_count;
END;
$$;

-- Restore original counter functions
CREATE OR REPLACE FUNCTION public.increment_like_count(post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT public.check_rate_limit(auth.uid(), 'like_action', 60, 30) THEN
        RAISE EXCEPTION 'RATE_LIMIT_EXCEEDED: Too many like actions. Please wait a moment before trying again.';
    END IF;
    
    UPDATE public.posts 
    SET like_count = like_count + 1 
    WHERE id = post_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'POST_NOT_FOUND: Post not found or you do not have permission to like it.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_like_count(post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT public.check_rate_limit(auth.uid(), 'unlike_action', 60, 30) THEN
        RAISE EXCEPTION 'RATE_LIMIT_EXCEEDED: Too many unlike actions. Please wait a moment before trying again.';
    END IF;
    
    UPDATE public.posts 
    SET like_count = GREATEST(0, like_count - 1)
    WHERE id = post_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'POST_NOT_FOUND: Post not found or you do not have permission to unlike it.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.increment_comment_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE posts 
    SET comment_count = comment_count + 1,
        updated_at = NOW()
    WHERE id = NEW.post_id;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_comment_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE posts 
    SET comment_count = GREATEST(comment_count - 1, 0),
        updated_at = NOW()
    WHERE id = OLD.post_id;
    RETURN OLD;
END;
$$;

-- Restore original validation functions
CREATE OR REPLACE FUNCTION public.validate_uuid_input(input_text text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF input_text IS NULL THEN
        RETURN false;
    END IF;
    
    IF input_text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        RETURN true;
    ELSE
        RETURN false;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.sanitize_text_input(input_text text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF input_text IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Basic sanitization: remove HTML tags and trim
    RETURN trim(regexp_replace(input_text, '<[^>]*>', '', 'g'));
END;
$$;

-- Drop new functions created by refactoring
DROP FUNCTION IF EXISTS public.cleanup_data_by_retention CASCADE;
DROP FUNCTION IF EXISTS public.cleanup_rate_limits CASCADE;
DROP FUNCTION IF EXISTS public.cleanup_security_logs CASCADE;
DROP FUNCTION IF EXISTS public.run_scheduled_cleanups CASCADE;
DROP FUNCTION IF EXISTS public.update_counter CASCADE;
DROP FUNCTION IF EXISTS public.update_post_counter CASCADE;
DROP FUNCTION IF EXISTS public.auto_increment_comment_count CASCADE;
DROP FUNCTION IF EXISTS public.auto_decrement_comment_count CASCADE;
DROP FUNCTION IF EXISTS public.find_existing_conversation CASCADE;
DROP FUNCTION IF EXISTS public.create_new_conversation CASCADE;
DROP FUNCTION IF EXISTS public.reset_conversation_visibility CASCADE;
DROP FUNCTION IF EXISTS public.get_conversations_with_metadata CASCADE;
DROP FUNCTION IF EXISTS public.validate_input CASCADE;
DROP FUNCTION IF EXISTS public.sanitize_user_content CASCADE;
DROP FUNCTION IF EXISTS public.validate_multiple_inputs CASCADE;

-- Restore original triggers
DROP TRIGGER IF EXISTS increment_comment_count_trigger ON comments;
DROP TRIGGER IF EXISTS decrement_comment_count_trigger ON comments;

CREATE TRIGGER increment_comment_count_trigger
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION public.increment_comment_count();

CREATE TRIGGER decrement_comment_count_trigger
    AFTER DELETE ON comments
    FOR EACH ROW
    EXECUTE FUNCTION public.decrement_comment_count();

-- Log rollback completion
DO $$
BEGIN
    PERFORM public.log_security_event(
        NULL,
        'refactoring_rollback',
        'RPC functions refactoring has been rolled back to original state',
        NULL, NULL,
        jsonb_build_object(
            'rollback_time', now(),
            'functions_restored', ARRAY[
                'cleanup_expired_data',
                'cleanup_rate_limits_unified',
                'increment_like_count',
                'decrement_like_count',
                'increment_comment_count',
                'decrement_comment_count',
                'validate_uuid_input',
                'sanitize_text_input'
            ]
        ),
        'medium'
    );
    
    RAISE NOTICE 'RPC functions refactoring rollback completed successfully';
END;
$$;

-- Add comment
COMMENT ON SCHEMA public IS 'RPC functions restored to original state after rollback';