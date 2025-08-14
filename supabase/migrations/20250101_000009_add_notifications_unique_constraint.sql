-- ======================================================================
-- Migration: 20250101_000009_add_notifications_unique_constraint.sql
-- Purpose: Add unique constraint to prevent duplicate notifications
-- Dependencies: public.notifications
-- ======================================================================


-- Add unique constraint for follow notifications
-- This will prevent duplicate follow notifications from the same user
ALTER TABLE notifications 
ADD CONSTRAINT unique_follow_notifications 
UNIQUE (user_id, type, related_user_id)
WHERE type = 'follow' AND related_user_id IS NOT NULL;

-- Add comment explaining the constraint
COMMENT ON CONSTRAINT unique_follow_notifications ON notifications IS 
