-- Add media dimensions to posts table
ALTER TABLE public.posts 
ADD COLUMN media_width FLOAT,
ADD COLUMN media_height FLOAT;

-- Create index for queries that might filter by aspect ratio
CREATE INDEX IF NOT EXISTS idx_posts_media_dimensions 
ON public.posts (media_width, media_height);

-- Add comment for documentation
COMMENT ON COLUMN public.posts.media_width IS 'Width of the media content in pixels';
COMMENT ON COLUMN public.posts.media_height IS 'Height of the media content in pixels';