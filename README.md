# STILL

STILLは、写真投稿と記事投稿の両方をサポートする総合的なクリエイティブプラットフォームです。プロ級の写真編集機能と、新聞・雑誌スタイルの記事作成機能を組み合わせた革新的なアプリです。

## 主要機能

### 📸 写真投稿機能
- **プロ級カメラ**: カスタムカメラ with リアルタイムフィルター
  - ピンチズーム (1x-10x)
  - タップフォーカス機能
  - フラッシュ制御
  - フロント/バックカメラ切替
  - リアルタイムフィルタープレビュー

- **高度な写真編集**: RAWファイル対応の本格的エディター
  - RAW画像処理 (CR2, ARW, NEF, DNG, RAF, ORF対応)
  - プロレベルの調整項目 (露出、色温度、ハイライト、シャドウ)
  - Metalベースのリアルタイムプレビュー
  - 豊富なフィルターパック
  - 編集履歴管理

- **インテリジェントな画像処理**
  - 自動アスペクト比検出
  - メモリ効率的な最適化
  - 複数品質での書き出し
  - サムネイル自動生成

### 📝 記事投稿機能
- **雑誌記事エディター**: フルスクリーンエディター
  - 画面の2/3を占める紙のようなキャンバス
  - ドラッグ&ドロップ対応
  - リアルタイムプレビュー機能
  - スタイリッシュなグラデーション背景

### 📱 フィード機能
- **統合フィード**: 写真と記事を美しく表示
  - 新聞記事: シンプルで情報重視のレイアウト
  - 雑誌記事: ビジュアル重視のスタイリッシュなデザイン
  - 写真投稿: グリッドレイアウト with 混合アスペクト比
  - ソーシャル機能 (いいね、コメント、ユーザープロフィール)

### サポートする記事タイプ

#### 新聞記事 (Newspaper)
- 事実に基づいた情報を分かりやすく伝える
- シンプルで読みやすいレイアウト
- ニュース、レポート、解説記事に適している

#### 雑誌記事 (Magazine)
- スタイリッシュで魅力的なビジュアル
- ストーリー性を重視
- ライフスタイル、特集、エンターテイメント記事に適している

## プロジェクト構成

```
tete/
├── Core/
│   ├── DataModels/
│   │   ├── Post.swift                 # 写真投稿モデル
│   │   └── Article.swift              # 記事モデル定義
│   ├── Services/
│   │   └── PostService.swift          # 写真投稿データ操作
│   ├── Repositories/
│   │   └── ArticleRepository.swift    # 記事データ操作
│   ├── ImageProcessing/
│   │   ├── ImageProcessor.swift       # 画像処理・最適化
│   │   ├── UnifiedImageProcessor.swift
│   │   └── CoreImageManager.swift
│   └── Performance/
│       └── ImageCacheManager.swift    # 画像キャッシュ管理
├── Features/
│   ├── Camera/
│   │   ├── Views/
│   │   │   ├── CustomCameraView.swift # カスタムカメラ実装
│   │   │   └── CustomCameraPreview.swift
│   │   └── ViewModels/
│   │       └── CustomCameraViewModel.swift
│   ├── PhotoEditor/
│   │   ├── Views/
│   │   │   ├── PhotoEditorView.swift  # 写真編集エディター
│   │   │   └── ModernPhotoEditorView.swift
│   │   ├── ViewModels/
│   │   │   └── PhotoEditorViewModel.swift
│   │   └── Models/
│   │       └── RAWImageProcessor.swift # RAW画像処理
│   ├── CreatePost/
│   │   ├── Views/
│   │   │   ├── PhotoPickerView.swift  # 写真選択画面
│   │   │   └── ModernCreatePostFlow.swift
│   │   └── ViewModels/
│   │       └── CreatePostViewModel.swift
│   ├── Articles/
│   │   └── Views/
│   │       ├── StoryStyleEditorView.swift    # 雑誌記事エディター
│   │       └── ArticleTypeSelectionView.swift
│   ├── ArticleEditor/
│   │   └── Views/
│   │       └── PaperBasedEditorView.swift
│   ├── Magazine/
│   │   └── Views/
│   │       └── MagazineView.swift     # 記事フィード表示
│   └── SharedViews/
│       └── Components/
│           └── SophisticatedImageView.swift # 高度な画像表示
```

## 技術仕様

### 使用技術
- **フレームワーク**: SwiftUI, AVFoundation, Metal, Core Image
- **データベース**: Supabase (PostgreSQL)
- **ストレージ**: Supabase Storage
- **アーキテクチャ**: MVVM + Repository パターン
- **画像処理**: Core Image, Metal Performance Shaders
- **RAW処理**: ImageIO, Core Graphics

### 主要コンポーネント

#### CustomCameraView
プロ級カメラ機能
- AVFoundation ベースのリアルタイムプレビュー
- マルチタッチズーム (1x-10x)
- タップツーフォーカス with 視覚フィードバック
- リアルタイムフィルター適用
- フラッシュ & カメラ切替制御

#### PhotoEditorView
高度な写真編集エディター
- Metal ベースのリアルタイムプレビュー
- RAW ファイル対応 (主要メーカー全対応)
- プロレベルの調整項目 (露出、色温度、ハイライト/シャドウ)
- 非破壊編集 & 編集履歴管理
- 高品質フィルターパック

#### StoryStyleEditorView
雑誌記事エディター
- フルスクリーン表示
- 動的グラデーション背景
- インタラクティブな紙のキャンバス
- リアルタイム編集機能

#### ImageProcessor
インテリジェント画像処理
- 自動リサイズ & 最適化 (最大2048px)
- メモリ効率的な処理
- 複数品質書き出し (最高品質〜圧縮)
- サムネイル自動生成

#### PostService & MagazineFeedView
統合コンテンツ管理
- 写真と記事の統合フィード
- 効率的なデータ取得 & キャッシュ
- ソーシャル機能 (いいね、コメント)
- カテゴリ別セクション
- レスポンシブレイアウト

#### ArticleRepository
記事データの管理
- CRUD操作
- ユーザー認証連携
- リアルタイム更新

### データモデル

#### Post (写真投稿)
```swift
struct Post {
    let id: String
    let userId: String
    let mediaUrl: String           // 画像・動画URL
    let thumbnailUrl: String?      // サムネイルURL
    let mediaType: MediaType       // .photo または .video
    let mediaWidth: Int            // 画像幅
    let mediaHeight: Int           // 画像高
    let caption: String?           // キャプション
    let location: String?          // 位置情報
    let latitude: Double?
    let longitude: Double?
    let isPublic: Bool             // 公開/非公開
    let likeCount: Int
    let commentCount: Int
    let createdAt: Date
    // ユーザー情報、いいね状態など...
}
```

#### BlogArticle (記事投稿)
```swift
struct BlogArticle {
    let id: String
    let userId: String
    let title: String
    let content: String
    let summary: String?
    let category: String?
    let tags: [String]
    let isPremium: Bool
    let coverImageUrl: String?
    let status: ArticleStatus
    let articleType: ArticleType  // .newspaper または .magazine
    let publishedAt: Date?
    let viewCount: Int
    let likeCount: Int
    // その他のプロパティ...
}
```

#### MediaType & ArticleType
```swift
enum MediaType: String {
    case photo = "photo"
    case video = "video"
}

enum ArticleType: String {
    case newspaper = "newspaper"  // 新聞記事
    case magazine = "magazine"    // 雑誌記事
}
```

## セットアップ

1. プロジェクトをクローン
2. Supabaseの設定
3. 依存関係の解決
4. ビルド&実行

## パフォーマンス & 最適化

### 画像処理最適化
- **メモリ効率**: 大容量RAW画像の効率的な処理
- **プログレッシブ読み込み**: サムネイル→フル画像の段階的表示
- **キャッシュ戦略**: インテリジェントな画像キャッシュ管理
- **バックグラウンド処理**: UI blocking なしの画像処理

### ネットワーク最適化
- **画像圧縮**: アップロード前の自動最適化
- **プログレストラッキング**: リアルタイムアップロード進捗
- **オフライン対応**: ローカルキャッシュでのオフライン閲覧

## 特徴的な技術実装

### RAW画像処理
- **対応フォーマット**: Canon (CR2), Sony (ARW), Nikon (NEF), Adobe (DNG), Fujifilm (RAF), Olympus (ORF)
- **プロレベル調整**: 露出、色温度、ハイライト/シャドウ、ノイズリダクション
- **非破壊編集**: 元画像を保持した編集システム

### リアルタイムフィルター
- **Metal シェーダー**: 60fps でのリアルタイムプレビュー
- **プロフィルター**: 映画的フィルターパック
- **カスタマイズ**: 強度調整可能なフィルター

### インテリジェントUI
- **アスペクト比自動検出**: 16:9以上の画像は自動でランドスケープ表示
- **アダプティブレイアウト**: 画像サイズに応じた最適レイアウト
- **コンテンツモデレーション**: AI による自動コンテンツ検閲

## アプリの位置づけ

- **写真投稿**: プロ級の編集機能付き
- **記事投稿**: 美しいレイアウトでのライティング
- **高品質フィルター**: RAW現像機能まで搭載

プロフェッショナルなクリエイターから一般ユーザーまで、誰でも美しいコンテンツを作成・共有できるプラットフォームを目指しています。