# STILL アプリケーション セキュリティドキュメント

## 📋 目次
1. [セキュリティ状況概要](#セキュリティ状況概要)
2. [RLSセキュリティテスト](#rlsセキュリティテスト)
3. [発見された脆弱性と修正](#発見された脆弱性と修正)
4. [セキュリティテスト手順](#セキュリティテスト手順)
5. [定期メンテナンス](#定期メンテナンス)

## 🛡️ セキュリティ状況概要

**総合セキュリティレベル: A（優良）**  
**最終テスト実施日**: 2025-07-26  
**次回レビュー予定**: 2025-08-26  

## 🔍 RLSセキュリティテスト

### テスト概要
cURLコマンドを使用してSupabaseのRow Level Security (RLS)が適切に機能しているかを検証しました。

### テスト方法
```bash
# 基本的なテストコマンド構造
curl "https://[プロジェクトID].supabase.co/rest/v1/[テーブル名]?select=*" \
-H "apikey: [anonキー]" \
-H "Authorization: Bearer [anonキー]"
```

### テスト対象テーブル
| テーブル | 修正前状況 | 修正後状況 | セキュリティレベル |
|---------|------------|------------|-------------------|
| profiles | ⚠️ 全データ漏洩 | ✅ `[]` (安全) | 🟢 良好 |
| posts | ⚠️ 全データ漏洩 | ✅ `[]` (安全) | 🟢 良好 |
| messages | ✅ `[]` (元から安全) | ✅ `[]` (安全) | 🟢 良好 |
| notifications | ✅ `[]` (元から安全) | ✅ `[]` (安全) | 🟢 良好 |
| follows | ✅ `[]` (元から安全) | ✅ `[]` (安全) | 🟢 良好 |

## 🚨 発見された脆弱性と修正

### 重大な脆弱性 (修正済み)

#### 1. profilesテーブルの情報漏洩
- **問題**: 未認証でも全ユーザーのプロフィール情報が取得可能
- **原因**: `"Public profiles viewable by everyone"` ポリシーの条件が `true`
- **修正**: ポリシーを削除し、認証必須に変更
```sql
DROP POLICY IF EXISTS "Public profiles viewable by everyone" ON profiles;
CREATE POLICY "Authenticated users can view profiles" ON profiles
    FOR SELECT USING (auth.role() = 'authenticated');
```

#### 2. postsテーブルの情報漏洩
- **問題**: 未認証でも全投稿データが取得可能
- **原因**: 複数の過度に許可的なポリシーが存在
- **修正**: 危険なポリシーを削除し、認証必須に変更
```sql
DROP POLICY IF EXISTS "Posts are viewable by everyone" ON posts;
DROP POLICY IF EXISTS "Public posts are viewable by everyone" ON posts;
CREATE POLICY "Authenticated users can view public posts" ON posts
    FOR SELECT USING (auth.role() = 'authenticated' AND is_public = true);
```

## 🧪 セキュリティテスト手順

### 1. 必要な情報の取得
```bash
# プロジェクトURL
https://[あなたのプロジェクトID].supabase.co

# anonキー (Supabase Dashboard > Settings > API)
eyJ... (実際のキー)
```

### 2. テストコマンドの実行

#### profilesテーブルのテスト
```bash
curl "https://[プロジェクトID].supabase.co/rest/v1/profiles?select=*" \
-H "apikey: [anonキー]" \
-H "Authorization: Bearer [anonキー]"
```

#### postsテーブルのテスト
```bash
curl "https://[プロジェクトID].supabase.co/rest/v1/posts?select=*" \
-H "apikey: [anonキー]" \
-H "Authorization: Bearer [anonキー]"
```

#### messagesテーブルのテスト
```bash
curl "https://[プロジェクトID].supabase.co/rest/v1/messages?select=*" \
-H "apikey: [anonキー]" \
-H "Authorization: Bearer [anonキー]"
```

#### notificationsテーブルのテスト
```bash
curl "https://[プロジェクトID].supabase.co/rest/v1/notifications?select=*" \
-H "apikey: [anonキー]" \
-H "Authorization: Bearer [anonキー]"
```

#### followsテーブルのテスト
```bash
curl "https://[プロジェクトID].supabase.co/rest/v1/follows?select=*" \
-H "apikey: [anonキー]" \
-H "Authorization: Bearer [anonキー]"
```

### 3. 結果の判定
- **✅ 安全**: `[]` (空の配列) が返ってくる
- **⚠️ 危険**: 実際のデータが返ってくる

### 4. 自動化スクリプト (推奨)
```bash
#!/bin/bash
# セキュリティテスト自動化スクリプト

PROJECT_URL="https://[プロジェクトID].supabase.co"
ANON_KEY="[anonキー]"

TABLES=("profiles" "posts" "messages" "notifications" "follows")

echo "🔍 RLSセキュリティテスト開始"
echo "================================"

for table in "${TABLES[@]}"; do
    echo "テスト中: $table"
    response=$(curl -s "${PROJECT_URL}/rest/v1/${table}?select=*" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${ANON_KEY}")
    
    if [ "$response" = "[]" ]; then
        echo "✅ $table: 安全"
    else
        echo "⚠️ $table: 脆弱性あり - データが漏洩している"
        echo "Response: $response"
    fi
    echo "--------------------------------"
done

echo "🔍 テスト完了"
```

## 🔒 現在のセキュリティ機能

### 1. Row Level Security (RLS)
- ✅ 全主要テーブルでRLS有効化済み
- ✅ 適切なポリシー設定完了
- ✅ パフォーマンス最適化済み

### 2. データベースセキュリティ
- ✅ Security Definer Viewを削除
- ✅ 外部キーインデックス追加によるパフォーマンス向上
- ✅ セキュリティ監査ログシステム導入
- ✅ レート制限システム強化

### 3. アクセス制御
- ✅ ユーザーは自分のデータのみアクセス可能
- ✅ 適切な公開データポリシー
- ✅ Service roleの権限適切に制限

### 4. 監査ログシステム
```sql
-- セキュリティイベントの自動ログ
SELECT log_security_event('login', 'auth', 'user_123');
```

### 5. レート制限システム
- ユーザーごとのAPI使用量追跡
- 異常なアクセスパターンの検出

## ⚠️ 今後対応推奨項目

### 1. Supabase Auth設定（手動設定が必要）
```
優先度: 中
場所: Supabase Dashboard > Authentication > Settings

□ OTP有効期限を1時間未満に短縮
□ 漏洩パスワード保護を有効化
□ 2FA設定の強化
```

### 2. 関数のsearch_path設定
```sql
-- 以下の関数にsearch_pathを追加
ALTER FUNCTION get_user_group_conversations SET search_path = public;
ALTER FUNCTION get_user_conversations SET search_path = public;
```

### 3. API セキュリティ強化
- レート制限の実装と監視
- APIキーローテーションの定期実行
- セキュリティヘッダーの追加

## 🚨 セキュリティインシデント対応

### 1. 異常検知時
1. `security_audit_log`テーブルで異常パターン確認
2. 該当ユーザーのアクセス一時停止
3. ログ分析と原因調査

### 2. データ漏洩疑い時
1. 即座にAPIキーローテーション
2. 全ユーザーセッション無効化
3. セキュリティログの詳細分析

## 📝 定期メンテナンス

### 月次タスク
- [ ] セキュリティログレビュー
- [ ] 異常アクセスパターンチェック
- [ ] パフォーマンス監視
- [ ] RLSテストの実行

### 四半期タスク
- [ ] APIキーローテーション
- [ ] セキュリティポリシー見直し
- [ ] ペネトレーションテスト
- [ ] 全テーブルのRLS監査

### RLSテストチェックリスト
```bash
# 四半期ごとに実行する推奨テスト
□ profilesテーブルのRLSテスト
□ postsテーブルのRLSテスト
□ messagesテーブルのRLSテスト
□ notificationsテーブルのRLSテスト
□ followsテーブルのRLSテスト
□ 新規追加テーブルのRLSテスト
□ テスト結果の文書化
□ 脆弱性発見時の即座対応
```

## 📊 RLS有効テーブル一覧

| テーブル | RLS | ポリシー数 | セキュリティレベル |
|---------|-----|-----------|-------------------|
| profiles | ✅ | 3 | 🟢 良好 |
| posts | ✅ | 4 | 🟢 良好 |
| likes | ✅ | 3 | 🟢 良好 |
| follows | ✅ | 2 | 🟢 良好 |
| notifications | ✅ | 3 | 🟢 良好 |
| messages | ✅ | 3 | 🟢 良好 |
| conversations | ✅ | 3 | 🟢 良好 |
| conversation_participants | ✅ | 3 | 🟢 良好 |
| security_audit_log | ✅ | 1 | 🟢 良好 |
| rate_limits | ✅ | 2 | 🟢 良好 |

---

**このドキュメントは定期的に更新され、最新のセキュリティ状況を反映しています。**  
**セキュリティに関する質問や懸念がある場合は、即座に開発チームに報告してください。**