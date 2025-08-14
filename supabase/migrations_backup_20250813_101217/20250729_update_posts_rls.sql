-- 既存のpostsテーブルのSELECTポリシーを削除
DROP POLICY IF EXISTS "Authenticated users can view public posts" ON public.posts;
DROP POLICY IF EXISTS "Users can view their own posts" ON public.posts;


-- 新しい統合SELECTポリシーを作成
CREATE POLICY "Users can see posts based on privacy settings" ON public.posts
FOR SELECT USING (
  -- 投稿者自身は常に見れる
  (user_id = auth.uid()) OR
  -- 公開アカウントの投稿は誰でも見れる
  (EXISTS (
    SELECT 1
    FROM profiles
    WHERE profiles.id = posts.user_id AND profiles.is_private = false
  )) OR
  -- 鍵アカウントの投稿は、承認されたフォロワーのみが見れる
  (EXISTS (
    SELECT 1
    FROM follows
    WHERE follows.following_id = posts.user_id AND follows.follower_id = auth.uid() AND follows.status = 'accepted'
  ))
);