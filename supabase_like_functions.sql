-- Supabase Database Functions for Like System
-- Execute these in your Supabase SQL editor

-- Function to increment like count
CREATE OR REPLACE FUNCTION increment_like_count(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts 
  SET like_count = like_count + 1 
  WHERE id = post_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement like count
CREATE OR REPLACE FUNCTION decrement_like_count(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts 
  SET like_count = GREATEST(like_count - 1, 0)
  WHERE id = post_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get posts with like status for a specific user
CREATE OR REPLACE FUNCTION get_posts_with_like_status(user_id UUID)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  media_url TEXT,
  media_type TEXT,
  caption TEXT,
  location_name TEXT,
  latitude FLOAT,
  longitude FLOAT,
  is_public BOOLEAN,
  created_at TIMESTAMPTZ,
  like_count INTEGER,
  comment_count INTEGER,
  is_liked_by_me BOOLEAN
) AS $$
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
  FROM posts p
  LEFT JOIN likes l ON p.id = l.post_id AND l.user_id = user_id
  WHERE p.is_public = true
  ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql;