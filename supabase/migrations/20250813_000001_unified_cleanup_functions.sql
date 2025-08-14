--======================================================================
-- MARK: - Unified Cleanup Functions Migration
-- Purpose: Consolidate cleanup functions into a single configurable function
-- Path: supabase/migrations/20250813_000001_unified_cleanup_functions.sql
--======================================================================

-- Drop existing cleanup functions if they exist
DROP FUNCTION IF EXISTS public.cleanup_expired_data();
DROP FUNCTION IF EXISTS public.cleanup_rate_limits_unified(integer);

-- Create unified cleanup function with configurable retention
CREATE OR REPLACE FUNCTION public.cleanup_data_by_retention(
    p_table_name text,
    p_retention_hours integer DEFAULT 24,
    p_date_column text DEFAULT 'created_at'
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    deleted_count integer;
    query_text text;
BEGIN
    -- Validate input parameters
    IF p_table_name IS NULL OR p_table_name = '' THEN
        RAISE EXCEPTION 'Table name cannot be null or empty';
    END IF;
    
    IF p_retention_hours <= 0 THEN
        RAISE EXCEPTION 'Retention hours must be positive';
    END IF;
    
    IF p_date_column IS NULL OR p_date_column = '' THEN
        RAISE EXCEPTION 'Date column cannot be null or empty';
    END IF;
    
    -- Validate table exists and user has permission
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = p_table_name
    ) THEN
        RAISE EXCEPTION 'Table % does not exist', p_table_name;
    END IF;
    
    -- Validate column exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = p_table_name 
        AND column_name = p_date_column
    ) THEN
        RAISE EXCEPTION 'Column % does not exist in table %', p_date_column, p_table_name;
    END IF;
    
    -- Build and execute dynamic SQL
    query_text := format(
        'DELETE FROM public.%I WHERE %I < now() - interval ''%s hours''',
        p_table_name,
        p_date_column,
        p_retention_hours
    );
    
    EXECUTE query_text;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Log cleanup activity if records were deleted
    IF deleted_count > 0 THEN
        PERFORM public.log_security_event(
            NULL,
            'data_cleanup',
            format('Cleaned up %s records from %s older than %s hours', 
                   deleted_count, p_table_name, p_retention_hours),
            NULL, NULL,
            jsonb_build_object(
                'table', p_table_name,
                'records_deleted', deleted_count,
                'retention_hours', p_retention_hours,
                'date_column', p_date_column
            ),
            'low'
        );
    END IF;
    
    RETURN deleted_count;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log error and re-raise
        PERFORM public.log_security_event(
            NULL,
            'cleanup_error',
            format('Error cleaning up table %s: %s', p_table_name, SQLERRM),
            NULL, NULL,
            jsonb_build_object(
                'table', p_table_name,
                'retention_hours', p_retention_hours,
                'error', SQLERRM
            ),
            'high'
        );
        RAISE;
END;
$$;

-- Create convenience functions for common cleanup tasks
CREATE OR REPLACE FUNCTION public.cleanup_rate_limits(
    p_retention_hours integer DEFAULT 2
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN public.cleanup_data_by_retention('rate_limits', p_retention_hours, 'window_start');
END;
$$;

CREATE OR REPLACE FUNCTION public.cleanup_security_logs(
    p_retention_days integer DEFAULT 90
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN public.cleanup_data_by_retention('security_logs', p_retention_days * 24, 'created_at');
END;
$$;

-- Create scheduled cleanup job (PostgreSQL cron extension required)
-- This should be run by a scheduled job or external cron
CREATE OR REPLACE FUNCTION public.run_scheduled_cleanups()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    cleanup_config jsonb;
    config_record record;
    total_deleted integer := 0;
BEGIN
    -- Define cleanup configuration
    cleanup_config := jsonb_build_array(
        jsonb_build_object('table', 'rate_limits', 'hours', 2, 'column', 'window_start'),
        jsonb_build_object('table', 'security_logs', 'hours', 2160, 'column', 'created_at'), -- 90 days
        jsonb_build_object('table', 'notifications', 'hours', 720, 'column', 'created_at') -- 30 days for read notifications
    );
    
    -- Run cleanup for each configured table
    FOR config_record IN SELECT * FROM jsonb_array_elements(cleanup_config) AS config
    LOOP
        BEGIN
            total_deleted := total_deleted + public.cleanup_data_by_retention(
                config_record.config->>'table',
                (config_record.config->>'hours')::integer,
                config_record.config->>'column'
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- Continue with other cleanups even if one fails
                RAISE NOTICE 'Cleanup failed for %: %', 
                    config_record.config->>'table', SQLERRM;
        END;
    END LOOP;
    
    -- Log summary
    IF total_deleted > 0 THEN
        PERFORM public.log_security_event(
            NULL,
            'scheduled_cleanup_complete',
            format('Scheduled cleanup completed. Total records deleted: %s', total_deleted),
            NULL, NULL,
            jsonb_build_object('total_deleted', total_deleted),
            'low'
        );
    END IF;
END;
$$;

-- Grant appropriate permissions
GRANT EXECUTE ON FUNCTION public.cleanup_data_by_retention TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_rate_limits TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_security_logs TO service_role;
GRANT EXECUTE ON FUNCTION public.run_scheduled_cleanups TO service_role;

-- Add comments for documentation
COMMENT ON FUNCTION public.cleanup_data_by_retention IS 'Unified cleanup function for removing old records based on retention policy';
COMMENT ON FUNCTION public.cleanup_rate_limits IS 'Convenience function to cleanup rate limit records';
COMMENT ON FUNCTION public.cleanup_security_logs IS 'Convenience function to cleanup security log records';
COMMENT ON FUNCTION public.run_scheduled_cleanups IS 'Run all scheduled cleanup tasks based on configuration';