# couleur 推薦システム設計書

## 🎯 目的

Twitter/PayPalの技術思想を応用し、写真共有に特化した高度な推薦システムを構築する。

---

## 🏗️ システムアーキテクチャ

### 概要図
```
┌─────────────────────────────────────────────────────────────┐
│                     couleur推薦システム                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [全投稿プール]                                              │
│       ↓                                                     │
│  ┌─────────┐    ┌──────────┐    ┌──────────┐              │
│  │候補生成  │ → │軽量ランキング│ → │重量ランキング│           │
│  │(1000s)  │    │(100s)     │    │(20-30)    │            │
│  └─────────┘    └──────────┘    └──────────┘              │
│       ↑              ↑               ↑                      │
│  ┌─────────────────────────────────────┐                   │
│  │     特徴量エンジニアリング           │                   │
│  │  ・視覚的特徴 ・エンゲージメント     │                   │
│  │  ・ユーザー嗜好 ・時系列パターン     │                   │
│  └─────────────────────────────────────┘                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 コンポーネント詳細

### 1. 候補生成層

#### データソース
- **Following**: フォロー中ユーザーの最新投稿
- **Discovery**: 非フォローからの関連投稿
- **Trending**: 急上昇中のコンテンツ
- **Similar Users**: 類似ユーザーからの投稿

#### 実装例
```swift
protocol CandidateSource {
    func getCandidates(for userId: String, limit: Int) async throws -> [PostCandidate]
}

class FollowingCandidateSource: CandidateSource {
    func getCandidates(for userId: String, limit: Int) async throws -> [PostCandidate] {
        let followingIds = await getFollowingUserIds(userId)
        let posts = await supabase
            .from("posts")
            .select("*")
            .in("user_id", followingIds)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        
        return posts.map { PostCandidate(post: $0, source: .following) }
    }
}
```

### 2. 特徴量エンジニアリング

#### 視覚的特徴（写真SNS特化）
```swift
struct VisualFeatures {
    // 色彩分析
    let dominantColors: [Color]
    let colorHarmony: Double        // 0-1: 色の調和度
    let colorVibrancy: Double       // 0-1: 鮮やかさ
    
    // 構図分析
    let compositionType: CompositionType
    let ruleOfThirdsScore: Double
    let symmetryScore: Double
    let leadingLinesScore: Double
    
    // 技術的品質
    let sharpnessScore: Double
    let exposureQuality: Double
    let noiseLevel: Double
    
    // スタイル分類
    let photographyStyle: PhotographyStyle
    let aestheticScore: Double      // 美的スコア
}

enum CompositionType {
    case ruleOfThirds
    case centered
    case diagonal
    case symmetrical
    case minimalist
}

enum PhotographyStyle {
    case portrait
    case landscape
    case street
    case macro
    case abstract
    case documentary
}
```

#### エンゲージメント特徴
```swift
struct EngagementFeatures {
    // 速度指標
    let likeVelocity: Double       // いいね/時間
    let saveVelocity: Double       // 保存/時間
    let commentVelocity: Double    // コメント/時間
    
    // 品質指標
    let engagementRate: Double     // (いいね+保存+コメント)/表示数
    let saveToLikeRatio: Double    // 保存/いいね（価値の指標）
    let commentQuality: Double     // コメントの長さ・感情スコア
    
    // 拡散指標
    let shareCount: Int
    let virality: Double           // 拡散係数
}
```

### 3. 軽量ランキング層

#### 高速スコアリング
```swift
class LightweightRanker {
    func rank(_ candidates: [PostCandidate], for userId: String) async -> [PostCandidate] {
        let userProfile = await getUserQuickProfile(userId)
        
        return candidates
            .map { candidate in
                var score = 0.0
                
                // 基本スコア
                score += candidate.recencyScore * 0.2
                score += candidate.popularityScore * 0.3
                
                // パーソナライゼーション（簡易版）
                score += calculateQuickAffinity(candidate, userProfile) * 0.5
                
                return candidate.withScore(score)
            }
            .sorted { $0.score > $1.score }
            .prefix(100)
            .map { $0 }
    }
}
```

### 4. 重量ランキング層

#### MLモデル統合
```swift
class HeavyweightRanker {
    private let mlModel: RecommendationMLModel
    
    func rank(_ candidates: [PostCandidate], for userId: String) async -> [Post] {
        // 詳細特徴量抽出
        let features = await extractDetailedFeatures(candidates, userId: userId)
        
        // ML予測
        let predictions = await mlModel.batchPredict(features)
        
        // 多様性調整
        let diversified = applyDiversityBoost(candidates, predictions)
        
        // 最終ランキング
        return diversified
            .sorted { $0.finalScore > $1.finalScore }
            .prefix(25)
            .map { $0.post }
    }
    
    private func applyDiversityBoost(
        _ candidates: [PostCandidate], 
        _ scores: [Double]
    ) -> [RankedPost] {
        var rankedPosts: [RankedPost] = []
        var seenAuthors: Set<String> = []
        var seenStyles: Set<PhotographyStyle> = []
        
        for (candidate, score) in zip(candidates, scores) {
            var adjustedScore = score
            
            // 作者の多様性
            if seenAuthors.contains(candidate.post.userId) {
                adjustedScore *= 0.7  // 同じ作者は30%減点
            } else {
                seenAuthors.insert(candidate.post.userId)
            }
            
            // スタイルの多様性
            if let style = candidate.visualFeatures?.photographyStyle {
                if seenStyles.contains(style) {
                    adjustedScore *= 0.85  // 同じスタイルは15%減点
                } else {
                    seenStyles.insert(style)
                }
            }
            
            rankedPosts.append(RankedPost(
                post: candidate.post,
                originalScore: score,
                finalScore: adjustedScore
            ))
        }
        
        return rankedPosts
    }
}
```

---

## 🧠 機械学習モデル

### モデルアーキテクチャ
```python
# TensorFlow/Core ML用のモデル定義例
class CouleurRecommendationModel(tf.keras.Model):
    def __init__(self):
        super().__init__()
        
        # 特徴量エンコーダー
        self.visual_encoder = tf.keras.Sequential([
            tf.keras.layers.Dense(128, activation='relu'),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(64, activation='relu')
        ])
        
        self.engagement_encoder = tf.keras.Sequential([
            tf.keras.layers.Dense(64, activation='relu'),
            tf.keras.layers.Dense(32, activation='relu')
        ])
        
        self.user_encoder = tf.keras.Sequential([
            tf.keras.layers.Dense(128, activation='relu'),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(64, activation='relu')
        ])
        
        # 結合層
        self.fusion = tf.keras.Sequential([
            tf.keras.layers.Dense(128, activation='relu'),
            tf.keras.layers.Dropout(0.3),
            tf.keras.layers.Dense(64, activation='relu'),
            tf.keras.layers.Dense(32, activation='relu')
        ])
        
        # 出力層（複数タスク）
        self.like_prediction = tf.keras.layers.Dense(1, activation='sigmoid')
        self.save_prediction = tf.keras.layers.Dense(1, activation='sigmoid')
        self.engagement_time = tf.keras.layers.Dense(1, activation='linear')
        
    def call(self, inputs):
        visual_features = inputs['visual']
        engagement_features = inputs['engagement']
        user_features = inputs['user']
        
        # エンコード
        visual_encoded = self.visual_encoder(visual_features)
        engagement_encoded = self.engagement_encoder(engagement_features)
        user_encoded = self.user_encoder(user_features)
        
        # 結合
        combined = tf.concat([visual_encoded, engagement_encoded, user_encoded], axis=1)
        fused = self.fusion(combined)
        
        # 予測
        like_prob = self.like_prediction(fused)
        save_prob = self.save_prediction(fused)
        engagement_duration = self.engagement_time(fused)
        
        # 総合スコア
        final_score = (
            like_prob * 0.3 + 
            save_prob * 0.5 +  # 保存は価値が高い
            tf.sigmoid(engagement_duration / 30) * 0.2  # 30秒を基準
        )
        
        return {
            'score': final_score,
            'like_probability': like_prob,
            'save_probability': save_prob,
            'expected_engagement_time': engagement_duration
        }
```

### 学習データ
```sql
-- 学習用のインタラクションデータ
CREATE VIEW ml_training_data AS
SELECT 
    ui.user_id,
    ui.post_id,
    p.created_at as post_created_at,
    ui.created_at as interaction_at,
    ui.action_type,
    ui.duration_seconds,
    pf.color_palette,
    pf.composition_type,
    pf.aesthetic_score,
    u.follower_count,
    u.following_count,
    u.post_count,
    -- ラベル
    CASE WHEN ui.action_type = 'like' THEN 1 ELSE 0 END as liked,
    CASE WHEN ui.action_type = 'save' THEN 1 ELSE 0 END as saved,
    ui.duration_seconds as engagement_duration
FROM user_interactions ui
JOIN posts p ON ui.post_id = p.id
JOIN post_features pf ON p.id = pf.post_id
JOIN user_profiles u ON ui.user_id = u.id
WHERE ui.created_at > NOW() - INTERVAL '30 days';
```

---

## 🚀 実装ロードマップ

### Phase 1: 基礎実装（4週間）
- [ ] データモデル拡張
- [ ] 基本的な候補生成
- [ ] シンプルなスコアリング
- [ ] A/Bテスト基盤

### Phase 2: ML統合（6週間）
- [ ] 特徴量パイプライン
- [ ] MLモデル訓練
- [ ] リアルタイム推論
- [ ] パフォーマンス最適化

### Phase 3: 高度な機能（8週間）
- [ ] SimClustersスタイル実装
- [ ] リアルタイム学習
- [ ] 説明可能AI
- [ ] クリエイター分析ダッシュボード

---

## 📊 評価指標

### ビジネスKPI
- **DAU/MAU**: 日次/月次アクティブユーザー
- **セッション時間**: 平均滞在時間
- **エンゲージメント率**: (いいね+保存+コメント)/表示数
- **リテンション**: 7日、30日リテンション

### アルゴリズムメトリクス
- **CTR**: クリック率
- **Save Rate**: 保存率
- **Dwell Time**: 閲覧時間
- **Diversity**: 作者・スタイルの多様性

### ユーザー満足度
- **NPS**: ネットプロモータースコア
- **アンケート**: 推薦品質の主観評価
- **クリエイター満足度**: 投稿のリーチと反応

---

## 🔒 プライバシーとセキュリティ

### データ保護
- 個人識別情報の匿名化
- 最小限のデータ収集
- 定期的なデータ削除

### 透明性
- アルゴリズムの説明機能
- ユーザー設定による制御
- データ利用の明示

### セキュリティ
- PayPal風の多層防御
- 異常検知システム
- 定期的な監査

---

このドキュメントは、couleurの推薦システム開発の指針として継続的に更新されます。