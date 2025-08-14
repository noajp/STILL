-- ======================================================================
-- Migration: 20250101_000011_add_status_to_follows.sql
-- Purpose: Add status column to follows table for follow requests
-- Dependencies: public.follows
-- ======================================================================


-- 1. 既存のRLSポリシーを一旦削除します。
DROP POLICY IF EXISTS "Follows are viewable by everyone" ON public.follows;
DROP POLICY IF EXISTS "Users can insert their own follows" ON public.follows;
DROP POLICY IF EXISTS "Users can delete their own follows" ON public.follows;

-- 4. 新しいRLSポリシーを定義します。

-- SELECT: 誰でもフォロー関係を閲覧できます。プライベートアカウントの投稿自体は別のRLSで保護します。
CREATE POLICY "Follows are viewable by everyone" ON public.follows
    FOR SELECT USING (true);

-- INSERT: ユーザーは自分自身のフォローリクエストのみ作成できます。
CREATE POLICY "Users can insert their own follows" ON public.follows
    FOR INSERT WITH CHECK (auth.uid() = follower_id);

-- UPDATE: フォローされたユーザー（following_id）が、'pending'のステータスを'accepted'または'declined'に更新できます。
-- これがリクエストの承認・拒否の核となります。
CREATE POLICY "Users can update status of their follow requests" ON public.follows
    FOR UPDATE USING (auth.uid() = following_id) WITH CHECK (status IN ('accepted', 'declined'));

-- DELETE: フォローした本人（follower_id）がフォローを解除（DELETE）できます。
-- または、フォローされた本人（following_id）がリクエストを拒否（DELETE）できます。
CREATE POLICY "Users can delete their own follows or decline requests" ON public.follows
