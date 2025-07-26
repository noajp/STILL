# STILL Project - Claude セッション管理ドキュメント

## 📋 プロジェクト概要

**プロジェクト名**: STILL  
**アプリケーション種別**: iOS SNSアプリ（写真投稿＋記事投稿）  
**技術スタック**: SwiftUI + Supabase  
**開発環境**: Xcode, Claude Code CLI  
**開発状況**: 80%完成 - 既存機能を壊さないよう注意

## 🗂️ ドキュメント構造

### 📁 MarkDown/
- `claude.md` - このファイル（Claude Code セッション管理）
- `security.md` - **セキュリティドキュメント**（必読）

## 🔒 セキュリティ情報

**重要**: このプロジェクトのセキュリティ関連情報は以下のファイルに統合されています：

👉 **[MarkDown/security.md](./security.md)** を必ず確認してください

### セキュリティドキュメントの内容
- RLSセキュリティテスト結果
- 発見された脆弱性と修正内容
- cURLを使用したセキュリティテスト手順
- 定期メンテナンススケジュール
- インシデント対応手順

## 🚀 現在の開発状況

### ✅ 完了済み機能
- 基本的なSNS機能（投稿、フィード）
- ユーザー認証とプロフィール管理
- メッセージ機能（暗号化対応）
- フォロー/フォロワー機能
- 通知システム（bell icon付き）
- セキュリティ強化（RLS、監査ログ）

### 🔧 技術的修正履歴
1. **プロフィール取得エラー修正** - UserRepositoryのタスクキャンセル問題解決
2. **重大セキュリティ脆弱性修正** - RLSポリシーの緩緩を修正、cURLテストで検証
3. **削除メッセージ復元問題修正** - hidden_for_userフィルターをview/RPC関数に追加
4. **メッセージ機能修復** - user_conversations_viewの再作成と関連機能の復旧
5. **通知システム実装** - NotificationService、NotificationListView作成完了

### 🎯 現在のTODOリスト
- 通知テスト - アプリ内でフォロー/いいねアクションをテストしてログ確認
- いいね機能の完全実装 - UI改善、アニメーション、カウント表示
- 投稿機能の作り込み - 写真編集、フィルター、キャプション入力の改善

## 🏗️ アーキテクチャ

### 設計パターン
- **MVVM**: @StateObject と @ObservableObject を使用
- **ViewModels**: ビジネスロジック処理
- **Services**: API/データベース相互作用
- **Repositories**: データ永続化管理

### プロジェクト構造
```
/Users/nakanotakanori/Dev/STILL/
├── MarkDown/                  # ドキュメント管理
│   ├── claude.md             # Claude管理ドキュメント（このファイル）
│   └── security.md           # セキュリティドキュメント
├── still/                    # iOSアプリメインコード
│   ├── Application/          # アプリエントリーポイント
│   ├── Core/                # 共有コンポーネント、モデル、サービス
│   │   ├── Components/      # 再利用可能UIコンポーネント
│   │   ├── DataModels/      # データ構造
│   │   ├── Services/        # ビジネスロジックサービス
│   │   └── Repositories/    # データ永続化
│   └── Features/           # 機能モジュール
│       ├── HomeFeed/       # 写真フィード機能
│       ├── Articles/       # 記事作成・表示
│       ├── Messages/       # ダイレクトメッセージ・グループチャット
│       ├── MyPage/         # ユーザープロフィール
│       └── SharedViews/    # 共有UIコンポーネント
├── supabase/                 # データベースマイグレーション
└── README.md                 # プロジェクトREADME
```

### 重要なコンポーネント
- **UnifiedHeader**: アプリ全体で使用される統一ヘッダー
- **CustomTabBar**: メインナビゲーション（フィード、記事、投稿、メッセージ、プロフィール）
- **PostTypeSelectionPopup**: 写真・記事投稿選択のポップアップ
- **ScrollableHeaderView**: コンテンツと自然にスクロールするヘッダー

### 実装フロー
- **写真投稿**: CustomTabBar → PostTypeSelectionPopup → PhotoPickerView → ModernPhotoEditorView
- **記事投稿**: CustomTabBar → PostTypeSelectionPopup → ArticleEditorView
- **ヘッダー**: コンテンツと共にスクロール（アニメーション非表示なし）
- **フィード**: マソナリーグリッドレイアウトで交互パターン

## 🛠️ 開発環境・コマンド

### ビルド・テストコマンド
```bash
# ビルド
xcodebuild -scheme still -destination "platform=iOS Simulator,name=iPhone 16 Pro" build

# Lint実行（利用可能な場合）
swiftlint

# テスト実行
xcodebuild test -scheme still -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

### コードスタイルガイドライン
- SwiftUIの宣言的構文を使用
- 既存のコードパターンと規則に従う
- 一貫したスペーシングとインデント（4スペース）
- MinimalDesign.Colorsで一貫したテーマ
- 明示的に要求されない限りコメント不要
- レスポンスは簡潔に

### ファイルヘッダー要件
**新しいファイルには常にこのヘッダー形式を含める:**
```swift
//======================================================================
// MARK: - FileName.swift
// Purpose: Brief description of file purpose (日本語での簡潔な説明)
// Path: relative/path/to/file.swift
//======================================================================
```

**例:**
```swift
//======================================================================
// MARK: - AuthManager.swift
// Purpose: Authentication manager with user session handling, secure token management, and Supabase auth integration (ユーザーセッション処理、セキュアトークン管理、Supabase認証統合を持つ認証マネージャー)
// Path: still/Core/Auth/AuthManager.swift
//======================================================================
```

**重要**: このヘッダーがないファイルに遭遇した場合、ファイル修正時に即座に追加する。

### 重要なファイルパス
- **iOS App**: `/Users/nakanotakanori/Dev/STILL/still/`
- **Supabase Migrations**: `/Users/nakanotakanori/Dev/STILL/supabase/migrations/`
- **セキュリティドキュメント**: `/Users/nakanotakanori/Dev/STILL/MarkDown/security.md`

## 🎨 UI/UXデザイン原則

### デザインリファレンス
- **Atlassian Design System**: https://atlassian.design/
- Atlassianの哲学に従う: "Design with clarity, Build with confidence"
- 体系的デザインアプローチのための基盤を参考

### コアデザイン原則
- **明瞭性第一**: ユーザーがインターフェースとの相互作用に混乱すべきでない
- **ミニマルデザイン美学**: 不要な装飾のない、清潔で目的明確な要素
- **体系的アプローチ**: 全コンポーネント間の一貫性のためデザイントークンを使用
- **アクセシビリティ**: 幅広い使いやすさと良好なユーザー体験のためのデザイン
- **モジュラーコンポーネント**: 構成可能な再利用性の高い柔軟なUI要素

### ビジュアルデザイン標準
- **赤アクセントカラー**: MinimalDesign.Colors.accentRed をプライマリアクション・ハイライトに使用
- **ダークモードサポート**: アプリ全体でフルテーマ互換性
- **タイポグラフィ**: 読みやすさを向上させる一貫したフォントウェイト・サイズ
- **スペーシング**: ビジュアル階層のためのデザイントークンを使用した体系的スペーシング
- **絵文字なし**: ユーザーが明示的に要求しない限り

### インタラクションデザイン
- **直感的ナビゲーション**: ユーザーは現在地と目的地への道筋を理解すべき
- **即座のフィードバック**: ユーザーアクションに対する視覚的応答（ボタン状態、ローディング表示）
- **穏やかなアニメーション**: 注意散漫にならずに注意を導く繊細なトランジション
- **タッチターゲット**: デザイン標準に従ったモバイル相互作用に適切なサイジング

## 📊 Supabase統合・データベース情報

### 基本設定
- **プロジェクトURL**: `https://yccjlkcxqybxqewzchen.supabase.co`
- **認証**: AuthManager経由
- **リアルタイム機能**: メッセージング用
- **画像ストレージ**: 投稿・プロフィール用
- **データベースビュー**: キャッシュ問題回避のためRPC関数の代わりに使用

### 主要テーブル
- profiles, posts, messages, notifications, follows
- 全テーブルでRLS有効、監査ログシステム導入済み

### セキュリティ状況
**最新テスト日**: 2025-07-26  
**セキュリティレベル**: A（優良）  
**重大な脆弱性**: なし（修正済み）

### よくある問題と解決策
- **UUID大文字小文字**: 比較時は常に小文字に変換
- **Supabase RPCキャッシュ**: データベースビューまたはフレッシュクライアントインスタンスを使用
- **ヘッダー位置**: パディング値を慎重に調整
- **スクロールインジケーター**: ScrollViewで `showsIndicators: false` を使用

## 💡 Claude Code 使用時の注意点

### セッション継続時の確認事項
1. **セキュリティ状況の確認**
   ```bash
   # 定期的にRLSテストを実行
   cat /Users/nakanotakanori/Dev/STILL/MarkDown/security.md
   ```

2. **現在のTODO状況確認**
   - TodoWriteツールで最新状況を確認
   - 優先度の高いタスクから着手

3. **プロジェクト構造の理解**
   - still/ - メインのiOSアプリコード
   - supabase/ - データベースマイグレーション
   - MarkDown/ - ドキュメント管理

### 頻繁に使用するコマンド
```bash
# プロジェクトディレクトリに移動
cd /Users/nakanotakanori/Dev/STILL

# ビルドテスト
xcodebuild -project still.xcodeproj -scheme still build

# Supabaseマイグレーション確認
ls supabase/migrations/

# セキュリティテスト実行
curl "https://yccjlkcxqybxqewzchen.supabase.co/rest/v1/profiles?select=*" \
-H "apikey: [anonキー]" \
-H "Authorization: Bearer [anonキー]"
```

## 🔄 定期タスク

### 開発セッション開始時
- [ ] 前回のTODO状況確認
- [ ] セキュリティドキュメント確認
- [ ] 最新のgit statusチェック

### 開発セッション終了時
- [ ] TodoWriteで進捗更新
- [ ] 重要な変更のcommit
- [ ] セキュリティに関わる変更があった場合はsecurity.md更新

### 週次
- [ ] セキュリティテストの実行
- [ ] パフォーマンス確認
- [ ] 未使用コードの整理

## 📝 コミット規則

### コミットメッセージフォーマット
```
<type>(<scope>): <description>

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### よく使用するtype
- `feat`: 新機能
- `fix`: バグ修正
- `security`: セキュリティ修正
- `refactor`: リファクタリング
- `docs`: ドキュメント更新

## ⚠️ 重要なリマインダー

### 開発時の必須事項
- **ALWAYS** セッション開始時にこのファイルを確認
- **NEVER** 絶対に必要でない限りファイルを作成しない
- **ALWAYS** 既存ファイルの編集を優先する
- **NEVER** 要求されない限りドキュメントを予備的に作成しない
- **ALWAYS** 変更前に徹底的に調査する
- 破壊的変更の可能性について不明な場合はユーザーに確認

### 🚫 禁止される欺瞞的行為

#### セキュリティに関する禁止事項
- **NEVER** セキュリティ要件を緩める・回避して実装を簡略化する
- **NEVER** テストケースを改竄・スキップして問題を隠蔽する
- **NEVER** 一時的・簡易版として不完全なセキュリティ実装を行う
- **NEVER** RLSポリシーや制約を「動作させるため」に削除・緩和する
- **NEVER** セキュリティ上の問題を「後で修正予定」として放置する

#### 問題解決アプローチ
- **ALWAYS** セキュリティ要件を満たす正しい実装方法を徹底調査する
- **ALWAYS** 詰まった場合は安易な回避策ではなく根本的解決を目指す
- **ALWAYS** 不明な点があれば実装前にユーザーに相談する
- **ALWAYS** セキュリティとユーザー保護を最優先に考える

#### 相談・サポート体制
- **技術的困難**: アーキテクチャ変更が必要な場合は設計から相談
- **セキュリティ懸念**: 実装方針に疑問がある場合は事前確認を求める
- **制約との矛盾**: 要件とセキュリティが矛盾する場合は代替案を提示
- **実装の複雑性**: 適切な実装が複雑になる場合は段階的計画を相談

### テストアプローチ
- README確認またはコードベース検索でテストコマンドを確認
- 変更後は常にlint/typecheckを実行
- iPhone 16 Pro シミュレーターでテスト

### 🔒 セキュリティ最優先原則

#### 最重要事項
**セキュリティ要件を守りユーザーを保護することは最重要であり、一切の妥協は許されない**

- **ユーザーデータ保護**: 個人情報、メッセージ、投稿内容の完全な保護
- **不正アクセス防止**: 認証・認可システムの堅牢性確保
- **データ漏洩防止**: RLS、暗号化、アクセス制御の徹底
- **プライバシー保護**: ユーザーの同意なしにデータアクセスさせない

### セキュリティ要件・標準

#### データベースセキュリティ（実装済み）
- **RLS (Row Level Security)**: 全テーブルで適切なポリシーと共に有効
- **関数セキュリティ**: SQLインジェクション防止のためsearch_pathを明示的に設定
- **拡張セキュリティ**: pgauditを適切な権限で拡張スキーマに移動
- **データ保持**: 自動クリーンアップのためのポリシー設定

#### 認証セキュリティ
- ✅ **Keychainストレージ**: Secrets.plistから安全なKeychainへのシークレット移行
- ✅ **SecureConfig**: 中央集約的な安全な設定管理
- ⚠️ **パスワード保護**: HaveIBeenPwned侵害検出（Supabaseダッシュボード設定必要）
- ⚠️ **MFA強化**: 追加の多要素認証方法が必要

#### アプリケーションセキュリティ標準
- **シークレット/キーの非公開・非ログ** - 全センシティブデータにSecureConfigを使用
- **入力検証**: 全ユーザー入力にInputValidatorを使用
- **メッセージ暗号化**: プライベート通信用
- **レート制限**: ブルートフォース攻撃防止のため実装
- **セキュリティ監視**: 監査ログとハニーポットテーブル経由

#### キー管理
- **Supabase URL**: `https://yccjlkcxqybxqewzchen.supabase.co`
- **APIキー**: Keychainに格納、SecureConfig経由でアクセス
- **環境変数**: 開発用、本番用Keychain

## 🚨 緊急時対応

### セキュリティインシデント発生時
1. **即座に** `MarkDown/security.md` の「セキュリティインシデント対応」セクションを参照
2. 侵害された場合は即座にAPIキーローテーション
3. 疑わしい活動について監査ログをレビュー
4. データアクセスパターンが変更された場合はRLSポリシーを更新

### アプリクラッシュ時
1. ログの確認とエラー原因特定
2. 緊急修正の適用
3. テスト実行後にデプロイ

### 継続的セキュリティタスク
1. SupabaseダッシュボードでHaveIBeenPwned保護を有効化
2. 追加MFA方法（TOTP、SMS）を設定
3. `mcp__supabase__get_advisors` を使用した定期セキュリティ監査
4. 異常についてセキュリティログを監視

---

**このドキュメントはプロジェクトの中央管理ハブとして機能します。**  
**新しいセッション開始時は必ずこのファイルを確認してください。**