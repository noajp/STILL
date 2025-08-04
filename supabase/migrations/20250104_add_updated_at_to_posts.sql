-- Add updated_at column to posts table
-- This migration adds the missing updated_at column that is referenced by database triggers

-- Add updated_at column to posts table
ALTER TABLE posts 
ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();

-- Update existing rows to have updated_at = created_at
UPDATE posts 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- Add trigger to automatically update updated_at on row updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to posts table
DROP TRIGGER IF EXISTS update_posts_updated_at ON posts;
CREATE TRIGGER update_posts_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comment
COMMENT ON COLUMN posts.updated_at IS 'Timestamp when the post was last updated';