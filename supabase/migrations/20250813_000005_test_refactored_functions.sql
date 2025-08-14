--======================================================================
-- MARK: - Test Suite for Refactored Functions
-- Purpose: Verify all refactored functions work correctly
-- Path: supabase/migrations/20250813_000005_test_refactored_functions.sql
--======================================================================

-- Create test helper function
CREATE OR REPLACE FUNCTION public.test_refactored_functions()
RETURNS TABLE (
    test_name text,
    test_result boolean,
    test_message text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_test_user_id uuid;
    v_test_post_id uuid;
    v_test_result boolean;
    v_test_count integer;
    v_sanitized_text text;
    v_validation_result boolean;
BEGIN
    -- Test 1: Unified cleanup function
    test_name := 'Test cleanup_data_by_retention';
    BEGIN
        -- This should work without error (even if no records deleted)
        PERFORM public.cleanup_data_by_retention('rate_limits', 24, 'window_start');
        test_result := true;
        test_message := 'Cleanup function executed successfully';
        RETURN NEXT;
    EXCEPTION
        WHEN OTHERS THEN
            test_result := false;
            test_message := 'Cleanup function failed: ' || SQLERRM;
            RETURN NEXT;
    END;
    
    -- Test 2: Generic counter management
    test_name := 'Test update_counter function';
    BEGIN
        -- Get a test post ID (or create one)
        SELECT id INTO v_test_post_id FROM posts LIMIT 1;
        
        IF v_test_post_id IS NOT NULL THEN
            -- Test incrementing a counter
            PERFORM public.update_post_counter(v_test_post_id, 'view', 1);
            test_result := true;
            test_message := 'Counter update executed successfully';
        ELSE
            test_result := false;
            test_message := 'No posts available for testing';
        END IF;
        RETURN NEXT;
    EXCEPTION
        WHEN OTHERS THEN
            test_result := false;
            test_message := 'Counter update failed: ' || SQLERRM;
            RETURN NEXT;
    END;
    
    -- Test 3: Input validation - UUID
    test_name := 'Test UUID validation';
    BEGIN
        -- Test valid UUID
        v_validation_result := public.validate_input('550e8400-e29b-41d4-a716-446655440000', 'uuid');
        IF v_validation_result THEN
            test_result := true;
            test_message := 'Valid UUID accepted';
        ELSE
            test_result := false;
            test_message := 'Valid UUID rejected';
        END IF;
        RETURN NEXT;
        
        -- Test invalid UUID (should fail)
        test_name := 'Test invalid UUID rejection';
        BEGIN
            v_validation_result := public.validate_input('not-a-uuid', 'uuid');
            test_result := false;
            test_message := 'Invalid UUID was accepted';
        EXCEPTION
            WHEN OTHERS THEN
                test_result := true;
                test_message := 'Invalid UUID correctly rejected';
        END;
        RETURN NEXT;
    EXCEPTION
        WHEN OTHERS THEN
            test_result := false;
            test_message := 'UUID validation test failed: ' || SQLERRM;
            RETURN NEXT;
    END;
    
    -- Test 4: Input validation - Email
    test_name := 'Test email validation';
    BEGIN
        -- Test valid email
        v_validation_result := public.validate_input('test@example.com', 'email');
        IF v_validation_result THEN
            test_result := true;
            test_message := 'Valid email accepted';
        ELSE
            test_result := false;
            test_message := 'Valid email rejected';
        END IF;
        RETURN NEXT;
        
        -- Test invalid email
        test_name := 'Test invalid email rejection';
        BEGIN
            v_validation_result := public.validate_input('not-an-email', 'email');
            test_result := false;
            test_message := 'Invalid email was accepted';
        EXCEPTION
            WHEN OTHERS THEN
                test_result := true;
                test_message := 'Invalid email correctly rejected';
        END;
        RETURN NEXT;
    EXCEPTION
        WHEN OTHERS THEN
            test_result := false;
            test_message := 'Email validation test failed: ' || SQLERRM;
            RETURN NEXT;
    END;
    
    -- Test 5: Content sanitization
    test_name := 'Test content sanitization - XSS prevention';
    BEGIN
        -- Test XSS script removal
        v_sanitized_text := public.sanitize_user_content(
            'Hello <script>alert("XSS")</script> World',
            'comment'
        );
        
        IF position('<script>' in v_sanitized_text) = 0 THEN
            test_result := true;
            test_message := 'Script tags successfully removed';
        ELSE
            test_result := false;
            test_message := 'Script tags not removed';
        END IF;
        RETURN NEXT;
    EXCEPTION
        WHEN OTHERS THEN
            test_result := false;
            test_message := 'Content sanitization failed: ' || SQLERRM;
            RETURN NEXT;
    END;
    
    -- Test 6: Username sanitization
    test_name := 'Test username sanitization';
    BEGIN
        v_sanitized_text := public.sanitize_user_content(
            'user@#$%name123',
            'username'
        );
        
        -- Check if special characters were removed
        IF v_sanitized_text = 'username123' THEN
            test_result := true;
            test_message := 'Username correctly sanitized';
        ELSE
            test_result := false;
            test_message := format('Username sanitization unexpected result: %s', v_sanitized_text);
        END IF;
        RETURN NEXT;
    EXCEPTION
        WHEN OTHERS THEN
            test_result := false;
            test_message := 'Username sanitization failed: ' || SQLERRM;
            RETURN NEXT;
    END;
    
    -- Test 7: Backward compatibility functions
    test_name := 'Test backward compatibility - validate_uuid_input';
    BEGIN
        v_validation_result := public.validate_uuid_input('550e8400-e29b-41d4-a716-446655440000');
        IF v_validation_result THEN
            test_result := true;
            test_message := 'Backward compatible UUID validation works';
        ELSE
            test_result := false;
            test_message := 'Backward compatible UUID validation failed';
        END IF;
        RETURN NEXT;
    EXCEPTION
        WHEN OTHERS THEN
            test_result := false;
            test_message := 'Backward compatibility test failed: ' || SQLERRM;
            RETURN NEXT;
    END;
    
    -- Test 8: Backward compatibility - sanitize_text_input
    test_name := 'Test backward compatibility - sanitize_text_input';
    BEGIN
        v_sanitized_text := public.sanitize_text_input('Hello <b>World</b>');
        IF position('<b>' in v_sanitized_text) = 0 THEN
            test_result := true;
            test_message := 'Backward compatible text sanitization works';
        ELSE
            test_result := false;
            test_message := 'Backward compatible text sanitization failed';
        END IF;
        RETURN NEXT;
    EXCEPTION
        WHEN OTHERS THEN
            test_result := false;
            test_message := 'Backward compatibility test failed: ' || SQLERRM;
            RETURN NEXT;
    END;
    
    -- Test 9: Conversation functions
    test_name := 'Test find_existing_conversation';
    BEGIN
        -- Get two test users
        SELECT id INTO v_test_user_id FROM profiles LIMIT 1;
        
        IF v_test_user_id IS NOT NULL THEN
            -- This should return NULL or a UUID without error
            PERFORM public.find_existing_conversation(v_test_user_id, v_test_user_id);
            test_result := true;
            test_message := 'Conversation search function works';
        ELSE
            test_result := false;
            test_message := 'No users available for testing';
        END IF;
        RETURN NEXT;
    EXCEPTION
        WHEN OTHERS THEN
            test_result := false;
            test_message := 'Conversation function test failed: ' || SQLERRM;
            RETURN NEXT;
    END;
    
END;
$$;

-- Run the tests
DO $$
DECLARE
    v_test_record record;
    v_total_tests integer := 0;
    v_passed_tests integer := 0;
    v_failed_tests integer := 0;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Running Refactored Functions Test Suite';
    RAISE NOTICE '========================================';
    
    FOR v_test_record IN SELECT * FROM public.test_refactored_functions()
    LOOP
        v_total_tests := v_total_tests + 1;
        
        IF v_test_record.test_result THEN
            v_passed_tests := v_passed_tests + 1;
            RAISE NOTICE '✓ PASS: % - %', v_test_record.test_name, v_test_record.test_message;
        ELSE
            v_failed_tests := v_failed_tests + 1;
            RAISE WARNING '✗ FAIL: % - %', v_test_record.test_name, v_test_record.test_message;
        END IF;
    END LOOP;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Test Results: % passed, % failed out of % total tests', 
        v_passed_tests, v_failed_tests, v_total_tests;
    RAISE NOTICE '========================================';
    
    -- Log test results
    PERFORM public.log_security_event(
        NULL,
        'function_test_complete',
        format('Function tests completed: %s/%s passed', v_passed_tests, v_total_tests),
        NULL, NULL,
        jsonb_build_object(
            'total_tests', v_total_tests,
            'passed', v_passed_tests,
            'failed', v_failed_tests
        ),
        CASE WHEN v_failed_tests > 0 THEN 'high' ELSE 'low' END
    );
    
    -- Fail the migration if any tests failed
    IF v_failed_tests > 0 THEN
        RAISE EXCEPTION 'Function tests failed: % out of % tests failed', v_failed_tests, v_total_tests;
    END IF;
END;
$$;

-- Clean up test function
DROP FUNCTION IF EXISTS public.test_refactored_functions();

-- Add comment
COMMENT ON SCHEMA public IS 'Refactored RPC functions test completed successfully';