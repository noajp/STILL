-- Add unique constraint for notifications to prevent duplicate follow notifications
-- This ensures that for each user_id + type + related_user_id combination, only one notification exists
-- When a follow notification is created, it will update the existing one instead of creating a duplicate

-- Add unique constraint for follow notifications
-- This will prevent duplicate follow notifications from the same user
ALTER TABLE notifications 
ADD CONSTRAINT unique_follow_notifications 
UNIQUE (user_id, type, related_user_id)
WHERE type = 'follow' AND related_user_id IS NOT NULL;

-- Add comment explaining the constraint
COMMENT ON CONSTRAINT unique_follow_notifications ON notifications IS 
'Ensures only one follow notification exists per user from each follower';