--======================================================================
-- MARK: - Unified Counter Management Migration
-- Purpose: Consolidate counter increment/decrement functions into a single configurable function
-- Path: supabase/migrations/20250813_000002_unified_counter_management.sql
--======================================================================

-- Create unified counter update function
CREATE OR REPLACE FUNCTION public.update_counter(
    p_table_name text,
    p_record_id uuid,
    p_counter_column text,
    p_increment_value integer DEFAULT 1,
    p_rate_limit_config jsonb DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    query_text text;
    updated_rows integer;
    rate_limit_action text;
    rate_limit_window integer;
    rate_limit_max_requests integer;
BEGIN
    -- Validate input parameters
    IF p_table_name IS NULL OR p_table_name = '' THEN
        RAISE EXCEPTION 'Table name cannot be null or empty';
    END IF;
    
    IF p_record_id IS NULL THEN
        RAISE EXCEPTION 'Record ID cannot be null';
    END IF;
    
    IF p_counter_column IS NULL OR p_counter_column = '' THEN
        RAISE EXCEPTION 'Counter column cannot be null or empty';
    END IF;
    
    -- Apply rate limiting if configured
    IF p_rate_limit_config IS NOT NULL THEN
        rate_limit_action := p_rate_limit_config->>'action';
        rate_limit_window := COALESCE((p_rate_limit_config->>'window_seconds')::integer, 60);
        rate_limit_max_requests := COALESCE((p_rate_limit_config->>'max_requests')::integer, 30);
        
        IF rate_limit_action IS NOT NULL THEN
            IF NOT public.check_rate_limit(
                auth.uid(), 
                rate_limit_action, 
                rate_limit_window, 
                rate_limit_max_requests
            ) THEN
                RAISE EXCEPTION 'RATE_LIMIT_EXCEEDED: Too many % actions. Please wait before trying again.', rate_limit_action;
            END IF;
        END IF;
    END IF;
    
    -- Validate table and column exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = p_table_name
    ) THEN
        RAISE EXCEPTION 'Table % does not exist', p_table_name;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = p_table_name 
        AND column_name = p_counter_column
    ) THEN
        RAISE EXCEPTION 'Column % does not exist in table %', p_counter_column, p_table_name;
    END IF;
    
    -- Build and execute dynamic SQL
    -- Ensure counter doesn't go below 0
    query_text := format(
        'UPDATE public.%I SET %I = GREATEST(0, %I + $1), updated_at = NOW() WHERE id = $2',
        p_table_name,
        p_counter_column,
        p_counter_column
    );
    
    EXECUTE query_text USING p_increment_value, p_record_id;
    GET DIAGNOSTICS updated_rows = ROW_COUNT;
    
    -- Verify the update worked
    IF updated_rows = 0 THEN
        RAISE EXCEPTION 'RECORD_NOT_FOUND: Record % not found in table % or you do not have permission to update it.', 
            p_record_id, p_table_name;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log error for debugging
        PERFORM public.log_security_event(
            auth.uid(),
            'counter_update_error',
            format('Error updating counter %s in table %s: %s', 
                   p_counter_column, p_table_name, SQLERRM),
            NULL, NULL,
            jsonb_build_object(
                'table', p_table_name,
                'record_id', p_record_id,
                'counter_column', p_counter_column,
                'increment_value', p_increment_value,
                'error', SQLERRM
            ),
            'medium'
        );
        RAISE;
END;
$$;

-- Create specific counter functions for posts (maintaining backward compatibility)
CREATE OR REPLACE FUNCTION public.update_post_counter(
    p_post_id uuid,
    p_counter_type text,  -- 'like', 'comment', 'share', 'view'
    p_increment integer DEFAULT 1
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    counter_column text;
    rate_limit_config jsonb;
BEGIN
    -- Map counter type to column name
    CASE p_counter_type
        WHEN 'like' THEN
            counter_column := 'like_count';
            -- Configure rate limiting for likes
            rate_limit_config := jsonb_build_object(
                'action', CASE WHEN p_increment > 0 THEN 'like_action' ELSE 'unlike_action' END,
                'window_seconds', 60,
                'max_requests', 30
            );
        WHEN 'comment' THEN
            counter_column := 'comment_count';
            -- Comments might have different rate limits
            rate_limit_config := jsonb_build_object(
                'action', 'comment_action',
                'window_seconds', 60,
                'max_requests', 10
            );
        WHEN 'share' THEN
            counter_column := 'share_count';
            rate_limit_config := jsonb_build_object(
                'action', 'share_action',
                'window_seconds', 60,
                'max_requests', 5
            );
        WHEN 'view' THEN
            counter_column := 'view_count';
            -- Views typically don't need rate limiting
            rate_limit_config := NULL;
        ELSE
            RAISE EXCEPTION 'Invalid counter type: %. Valid types are: like, comment, share, view', p_counter_type;
    END CASE;
    
    -- Call the generic counter update function
    PERFORM public.update_counter(
        'posts',
        p_post_id,
        counter_column,
        p_increment,
        rate_limit_config
    );
END;
$$;

-- Create trigger functions for automatic counter updates
CREATE OR REPLACE FUNCTION public.auto_increment_comment_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    PERFORM public.update_post_counter(NEW.post_id, 'comment', 1);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.auto_decrement_comment_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    PERFORM public.update_post_counter(OLD.post_id, 'comment', -1);
    RETURN OLD;
END;
$$;

-- Drop old trigger functions if they exist
DROP TRIGGER IF EXISTS increment_comment_count_trigger ON comments;
DROP TRIGGER IF EXISTS decrement_comment_count_trigger ON comments;

-- Create new triggers using the unified functions
CREATE TRIGGER increment_comment_count_trigger
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_increment_comment_count();

CREATE TRIGGER decrement_comment_count_trigger
    AFTER DELETE ON comments
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_decrement_comment_count();

-- Create backward compatibility wrapper functions
CREATE OR REPLACE FUNCTION public.increment_like_count(post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    PERFORM public.update_post_counter(post_id, 'like', 1);
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_like_count(post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    PERFORM public.update_post_counter(post_id, 'like', -1);
END;
$$;

-- Drop old trigger functions
DROP FUNCTION IF EXISTS public.increment_comment_count() CASCADE;
DROP FUNCTION IF EXISTS public.decrement_comment_count() CASCADE;

-- Grant appropriate permissions
GRANT EXECUTE ON FUNCTION public.update_counter TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_post_counter TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_like_count TO authenticated;
GRANT EXECUTE ON FUNCTION public.decrement_like_count TO authenticated;

-- Add comments for documentation
COMMENT ON FUNCTION public.update_counter IS 'Generic counter update function with rate limiting support';
COMMENT ON FUNCTION public.update_post_counter IS 'Specific counter update function for posts table';
COMMENT ON FUNCTION public.increment_like_count IS 'Backward compatibility wrapper for incrementing post likes';
COMMENT ON FUNCTION public.decrement_like_count IS 'Backward compatibility wrapper for decrementing post likes';