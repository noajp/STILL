--======================================================================
-- MARK: - Comprehensive Validation and Sanitization Functions
-- Purpose: Create unified validation and sanitization functions for better security
-- Path: supabase/migrations/20250813_000004_comprehensive_validation_functions.sql
--======================================================================

-- Drop existing validation functions if they exist
DROP FUNCTION IF EXISTS public.validate_uuid_input(text);
DROP FUNCTION IF EXISTS public.sanitize_text_input(text);

-- Create comprehensive input validation function
CREATE OR REPLACE FUNCTION public.validate_input(
    p_input_value text,
    p_validation_type text,
    p_additional_rules jsonb DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_min_length integer;
    v_max_length integer;
    v_pattern text;
    v_custom_message text;
BEGIN
    -- Handle NULL input
    IF p_input_value IS NULL THEN
        -- Check if NULL is allowed
        IF p_additional_rules IS NOT NULL AND 
           COALESCE((p_additional_rules->>'allow_null')::boolean, false) THEN
            RETURN true;
        END IF;
        RETURN false;
    END IF;
    
    -- Extract additional rules
    v_min_length := COALESCE((p_additional_rules->>'min_length')::integer, 0);
    v_max_length := COALESCE((p_additional_rules->>'max_length')::integer, 2147483647);
    v_pattern := p_additional_rules->>'pattern';
    v_custom_message := p_additional_rules->>'error_message';
    
    -- Check length constraints
    IF length(p_input_value) < v_min_length OR length(p_input_value) > v_max_length THEN
        IF v_custom_message IS NOT NULL THEN
            RAISE EXCEPTION '%', v_custom_message;
        ELSE
            RAISE EXCEPTION 'Input length must be between % and % characters', v_min_length, v_max_length;
        END IF;
    END IF;
    
    -- Validate based on type
    CASE p_validation_type
        WHEN 'uuid' THEN
            -- UUID validation
            IF NOT p_input_value ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
                RAISE EXCEPTION 'Invalid UUID format';
            END IF;
            
        WHEN 'email' THEN
            -- Email validation (RFC 5322 simplified)
            IF NOT p_input_value ~* '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
                RAISE EXCEPTION 'Invalid email format';
            END IF;
            
        WHEN 'username' THEN
            -- Username validation (alphanumeric, underscore, dash, 3-30 chars)
            IF NOT p_input_value ~* '^[a-zA-Z0-9_-]{3,30}$' THEN
                RAISE EXCEPTION 'Username must be 3-30 characters and contain only letters, numbers, underscore, and dash';
            END IF;
            
        WHEN 'phone' THEN
            -- Phone number validation (international format)
            IF NOT p_input_value ~* '^\+?[1-9]\d{1,14}$' THEN
                RAISE EXCEPTION 'Invalid phone number format';
            END IF;
            
        WHEN 'url' THEN
            -- URL validation
            IF NOT p_input_value ~* '^https?://[a-zA-Z0-9][-a-zA-Z0-9._]*[a-zA-Z0-9](:[0-9]+)?(/.*)?$' THEN
                RAISE EXCEPTION 'Invalid URL format';
            END IF;
            
        WHEN 'alphanumeric' THEN
            -- Alphanumeric only
            IF NOT p_input_value ~* '^[a-zA-Z0-9]+$' THEN
                RAISE EXCEPTION 'Input must contain only letters and numbers';
            END IF;
            
        WHEN 'numeric' THEN
            -- Numeric only
            IF NOT p_input_value ~* '^[0-9]+$' THEN
                RAISE EXCEPTION 'Input must contain only numbers';
            END IF;
            
        WHEN 'alpha' THEN
            -- Letters only
            IF NOT p_input_value ~* '^[a-zA-Z]+$' THEN
                RAISE EXCEPTION 'Input must contain only letters';
            END IF;
            
        WHEN 'custom' THEN
            -- Custom pattern validation
            IF v_pattern IS NOT NULL AND NOT p_input_value ~ v_pattern THEN
                IF v_custom_message IS NOT NULL THEN
                    RAISE EXCEPTION '%', v_custom_message;
                ELSE
                    RAISE EXCEPTION 'Input does not match required pattern';
                END IF;
            END IF;
            
        ELSE
            RAISE EXCEPTION 'Unknown validation type: %', p_validation_type;
    END CASE;
    
    RETURN true;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log validation failure for security monitoring
        PERFORM public.log_security_event(
            auth.uid(),
            'validation_failed',
            format('Validation failed for type %s: %s', p_validation_type, SQLERRM),
            NULL, NULL,
            jsonb_build_object(
                'validation_type', p_validation_type,
                'input_length', length(p_input_value),
                'error', SQLERRM
            ),
            'low'
        );
        RAISE;
END;
$$;

-- Create comprehensive content sanitization function
CREATE OR REPLACE FUNCTION public.sanitize_user_content(
    p_content text,
    p_content_type text,
    p_max_length integer DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_sanitized text;
    v_max_len integer;
BEGIN
    -- Handle NULL input
    IF p_content IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Start with basic sanitization
    v_sanitized := p_content;
    
    -- Remove control characters except newlines and tabs
    v_sanitized := regexp_replace(v_sanitized, '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', 'g');
    
    -- Content type specific sanitization
    CASE p_content_type
        WHEN 'comment', 'caption', 'bio' THEN
            -- Allow basic formatting but strip dangerous content
            -- Remove script tags
            v_sanitized := regexp_replace(v_sanitized, '<script[^>]*>.*?</script>', '', 'gi');
            -- Remove style tags
            v_sanitized := regexp_replace(v_sanitized, '<style[^>]*>.*?</style>', '', 'gi');
            -- Remove iframe tags
            v_sanitized := regexp_replace(v_sanitized, '<iframe[^>]*>.*?</iframe>', '', 'gi');
            -- Remove onclick and other event handlers
            v_sanitized := regexp_replace(v_sanitized, '\son\w+\s*=\s*["\'][^"\']*["\']', '', 'gi');
            -- Remove javascript: protocol
            v_sanitized := regexp_replace(v_sanitized, 'javascript:', '', 'gi');
            
            -- Set default max length based on content type
            v_max_len := COALESCE(p_max_length, 
                CASE p_content_type
                    WHEN 'comment' THEN 500
                    WHEN 'caption' THEN 2200
                    WHEN 'bio' THEN 150
                    ELSE 1000
                END
            );
            
        WHEN 'username', 'display_name' THEN
            -- Strict sanitization for usernames
            -- Remove all HTML tags
            v_sanitized := regexp_replace(v_sanitized, '<[^>]*>', '', 'g');
            -- Keep only alphanumeric, space, underscore, dash
            v_sanitized := regexp_replace(v_sanitized, '[^a-zA-Z0-9 _-]', '', 'g');
            -- Remove multiple spaces
            v_sanitized := regexp_replace(v_sanitized, '\s+', ' ', 'g');
            -- Trim whitespace
            v_sanitized := trim(v_sanitized);
            
            v_max_len := COALESCE(p_max_length, 50);
            
        WHEN 'message' THEN
            -- Messages allow more formatting but still need sanitization
            -- Remove dangerous tags but keep basic formatting
            v_sanitized := regexp_replace(v_sanitized, '<script[^>]*>.*?</script>', '', 'gi');
            v_sanitized := regexp_replace(v_sanitized, '<iframe[^>]*>.*?</iframe>', '', 'gi');
            v_sanitized := regexp_replace(v_sanitized, 'javascript:', '', 'gi');
            
            v_max_len := COALESCE(p_max_length, 10000);
            
        WHEN 'article' THEN
            -- Articles need minimal sanitization
            -- Just remove script tags and event handlers
            v_sanitized := regexp_replace(v_sanitized, '<script[^>]*>.*?</script>', '', 'gi');
            v_sanitized := regexp_replace(v_sanitized, '\son\w+\s*=\s*["\'][^"\']*["\']', '', 'gi');
            
            v_max_len := COALESCE(p_max_length, 50000);
            
        WHEN 'plain' THEN
            -- Remove all HTML and special formatting
            v_sanitized := regexp_replace(v_sanitized, '<[^>]*>', '', 'g');
            v_sanitized := regexp_replace(v_sanitized, '\s+', ' ', 'g');
            v_sanitized := trim(v_sanitized);
            
            v_max_len := COALESCE(p_max_length, 1000);
            
        ELSE
            -- Default sanitization
            v_sanitized := regexp_replace(v_sanitized, '<[^>]*>', '', 'g');
            v_max_len := COALESCE(p_max_length, 1000);
    END CASE;
    
    -- Apply length limit
    IF v_max_len IS NOT NULL AND length(v_sanitized) > v_max_len THEN
        v_sanitized := left(v_sanitized, v_max_len);
    END IF;
    
    RETURN v_sanitized;
END;
$$;

-- Backward compatibility wrapper functions
CREATE OR REPLACE FUNCTION public.validate_uuid_input(p_input text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    RETURN public.validate_input(p_input, 'uuid');
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION public.sanitize_text_input(p_input text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    RETURN public.sanitize_user_content(p_input, 'plain', 1000);
END;
$$;

-- Create helper function for batch validation
CREATE OR REPLACE FUNCTION public.validate_multiple_inputs(
    p_inputs jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_result jsonb := '{}';
    v_field record;
    v_is_valid boolean;
    v_error_message text;
BEGIN
    -- Validate each input field
    FOR v_field IN SELECT * FROM jsonb_each_text(p_inputs)
    LOOP
        BEGIN
            -- Extract validation rules for this field
            v_is_valid := public.validate_input(
                v_field.value,
                (p_inputs->>v_field.key)::text,
                p_inputs->v_field.key->'rules'
            );
            
            v_result := v_result || jsonb_build_object(
                v_field.key, 
                jsonb_build_object(
                    'valid', v_is_valid,
                    'value', v_field.value
                )
            );
        EXCEPTION
            WHEN OTHERS THEN
                v_result := v_result || jsonb_build_object(
                    v_field.key, 
                    jsonb_build_object(
                        'valid', false,
                        'error', SQLERRM,
                        'value', v_field.value
                    )
                );
        END;
    END LOOP;
    
    RETURN v_result;
END;
$$;

-- Grant appropriate permissions
GRANT EXECUTE ON FUNCTION public.validate_input TO authenticated;
GRANT EXECUTE ON FUNCTION public.sanitize_user_content TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_uuid_input TO authenticated;
GRANT EXECUTE ON FUNCTION public.sanitize_text_input TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_multiple_inputs TO authenticated;

-- Add comments for documentation
COMMENT ON FUNCTION public.validate_input IS 'Comprehensive input validation with support for multiple validation types';
COMMENT ON FUNCTION public.sanitize_user_content IS 'Content sanitization based on content type with XSS prevention';
COMMENT ON FUNCTION public.validate_uuid_input IS 'Backward compatibility wrapper for UUID validation';
COMMENT ON FUNCTION public.sanitize_text_input IS 'Backward compatibility wrapper for text sanitization';
COMMENT ON FUNCTION public.validate_multiple_inputs IS 'Batch validation for multiple input fields';