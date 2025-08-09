--- MarkDown/RPC_REFACTORING_PLAN.md ---

# RPC Functions Refactoring Plan

## 📋 Current State Analysis

The STILL app currently has **36 RPC functions** in the Supabase database. Many of these functions have overlapping functionality, complex logic, or could benefit from consolidation and optimization.

## 🎯 Refactoring Categories

### 1. **Duplicated Cleanup Functions** 🔄
**Current Functions:**
```sql
cleanup_old_rate_limits()     -- Deletes records older than 2 hours
cleanup_rate_limits()         -- Deletes records older than 24 hours
cleanup_expired_data()        -- Generic cleanup with policies
```

**Issues:**
- Same logic duplicated across multiple functions
- Different retention periods hardcoded
- No unified cleanup strategy

**Proposed Solution:**
```sql
-- Unified cleanup function with configurable retention
cleanup_data_by_retention(
    table_name text,
    retention_hours integer,
    date_column text DEFAULT 'created_at'
)
```

**Benefits:**
- Single source of truth for cleanup logic
- Configurable retention periods
- Easier maintenance and testing

---

### 2. **Counter Management Duplication** 📊
**Current Functions:**
```sql
increment_like_count(post_id)      -- Likes +1 with rate limiting
decrement_like_count(post_id)      -- Likes -1 with rate limiting
increment_comment_count()          -- Comments +1 (trigger function)
decrement_comment_count()          -- Comments -1 (trigger function)
```

**Issues:**
- Similar logic scattered across 4 functions
- Inconsistent rate limiting application
- Repeated counter update patterns

**Proposed Solution:**
```sql
-- Unified counter management
update_post_counter(
    post_id uuid,
    counter_type text,           -- 'like', 'comment', 'share', etc.
    increment_value integer,     -- +1, -1, or any value
    rate_limit_config jsonb     -- Optional rate limiting settings
)
```

**Benefits:**
- Consistent counter logic
- Easy to add new counter types
- Centralized rate limiting

---

### 3. **Complex Conversation Management** 💬
**Current Functions:**
```sql
get_or_create_direct_conversation()  -- 200+ lines, very complex
get_user_conversations()            -- Direct messages only
get_user_group_conversations()      -- Group chats only
```

**Issues:**
- `get_or_create_direct_conversation` is over 200 lines long
- Difficult to understand and maintain
- Similar query patterns duplicated

**Proposed Solution:**
```sql
-- Break down into smaller, focused functions
find_existing_conversation(user1_id uuid, user2_id uuid)
create_new_conversation(participants uuid[], is_group boolean)
get_conversations_with_metadata(user_id uuid, conversation_type text)
reset_conversation_visibility(conversation_id uuid, user_ids uuid[])
```

**Benefits:**
- Each function has single responsibility
- Easier to test and debug
- Reusable components

---

### 4. **Scattered Security Functions** 🔐
**Current Functions:**
```sql
log_security_event()          -- Security audit logging
anonymize_user_data()         -- Data anonymization
export_user_data()            -- GDPR data export
mask_sensitive_email()        -- Email privacy masking
configure_audit_settings()    -- Audit configuration
```

**Issues:**
- Security logic spread across multiple functions
- Inconsistent logging patterns
- Hard to maintain security standards

**Proposed Solution:**
```sql
-- Unified security audit system
audit_user_action(
    action_type text,
    resource_type text,
    resource_id text,
    metadata jsonb
)

-- Privacy control system
apply_privacy_rules(
    requesting_user_id uuid,
    data_owner_id uuid,
    data_type text,
    raw_data jsonb
)
```

**Benefits:**
- Centralized security logging
- Consistent privacy rule application
- Easier compliance management

---

### 5. **Insufficient Validation Functions** ✅
**Current Functions:**
```sql
validate_uuid_input(input_text)    -- UUID format validation
sanitize_text_input(input_text)    -- Basic text sanitization
```

**Issues:**
- Limited validation coverage
- No comprehensive input sanitization
- Missing common validation patterns

**Proposed Solution:**
```sql
-- Comprehensive validation suite
validate_input(
    input_value text,
    validation_type text,      -- 'uuid', 'email', 'username', etc.
    additional_rules jsonb     -- Custom validation rules
)

sanatize_user_content(
    content text,
    content_type text,         -- 'comment', 'caption', 'bio', etc.
    max_length integer
)
```

**Benefits:**
- Consistent validation across the app
- Easy to add new validation types
- Better security posture

---

## 🚀 Implementation Priority

### **Phase 1: High Priority (Immediate Impact)**
1. **Cleanup Functions Consolidation**
   - **Effort:** Low (2-3 hours)
   - **Impact:** High (easier maintenance)
   - **Risk:** Very Low

2. **Counter Functions Unification**
   - **Effort:** Medium (4-6 hours)
   - **Impact:** High (bug reduction, consistency)
   - **Risk:** Low (well-tested logic)

### **Phase 2: Medium Priority (Quality Improvement)**
3. **Conversation Management Refactoring**
   - **Effort:** High (8-12 hours)
   - **Impact:** Very High (maintainability)
   - **Risk:** Medium (complex logic changes)

4. **Validation Functions Enhancement**
   - **Effort:** Medium (4-6 hours)
   - **Impact:** High (security improvement)
   - **Risk:** Low (additive changes)

### **Phase 3: Low Priority (Future Enhancement)**
5. **Security Functions Reorganization**
   - **Effort:** High (8-10 hours)
   - **Impact:** Medium (already working well)
   - **Risk:** Medium (security-critical changes)

---

## 📈 Expected Benefits

### **Code Quality**
- **Reduced Duplication:** From 36 functions to ~25 focused functions
- **Improved Readability:** Shorter, single-purpose functions
- **Better Testing:** Smaller units easier to test

### **Maintenance**
- **Easier Updates:** Change logic in one place
- **Faster Debugging:** Clear function responsibilities
- **Reduced Bugs:** Less duplicate code to maintain

### **Performance**
- **Query Optimization:** Consolidated similar queries
- **Reduced Database Load:** More efficient function calls
- **Better Caching:** Smaller, focused functions cache better

### **Security**
- **Consistent Validation:** All inputs validated the same way
- **Centralized Security:** Security rules in one place
- **Better Auditing:** Unified logging approach

---

## 🧪 Testing Strategy

### **Before Refactoring**
1. **Document Current Behavior**
   - Create test cases for all existing functions
   - Record expected inputs/outputs
   - Note any edge cases or quirks

2. **Backup Strategy**
   - Create migration rollback scripts
   - Test rollback procedures
   - Keep old functions temporarily for comparison

### **During Refactoring**
1. **Incremental Changes**
   - Refactor one category at a time
   - Test each change thoroughly
   - Keep old and new functions side by side initially

2. **Validation Testing**
   - Compare outputs between old and new functions
   - Performance benchmarking
   - Load testing for critical functions

### **After Refactoring**
1. **Cleanup**
   - Remove old functions after validation period
   - Update documentation
   - Train team on new function structure

---

## 📝 Migration Notes

### **Database Migrations**
- Each refactoring phase should be a separate migration
- Include rollback procedures
- Test migrations on development environment first

### **Application Code Updates**
- Update Swift code to use new function signatures
- Replace direct SQL calls with new RPC functions
- Update error handling for new function behaviors

### **Monitoring**
- Add logging to track function usage
- Monitor performance metrics
- Set up alerts for function failures

---

## 🎯 Success Metrics

### **Quantitative Goals**
- **Reduce function count:** From 36 to ~25 functions
- **Reduce average function length:** Target <50 lines per function
- **Improve test coverage:** 90%+ coverage for all RPC functions
- **Performance improvement:** <10ms average response time

### **Qualitative Goals**
- **Better maintainability:** Easier for new developers to understand
- **Improved reliability:** Fewer bugs in production
- **Enhanced security:** Consistent validation and auditing
- **Better documentation:** Clear purpose for each function

---

## 🔧 Implementation Checklist

### **Pre-Implementation**
- [ ] Review current function usage in Swift code
- [ ] Create comprehensive test suite
- [ ] Set up monitoring and alerting
- [ ] Prepare rollback procedures

### **Phase 1: Cleanup & Counters**
- [ ] Implement unified cleanup function
- [ ] Migrate existing cleanup calls
- [ ] Implement unified counter function
- [ ] Update trigger functions
- [ ] Test thoroughly

### **Phase 2: Conversations & Validation**
- [ ] Break down complex conversation function
- [ ] Implement new conversation functions
- [ ] Enhance validation functions
- [ ] Update application calls

### **Phase 3: Security & Final Cleanup**
- [ ] Reorganize security functions
- [ ] Remove deprecated functions
- [ ] Update documentation
- [ ] Performance optimization

---

*Last Updated: January 4, 2025*
*Project: STILL iOS App - Supabase RPC Functions*

--- MarkDown/database-functions.md ---

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

--- MarkDown/geminiadvise(2).md ---

# Supabase Security Audit Report (2025年7月27日)

このレポートは、STILLプロジェクトのSupabaseデータベースおよび関連するクライアントサイドコードに対するセキュリティ監査の結果をまとめたものです。RLS（Row Level Security）の検証、SQLインジェクションの可能性、クライアントサイドの入力値検証、および機密情報のハードコードに関する調査を実施しました。

## 1. RLS (Row Level Security) 検証結果

SupabaseのRLSポリシーは、匿名アクセスからのデータ保護において適切に機能していることが確認されました。

*   **テスト対象テーブル:** `profiles`, `posts`, `likes`, `follows`, `notifications`
*   **結果:** すべてのテーブルで、匿名アクセス時に空の配列 `[]` が返され、RLSが有効に機能していることが確認されました。

## 2. SQLインジェクションとデータベース関数のレビュー

データベースに定義されているSQL関数とRLSポリシーの論理的なレビューを実施しました。

### 2.1. 発見された脆弱性

1.  **【重大】情報漏洩 (CWE-200): 他ユーザーの会話リスト閲覧**
    *   **対象関数:** `get_user_conversations(user_id_param uuid)`, `get_user_group_conversations(user_id_param uuid)`
    *   **内容:** これらの関数は `SECURITY DEFINER` で実行され、引数として `user_id_param` を受け取ります。これにより、認証済みユーザーは他のユーザーのIDを指定することで、そのユーザーのダイレクトメッセージおよびグループチャットのリストを閲覧できてしまいます。
    *   **該当ファイル:**
        *   `supabase/migrations/20250117000001_create_get_user_conversations_function.sql`
        *   `supabase/migrations/20250120000001_fix_get_user_conversations_function.sql`
        *   `supabase/migrations/20250719000001_add_group_chat_functionality.sql`
        *   `supabase/migrations/20250726_functions_and_views_backup.sql`
    *   **推奨される修正:** これらの関数は、引数を取らずに `auth.uid()` を使用して現在ログインしているユーザー自身の会話情報のみを返すように修正すべきです。

2.  **【中】なりすまし/不正なデータ注入 (CWE-284): 通知の不正作成**
    *   **対象テーブル:** `notifications`
    *   **内容:** `notifications` テーブルの `insert` ポリシーが `WITH CHECK (true)` となっているため、`user_id` の所有者チェックが行われません。これにより、認証済みユーザーは `user_id` を偽って他人宛の通知を自由に作成できてしまいます。
    *   **該当ファイル:** `supabase/migrations/20250726_create_notifications_table.sql`
    *   **推奨される修正:** `insert` ポリシーを `FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id)` に変更し、ユーザーが自分宛の通知のみ作成できるようにするか、または `FOR INSERT TO service_role WITH CHECK (true)` として、通知の挿入を `service_role` のみに限定すべきです。

3.  **【低】不十分なサニタイズ処理 (CWE-79, CWE-89): `sanitize_text_input` 関数**
    *   **対象関数:** `public.sanitize_text_input(input_text text, max_length integer)` (PostgreSQL関数)
    *   **内容:** この関数はブラックリスト方式でXSSやSQLインジェクションのパターンを除去しようとしますが、このようなアプローチは完全ではなく、巧妙な攻撃をバイパスされる可能性があります。
    *   **該当ファイル:** `supabase/migrations/20250726_functions_and_views_backup.sql`
    *   **推奨される修正:** データベース側でこの関数に過度に依存せず、アプリケーション側でパラメータ化クエリを徹底し、入力値の検証を厳密に行うべきです。

### 2.2. その他のレビュー結果

*   `profiles`, `posts`, `likes`, `follows`, `conversations`, `conversation_participants`, `messages`, `group_members` テーブルのRLSポリシーは、論理的に適切に設定されており、SQLインジェクションや不正なデータ操作のリスクは低いと判断されました。
*   `anonymize_user_data` や `export_user_data` のような機密性の高い操作を行う関数は、`auth.uid()` を使ってユーザー自身のデータに限定するチェックが適切に実装されていました。

## 3. クライアントサイド入力値検証の確認

主要なユーザー入力機能において、クライアントサイドでの入力値検証が欠落していることが判明しました。

### 3.1. 発見された脆弱性

1.  **【中】クライアントサイド入力値検証の欠落 (CWE-20): 投稿作成機能**
    *   **対象:** キャプション (`caption`)、位置情報 (`locationName`)
    *   **内容:** `CreatePostViewModel.swift` 内で、ユーザー入力がデータベースに送信される前に `InputValidator` を使ったサニタイズ・検証が行われていません。
    *   **影響:** XSS、不正なデータ注入、UIの崩れなど。
    *   **該当ファイル:** `still/Features/CreatePost/ViewModels/CreatePostViewModel.swift`
    *   **推奨される修正:** `InputValidator.validatePostContent()` や `InputValidator.sanitizeText()` を使用して、データベースに保存する前にこれらのフィールドを検証・サニタイズすべきです。

2.  **【中】クライアントサイド入力値検証の欠落 (CWE-20): プロフィール編集機能**
    *   **対象:** ユーザー名 (`username`)、表示名 (`displayName`)、自己紹介 (`bio`)
    *   **内容:** `MyPageViewModel.swift` 内で、ユーザー入力がデータベースに送信される前に `InputValidator` を使ったサニタイズ・検証が行われていません。
    *   **影響:** XSS、不正なデータ注入、UIの崩れなど。
    *   **該当ファイル:** `still/Features/MyPage/ViewModels/MyPageViewModel.swift`
    *   **推奨される修正:** `InputValidator.sanitizeText()` や適切なバリデーション関数を使用して、データベースに保存する前にこれらのフィールドを検証・サニタイズすべきです。

3.  **【中】クライアントサイド入力値検証の欠落 (CWE-20): メッセージ送信機能**
    *   **対象:** メッセージ本文 (`content`)
    *   **内容:** `MessageService.swift` 内で、メッセージ本文が暗号化される前に `InputValidator` を使ったサニタイズ・検証が行われていません。特に `last_message_preview` には暗号化されていない生データが保存されるため、XSSのリスクがあります。
    *   **影響:** XSS、不正なデータ注入、UIの崩れなど。
    *   **該当ファイル:** `still/Core/Services/MessageService.swift`
    *   **推奨される修正:** `InputValidator.sanitizeText()` を使用して、メッセージ本文を暗号化する前、および `last_message_preview` に設定する前にサニタイズすべきです。

### 3.2. `InputValidator.swift` の評価

*   `still/Core/Security/InputValidator.swift` には、多機能で堅牢な入力値検証・サニタイズの仕組みが用意されています。XSSやSQLインジェクション対策のためのサニタイズ関数、メールアドレス、パスワード、URL、電話番号、投稿コンテンツの検証関数が含まれています。
*   このバリデーター自体は適切に設計されていますが、**アプリケーションの各入力箇所で適切に呼び出されていない**ことが問題です。

## 4. 機密情報漏洩の再確認

プロジェクト全体を対象に、APIキー、シークレット、トークン、パスワードなどの機密情報がハードコードされていないかを再確認しました。

### 4.1. 発見された懸念点

*   **`.mcp.json` ファイル内の `SUPABASE_ACCESS_TOKEN`:**
    *   このファイルに `SUPABASE_ACCESS_TOKEN` が記載されています。このファイルがどのような目的で使用されているか不明ですが、もしこれが本番環境で使用されるアクセスキーである場合、ソース管理下に置くべきではありません。
    *   **推奨される対応:** このファイルの用途を確認し、もし機密情報を含む場合は `.gitignore` に追加するか、より安全な方法で管理することを検討してください。

### 4.2. その他のレビュー結果

*   以前修正した `still/Supabase.swift` 以外のアプリケーションコード内で、直接的にAPIキーやパスワードなどの機密情報がハードコードされている箇所は見当たりませんでした。
*   `Secrets.plist` を `.gitignore` で管理し、`KeychainManager` を使ってキーチェーンに機密情報を保存する設計は、iOSアプリケーションにおけるベストプラクティスに沿っています。
*   ドキュメントやテストファイル内のサンプル、モックデータは問題ありません。

## 結論と次のステップ

本監査により、STILLプロジェクトにはいくつかのセキュリティ上の脆弱性が存在することが明らかになりました。特に、**他ユーザーの会話リストを閲覧できてしまう情報漏洩の脆弱性**は重大であり、最優先で修正すべきです。

次に、これらの発見された脆弱性を修正することをお勧めします。


--- MarkDown/geminiadvise.md ---

[File content partially truncated: some lines exceeded maximum length of 2000 characters.]
タイトル:Supabase セキュリティ設定と確認

iOSアプリ開発者のためのSupabaseセキュリティ堅牢化バイブル：見過ごされがちな設定から高度な防御戦略まで序論本レポートは、Supabaseをバックエンドとして利用するiOSアプリケーション開発者向けに、単なるセキュリティ設定のチェックリストを超えた、包括的かつ実践的な堅牢化戦略を提供することを目的とします。今日のデジタル環境において、アプリケーションのセキュリティは機能性と同等、あるいはそれ以上に重要です。特に、クライアントサイド（iOSアプリ）から直接データベースAPIを操作できるSupabaseの利便性は、裏を返せば、厳格なセキュリティモデルの構築を開発者自身に委ねることを意味します。本レポートの核心的な哲学は「多層防御（Defense in Depth）」です。単一のセキュリティ対策が完璧であることはあり得ません。したがって、我々はデータの核心から始まり、API、認証、アプリケーションロジック、そしてユーザーとの接点に至るまで、複数の防御層を構築していきます。ある層が突破されたとしても、次の層が脅威を食い止める。このアプローチにより、高度なハッキング攻撃にも耐えうる、真に堅牢なシステムを設計します。本レポートを通じて、推奨される各セキュリティ制御を「どのように（How）」実装するかだけでなく、「なぜ（Why）」それが必要なのかという根本的な原則を深く理解し、将来のアーキテクチャ設計においても安全な判断を下せるようになることを目指します。第1章：Supabaseセキュリティの礎：Row-Level Security (RLS) の完全マスターRow-Level Security (RLS) は、Supabaseにおけるセキュリティアーキテクチャの議論の余地なき基盤です。これは、データベースバックエンドのAPIをiOSアプリのようなクライアントアプリケーションに直接公開することを安全にするための、最も重要なメカニズムです。この章では、RLSの基本原則から高度な実装パターンまでを網羅的に解説します。1.1. なぜRLSが不可欠なのか：「デフォルトで拒否」の原則RLSが他のセキュリティ対策と一線を画すのは、それがアプリケーション層ではなく、データ層でセキュリティを強制する点にあります 1。アプリケーションのコードにはバグが潜む可能性がありますが、データベースレベルで定義されたポリシーは、クエリの発信元（iOSアプリ、管理ツール、あるいは悪意のあるスクリプト）に関わらず、すべてのデータアクセス要求に対して一貫して適用されます。テーブルに対してRLSを有効化すると、その瞬間からデフォルトの挙動は「すべてのアクセスを拒否」に変わります 3。SELECT、INSERT、UPDATE、DELETEのいずれの操作も、明示的にアクセスを許可するポリシーを作成しない限り、実行できなくなります。この「デフォルトで拒否」という姿勢は、セキュアなシステムを構築する上での基本中の基本です。この原則の重要性を理解するために、具体的なシナリオを考えてみましょう。ある開発者が、ユーザーが閲覧権限を持つ投稿のみを表示するiOSアプリを開発したとします。UI上では、権限のある投稿を取得するボタンしか表示されないかもしれません。しかし、悪意のあるユーザーがプロキシツール（例：Burp Suite）を用いてアプリのAPIリクエストを傍受し、改ざんして「すべての投稿を取得する（select *）」というリクエストを送信したとします。RLSがなければ、この不正なリクエストはデータベースに直接届き、すべての投稿データが漏洩してしまいます。しかし、RLSが適切に設定されていれば、たとえアプリケーション層が侵害され不正なクエリが送信されたとしても、データベース自体が最終的な門番として機能します。データベースは、USING (auth.uid() = user_id)のようなポリシーを強制的に適用し、条件に合致するデータのみをフィルタリングしてから結果を返します 2。このように、RLSはデータアクセスルールをアプリケーションのビジネスロジックから根本的に切り離し、予期せぬクライアントサイドの脆弱性に対する堅牢なセーフティネットを提供するのです。1.2. RLSの有効化：最初の、そして最も重要な一歩RLSを有効化するプロセスは単純ですが、これを怠ることは致命的なセキュリティホールに繋がります。ダッシュボードからの有効化Supabaseのダッシュボードで Database -> Tables と進み、対象のテーブルを選択後、Enable Row Level Security のトグルをオンにします 6。ダッシュボード経由で作成されたテーブルでは、この設定はデフォルトで有効に... [truncated]
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
2設定の確認（Verification）データベース内のすべてのテーブルでRLSが有効になっているかを確認することは、定期的なセキュリティ監査の重要な一部です。以下のクエリを実行することで、publicスキーマ内の全テーブルのRLSステータスを一覧できます。SQL-- 'public'スキーマ内の全テーブルとそのRLSステータスをリストアップする
SELECT
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
-- 想定される結果: 機密データを扱うすべてのテーブルにおいて、'rowsecurity'カラムが't'（true）であること。
このクエリの結果、機密データを保持するテーブルの rowsecurity が f (false) になっている場合、それは重大なセキュリティリスクを示しています。1.3. 高度なアクセスポリシーの設計：iOSアプリのシナリオ別実践ガイドここでは、一般的なソーシャルメディア系iOSアプリで想定される機能に基づいた、実践的なRLSポリシーのSQL記述例を提示します。これらは、より複雑なロジックを構築するためのテンプレートとして利用できます。シナリオ1：ユーザープロフィール要件：全ユーザーのプロフィールを閲覧できるが、更新は自分自身のものに限る。SQL-- ポリシー: 全ユーザーがプロフィールを閲覧できる
CREATE POLICY "Public profiles are viewable by everyone."
  ON public.profiles FOR SELECT
  USING (true);

-- ポリシー: ユーザーは自身のプロフィールのみ更新できる
CREATE POLICY "Users can update their own profile."
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
7シナリオ2：投稿要件：全ユーザーの投稿を閲覧できるが、投稿の作成・編集・削除は自分自身のものに限る。SQL-- ポリシー: ユーザーは自身の投稿のみ作成できる
CREATE POLICY "Users can insert their own posts."
  ON public.posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ポリシー: ユーザーは自身の投稿のみ削除できる
CREATE POLICY "Users can delete their own posts."
  ON public.posts FOR DELETE
  USING (auth.uid() = user_id);

-- ポリシー: ユーザーは自身の投稿のみ更新できる
CREATE POLICY "Users can update their own posts."
  ON public.posts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
7シナリオ3：プライベートメッセージ要件：ユーザーは、自分が送信者または受信者であるメッセージのみを閲覧できる。SQL-- 'messages'テーブルに'sender_id'と'receiver_id'カラムが存在すると仮定
CREATE POLICY "Users can read their own messages."
  ON public.messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
9シナリオ4：フォローシステム要件：ユーザーは、自分がフォローしているユーザーの投稿、または自分自身の投稿のみを閲覧できる。SQL-- 'followers'テーブルに'follower_id'と'following_id'カラムが存在すると仮定
CREATE POLICY "Users can see posts from followed users and their own."
  ON public.posts FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id IN (SELECT following_id FROM public.followers WHERE follower_id = auth.uid())
  );
1.4. USINGとWITH CHECK句の戦略的活用RLSポリシーを効果的に記述するためには、USING句とWITH CHECK句の役割を正確に理解することが不可欠です。USING句（SELECT, UPDATE, DELETE用）: この句は、データベースに既に存在する行を評価対象とします。どの行が操作の対象として見えるか、あるいは選択可能かを決定します。「ユーザーはこの行を操作対象として認識できるか？」という問いに答えるものです 10。WITH CHECK句（INSERT, UPDATE用）: この句は、これから挿入または更新されようとしている新しいデータを評価対象とします。この変更によって生成される新しい行が、引き続きポリシーの条件を満たすかどうかを検証します。「提案されている変更はルールに準拠しているか？」という問いに答えるものです 3。UPDATEポリシーの重要性: UPDATE操作は、既存の行を新しいデータで置き換えるため、USINGとWITH CHECKの両方を使用することが極めて重要です。USINGは、ユーザーが更新対象の行にアクセスできるかをチェックし、WITH CHECKは、ユーザーがその行を自分にアクセス権のない状態（例えば、user_idを他人のものに変更する）に更新できないように保証します 3。この両方を用いることで、データの所有権が不正に変更されるのを防ぐことができます。1.5. 高度なRLSパターン：テーブル結合とSECURITY DEFINER関数の安全な利用法より複雑なアプリケーションでは、他のテーブルの情報を参照するポリシーが必要になります。テーブル結合を含むポリシーあるテーブルのポリシーが、別のテーブル（例：user_rolesテーブル）のデータを確認する必要がある場合、サブクエリやEXISTS句が用いられます。SQL-- ポリシー: 'admin'ロールを持つユーザーは'documents'テーブルの全レコードを閲覧できる
CREATE POLICY "Admins can view all documents."
  ON public.documents FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.user_roles
      WHERE user_roles.user_id = auth.uid() AND user_roles.role = 'admin'
    )
  );
6SECURITY DEFINERの罠と安全な利用法時として、ポリシーが参照しようとするテーブル自体にRLSが設定されており、現在のユーザーにはそのテーブルを読み取る権限がない、というジレンマが発生することがあります。この問題を解決するのがSECURITY DEFINER関数です。この関数は、呼び出し元のユーザーではなく、関数の所有者の権限で実行されます 11。これは非常に強力ですが、同時に重大なセキュリティリスクも伴います。このリスクの核心は、PostgreSQLのsearch_pathの挙動にあります。search_pathは、データベースオブジェクト（関数や演算子など）を探す際にPostgreSQLが参照するスキーマの順序を定義します。もし開発者がSECURITY DEFINER関数にsearch_pathを明示的に設定しなかった場合、攻撃者がpublicスキーマ（デフォルトのsearch_pathに含まれることが多い）にCREATE権限を持っていると、+演算子のような正当なオブジェクトと同名の悪意のある関数や演算子を作成できてしまいます。そして、高い権限を持つSECURITY DEFINER関数が呼び出された際に、意図せず攻撃者のコードが関数の所有者の権限で実行され、権限昇格攻撃に繋がる可能性があります 12。この脆弱性を回避するためのベストプラクティスは、SECURITY DEFINER関数には常に安全なsearch_pathを設定し、信頼できないロールからはpublicスキーマのCREATE権限を剥奪することです。SQL-- SECURITY DEFINER関数の安全な実装例
CREATE OR REPLACE FUNCTION is_team_member(team_id_to_check int)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
-- この部分が極めて重要！
SET search_path = pg_catalog, public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.members
    WHERE members.team_id = team_id_to_check AND members.user_id = auth.uid()
  );
$$;
31.6. RLSのパフォーマンス：高速かつ安全なポリシー記述の秘訣複雑なRLSポリシーは、すべての行アクセスに対して適用されるため、クエリのパフォーマンスに影響を与える可能性があります。安全性を損なうことなくパフォーマンスを維持するためには、以下のテクニックが有効です。インデックスの活用: RLSポリシー内で使用されるカラム（例：user_id, team_id）には、必ずインデックスを作成してください。これにより、ポリシー評価の際のデータ検索が劇的に高速化されます 13。関数の結果のキャッシュ: auth.uid()のような関数呼び出しをSELECT文でラップします。これにより、PostgreSQLのクエリオプティマイザは、ステートメントの実行中に一度だけ関数を評価し、その結果をキャッシュして使い回します。各行ごとに関数を再評価するのを避けるため、パフォーマンスが大幅に向上します 13。非推奨: USING (auth.uid() = user_id)推奨: USING ((SELECT auth.uid()) = user_id)RLSはセキュリティ、WHEREはフィルタリング: RLSは最後の砦としてのセキュリティ層であり、アプリケーションの主要なデータフィルタリング手段として依存すべきではありません。アプリケーションのコードでは、常に明示的なWHERE句（例：.eq('user_id', userId)）を追加してください。これにより、クエリオプティマイザがインデックスをより効率的に利用できるようになり、クエリ全体のパフォーマンスが向上します 14。1.7. RLS設定の検証チェックリストと確認コマンド集定義したRLSが意図通りに機能しているかを確認するための、具体的な検証方法をまとめます。全機密テーブルでRLSが有効か？: 1.2で示したpg_tablesをクエリするコマンドを使用します。RLSが有効なテーブルにはポリシーが定義されているか？: RLSが有効でポリシーが一つも定義されていないテーブルは、誰からもアクセスできなくなります。ダッシュボードのAuthentication > Policiesで確認します。特定のユーザーとしてポリシーをテストするには？: SupabaseのSQLエディタが提供するユーザー偽装（impersonation）機能が最も簡単です 2。または、psqlセッションで以下のコマンドを実行することでもシミュレーションが可能です 6。SQL-- 特定のユーザーからのリクエストをシミュレート
SET ROLE authenticated;
SET request.jwt.claims = '{"sub":"<テストしたいユーザーのUUID>", "role":"authenticated"}';

-- テストしたいクエリを実行
SELECT * FROM public.posts;

-- セッションをリセット
RESET ROLE;
第2章：APIキー管理：バックエンドへの正面玄関を守るAPIキーは、Supabaseプロジェクトへのアクセスを制御する第一の防御線です。この層が破られれば、RLSを含む他のすべてのセキュリティ対策が無意味になる可能性があります。APIキーの役割と適切な管理方法を理解することは、堅牢なアプリケーションを構築するための必須条件です。2.1. APIキーの解剖学：anonキーとservice_roleキーSupabaseは主に2種類のAPIキーを提供します。それぞれの役割と権限は根本的に異なります。anonキー（Anonymous/Public Key）: これは低権限のキーであり、iOSアプリのようなクライアントサイドでの使用を意図しています。このキーを使ってリクエストが行われた際、ユーザーがログインしていればPostgresのauthenticatedロールが、ログインしていなければanonロールが使用されます。このキーの安全性は、RLSポリシーが正しく、かつ厳格に実装されているかどうかに完全に依存します 15。service_roleキー（Admin Key）: これは最高権限を持つキーです。このキーを使用すると、Postgresのservice_roleロールが適用され、このロールはBYPASSRLS権限を持つため、すべてのRLSポリシーを完全にバイパスします。これは、信頼されたサーバー間の通信や、管理者用のスクリプトなど、バックエンド環境でのみ使用されることを想定しています 3。2.2. 黄金律：service_roleキーは決してクライアントに含めてはならないservice_roleキーをiOSアプリのソースコード内に埋め込むことは、開発者が犯しうる最も壊滅的なセキュリティ上の過ちです。このキーが漏洩すると、攻撃者はデータベース全体に対する無制限の管理者アクセス権（神モード）を手に入れることになり、時間と労力をかけて構築したRLSポリシーはすべて無力化されます 15。攻撃者は、iOSアプリを逆コンパイルしたり、ネットワークトラフィックを監視したりすることで、ハードコードされたキーを比較的容易に抽出できます。このキーは、いかなる状況下でもクライアントサイドに存在してはなりません。2.3. モダンなアプローチ：失効可能なpublishableキーとsecretキーへの移行Supabaseは、従来のJWTベースのキーが抱えるセキュリティ上の弱点を克服するため、新しいタイプのAPIキーを導入しました 16。publishableキー: 従来のanonキーを置き換えるものです。secretキー: 従来のservice_roleキーを置き換えるものです。これらの新しいキーへの移行が強く推奨される理由は、キーの「失効可能性」にあります。従来のanonキーとservice_roleキーは、実はプロジェクトのマスターJWTシークレットで署名された、有効期間の長いJWT（JSON Web Token）です 16。もしservice_roleキーが漏洩した場合、それを無効化する唯一の方法は、プロジェクト全体のJWTシークレットをローテーションすることでした。しかし、JWTシークレットのローテーションは、すべてのユーザーセッションを強制的に無効にし、関連するすべてのキーを更新する必要がある、サービス停止を伴う非常に影響の大きな操作です 16。対照的に、新しいsecretキーはJWTではなく、独立した不透明なトークンです。これにより、個々のキーを独立して作成・削除できます。もし一つのsecretキーが漏洩しても、ダッシュボードからそのキーを即座に削除し、新しいキーを生成するだけで対応が完了します。このプロセスはダウンタイムを一切伴いません 19。この変更は、管理が困難でリスクの高いモデルから、現代的なセキュリティベストプラクティス（即時失効）に沿った、柔軟で運用上安全なモデルへの根本的な転換を意味します。2.4. あなたのiOSプロジェクトに潜む漏洩キーを監査する方法service_roleキーが誤ってクライアントコードに含まれていないかを確認するための監査は、不可欠なプロセスです。コードスキャン: Swiftのプロジェクト全体で、"service_role"という文字列や、キー自体の特徴的なフォーマット（eyJ...）を検索します。環境変数の確認: APIキーは、ソースコードにハードコードするのではなく、ビルド時の環境変数など、安全な方法で読み込まれていることを確認します。サードパーティツールの活用: SecureVibing 21 や SupaSniffer 22 のようなツールは、漏洩したAPIキーやRLSの不備といった一般的な設定ミスを自... [truncated]
SELECT id, raw_app_meta_data, raw_user_meta_data FROM auth.users;
3.2. Swiftにおけるセキュアなトークンハンドリング：キーチェーンによるJWTの保存と更新ユーザーがログインすると、Supabaseは短命のaccess_tokenと長命のrefresh_tokenを提供します。アプリを再起動してもセッションを維持するためには、これらのトークンをデバイス上に安全に永続化する必要があります。不適切な方法：UserDefaultsへの保存:UserDefaultsは、暗号化されていないプロパティリスト（plist）ファイルとしてデバイスに保存されます。ファイルシステムにアクセスできる攻撃者にとっては、トークンを盗み出すことは些細なことです。ここに機密情報を保存するべきではありません 23。適切な方法：キーチェーンへの保存:**キーチェーン（Keychain）**は、パスワードやトークン、暗号鍵などの機密情報を安全に保管するためにAppleが提供する、システムレベルの暗号化されたデータベースです。トークンの保存には、必ずキーチェーンを使用してください 23。実装パターンとリフレッシュトークンのライフサイクル:セッション管理の核心は、リフレッシュトークンの安全なライフサイクルにあります。access_tokenはAPIリクエストの都度送信されるため、有効期間は短く（例：15分〜1時間）設定し、万が一漏洩した際の影響範囲を限定します。refresh_tokenは有効期間が長く（例：数日〜数週間）、キーチェーンに安全に保管します。このトークンの唯一の目的は、新しいaccess_tokenとrefresh_tokenのペアを取得することです。API呼び出しが「トークン期限切れ」エラーで失敗した場合、アプリのネットワーク層は自動的かつ透過的に、キーチェーンからrefresh_tokenを取り出して新しいセッションを取得するべきです。refresh_token自体が無効（期限切れ、またはサーバー側で失効）になった場合にのみ、ユーザーに再ログインを要求します。このフローは、短い有効期間のアクセストークンというセキュリティ原則を守りつつ、ユーザーにシームレスな体験を提供します。ユーザーのパスワードを保存して再認証するのは、絶対に行ってはならないアンチパターンです 27。以下は、キーチェーンラッパーライブラリ（例：SwiftKeychainWrapper）を使用した概念的な実装コードです。Swiftimport SwiftKeychainWrapper
import Supabase

class AuthManager {
    static let shared = AuthManager()
    private let supabase = SupabaseClient(supabaseURL: URL(string: "YOUR_URL")!, supabaseKey: "YOUR_ANON_KEY")

    // ログイン成功時にトークンをキーチェーンに保存
    func saveSession(_ session: Session) {
        KeychainWrapper.standard.set(session.accessToken, forKey: "supabase_access_token")
        KeychainWrapper.standard.set(session.refreshToken, forKey: "supabase_refresh_token")
    }

    // アプリ起動時にセッションを復元
    func restoreSession() async -> Bool {
        guard let refreshToken = KeychainWrapper.standard.string(forKey: "supabase_refresh_token") else {
            return false
        }
        do {
            let session = try await supabase.auth.refreshSession(refreshToken: refreshToken)
            self.saveSession(session)
            // Supabaseクライアントにセッションをセット
            try await supabase.auth.setSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )
            return true
        } catch {
            // リフレッシュ失敗。トークンをクリアして再ログインを促す
            self.clearSession()
            return false
        }
    }

    func clearSession() {
        KeychainWrapper.standard.removeObject(forKey: "supabase_access_token")
        KeychainWrapper.standard.removeObject(forKey: "supabase_refresh_token")
    }
}
3.3. 「Sign in with Apple」の導入：ネイティブで安全な認証体験の実装Supabaseは、AppleのAuthenticationServicesフレームワークを使用したネイティブの「Sign in with Apple」を直接サポートしています 28。このフローでは、まずデバイス上でAppleからid_tokenを取得し、それをSupabaseのsignInWithIdToken()メソッドに渡します。SupabaseはAppleとトークンを検証し、成功すれば新しいユーザーセッションを作成します 28。これは、ネイティブアプリ内でWebViewベースのOAuthフローを使用するよりも、はるかに安全で優れたユーザー体験を提供します。3.4. 認証機能の強化基本的な認証フローに加えて、以下の機能を導入することでセキュリティをさらに強化できます。多要素認証（MFA）: SupabaseダッシュボードのAuthentication -> ProvidersからMFAを有効化できます。これは、認証情報が盗まれた際の不正アクセスに対する非常に強力な防御層となります 18。強力なパスワードポリシーとメール確認: パスワードの最低文字数を設定し、メールアドレスの確認を必須にすることで、脆弱なパスワードの使用や偽のアカウントによるサインアップを防ぎます。これらは実装が容易でありながら効果の高い堅牢化策です 18。第4章：多層防御：高度な堅牢化技術RLSと認証という中核的なセキュリティ設定の上に、さらなる防御層を積み重ねることで、アプリケーション全体の耐性を飛躍的に向上させることができます。この章では、より高度な堅牢化技術について解説します。4.1. Edge Functionsによるビジネスロジックの保護iOSアプリ内のロジックはすべてクライアントサイドに存在し、リバースエンジニアリングや改ざんの対象となり得ます。価格計算や権限チェックのような機密性の高いビジネスロジックをクライアントに置くことは、重大な脆弱性です。解決策は、これらの重要なロジックをSupabase Edge Functionsに移行することです。Edge Functionsは、安全なサーバーサイド環境で実行されるTypeScript（Deno）の関数です 18。例えば、eコマースアプリで最終的な支払い金額を計算するロジックを考えます。もし価格 * 数量 * (1 - 割引率)という計算がiOSアプリ内で行われていると、攻撃者はリクエストを改ざんして不正な割引を適用するかもしれません。この計算をEdge Functionに移行し、クライアントからは商品IDと数量のみを送信するようにすれば、信頼できるサーバーが権威ある最終価格を計算するため、この種のリスクを排除できます。Edge Functions自体も保護する必要があります。URLを直接呼び出すことが可能なため、関数内で必ずユーザー認証をチェックする処理を実装してください（例：const { user } = await supabase.auth.getUser(jwt)）18。4.2. ファイルストレージの封鎖：プライベートバケットと署名付きURLの徹底公開（Public）設定のストレージバケットは、その名の通り、誰でもアクセス可能です。ユーザーがアップロードした領収書や、友人だけに公開するつもりのプロフィール写真のような機密ファイルを公開バケットに保存することは、頻発するデータ漏洩の原因です。安全なファイルストレージを実現するための手順は以下の通りです。プライベートバケットの使用: デフォルトでストレージバケットは「Private」に設定します 18。ストレージRLSの活用: データベーステーブルと同様に、storage.objectsテーブルに対してRLSポリシーを記述し、ファイルへのアクセスを制御します。一般的なパターンは、user_idごとにフォルダを整理し、ユーザーが自身のフォルダにのみアクセスできるようにするものです 2。署名付きURL（Signed URLs）の利用: プライベートバケット内のファイルへ一時的にアクセスを許可する場合（例：ユーザーがアプリ内で自身のプロフィール写真を表示する）、サーバーサイド（例：Edge Function内）で有効期間の短い署名付きURLを生成します。これにより、ファイルを恒久的に公開することなく、時間とアクセス先を限定した安全なアクセスを提供できます 18。4.3. データベースレベルの堅牢化：RLSを超えてRLSは強力ですが、データベースレベルで考慮すべきセキュリティ対策はそれだけではありません。4.3.1. SECURITY DEFINERの罠第1... [truncated]
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- データ挿入時
INSERT INTO user_profiles (id, ssn_encrypted)
VALUES (auth.uid(), pgp_sym_encrypt('123-45-678', 'your-secret-encryption-key'));

-- データ取得時
SELECT id, pgp_sym_decrypt(ssn_encrypted, 'your-secret-encryption-key'::bytea) AS ssn
FROM user_profiles WHERE id = auth.uid();
30鍵管理の重要性: 上記の'your-secret-encryption-key'は、SupabaseのEdge Functionのシークレット管理機能など、安全な場所に保管する必要があり、決してデータベース内やクライアントコードにハードコードしてはなりません。4.4. 濫用の抑制：認証およびAPIへのレート制限の実装ブルートフォース攻撃、APIのスパム的利用、サービス妨害（DoS）攻撃からアプリケーションを保護するためには、レート制限が不可欠です。Supabase組み込みの制限: Supabaseは、/auth/v1/signupや/auth/v1/tokenといった認証エンドポイントに対して、デフォルトのレート制限を設けています 32。これは良いベースラインですが、一般的なAPI呼び出しに対してユーザー単位の制限を提供するものではありません。カスタムのユーザー単位レート制限: 「ユーザーは1分間に5回までしか投稿できない」といったアプリケーション固有の制限を実装するには、カスタムロジックが必要です。推奨される実装パターンは、Edge Functionと、Upstash Redisのような低遅延の外部データストアを組み合わせる方法です 33。データベースAPIへのプロキシとして機能するEdge Functionを作成します。関数内で、ユーザーのID（auth.uid()）またはIPアドレスを取得します。Redisを使用して、その識別子に対するカウンターをインクリメントし、有効期限を設定します。カウンターが制限を超えた場合はHTTP 429 "Too Many Requests"エラーを返し、そうでなければデータベース操作を続行します 33。4.5. 監査証跡の構築：不審なアクティビティの監視と記録多くのアプリケーションにとって、「誰が」「いつ」「何を」変更したのかを追跡できることは、セキュリティインシデントの調査やコンプライアンス要件のために極めて重要です。Supabaseは、すぐに使える詳細な監査ログ機能を提供していないため、自身で構築する必要があります 1。最も効果的な実装パターンは、Postgresのトリガー機能を利用する方法です。変更イベントを保存するためのaudit_logテーブルを作成します 36。操作の種類（INSERT, UPDATE, DELETE）、テーブル名、変更前後の行データ（JSONB形式）、そしてJWTから取得したユーザー情報（例：auth.jwt() ->> 'email'）を記録する、汎用的なトリガー関数を作成します 36。機密データを扱うテーブルに対して、データが変更された後にこの関数を実行するトリガーを作成します。SQL-- 監査ログを記録するトリガー関数の例
CREATE OR REPLACE FUNCTION log_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
-- SECURITY DEFINERを使用し、どのロールからでも実行できるようにする
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.audit_log (
    user_email,
    table_name,
    action,
    old_record,
    new_record
  )
  VALUES (
    auth.jwt() ->> 'email',
    TG_TABLE_NAME,
    TG_OP,
    CASE WHEN (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN to_jsonb(OLD) ELSE NULL END,
    CASE WHEN (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END
  );
  RETURN NEW;
END;
$$;

-- テーブルにトリガーを適用
CREATE TRIGGER posts_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.posts
FOR EACH ROW EXECUTE FUNCTION log_changes();
第5章：総括：包括的セキュリティチェックリストと検証プロトコル本レポートで解説した多岐にわたるセキュリティ対策を統合し、アプリケーションのセキュリティ体制を定期的かつ体系的に監査するための、実践的な検証プロトコルを提示します。このチェックリストは、単なる一読で終わるのではなく、開発ライフサイクルを通じて繰り返し参照されるべき実用的なツールとして設計されています。各項目は、セキュリティ上の懸念、それを検証するための具体的なコマンドやアクション、そして期待される安全な状態を明確に示しています。このプロトコルを用いることで、開発者は自身のアプリケーションのセキュリティレベルを客観的に測定し、潜在的な脆弱性をプロアクティブに特定・修正することが可能になります。Supabaseセキュリティ検証プロトコルセキュリティ領域制御・設定項目検証方法（SQL/コマンド/アクション）期待される安全な状態重要度データアクセス (RLS)全ての機密テーブルでRLSが有効化されている。SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = false;クエリ結果に、機密性の高いユーザーデータを格納するテーブルが含まれないこと。高RLSが有効な全テーブルにポリシーが定義されている。ダッシュボードで確認: Authentication > Policies。クライアントからのアクセスが意図されている全てのテーブルに、必要に応じたSELECT, INSERT, UPDATE, DELETEポリシーが存在し、アクセスの隙間がないこと。高RLSポリシーがauth.uid()を正しく使用している。SELECT polname, poldef FROM pg_policies WHERE tablename = 'your_table';poldef（ポリシー定義）に、(auth.uid() = user_id)のような所有権を検証するロジックが含まれていること。高SECURITY DEFINER関数に安全なsearch_pathが設定されている。SQLエディタで関数の定義を確認する。全てのSECURITY DEFINER関数にSET search_path =...句が含まれていること。高APIキーservice_roleキーがクライアントコードに含まれていない。grep -r "service_role" /path/to/your/ios/projectコマンドが何も結果を返さないこと。高新しいpublishableおよびsecretキーに移行済みである。ダッシュボードで確認: Project Settings > API。publishableキーとsecretキーが存在し、使用されていること。可能であればレガシーキーは無効化されていること。中認証JWTはUserDefaultsではなくキーチェーンに保存されている。Swiftコード内でUserDefaults.standard.setがトークンデータと共に使用されていないかレビューする。トークンがUserDefaultsに保存されていないこと。KeychainWrapperのようなセキュアなラッパーが使用されていること。高ロール情報はuser_metadataではなくapp_metadataに保存されている。SELECT id, raw_app_meta_data FROM auth.users WHERE raw_user_meta_data ->> 'role' IS NOT NULL;クエリが何も行を返さないこと。認可データはraw_app_meta_dataにのみ存在すること。高プロジェクトでMFAが有効になっている。ダッシュボードで確認: Authentication > Providers > Email。Enable MFAがオンになっていること。中多層防御機密ファイルはプライベートストレージバケットに保存されている。ダッシュボードで確認: Storage。ユーザー固有のファイルを含むバケットが「Private」とマークされていること。中重要な操作に対してカスタムのレート制限が設定されている。Edge FunctionsやAPIゲートウェイの設定をレビューする。主要なエンドポイントに対して、Redis等を利用したレート制限ロジックが存在すること。中主要なテーブルに対して監査証跡が有効になっている。SELECT objid::regclass, tgname FROM pg_trigger;profiles, postsなどのテーブルにlog_changes関数を実行するトリガーが存在すること。中

タイトル:SupabaseとRow Level Securityに関する客観的分析：高トラフィックなソーシャルアプリケーションへの適合性
SupabaseとRow Level Securityに関する客観的分析：高トラフィックなソーシャルアプリケーションへの適合性第1章 RLS中心アーキテクチャ：アプリケーションセキュリティにおけるパラダイムシフトSupabaseのアーキテクチャを評価する上で、その根幹をなすRow Level Security (RLS) は単なる一機能ではなく、プラットフォーム全体の開発モデルを規定する中心的なセキュリティプリミティブとして理解されなければならない。このアプローチは、伝統的にアプリケーション層に存在した認可ロジックをデータ層、すなわちデータベース自体に移行させるという、根本的なパラダイムシフトを開発者に要求する。1.1 パラダイムの定義：データベースレベル認可 vs. アプリケーションレベル認可従来のウェブアーキテクチャは、クライアントとデータベースの間にミドルウェアやAPIサーバーを配置する多層構造を基本とする。このモデルでは、認可ロジック、すなわち「誰がどのデータにアクセスできるか」という判断は、Node.js、Python、Goなどで記述されたアプリケーションコード内で実行されるのが一般的である 2。対照的に、SupabaseはPostgRESTを活用し、PostgreSQLデータベースを直接RESTful APIとして公開するアーキテクチャを採用している 4。この設計により、クライアントからデータベースへの直接的なアクセスが可能になるため、データベースレベルでの堅牢なセキュリティメカニズムが不可欠となる。ここで中心的な役割を果たすのが、PostgreSQLネイティブの機能であるRLSである。Supabaseのシステムは、認証サービスであるGoTrueとRLSを緊密に統合している。ユーザーが認証されると、GoTrueはJSON Web Token (JWT) を発行する 6。クライアントからのすべてのAPIリクエストにはこのJWTが付与され、APIゲートウェイ（PostgREST）がこれを検証する。検証後、PostgRESTはデータベースセッション内で特定のセッション変数を設定する（例：request.jwt.claims）。これにより、SQLクエリ、特にRLSポリシー内から、現在リクエストを行っているユーザーのID (auth.uid()) やJWTに含まれるその他の情報 (auth.jwt()) に直接アクセスできるようになる 7。この仕組みは「多層防御 (defense in depth)」モデルを形成し、データソースそのものでセキュリティが強制されるため、仮にアプリケーションロジックに不備があったとしても、不正なデータアクセスを防ぐ強力な防衛線となる 8。このアーキテクチャがもたらす最大のトレードオフは、基本的なCRUD操作においてはカスタムのミドルウェアAPIを不要にし、開発を大幅に簡素化する可能性がある一方で、従来アプリケーションコードが担っていた複雑なビジネスロジックや認可判定の責務を、SQLという形でデータベース層に移行させる点にある。1.2 比較分析：RLS vs. Firebase Rules vs. AWS Amplify @authSupabaseのRLS中心アプローチの特性を明確にするため、他の主要なBackend-as-a-Service (BaaS) プラットフォームの認可モデルと比較分析する。Firebase Security RulesFirebaseは、独自のJavaScript風の構文で記述されたセキュリティルールを、NoSQLドキュメントデータベース（Firestore）に適用するモデルを採用している 11。Supabase RLSとの間には、いくつかの根本的な差異が存在する。データモデル: 最も本質的な違いは、リレーショナル（PostgreSQL）とドキュメント（Firestore）というデータモデルの差である。これはクエリの能力、データの一貫性、そしてリレーションの表現方法に直接影響を及ぼす 14。写真共有SNSのような複雑な関係性（フォロー、ブロックなど）を持つアプリケーションでは、リレーショナルモデルがより自然に適合する場合が多い。言語: Supabaseが採用するSQLは、数十年にわたる歴史を持つ業界標準の問い合わせ言語であり、広範なエコシステムと知見が存在する。一方、Firebaseのルールはプラットフォーム固有のドメイン固有言語 (DSL) であり、その知識は他プラットフォームへ移植できない 13。デバッグ体験: 開発者コミュニティからのフィードバックとして、Firebaseのルールは大規模になるとデバッグが困難で、「直感的でない」と感じられることがある点が指摘されて... [truncated]
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT,
  avatar_url TEXT,
  is_private BOOLEAN DEFAULT false
);

-- 投稿テーブル
CREATE TABLE public.posts (
  id BIGSERIAL PRIMARY KEY,
  content TEXT,
  image_url TEXT,
  user_id UUID NOT NULL REFERENCES public.profiles(id)
);

-- RLSの有効化
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
次に、具体的なポリシーを定義する。プロフィールの閲覧ポリシー:SQLCREATE POLICY "Public profiles are viewable by everyone."
  ON public.profiles FOR SELECT
  USING (true);
このポリシーはUSING句にtrueを指定することで、全てのSELECT操作を許可する。プロフィールの更新ポリシー:SQLCREATE POLICY "Users can update their own profile."
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
このポリシーでは、USING句とWITH CHECK句の両方が使用されている。USING句は、UPDATEやDELETEのようなコマンドが作用する既存の行をフィルタリングするために評価される。一方、WITH CHECK句は、INSERTやUPDATEによって新しく生成される行が条件を満たすかを検証するために評価される 24。この場合、操作対象のプロフィールのidが認証ユーザーのID (auth.uid()) と一致する場合にのみ更新を許可し、さらに更新後の行も同じ条件を満たすことを保証している。2.2 ソーシャルグラフの実装：フォロー、ブロック、プライバシー設定ソーシャルネットワークの核心は、ユーザー間の関係性に基づいた複雑なアクセス制御にある。ここでは、フォロー関係、ブロック機能、そして非公開アカウント設定を考慮した、より現実的な投稿閲覧ポリシーを構築する。まず、これらの関係性を格納するためのテーブルを設計する。SQL-- フォロー関係を管理するテーブル
CREATE TABLE public.followers (
  follower_id UUID NOT NULL REFERENCES public.profiles(id),
  following_id UUID NOT NULL REFERENCES public.profiles(id),
  PRIMARY KEY (follower_id, following_id)
);

-- ブロック関係を管理するテーブル
CREATE TABLE public.blocks (
  blocker_id UUID NOT NULL REFERENCES public.profiles(id),
  blocked_id UUID NOT NULL REFERENCES public.profiles(id),
  PRIMARY KEY (blocker_id, blocked_id)
);

-- RLSの有効化
ALTER TABLE public.followers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;
これらのテーブルを基に、postsテーブルに対する複雑なSELECTポリシーを構築する。このポリシーは、以下の条件を論理的に組み合わせる必要がある。ユーザーは常に自身の投稿を閲覧できる。投稿者のプロフィールが公開されている場合、投稿者は閲覧者をブロックしていない限り、投稿を閲覧できる。投稿者のプロフィールが非公開の場合、閲覧者が投稿者をフォローしており、かつ投稿者が閲覧者をブロックしていない場合に限り、投稿を閲覧できる。これらのルールを実装したSQLポリシーは以下のようになる。SQLCREATE POLICY "Users can view posts based on social graph rules."
ON public.posts FOR SELECT USING (
  -- ルール1: 自身の投稿は常に閲覧可能
  (auth.uid() = posts.user_id)
  OR
  (
    -- ルール2: 投稿者のプロフィールが公開の場合
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = posts.user_id AND profiles.is_private = false
    )
    -- かつ、投稿者にブロックされていない
    AND NOT EXISTS (
      SELECT 1 FROM public.blocks
      WHERE blocks.blocker_id = posts.user_id AND blocks.blocked_id = auth.uid()
    )
  )
  OR
  (
    -- ルール3: 投稿者のプロフィールが非公開の場合
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = posts.user_id AND profiles.is_private = true
    )
    -- かつ、投稿者をフォローしている
    AND EXISTS (
      SELECT 1 FROM public.followers
      WHERE followers.follower_id = auth.uid() AND followers.following_id = posts.user_id
    )
    -- かつ、投稿者にブロックされていない
    AND NOT EXISTS (
      SELECT 1 FROM public.blocks
      WHERE blocks.blocker_id = posts.user_id AND blocks.blocked_id = auth.uid()
    )
  )
);
このポリシーは、EXISTSを用いたサブクエリを複数組み合わせることで、JOINと同様の役割を果たし、複雑な条件分岐を実現している。これは、RLSがソーシャルネットワーク特有の複雑な認可ロジックを表現できる能力を持つことを明確に示す一方で、その記述が冗長になりがちで、慎重な論理設計が求められることも示唆している 9。この実装例から導き出される重要な点は、RLSポリシーの複雑性がアプリケーションのソーシャルルールの複雑性と正比例して増大し、それが保守性と認知的な負荷に直接的な影響を与えるということである。単純な所有権ポリシーは簡潔だが、ソーシャルグラフを反映したポリシーは桁違いに複雑になる。アプリケーションに新たなソーシャル機能（例えば、「親しい友達」リスト、特定のユーザーのミュート、グループ投稿など）が追加されるたびに、このポリシーに更なるOR句やAND句、EXISTSチェックが追加されるか、あるいは相互に作用する新しいポリシーが必要になる。これにより、「機能の成長」が「ポリシーの複雑化」を招き、ひいては「エラーやパフォーマンス問題のリスク増大」に繋がるという因果関係が生まれる。開発者は、単一のテーブルに対する権限を完全に理解するために、この巨大なSQLロジック全体を精神的に解析する必要に迫られる 17。この事実は、RLSがその生の形では、コンポーネントのように組み合わせたり、モジュール化したりすることが容易ではないという課題を浮き彫りにする。巨大で一枚岩となったポリシーは、論理的な推論やデバッグを困難にする 26。この課題こそが、開発者が感じる「難しさ」の根源であり、この複雑性を管理するためのアーキテクチャパターン（例えば、ロジックをデータベース関数に分割するなど）の必要性を示唆している。第3章 パフォーマンスの試練：高負荷下におけるRLSの最適化とスケーリングRLSを採用する上で最も重大な懸念事項の一つがパフォーマンスである。このセクションでは、RLSがなぜパフォーマンスのボトルネックになり得るのかを技術的に解説し、その問題を解決するための実践的な最適化手法を詳述する。3.1 行単位実行のボトルネック解説RLSのパフォーマンス問題を理解する上で最も重要な概念は、PostgreSQLがRLSポリシーの式を、クエリがアクセスしようとする全ての行に対して個別に評価するという点である 27。もしポリシー内にauth.uid()のような関数呼び出しやサブクエリが含まれている場合、その関数やサブクエリは行ごとに繰り返し実行される。これは、アプリケーション開発で知られる「N+1問題」がデータベースの認可レイヤーで発生するのと等価であり、特に大規模なテーブルに対するクエリにおいて、深刻なパフォーマンス低下を引き起こす。この影響は決して理論上の問題ではない。Supabaseが公開しているベンチマークデータによれば、最適化されていないRLSポリシーを持つクエリが11,000ミリ秒を要したのに対し、最適化を施した同じクエリはわずか7ミリ秒で完了した例がある 27。この事実は、RLSのパフォーマンス問題が現実的かつ重大であると同時に、適切な知識をもって対処すれば解決可能であることを示している。3.2 RLS最適化プレイブックRLSのパフォーマンスを劇的に改善するためには、いくつかの確立されたテクニックが存在する。これらは、PostgreSQLのクエリオプティマイザの挙動を理解し、それを活用するものである。テクニック1：戦略的なインデックス付与最も基本的かつ効果的な最適化は、RLSポリシーのUSING句やWITH CHECK句で使用される全ての列にインデックスを作成することである。例えば、USING (auth.uid() = user_id)のようなポリシーがある場合、user_id列にインデックスがなければ、データベースは条件を評価するためにテーブル全体をスキャン（フルテーブルスキャン）する必要がある。インデックスを付与することで、データベースは対象となる行を迅速に特定できるようになる 30。テクニック2：initPlanによる関数結果のキャッシュこれは、Supabase環境におけるRLSパフォーマンスチューニングの最も重要なテクニックである。前述の通り、auth.uid()のような関数はデフォルトで行ごとに実行される。しかし、これらの関数の返り値は、単一のクエリの実行中においては不変（ステーブル）である。この性質を利用し、関数呼び出しを(SELECT...)というサブクエリでラップすることで、PostgreSQLのクエリプランナにinitPlanを生成させることができる。initPlanは、メインのクエリが実行される前に一度だけ実行され、その... [truncated]

-- テストプラン（アサーションの数）を宣言
SELECT plan(4);

-- テストデータのセットアップ
INSERT INTO auth.users (id, email) VALUES
  ('a1b2c3d4-e5f6-7890-1234-567890abcdef'),
  ('b2c3d4e5-f6a7-8901-2345-67890abcdef1');

INSERT INTO public.posts (content, user_id) VALUES
  ('User A Post 1', 'a1b2c3d4-e5f6-7890-1234-567890abcdef'),
  ('User B Post 1', 'b2c3d4e5-f6a7-8901-2345-67890abcdef1');

-- User Aとしてリクエストをシミュレート
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claims" TO '{"sub":"a1b2c3d4-e5f6-7890-1234-567890abcdef"}';

-- テスト1: User Aは自身の投稿のみ閲覧できる
SELECT results_eq(
  'SELECT COUNT(*)::INT FROM public.posts',
  ARRAY[1],
  'User A should only see their own post.'
);

-- テスト2: User Aは自身の投稿を作成できる
SELECT lives_ok(
  $$ INSERT INTO public.posts (content, user_id) VALUES ('New post by User A', 'a1b2c3d4-e5f6-7890-1234-567890abcdef') $$