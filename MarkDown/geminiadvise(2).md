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
