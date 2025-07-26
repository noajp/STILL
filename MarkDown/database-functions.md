# Supabase データベース関数・ビュー管理ドキュメント

## 概要

このドキュメントは、STILLプロジェクトで使用しているSupabaseのRPC関数、トリガー、ビューの管理方法を説明します。

## 管理方法

### 1. マイグレーションファイルとして保存

Supabaseの関数やビューは `supabase/migrations/` フォルダ内にSQLファイルとして保存されています：

```
supabase/migrations/
├── 20240116000001_create_messaging_tables.sql
├── 20250726_security_improvements.sql
├── 20250726_functions_and_views_backup.sql  # 全関数・ビューのバックアップ
└── ...
```

### 2. 関数の分類

#### セキュリティ関数
- `log_security_event` - セキュリティイベントのログ記録
- `check_rate_limit` - レート制限チェック
- `anonymize_user_data` - ユーザーデータの匿名化（GDPR対応）
- `export_user_data` - ユーザーデータのエクスポート（GDPR対応）

#### メッセージング関数
- `get_or_create_direct_conversation` - ダイレクトメッセージの会話を取得/作成
- `send_message` - メッセージ送信
- `mark_conversation_as_read` - 会話を既読にマーク
- `get_user_conversations` - ユーザーの会話一覧取得
- `create_group_chat` - グループチャット作成
- `get_user_group_conversations` - グループ会話一覧取得

#### ソーシャル機能関数
- `increment_like_count` - いいね数増加
- `decrement_like_count` - いいね数減少
- `create_follow` - フォロー作成
- `get_posts_with_like_status` - いいね状態付き投稿取得

#### ユーティリティ関数
- `sanitize_text_input` - テキスト入力のサニタイズ（XSS/SQLインジェクション対策）
- `validate_uuid_input` - UUID形式の検証
- `cleanup_expired_data` - 期限切れデータのクリーンアップ

### 3. 本番環境から関数を取得

```sql
-- 全関数の定義を取得
SELECT 
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.prokind = 'f'
ORDER BY p.proname;

-- 全ビューの定義を取得
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views
WHERE schemaname = 'public'
ORDER BY viewname;
```

### 4. 関数の更新・デプロイ

1. **ローカルで編集**: `supabase/migrations/` 内のSQLファイルを編集
2. **マイグレーション作成**: 
   ```bash
   supabase migration new function_update_name
   ```
3. **ローカルテスト**:
   ```bash
   supabase db reset  # データベースリセット（注意：データが消える）
   supabase db push   # マイグレーション適用
   ```
4. **本番デプロイ**:
   ```bash
   supabase db push --db-url postgresql://postgres:[password]@[host]:5432/postgres
   ```

### 5. バックアップ戦略

定期的に以下のコマンドで関数・ビューをバックアップ：

```bash
# 日付付きバックアップファイル作成
supabase db dump -f supabase/migrations/$(date +%Y%m%d)_functions_backup.sql
```

### 6. セキュリティ考慮事項

- **SECURITY DEFINER**: 関数実行時の権限昇格に使用。慎重に使用する
- **search_path**: SQLインジェクション対策として明示的に設定
- **入力検証**: UUID検証、テキストサニタイズを必ず実施
- **レート制限**: APIの乱用を防ぐため、重要なアクションには制限を設定

### 7. トリガー管理

現在のトリガー：
- `update_conversation_on_new_message` - メッセージ作成時に会話を更新
- `manage_participant_deletion` - 最後の参加者削除時に会話も削除

### 8. ビュー管理

現在のビュー：
- `user_conversations_view` - ユーザーの会話一覧（セキュリティ適用済み）
- `accessible_conversation_participants` - アクセス可能な参加者一覧

## ベストプラクティス

1. **バージョン管理**: 全ての関数変更はマイグレーションファイルで管理
2. **テスト**: 本番デプロイ前に必ずローカルでテスト
3. **ドキュメント**: 関数の目的と使用方法をコメントで記載
4. **セキュリティ**: SECURITY DEFINERは最小限に、入力検証は必須
5. **パフォーマンス**: インデックスを適切に設定、実行計画を確認

## トラブルシューティング

### 関数が見つからない
```sql
-- 関数の存在確認
SELECT proname FROM pg_proc WHERE proname = 'function_name';
```

### 権限エラー
```sql
-- 関数の権限確認
SELECT has_function_privilege('function_name', 'execute');
```

### パフォーマンス問題
```sql
-- 実行計画の確認
EXPLAIN ANALYZE SELECT * FROM function_name(args);
```