# 鍵アカウント機能 詳細設計書

## 1. 概要

### 1.1 目的
STILLアプリにおいて、ユーザーが自分のプロフィールとコンテンツを承認したフォロワーのみに公開できる「鍵アカウント（プライベートアカウント）」機能の詳細設計を定義する。

### 1.2 現在の実装状況
- **followsテーブル**: status列（pending/accepted）実装済み
- **profilesテーブル**: is_private列（boolean）実装済み
- **FollowService**: プライベートアカウントのフォロー処理実装済み
- **通知システム**: フォローリクエスト通知（follow_request）と承認通知（follow_request_approved）実装済み
- **UI実装**: プライバシー設定画面、フォローリクエスト管理画面実装済み

### 1.3 設計方針
- **後方互換性の確保**: 既存の公開アカウントフォロー機能を壊さない
- **最小限の変更**: 既存の実装を最大限活用し、追加実装を最小限に抑える
- **一貫性の維持**: 既存のUIパターンとデザインシステムに従う

## 2. データベース設計

### 2.1 既存のスキーマ（変更なし）

#### follows テーブル
```sql
CREATE TABLE follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID REFERENCES profiles(id),
    following_id UUID REFERENCES profiles(id),
    status TEXT DEFAULT 'accepted' CHECK (status IN ('pending', 'accepted')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### profiles テーブル（関連部分のみ）
```sql
CREATE TABLE profiles (
    id UUID PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    is_private BOOLEAN DEFAULT false,
    -- その他のカラム...
);
```

### 2.2 必要なデータベース変更
**なし** - 既存のスキーマで鍵アカウント機能を完全に実装可能

## 3. 機能仕様

### 3.1 フォロー処理フロー

#### 3.1.1 公開アカウントへのフォロー（既存処理）
1. フォローボタンをタップ
2. followsテーブルにstatus='accepted'でレコード作成
3. フォロー通知（type='follow'）を送信
4. UIを即座に「Following」状態に更新

#### 3.1.2 鍵アカウントへのフォロー（実装済み）
1. フォローボタンをタップ
2. followsテーブルにstatus='pending'でレコード作成
3. フォローリクエスト通知（type='follow_request'）を送信
4. UIを「Requested」状態に更新

### 3.2 フォローリクエスト承認フロー（実装済み）
1. 鍵アカウントユーザーがフォローリクエスト管理画面にアクセス
2. 承認/拒否を選択
3. 承認時：
   - followsテーブルのstatusを'accepted'に更新
   - フォローリクエスト承認通知（type='follow_request_approved'）を送信
   - フォロワー数を更新
4. 拒否時：
   - followsテーブルからレコードを削除

### 3.3 コンテンツアクセス制御

#### 3.3.1 必要な追加実装

**投稿一覧の表示制御**
- 鍵アカウントの投稿は承認されたフォロワーのみ表示
- RLSポリシーの更新が必要

**プロフィール情報の表示制御**
- 鍵アカウントの場合、未承認ユーザーには限定的な情報のみ表示
- フォロワー数、フォロー数は表示
- 投稿数は表示するが、実際の投稿は非表示

## 4. UI/UX設計

### 4.1 実装済みのUI

#### 4.1.1 プライバシー設定画面
- トグルスイッチでプライベートアカウントのON/OFF切り替え
- 説明文で機能を説明

#### 4.1.2 フォローリクエスト管理画面
- 保留中のリクエスト一覧表示
- 各リクエストに対してAccept/Declineボタン
- 承認後はFollowボタンを表示（相互フォロー可能）

### 4.2 必要な追加UI実装

#### 4.2.1 プロフィール画面の更新
```swift
// OtherUserProfileView での表示制御
if userProfile.isPrivate && !followStatus.isFollowing {
    // 鍵アカウントで未承認の場合
    VStack {
        Image(systemName: "lock.fill")
        Text("This Account is Private")
        Text("Follow to see their photos and posts.")
    }
} else {
    // 通常の投稿表示
}
```

#### 4.2.2 フォローボタンの状態管理
- `Follow` → タップ → `Requested`（鍵アカウントの場合）
- `Follow` → タップ → `Following`（公開アカウントの場合）
- `Requested` → 承認 → `Following`

## 5. セキュリティとプライバシー

### 5.1 RLSポリシーの更新が必要な箇所

#### 5.1.1 posts テーブル
```sql
-- 既存のポリシーに追加条件を追加
CREATE POLICY "posts_select_policy" ON posts FOR SELECT
USING (
    -- 自分の投稿
    user_id = auth.uid()
    OR
    -- 公開アカウントの投稿
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = posts.user_id 
        AND is_private = false
    )
    OR
    -- 鍵アカウントでフォロワーの投稿
    EXISTS (
        SELECT 1 FROM follows
        WHERE following_id = posts.user_id
        AND follower_id = auth.uid()
        AND status = 'accepted'
    )
);
```

### 5.2 API レスポンスの制御
- 鍵アカウントのプロフィール情報は常に返す
- 投稿データはRLSで自動的にフィルタリング

## 6. 実装タスク

### 6.1 バックエンド（優先度：高）
1. ✅ followsテーブルのstatus列実装
2. ✅ profilesテーブルのis_private列実装
3. ✅ フォローリクエスト通知タイプの追加
4. ⬜ postsテーブルのRLSポリシー更新
5. ⬜ 既存のRLSポリシーの影響確認と更新

### 6.2 フロントエンド（優先度：高）
1. ✅ FollowServiceでのプライベートアカウント判定
2. ✅ フォローリクエスト管理画面
3. ✅ 通知システムの拡張
4. ⬜ プロフィール画面での投稿表示制御
5. ⬜ フォローボタンの「Requested」状態表示

### 6.3 テスト（優先度：中）
1. ⬜ 公開→鍵アカウント切り替え時の既存フォロワー維持確認
2. ⬜ 鍵→公開アカウント切り替え時のpendingリクエスト処理
3. ⬜ RLSポリシーの動作確認

## 7. 移行計画

### 7.1 既存ユーザーへの影響
- すべての既存アカウントはデフォルトで公開（is_private = false）
- 既存のフォロー関係はすべてacceptedステータスで維持
- ユーザーが手動でプライベートに切り替えるまで変更なし

### 7.2 段階的リリース
1. **Phase 1**: RLSポリシーの更新とテスト
2. **Phase 2**: UI実装の完成とテスト
3. **Phase 3**: 本番環境へのデプロイ

## 8. 今後の拡張可能性

### 8.1 将来的な機能追加
- フォローリクエストの有効期限
- 一括承認/拒否機能
- 承認済みフォロワーの管理画面
- クローズドフレンド機能（特定のフォロワーにのみ公開）

### 8.2 パフォーマンス最適化
- フォロワー承認状態のキャッシュ
- 大量のフォローリクエスト処理の最適化

## 9. 注意事項

### 9.1 後方互換性の確保
- status列のデフォルト値は'accepted'
- is_private列のデフォルト値はfalse
- 既存のAPIレスポンスフォーマットは変更しない

### 9.2 エッジケース
- アカウントを公開→鍵→公開と切り替えた場合のpendingリクエスト
- 相互フォロー時の承認フロー
- ブロック機能との組み合わせ（将来実装時）

## 10. まとめ

現在の実装状況を確認した結果、鍵アカウント機能の基本的な仕組みはすでに実装されており、必要な追加実装は以下の2点のみ：

1. **RLSポリシーの更新**: 投稿の表示制御
2. **UI実装の完成**: プロフィール画面での制御とフォローボタンの状態管理

これらの実装により、既存の公開アカウント機能を維持しながら、完全な鍵アカウント機能を提供できる。