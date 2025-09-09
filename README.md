# STILL - iOS Social Media Platform

STILL is a feature-rich social media platform for iOS, specialized in photo and article posting. It provides professional-grade photo editing capabilities and sophisticated article creation tools for creators.

STILLは、写真と記事の投稿に特化したiOS向けの多機能ソーシャルメディアプラットフォームです。クリエイター向けにプロ仕様の写真編集機能と洗練された記事作成ツールを提供します。

## 🚀 Overview / 概要

STILL combines the power of visual storytelling with written content, allowing creators to share their perspectives through both stunning imagery and compelling articles. Built with SwiftUI and powered by Supabase, it offers a seamless and secure social media experience.

STILLは、ビジュアルストーリーテリングの力と文章コンテンツを組み合わせ、クリエイターが素晴らしい画像と魅力的な記事の両方を通じて自分の視点を共有できるようにします。SwiftUIで構築され、Supabaseによって動作し、シームレスで安全なソーシャルメディア体験を提供します。

## 💻 Tech Stack / 技術スタック

### Frontend / フロントエンド
- **SwiftUI** - Modern declarative UI framework / モダンな宣言的UIフレームワーク
- **Swift Concurrency** - Async/await for efficient asynchronous operations / 効率的な非同期処理のためのAsync/await
- **Combine** - Reactive programming for data flow / データフローのためのリアクティブプログラミング
- **PhotosUI** - Advanced photo editing and management / 高度な写真編集と管理

### Backend & Services / バックエンド＆サービス
- **Supabase** - Backend as a Service / サービスとしてのバックエンド
  - PostgreSQL database with Row Level Security (RLS) / RLS付きPostgreSQLデータベース
  - Authentication and user management / 認証とユーザー管理
  - Real-time subscriptions / リアルタイムサブスクリプション
  - Edge Functions for server-side logic / サーバーサイドロジックのためのEdge Functions
  - Storage for media files / メディアファイルのストレージ

### Development Tools / 開発ツール
- **Xcode 16+** - Primary IDE / 主要IDE
- **Swift 5.9+** - Programming language / プログラミング言語
- **Git** - Version control / バージョン管理

## ✨ Key Features / 主要機能

### 📸 Photo Posting / 写真投稿
- **Advanced Camera** / **高機能カメラ**: Real-time filters, manual focus, zoom, and professional shooting features / リアルタイムフィルター、マニュアルフォーカス、ズーム、プロ仕様の撮影機能
- **Professional Editing** / **プロ級の編集**: RAW image processing, exposure/color/shadow adjustments, non-destructive editing / RAW画像処理、露出/カラー/シャドウ調整、非破壊編集
- **Filter Library** / **フィルターライブラリ**: Curated collection of artistic filters and effects / 厳選されたアーティスティックなフィルターとエフェクト

### 📝 Article Creation / 記事作成
- **Multiple Formats** / **複数のフォーマット**: 
  - News articles for factual reporting / 事実報道のためのニュース記事
  - Magazine-style articles with rich visual layouts / リッチなビジュアルレイアウトの雑誌スタイル記事
- **Intuitive Editor** / **直感的なエディタ**: Drag-and-drop interface for images and text / 画像とテキストのドラッグ＆ドロップインターフェース
- **Rich Text Support** / **リッチテキストサポート**: Formatting options for compelling storytelling / 魅力的なストーリーテリングのためのフォーマットオプション

### 📱 Social Features / ソーシャル機能
- **Unified Feed** / **統合フィード**: Mixed content stream of photos and articles / 写真と記事の混在コンテンツストリーム
- **Engagement** / **エンゲージメント**: Likes, comments, and follows / いいね、コメント、フォロー
- **Real-time Updates** / **リアルタイム更新**: Live notifications and messaging / ライブ通知とメッセージング
- **Profile Management** / **プロフィール管理**: Customizable profiles and content portfolios / カスタマイズ可能なプロフィールとコンテンツポートフォリオ

## 📂 Project Structure / プロジェクト構造

```
STILL/
├── still/                     # Main iOS application / メインiOSアプリケーション
│   ├── Application/          # App entry point and configuration / アプリエントリーポイントと設定
│   │   ├── STILLApp.swift
│   │   └── AppEnvironment.swift
│   ├── Core/                 # Shared components and services / 共有コンポーネントとサービス
│   │   ├── Auth/            # Authentication logic / 認証ロジック
│   │   ├── DataModels/      # Data structures and models / データ構造とモデル
│   │   ├── Repositories/    # Data persistence layer / データ永続化層
│   │   ├── Security/        # Security utilities and encryption / セキュリティユーティリティと暗号化
│   │   └── Services/        # Business logic and API clients / ビジネスロジックとAPIクライアント
│   └── Features/            # Feature modules / 機能モジュール
│       ├── HomeFeed/        # Main feed functionality / メインフィード機能
│       ├── Camera/          # Camera and capture / カメラと撮影
│       ├── PhotoEditor/     # Photo editing tools / 写真編集ツール
│       ├── Articles/        # Article creation and viewing / 記事作成と閲覧
│       ├── Messages/        # Direct messaging / ダイレクトメッセージ
│       ├── Profile/         # User profiles / ユーザープロフィール
│       └── Settings/        # App settings / アプリ設定
├── supabase/                 # Backend configuration / バックエンド設定
│   ├── migrations/          # Database migrations / データベースマイグレーション
│   └── functions/           # Edge Functions / Edge Functions
├── MarkDown/                # Documentation / ドキュメント
│   ├── CLAUDE.md           # AI assistant guidelines / AIアシスタントガイドライン
│   └── security.md         # Security documentation / セキュリティドキュメント
└── stillTests/              # Test suites / テストスイート
```

## 🛠️ Development Setup / 開発環境構築

### Prerequisites / 前提条件
- macOS 14.0+ (Sonoma or later / Sonoma以降)
- Xcode 16.0+
- iOS 17.0+ deployment target / iOS 17.0+デプロイメントターゲット
- Supabase account / Supabaseアカウント

### Environment Setup / 環境セットアップ

1. **Clone the repository / リポジトリをクローン**
   ```bash
   git clone <repository_url>
   cd STILL
   ```

2. **Install dependencies / 依存関係をインストール**
   ```bash
   # Open Xcode and let it resolve Swift Package Manager dependencies
   # XcodeでSwift Package Managerの依存関係を解決
   open still.xcodeproj
   ```

3. **Configure Supabase / Supabaseの設定**
   
   Create a `Development.xcconfig` file in the project root:
   プロジェクトルートに`Development.xcconfig`ファイルを作成:
   
   ```xcconfig
   // Development.xcconfig
   SUPABASE_URL = your_supabase_url_here
   SUPABASE_ANON_KEY = your_supabase_anon_key_here
   ```
   
   ⚠️ **Important / 重要**: This file is gitignored. Never commit API keys to version control.
   このファイルはgitignoreされています。APIキーを絶対にバージョン管理にコミットしないでください。

4. **Set up the database / データベースのセットアップ**
   ```bash
   # Apply database migrations / データベースマイグレーションを適用
   cd supabase
   supabase db reset
   ```

5. **Build and run / ビルドと実行**
   - Select the target device/simulator in Xcode / Xcodeでターゲットデバイス/シミュレータを選択
   - Press `Cmd+R` to build and run / `Cmd+R`でビルドと実行

## 📋 Available Commands / 利用可能なコマンド

### Build Commands / ビルドコマンド
```bash
# Build the project / プロジェクトをビルド
xcodebuild -project still.xcodeproj -scheme still build

# Run tests / テストを実行
xcodebuild test -scheme still -destination "platform=iOS Simulator,name=iPhone 16 Pro"

# Clean build folder / ビルドフォルダをクリーン
xcodebuild clean -project still.xcodeproj -scheme still
```

### Database Commands / データベースコマンド
```bash
# Run migrations / マイグレーションを実行
supabase migration up

# Create new migration / 新しいマイグレーションを作成
supabase migration new <migration_name>

# Reset database / データベースをリセット
supabase db reset
```

## 🔐 Environment Variables / 環境変数

Create a `Development.xcconfig` file with the following variables:
以下の変数を含む`Development.xcconfig`ファイルを作成:

| Variable / 変数 | Description / 説明 | Required / 必須 |
|----------|-------------|----------|
| `SUPABASE_URL` | Your Supabase project URL / SupabaseプロジェクトURL | ✅ |
| `SUPABASE_ANON_KEY` | Supabase anonymous key / Supabase匿名キー | ✅ |

## 🧪 Testing / テスト

The project uses XCTest framework for unit and UI testing:
プロジェクトはユニットテストとUIテストにXCTestフレームワークを使用:

```bash
# Run all tests / 全てのテストを実行
xcodebuild test -scheme still -destination "platform=iOS Simulator,name=iPhone 16 Pro"

# Run specific test suite / 特定のテストスイートを実行
xcodebuild test -scheme still -only-testing:stillTests/CoreTests
```

## 📚 Documentation / ドキュメント

- [AI Development Guidelines / AI開発ガイドライン](./CLAUDE.md) - Instructions for AI-assisted development / AI支援開発の手順
- [Security Documentation / セキュリティドキュメント](./MarkDown/security.md) - Security best practices and requirements / セキュリティのベストプラクティスと要件
- [API Documentation / APIドキュメント](https://supabase.com/docs) - Supabase API reference / Supabase APIリファレンス

## 🤝 Contributing / コントリビューション

1. Create a feature branch / フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
2. Commit your changes / 変更をコミット (`git commit -m 'Add amazing feature'`)
3. Push to the branch / ブランチにプッシュ (`git push origin feature/amazing-feature`)
4. Open a Pull Request / プルリクエストを開く

### Coding Standards / コーディング規約
- Follow SwiftUI best practices / SwiftUIのベストプラクティスに従う
- Use Swift Concurrency (async/await) for asynchronous operations / 非同期処理にSwift Concurrency (async/await)を使用
- Implement proper error handling / 適切なエラーハンドリングを実装
- Add comprehensive documentation for public APIs / パブリックAPIに包括的なドキュメントを追加
- Ensure all new features have corresponding tests / 全ての新機能に対応するテストを確保

## 📄 License / ライセンス

This project is proprietary software. All rights reserved.
このプロジェクトは独占的ソフトウェアです。全ての権利は留保されています。

## 🔗 Links / リンク

- [Supabase Dashboard / Supabaseダッシュボード](https://supabase.com/dashboard)
- [SwiftUI Documentation / SwiftUIドキュメント](https://developer.apple.com/documentation/swiftui/)
- [Project Issues / プロジェクトの課題](https://github.com/your-repo/issues)

---

Built with ❤️ using SwiftUI and Supabase
SwiftUIとSupabaseを使用して❤️を込めて構築