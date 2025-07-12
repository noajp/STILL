# Supabaseセキュリティ改善実施記録

実施日: 2025年6月18日

## 実施したセキュリティ改善

### 1. データベースセキュリティ

#### ✅ RLS (Row Level Security) の修正
- **問題**: `data_retention_policies`テーブルでRLSが無効になっていた
- **対策**: RLSを有効化し、service_roleのみがアクセスできるポリシーを追加
```sql
ALTER TABLE public.data_retention_policies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Only admins can access data retention policies" ON public.data_retention_policies
FOR ALL
USING (auth.jwt() ->> 'role' = 'service_role');
```

#### ✅ 関数のセキュリティ強化
- **問題**: `configure_audit_settings`関数でsearch_pathが設定されていなかった
- **対策**: search_pathを明示的に設定してSQLインジェクションのリスクを軽減
```sql
CREATE OR REPLACE FUNCTION public.configure_audit_settings()
SET search_path = public, pg_catalog
```

#### ✅ 拡張機能のスキーマ移動
- **問題**: pgaudit拡張がpublicスキーマにインストールされていた
- **対策**: extensionsスキーマに移動し、適切な権限を設定
```sql
CREATE SCHEMA IF NOT EXISTS extensions;
DROP EXTENSION IF EXISTS pgaudit CASCADE;
CREATE EXTENSION pgaudit SCHEMA extensions;
```

### 2. 認証セキュリティ（要対応）

#### ⚠️ 漏洩パスワード保護の有効化
- **現状**: HaveIBeenPwnedによる侵害されたパスワードのチェックが無効
- **推奨対策**: Supabaseダッシュボードから有効化が必要
- **参照**: [パスワードセキュリティドキュメント](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)

#### ⚠️ MFA（多要素認証）オプションの追加
- **現状**: MFAオプションが不足している
- **推奨対策**: より多くのMFA方式を有効化
- **参照**: [MFA設定ドキュメント](https://supabase.com/docs/guides/auth/auth-mfa)

## 既存のセキュリティ対策（良好な点）

### ✅ RLSが適切に設定されているテーブル
- `posts`: 公開投稿は全員が閲覧可能、作成・更新・削除は投稿者のみ
- `user_profiles`: 全員が閲覧可能、更新は本人のみ
- `messages`: 会話参加者のみアクセス可能
- `conversations`: 参加者のみアクセス可能
- `favorites`, `follows`, `likes`: 適切なユーザー制限

### ✅ セキュリティ関連テーブルの保護
- `security_logs`: システムのみアクセス可能（`false`ポリシー）
- `app_config`: システムのみアクセス可能（`false`ポリシー）
- `security_honeypot`: 全アクセスをブロック（`false`ポリシー）
- `rate_limits`: ユーザーは自分のレート制限のみ閲覧可能

## 次のステップ

1. **Supabaseダッシュボードでの設定**
   - 漏洩パスワード保護を有効化
   - MFAオプションを追加（TOTP、SMS等）

2. **定期的なセキュリティ監査**
   - `mcp__supabase__get_advisors`を定期的に実行
   - 新しいテーブル作成時は必ずRLSを有効化

3. **アプリケーション側の対策**
   - APIキーの適切な管理
   - クライアント側でのデータ検証
   - セキュリティヘッダーの設定

## 参考リンク
- [Supabase RLSベストプラクティス](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabaseセキュリティチェックリスト](https://supabase.com/docs/guides/platform/security)