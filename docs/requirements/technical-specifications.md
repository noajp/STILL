# 技術仕様書 - Technical Specifications

**最終更新**: 2025-06-16  
**ステータス**: Draft  
**承認者**: [技術責任者名]

---

## 🏗️ システムアーキテクチャ

### 全体アーキテクチャ
```
┌─────────────────────────────────────────────────────────┐
│                    Client Layer                         │
├─────────────────────────────────────────────────────────┤
│ SwiftUI Views + MTKView + ARSCNView                     │
│ ├── PhotoEditor/                                        │
│ ├── Camera/                                             │
│ ├── ARGame/                                             │
│ └── Social/                                             │
├─────────────────────────────────────────────────────────┤
│                  ViewModel Layer                        │
├─────────────────────────────────────────────────────────┤
│ MVVM ViewModels + Combine                               │
│ ├── PhotoEditViewModel                                  │
│ ├── ARGameViewModel                                     │
│ ├── SocialViewModel                                     │
│ └── AuthViewModel                                       │
├─────────────────────────────────────────────────────────┤
│                   Service Layer                         │
├─────────────────────────────────────────────────────────┤
│ Core Services                                           │
│ ├── PhotoEditingService (Core Image)                   │
│ ├── ARLocationService (ARKit + Core Location)          │
│ ├── GameEngineService                                  │
│ ├── RealtimeService (Supabase)                         │
│ └── ContentModerationService                           │
├─────────────────────────────────────────────────────────┤
│                   Data Layer                            │
├─────────────────────────────────────────────────────────┤
│ Supabase Backend + Local Storage                       │
│ ├── PostgreSQL Database                                │
│ ├── Real-time Subscriptions                            │
│ ├── File Storage                                       │
│ └── Core Data (Local Cache)                            │
└─────────────────────────────────────────────────────────┘
```

## 📱 クライアントサイド技術仕様

### 開発環境要件
```swift
// 最小要件
iOS: 15.0+
Xcode: 15.0+
Swift: 5.9+
Device: iPhone 12+ (A14 Bionic+)

// 推奨要件  
iOS: 17.0+
Device: iPhone 15+ (A17 Pro+)
Memory: 6GB+ RAM
Storage: 128GB+
```

### 主要フレームワーク
```swift
import SwiftUI          // UI Framework
import Combine          // Reactive Programming
import Core Image       // Image Processing
import Metal           // GPU Computing
import ARKit           // Augmented Reality
import Core Location   // Location Services
import Core ML         // Machine Learning
import Vision          // Computer Vision
import AVFoundation    // Camera/Audio
import Photos          // Photo Library
import CryptoKit       // Cryptography
```

### プロジェクト構造
```
Couleur/
├── Application/
│   ├── CouleurApp.swift
│   ├── AppCoordinator.swift
│   └── AppEnvironment.swift
├── Core/
│   ├── Services/
│   │   ├── PhotoEditingService.swift
│   │   ├── ARLocationService.swift
│   │   ├── GameEngineService.swift
│   │   ├── RealtimeService.swift
│   │   └── ContentModerationService.swift
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Post.swift
│   │   ├── GameSession.swift
│   │   └── ARTreasure.swift
│   └── Extensions/
├── Features/
│   ├── PhotoEditor/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Components/
│   ├── ARGame/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Components/
│   ├── Camera/
│   └── Social/
└── Resources/
    ├── Filters/
    ├── AR Assets/
    └── Localizations/
```

## 🎨 写真編集技術仕様

### Core Image実装

#### FilterEngine設計
```swift
protocol FilterEngine {
    func applyFilter(_ filter: FilterType, to image: CIImage, intensity: Float) -> CIImage
    func createFilterChain(_ filters: [FilterConfiguration]) -> CIFilter
    func optimizeForRealtime(_ enable: Bool)
}

class RetroFilterEngine: FilterEngine {
    private let context: CIContext
    private let metalDevice: MTLDevice
    
    init() {
        self.metalDevice = MTLCreateSystemDefaultDevice()!
        self.context = CIContext(mtlDevice: metalDevice)
    }
    
    func applyVintageEffect(to image: CIImage) -> CIImage {
        // 1. Color Grading (LUT)
        let colorGraded = image.applyingFilter("CIColorCube", parameters: [
            "inputCubeData": vintageColorLUT
        ])
        
        // 2. Film Grain (Custom Metal Shader)
        let filmGrain = colorGraded.applyingFilter("CustomFilmGrain", parameters: [
            "inputIntensity": 0.3,
            "inputGrainSize": 1.2
        ])
        
        // 3. Vignette
        let vignette = filmGrain.applyingFilter("CIVignette", parameters: [
            "inputIntensity": 0.8,
            "inputRadius": 1.5
        ])
        
        return vignette
    }
}
```

#### カスタムMetalシェーダー
```metal
// FilmGrain.metal
#include <metal_stdlib>
using namespace metal;

kernel void filmGrainEffect(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           constant float &intensity [[buffer(0)]],
                           constant float &grainSize [[buffer(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    
    float2 textureSize = float2(inTexture.get_width(), inTexture.get_height());
    float2 uv = float2(gid) / textureSize;
    
    // ランダムノイズ生成
    float noise = random(uv * grainSize);
    
    // 元画像色取得
    float4 color = inTexture.read(gid);
    
    // グレイン適用
    color.rgb += (noise - 0.5) * intensity;
    
    outTexture.write(color, gid);
}
```

#### LUTプロセッサー
```swift
class LUTProcessor {
    private static let lutSize = 64
    
    func loadVintageLUT() -> Data {
        // Kodak Portra風LUT
        // 3D Color Lookup Table (64x64x64)
        var lutData = Data()
        
        for blue in 0..<lutSize {
            for green in 0..<lutSize {
                for red in 0..<lutSize {
                    let r = Float(red) / Float(lutSize - 1)
                    let g = Float(green) / Float(lutSize - 1)
                    let b = Float(blue) / Float(lutSize - 1)
                    
                    // Vintage color mapping
                    let transformedColor = applyVintageTransform(r: r, g: g, b: b)
                    
                    lutData.append(contentsOf: [
                        UInt8(transformedColor.r * 255),
                        UInt8(transformedColor.g * 255),
                        UInt8(transformedColor.b * 255),
                        255
                    ])
                }
            }
        }
        
        return lutData
    }
}
```

## 🎮 ARゲーミフィケーション技術仕様

### ARKit統合

#### AR宝探しシステム
```swift
class ARTreasureHuntManager: NSObject {
    private var sceneView: ARSCNView
    private var locationManager: CLLocationManager
    private var treasures: [ARTreasure] = []
    
    func startTreasureHunt() {
        // 1. ARセッション開始
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
        
        // 2. 近隣宝箱取得
        loadNearbyTreasures()
        
        // 3. AR宝箱配置
        placeTreasuresInAR()
    }
    
    private func placeTreasuresInAR() {
        for treasure in treasures {
            let treasureNode = createTreasureNode(treasure)
            let anchor = ARAnchor(transform: treasure.transform)
            sceneView.session.add(anchor: anchor)
        }
    }
}
```

#### 位置情報ゲームエンジン
```swift
class LocationGameEngine {
    private let gameRadius: CLLocationDistance = 100 // 100m範囲
    
    func findNearbyPlayers() async -> [User] {
        guard let location = locationManager.location else { return [] }
        
        // Supabase Realtimeで近接ユーザー検索
        let nearbyUsers = try await supabase
            .from("user_locations")
            .select("*")
            .execute()
            .value
        
        return nearbyUsers.filter { user in
            location.distance(from: user.location) <= gameRadius
        }
    }
    
    func initiatePanoramaSession(with users: [User]) async {
        // 1. セッション作成
        let session = PanoramaSession(participants: users)
        
        // 2. 参加者に通知
        for user in users {
            await notifyUser(user, session: session)
        }
        
        // 3. 同期カウントダウン開始
        await startSynchronizedCountdown()
    }
}
```

### パノラマ撮影システム
```swift
class PanoramaCapture {
    private var captureSession: AVCaptureSession
    private var photoOutput: AVCapturePhotoOutput
    
    func captureSynchronizedPhotos() async -> [UIImage] {
        var photos: [UIImage] = []
        
        // 同期撮影
        for participant in session.participants {
            let photo = await capturePhotoFromParticipant(participant)
            photos.append(photo)
        }
        
        // パノラマ合成
        let panorama = await stitchPhotos(photos)
        return panorama
    }
    
    private func stitchPhotos(_ photos: [UIImage]) async -> UIImage {
        // OpenCV or Core Imageでパノラマ合成
        // 1. 特徴点検出
        // 2. マッチング
        // 3. ホモグラフィ計算
        // 4. 画像合成
    }
}
```

## 🗄️ データベース設計

### Supabase Schema
```sql
-- ユーザープロフィール拡張
ALTER TABLE profiles ADD COLUMN 
    game_level INTEGER DEFAULT 1,
    total_score INTEGER DEFAULT 0,
    badges_earned TEXT[] DEFAULT '{}',
    premium_expires_at TIMESTAMP;

-- 写真編集履歴
CREATE TABLE photo_edits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    filter_name VARCHAR(100) NOT NULL,
    parameters JSONB DEFAULT '{}',
    processing_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ゲームセッション
CREATE TABLE game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    game_type game_type_enum NOT NULL,
    status session_status_enum DEFAULT 'active',
    score INTEGER DEFAULT 0,
    duration_seconds INTEGER,
    location POINT, -- PostGIS
    metadata JSONB DEFAULT '{}',
    started_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- AR宝箱
CREATE TABLE ar_treasures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    treasure_type treasure_type_enum NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    altitude DECIMAL(8, 2) DEFAULT 0,
    difficulty_level INTEGER DEFAULT 1,
    reward_points INTEGER DEFAULT 10,
    found_by UUID[] DEFAULT '{}',
    max_finds INTEGER DEFAULT 10,
    expires_at TIMESTAMP,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT valid_coordinates CHECK (
        latitude BETWEEN -90 AND 90 AND
        longitude BETWEEN -180 AND 180
    )
);

-- パノラマセッション  
CREATE TABLE panorama_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    initiator_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    session_code VARCHAR(8) UNIQUE NOT NULL,
    max_participants INTEGER DEFAULT 6,
    participants UUID[] DEFAULT '{}',
    photo_urls TEXT[] DEFAULT '{}',
    result_panorama_url TEXT,
    location POINT,
    status session_status_enum DEFAULT 'waiting',
    expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '1 hour'),
    created_at TIMESTAMP DEFAULT NOW()
);

-- ユーザー実績
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    achievement_type achievement_type_enum NOT NULL,
    earned_at TIMESTAMP DEFAULT NOW(),
    game_session_id UUID REFERENCES game_sessions(id),
    metadata JSONB DEFAULT '{}',
    
    UNIQUE(user_id, achievement_type)
);

-- Enum定義
CREATE TYPE game_type_enum AS ENUM (
    'treasure_hunt',
    'panorama_capture',
    'filter_challenge'
);

CREATE TYPE session_status_enum AS ENUM (
    'waiting',
    'active', 
    'completed',
    'expired',
    'cancelled'
);

CREATE TYPE treasure_type_enum AS ENUM (
    'bronze',
    'silver', 
    'gold',
    'diamond',
    'special_event'
);

CREATE TYPE achievement_type_enum AS ENUM (
    'retro_master',
    'explorer',
    'team_worker',
    'influencer',
    'legend'
);
```

### インデックス最適化
```sql
-- 位置検索最適化
CREATE INDEX idx_ar_treasures_location ON ar_treasures USING GIST (
    ST_Point(longitude, latitude)
);

-- ゲームセッション検索
CREATE INDEX idx_game_sessions_user_type ON game_sessions (user_id, game_type);
CREATE INDEX idx_game_sessions_location ON game_sessions USING GIST (location);

-- 写真編集履歴
CREATE INDEX idx_photo_edits_user_created ON photo_edits (user_id, created_at DESC);

-- パノラマセッション
CREATE INDEX idx_panorama_sessions_code ON panorama_sessions (session_code);
CREATE INDEX idx_panorama_sessions_location ON panorama_sessions USING GIST (location);
```

## 🔄 リアルタイム通信仕様

### Supabase Realtime統合
```swift
class RealtimeGameService {
    private var client: SupabaseClient
    private var gameChannel: RealtimeChannelV2?
    
    func subscribeTo

GameUpdates() async {
        gameChannel = client.realtimeV2.channel("game_updates")
        
        // AR宝箱発見イベント
        await gameChannel?.on(.insert, table: "ar_treasure_finds") { message in
            await self.handleTreasureFound(message)
        }
        
        // パノラマセッション更新
        await gameChannel?.on(.update, table: "panorama_sessions") { message in
            await self.handlePanoramaUpdate(message)
        }
        
        // 近接ユーザー検出
        await gameChannel?.on(.insert, table: "user_locations") { message in
            await self.handleNearbyUser(message)
        }
        
        await gameChannel?.subscribe()
    }
}
```

## 🛡️ セキュリティ実装

### Row Level Security (RLS)
```sql
-- プロフィールアクセス制御
CREATE POLICY "Users can read own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles  
    FOR UPDATE USING (auth.uid() = id);

-- ゲームセッションアクセス制御
CREATE POLICY "Users can read own game sessions" ON game_sessions
    FOR SELECT USING (auth.uid() = user_id);

-- AR宝箱の発見記録
CREATE POLICY "Users can insert treasure finds" ON ar_treasure_finds
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- パノラマセッション参加制御
CREATE POLICY "Participants can read panorama session" ON panorama_sessions
    FOR SELECT USING (
        auth.uid() = initiator_id OR 
        auth.uid() = ANY(participants)
    );
```

### API認証・認可
```swift
class SecureAPIService {
    private let client: SupabaseClient
    
    func authenticatedRequest<T>(_ request: @escaping () async throws -> T) async throws -> T {
        // JWTトークン検証
        guard let token = await AuthManager.shared.currentSession?.accessToken else {
            throw APIError.unauthorized
        }
        
        // リクエスト実行
        return try await request()
    }
    
    func uploadPhotoWithValidation(_ image: UIImage) async throws -> String {
        // コンテンツモデレーション
        let moderationResult = await ContentModerationManager.shared.moderate(image)
        guard moderationResult.isApproved else {
            throw APIError.contentBlocked(moderationResult.reason)
        }
        
        // 画像アップロード
        return try await client.storage.from("photos").upload(
            path: generateSecurePath(),
            file: image.jpegData(compressionQuality: 0.8)!
        )
    }
}
```

## 📈 パフォーマンス最適化

### 画像処理最適化
```swift
class OptimizedImageProcessor {
    private let processingQueue = DispatchQueue(
        label: "image.processing",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    func processImageAsync(_ image: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                autoreleasepool {
                    let processed = self.applyOptimizedFilters(image)
                    continuation.resume(returning: processed)
                }
            }
        }
    }
    
    private func applyOptimizedFilters(_ image: UIImage) -> UIImage {
        // Core Imageコンテキスト再利用
        // Metalバッファプール使用
        // メモリ効率的な処理チェーン
    }
}
```

### メモリ管理
```swift
class ImageCache {
    private let cache = NSCache<NSString, UIImage>()
    
    init() {
        cache.countLimit = 50 // 最大50枚
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        
        // メモリ警告対応
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
}
```

---

## 📚 関連ドキュメント

- [Product Expansion Requirements](product-expansion-requirements.md)
- [Security Requirements](security-requirements.md)
- [Legal Requirements](legal-requirements.md)
- [ADR-003: Gamification Strategy](../decisions/ADR-003-gamification-strategy.md)

## 👥 レビュアー

**技術責任者**: [技術責任者名]  
**アーキテクト**: [アーキテクト名]  
**セキュリティエンジニア**: [セキュリティエンジニア名]  
**DevOpsエンジニア**: [DevOpsエンジニア名]