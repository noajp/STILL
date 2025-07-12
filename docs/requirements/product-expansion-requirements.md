# プロダクト拡張要件 - Product Expansion Requirements

**最終更新**: 2025-06-16  
**ステータス**: Draft  
**承認者**: [プロダクト責任者名]

---

## 🎯 戦略的ポジショニング

### 市場での差別化要因

```
Instagram/TikTok (動画中心) vs Couleur (高品質写真+ゲーム要素)
                                      ↓
                          ┌─────────────────────────┐
                          │  レトロ写真特化SNS     │
                          │  + ARゲーミフィケーション │
                          └─────────────────────────┘
                                      ↓
                          ニッチ市場での強いブランド確立
```

### 競合分析
- **Instagram**: 汎用的、動画中心、フィルター品質中程度
- **TikTok**: 動画特化、若年層中心、写真機能弱い
- **VSCO**: 写真編集強いが、ソーシャル機能弱い
- **Couleur**: **レトロ写真特化 + ARゲーム要素**で独自性確立

## 🏗️ 技術アーキテクチャ拡張計画

### 現在のアーキテクチャとの統合

#### 既存システム
```
┌─────────────┐    ┌────────────────┐    ┌─────────────┐
│ SwiftUI UI  │◄──►│ MVVM ViewModels│◄──►│ Supabase    │
└─────────────┘    └────────────────┘    └─────────────┘
```

#### 拡張後アーキテクチャ
```
┌─────────────┐    ┌────────────────┐    ┌─────────────┐
│ SwiftUI UI  │◄──►│ MVVM ViewModels│◄──►│ Supabase    │
│ + MTKView   │    │ + PhotoEditVM  │    │ + AR Data   │
│ + ARSCNView │    │ + ARGameVM     │    │ + GameState │
└─────────────┘    └────────────────┘    └─────────────┘
       │                   │                    │
       ▼                   ▼                    ▼
┌─────────────┐    ┌────────────────┐    ┌─────────────┐
│Core Image   │    │Photo Edit      │    │AR/Location  │
│Metal        │    │Service         │    │Service      │
│ARKit        │    │Filter Engine   │    │Game Engine  │
└─────────────┘    └────────────────┘    └─────────────┘
```

## 📅 段階的実装ロードマップ

### Phase 1: 写真編集基盤 (1-2ヶ月)

#### 1.1 Core Image統合
```swift
// 新規追加コンポーネント
PhotoEditingService/
├── FilterEngine.swift        # Core Imageフィルター管理
├── RetroFilterLibrary.swift  # レトロ専用フィルター
├── LUTProcessor.swift        # LUTベースの色変換
└── PerformanceOptimizer.swift # GPU最適化

Features/PhotoEditor/
├── Views/
│   ├── PhotoEditorView.swift     # メイン編集画面
│   ├── FilterSelectionView.swift # フィルター選択UI
│   └── MTKPhotoView.swift        # リアルタイム表示
├── ViewModels/
│   └── PhotoEditViewModel.swift  # 編集状態管理
└── Components/
    ├── FilterSlider.swift        # パラメータ調整
    └── EffectPreview.swift       # プレビュー表示
```

#### 1.2 レトロフィルター実装
```swift
// カスタムフィルター例
class VintageFilmFilter: CIFilter {
    // セピア + グレイン + ビネット効果
    // Metalシェーダーでフィルムグレイン生成
    // LUTで特定フィルムエミュレーション
}

// 提供フィルター種類
- Kodak Portra風
- Fuji Pro 400H風  
- Polaroid風
- 70s/80s/90s各年代風
- モノクロ銀塩風
```

#### 1.3 CreatePost統合
```
CreatePostView → PhotoEditorView → 編集完了 → 投稿作成
```

### Phase 2: ゲーミフィケーション基盤 (2-3ヶ月)

#### 2.1 位置情報ゲームエンジン
```swift
// 新規追加コンポーネント
GameEngine/
├── LocationGameManager.swift    # 位置ベースゲーム管理
├── PanoramaCapture.swift       # 集合写真撮影
├── ARTreasureHunt.swift        # AR宝探し
└── GameStateSync.swift         # リアルタイム同期

Core/Services/
├── ARService.swift             # ARKit統合
├── LocationService.swift       # 位置情報管理
└── GameProgressService.swift   # 進捗管理
```

#### 2.2 パノラマ集合写真機能
**実装要素:**
1. 位置検出 (CLLocationManager)
2. 近接ユーザー発見 (Supabase Realtime)
3. 撮影同期 (WebSocket通信)
4. 画像スティッチング (Core Image/OpenCV)
5. 結果共有 (既存投稿システム)

#### 2.3 AR宝探し機能
```swift
// ARKit + Vision + Core ML統合
ARTreasureHuntView/
├── ARSCNView                   # AR表示
├── 物体認識 (Vision)           # 現実オブジェクト検出
├── 仮想宝箱配置 (ARKit)        # GPS座標ベース
└── ゲーム進行管理              # スコア・レベル
```

### Phase 3: 高度機能・最適化 (3-4ヶ月)

#### 3.1 AI機能統合
```swift
// Core ML統合
PhotoAnalysisService/
├── AutoTagging.swift          # 写真の自動タグ付け
├── QualityAssessment.swift    # 写真品質評価
└── StyleRecommendation.swift  # フィルター推奨
```

#### 3.2 コミュニティ機能
```swift
// ゲーミフィケーション拡張
Community/
├── LeaderboardView.swift      # ランキング表示
├── ChallengeSystem.swift      # 撮影チャレンジ
├── BadgeSystem.swift          # 実績バッジ
└── EventManagement.swift      # ARイベント管理
```

## 🛠️ 技術実装詳細

### Core Image最適化戦略
```swift
class OptimizedFilterEngine {
    private let context: CIContext = {
        // GPU最適化コンテキスト
        let options = [CIContextOption.workingColorSpace: CGColorSpace.sRGB]
        return CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!, options: options)
    }()
    
    // フィルターチェーン最適化
    func applyRetroEffect(to image: CIImage) -> CIImage {
        // 複数フィルターを1つのカーネルに統合
        return image
            .applyingFilter("CISepiaTone")
            .applyingFilter("CustomFilmGrain") // Metalシェーダー
            .applyingFilter("VintageVignette")
    }
}
```

### AR + 位置情報統合
```swift
class ARLocationManager {
    // ARKit + Core Location統合
    func placeARTreasure(at coordinate: CLLocationCoordinate2D) {
        // GPS座標をAR空間に変換
        let location = CLLocation(latitude: coordinate.latitude,
                                longitude: coordinate.longitude)
        let arAnchor = ARGeoAnchor(coordinate: coordinate)
        // AR宝箱配置
    }
}
```

### リアルタイム通信拡張
```swift
// Supabase Realtimeでゲーム状態同期
class GameStateService {
    func syncPanoramaSession(participants: [User]) {
        // 撮影タイミング同期
        // カウントダウン共有
        // 結果合成
    }
    
    func updateARGameState(treasureFound: ARTreasure) {
        // 宝箱発見をリアルタイム通知
        // スコア更新
        // ランキング反映
    }
}
```

## 📊 データモデル拡張

### 新規テーブル設計
```sql
-- 写真編集履歴
CREATE TABLE photo_edits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES posts(id),
    filter_name VARCHAR(100) NOT NULL,
    parameters JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ゲームプレイ記録
CREATE TABLE game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id),
    game_type VARCHAR(50) NOT NULL, -- 'treasure_hunt', 'panorama'
    score INTEGER DEFAULT 0,
    duration_seconds INTEGER,
    location POINT, -- PostGIS地理座標
    created_at TIMESTAMP DEFAULT NOW()
);

-- AR宝箱配置
CREATE TABLE ar_treasures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    treasure_type VARCHAR(50) NOT NULL,
    found_by UUID[] DEFAULT '{}', -- 発見したユーザーID配列
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP
);

-- パノラマセッション
CREATE TABLE panorama_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    initiator_id UUID REFERENCES profiles(id),
    participants UUID[] NOT NULL,
    result_image_url TEXT,
    location POINT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ユーザー実績
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id),
    badge_type VARCHAR(50) NOT NULL,
    earned_at TIMESTAMP DEFAULT NOW(),
    game_session_id UUID REFERENCES game_sessions(id)
);
```

## 🎮 ゲーミフィケーション要素

### 進行システム
- **Level 1**: 写真初心者 (投稿5枚)
- **Level 2**: フィルター探求者 (レトロフィルター使用10回)
- **Level 3**: AR冒険者 (宝箱発見3個)
- **Level 4**: パノラママスター (集合写真撮影5回)
- **Level 5**: コミュニティリーダー (いいね100獲得)

### バッジシステム
- 📸 **レトロマスター**: 全フィルター使用
- 🗺️ **探検家**: 10箇所でAR宝探し完了
- 👥 **チームワーカー**: パノラマ撮影10回参加
- ⭐ **インフルエンサー**: フォロワー1000人達成
- 🏆 **レジェンド**: 全バッジ獲得

## 💰 収益化戦略

### プレミアム機能
- **高度フィルター**: プロ級レトロエフェクト
- **カスタムLUT**: オリジナル色調作成
- **優先AR宝箱**: 限定アイテム発見
- **無制限ストレージ**: 高解像度写真保存

### ブランドパートナーシップ
- **フィルムメーカー**: KodakやFujiとのコラボフィルター
- **カフェ・レストラン**: 位置ベースAR宝探しイベント
- **観光地**: 限定ARコンテンツ提供

## 🚀 市場展開戦略

### フェーズ1: コアユーザー獲得
- 写真愛好家コミュニティでのβテスト
- インフルエンサーとのコラボ
- レトロ写真コンテスト開催

### フェーズ2: 機能差別化
- 独自AR体験の強化
- コミュニティイベント定期開催
- ソーシャル機能の充実

### フェーズ3: グローバル展開
- 多言語対応
- 地域特化ARコンテンツ
- 海外インフルエンサー連携

## ⚡ 実装優先度

### 高優先度（Phase 1）
- [ ] Core Imageフィルターエンジン
- [ ] レトロフィルターライブラリ
- [ ] 写真編集UI
- [ ] 基本ゲーミフィケーション

### 中優先度（Phase 2）
- [ ] AR宝探し機能
- [ ] パノラマ撮影機能
- [ ] リアルタイム通信拡張
- [ ] バッジシステム

### 低優先度（Phase 3）
- [ ] AI写真解析
- [ ] 高度なARコンテンツ
- [ ] ブランドパートナーシップ
- [ ] 収益化機能

## 📈 成功指標

### ユーザーエンゲージメント
- **DAU増加率**: 月20%以上
- **セッション時間**: 平均15分以上
- **投稿頻度**: ユーザーあたり週3投稿以上
- **ゲーム参加率**: 60%以上

### 収益指標
- **プレミアム転換率**: 5%以上
- **ARPU**: $5以上/月
- **LTV**: $50以上
- **ブランドパートナーシップ**: 四半期5社以上

---

## 📚 関連ドキュメント

- [Technical Specifications](technical-specifications.md)
- [Security Requirements](security-requirements.md)
- [Legal Requirements](legal-requirements.md)
- [ADR-003: Gamification Strategy](../decisions/ADR-003-gamification-strategy.md)

## 👥 ステークホルダー

**プロダクト責任者**: [プロダクト責任者名]  
**技術責任者**: [技術責任者名]  
**UX/UIデザイナー**: [デザイナー名]  
**ゲーム企画**: [ゲーム企画担当者名]