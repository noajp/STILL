# Supabase統合：カオスシステムのデータ基盤設計

## 🗄️ データベーススキーマ設計

### カオス関連テーブル

#### 1. chaos_events テーブル
```sql
CREATE TABLE chaos_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    chaos_strategy TEXT NOT NULL, -- 'random', 'sabotage', 'temporal', etc.
    surprise_level FLOAT CHECK (surprise_level >= 0 AND surprise_level <= 1),
    user_reaction JSONB,
    context_data JSONB,
    learning_outcome FLOAT,
    session_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックス
CREATE INDEX idx_chaos_events_user_id ON chaos_events(user_id);
CREATE INDEX idx_chaos_events_created_at ON chaos_events(created_at);
CREATE INDEX idx_chaos_events_strategy ON chaos_events(chaos_strategy);
CREATE INDEX idx_chaos_events_surprise ON chaos_events(surprise_level);
```

#### 2. user_chaos_profiles テーブル
```sql
CREATE TABLE user_chaos_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    chaos_tolerance FLOAT DEFAULT 0.2 CHECK (chaos_tolerance >= 0 AND chaos_tolerance <= 1),
    adaptation_level FLOAT DEFAULT 0.0 CHECK (adaptation_level >= 0 AND adaptation_level <= 1),
    preferred_chaos_level FLOAT DEFAULT 0.3,
    learning_style JSONB DEFAULT '{}',
    aesthetic_preferences JSONB DEFAULT '{}',
    cognitive_load_threshold FLOAT DEFAULT 0.8,
    total_sessions INTEGER DEFAULT 0,
    successful_adaptations INTEGER DEFAULT 0,
    exploration_score FLOAT DEFAULT 0.0,
    diversity_exposure_index FLOAT DEFAULT 0.0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 自動更新トリガー
CREATE OR REPLACE FUNCTION update_chaos_profile_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_chaos_profile_timestamp
    BEFORE UPDATE ON user_chaos_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_chaos_profile_timestamp();
```

#### 3. algorithm_predictions テーブル
```sql
CREATE TABLE algorithm_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    predicted_posts JSONB NOT NULL, -- 予測された投稿IDの配列
    prediction_confidence JSONB DEFAULT '{}', -- 投稿IDごとの信頼度
    actual_engagement JSONB DEFAULT '{}', -- 実際のエンゲージメント
    chaos_intervention BOOLEAN DEFAULT FALSE,
    prediction_accuracy FLOAT,
    session_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 4. chaos_experiments テーブル
```sql
CREATE TABLE chaos_experiments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_name TEXT NOT NULL,
    description TEXT,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    parameters JSONB DEFAULT '{}',
    target_metrics JSONB DEFAULT '{}',
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed')),
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE experiment_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_id UUID REFERENCES chaos_experiments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    experiment_group TEXT NOT NULL, -- 'control', 'low_chaos', 'medium_chaos', 'high_chaos'
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(experiment_id, user_id)
);
```

#### 5. daily_chaos_challenges テーブル
```sql
CREATE TABLE daily_chaos_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    challenge_type TEXT NOT NULL,
    description TEXT NOT NULL,
    parameters JSONB DEFAULT '{}',
    reward_points INTEGER DEFAULT 100,
    completion_criteria JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(date)
);

CREATE TABLE user_challenge_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    challenge_id UUID REFERENCES daily_chaos_challenges(id) ON DELETE CASCADE,
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    completed_at TIMESTAMP WITH TIME ZONE,
    points_earned INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, challenge_id)
);
```

## 🔍 カスタムクエリ関数

### 1. 隠れた名作発見関数
```sql
CREATE OR REPLACE FUNCTION find_hidden_gems(
    user_id_param UUID,
    quality_threshold FLOAT DEFAULT 0.7,
    max_likes INTEGER DEFAULT 50,
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    post_id UUID,
    hidden_gem_score FLOAT,
    quality_score FLOAT,
    like_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as post_id,
        (p.quality_score / (p.like_count + 1)::FLOAT) as hidden_gem_score,
        p.quality_score,
        p.like_count,
        p.created_at
    FROM posts p
    LEFT JOIN user_interactions ui ON p.id = ui.post_id AND ui.user_id = user_id_param
    WHERE 
        p.like_count < max_likes
        AND p.quality_score > quality_threshold
        AND p.created_at > NOW() - INTERVAL '6 months'
        AND ui.id IS NULL -- ユーザーがまだ見ていない投稿
        AND p.is_active = true
    ORDER BY hidden_gem_score DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;
```

### 2. アンチアルゴリズム検索関数
```sql
CREATE OR REPLACE FUNCTION search_anti_algorithmic(
    user_id_param UUID,
    anti_patterns JSONB,
    limit_count INTEGER DEFAULT 25
)
RETURNS TABLE (
    post_id UUID,
    anti_match_score FLOAT,
    post_data JSONB
) AS $$
DECLARE
    user_preferences JSONB;
    excluded_styles TEXT[];
    excluded_colors TEXT[];
    excluded_themes TEXT[];
BEGIN
    -- ユーザーの最近の好みを分析
    SELECT 
        jsonb_build_object(
            'styles', array_agg(DISTINCT extracted_styles),
            'colors', array_agg(DISTINCT extracted_colors),
            'themes', array_agg(DISTINCT extracted_themes)
        )
    INTO user_preferences
    FROM (
        SELECT 
            jsonb_array_elements_text(p.metadata->'styles') as extracted_styles,
            jsonb_array_elements_text(p.metadata->'colors') as extracted_colors,
            jsonb_array_elements_text(p.metadata->'themes') as extracted_themes
        FROM posts p
        JOIN user_interactions ui ON p.id = ui.post_id
        WHERE ui.user_id = user_id_param
        AND ui.interaction_type IN ('like', 'save', 'view_long')
        AND ui.created_at > NOW() - INTERVAL '30 days'
    ) recent_preferences;

    -- 対極的なコンテンツを検索
    RETURN QUERY
    SELECT 
        p.id as post_id,
        calculate_anti_match_score(p.metadata, user_preferences, anti_patterns) as anti_match_score,
        jsonb_build_object(
            'title', p.title,
            'image_url', p.image_url,
            'metadata', p.metadata,
            'created_at', p.created_at
        ) as post_data
    FROM posts p
    LEFT JOIN user_interactions ui ON p.id = ui.post_id AND ui.user_id = user_id_param
    WHERE 
        ui.id IS NULL -- 未見の投稿
        AND p.is_active = true
        AND p.quality_score > 0.6
    ORDER BY anti_match_score DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- アンチマッチスコア計算関数
CREATE OR REPLACE FUNCTION calculate_anti_match_score(
    post_metadata JSONB,
    user_preferences JSONB,
    anti_patterns JSONB
)
RETURNS FLOAT AS $$
DECLARE
    style_divergence FLOAT := 0;
    color_divergence FLOAT := 0;
    theme_divergence FLOAT := 0;
    total_score FLOAT;
BEGIN
    -- スタイルの乖離度計算
    style_divergence := calculate_style_divergence(
        post_metadata->'styles',
        user_preferences->'styles'
    );
    
    -- 色彩の乖離度計算
    color_divergence := calculate_color_divergence(
        post_metadata->'colors',
        user_preferences->'colors'
    );
    
    -- テーマの乖離度計算
    theme_divergence := calculate_theme_divergence(
        post_metadata->'themes',
        user_preferences->'themes'
    );
    
    -- 重み付き総合スコア
    total_score := (style_divergence * 0.4) + (color_divergence * 0.3) + (theme_divergence * 0.3);
    
    RETURN LEAST(1.0, GREATEST(0.0, total_score));
END;
$$ LANGUAGE plpgsql;
```

### 3. 時系列破壊関数
```sql
CREATE OR REPLACE FUNCTION chaos_temporal_mix(
    user_id_param UUID,
    post_count INTEGER DEFAULT 25
)
RETURNS TABLE (
    post_id UUID,
    chaos_position INTEGER,
    original_timestamp TIMESTAMP WITH TIME ZONE,
    chaos_reason TEXT
) AS $$
DECLARE
    ancient_posts CURSOR FOR 
        SELECT id, created_at FROM posts 
        WHERE created_at < NOW() - INTERVAL '1 month'
        AND id NOT IN (
            SELECT post_id FROM user_interactions 
            WHERE user_id = user_id_param
        )
        ORDER BY RANDOM()
        LIMIT post_count / 3;
        
    recent_posts CURSOR FOR
        SELECT id, created_at FROM posts
        WHERE created_at > NOW() - INTERVAL '1 hour'
        ORDER BY RANDOM()
        LIMIT post_count / 3;
        
    medium_posts CURSOR FOR
        SELECT id, created_at FROM posts
        WHERE created_at BETWEEN NOW() - INTERVAL '1 month' AND NOW() - INTERVAL '1 hour'
        ORDER BY RANDOM()
        LIMIT post_count / 3;
BEGIN
    -- ランダムに古い、新しい、中間の投稿を混在させる
    -- 実装の詳細...
    RETURN;
END;
$$ LANGUAGE plpgsql;
```

## 📊 リアルタイム分析ビュー

### 1. カオス効果分析ビュー
```sql
CREATE VIEW chaos_effectiveness_analysis AS
WITH chaos_sessions AS (
    SELECT 
        ce.user_id,
        ce.session_id,
        AVG(ce.surprise_level) as avg_surprise,
        AVG(ce.learning_outcome) as avg_learning,
        COUNT(*) as chaos_events_count,
        SUM(CASE WHEN (ce.user_reaction->>'satisfaction')::FLOAT > 0.6 THEN 1 ELSE 0 END) as positive_reactions
    FROM chaos_events ce
    WHERE ce.created_at > NOW() - INTERVAL '7 days'
    GROUP BY ce.user_id, ce.session_id
),
regular_sessions AS (
    SELECT 
        ui.user_id,
        DATE_TRUNC('hour', ui.created_at) as session_hour,
        AVG(ui.engagement_score) as avg_engagement,
        COUNT(*) as interactions_count
    FROM user_interactions ui
    WHERE ui.created_at > NOW() - INTERVAL '7 days'
    AND NOT EXISTS (
        SELECT 1 FROM chaos_events ce 
        WHERE ce.user_id = ui.user_id 
        AND ce.session_id = ui.session_id
    )
    GROUP BY ui.user_id, DATE_TRUNC('hour', ui.created_at)
)
SELECT 
    'chaos' as session_type,
    AVG(cs.avg_surprise) as surprise_level,
    AVG(cs.avg_learning) as learning_score,
    AVG(cs.positive_reactions::FLOAT / cs.chaos_events_count) as satisfaction_rate,
    COUNT(*) as session_count
FROM chaos_sessions cs
UNION ALL
SELECT 
    'regular' as session_type,
    0.0 as surprise_level,
    0.0 as learning_score,
    AVG(rs.avg_engagement) as satisfaction_rate,
    COUNT(*) as session_count
FROM regular_sessions rs;
```

### 2. ユーザー適応進度ビュー
```sql
CREATE VIEW user_chaos_adaptation_progress AS
SELECT 
    ucp.user_id,
    ucp.chaos_tolerance,
    ucp.adaptation_level,
    ucp.exploration_score,
    
    -- 週次進歩率
    (ucp.adaptation_level - LAG(ucp.adaptation_level) OVER (
        PARTITION BY ucp.user_id 
        ORDER BY ucp.last_updated
    )) as weekly_adaptation_growth,
    
    -- 最近のカオス受容率
    (
        SELECT AVG(surprise_level) 
        FROM chaos_events ce 
        WHERE ce.user_id = ucp.user_id 
        AND ce.created_at > NOW() - INTERVAL '7 days'
    ) as recent_surprise_acceptance,
    
    -- 学習進歩率
    (
        SELECT AVG(learning_outcome) 
        FROM chaos_events ce 
        WHERE ce.user_id = ucp.user_id 
        AND ce.created_at > NOW() - INTERVAL '7 days'
    ) as recent_learning_rate,
    
    ucp.last_updated
FROM user_chaos_profiles ucp
WHERE ucp.total_sessions > 5; -- 最小セッション数フィルター
```

## 🔧 Supabase Edge Functions

### 1. カオス推薦エンジン
```typescript
// supabase/functions/chaos-recommendation/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface ChaosRequest {
  userId: string
  postCount: number
  chaosLevel: number
  strategies: string[]
}

serve(async (req) => {
  try {
    const { userId, postCount = 25, chaosLevel = 0.6, strategies }: ChaosRequest = await req.json()
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )
    
    // ユーザープロファイル取得
    const { data: userProfile } = await supabase
      .from('user_chaos_profiles')
      .select('*')
      .eq('user_id', userId)
      .single()
    
    // 戦略別投稿数計算
    const strategyDistribution = calculateStrategyDistribution(
      strategies, 
      postCount, 
      chaosLevel,
      userProfile
    )
    
    const recommendations = []
    
    // 各戦略で投稿を取得
    for (const [strategy, count] of Object.entries(strategyDistribution)) {
      const posts = await executeStrategy(strategy, userId, count, supabase)
      recommendations.push(...posts)
    }
    
    // 最終的なカオス配置
    const finalArrangement = applyChaosArrangement(recommendations, chaosLevel)
    
    // 分析データ記録
    await recordChaosEvent(userId, finalArrangement, chaosLevel, supabase)
    
    return new Response(
      JSON.stringify({ recommendations: finalArrangement }),
      { headers: { "Content-Type": "application/json" } }
    )
    
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})

async function executeStrategy(
  strategy: string, 
  userId: string, 
  count: number, 
  supabase: any
) {
  switch (strategy) {
    case 'hidden_gems':
      return await supabase.rpc('find_hidden_gems', {
        user_id_param: userId,
        limit_count: count
      })
      
    case 'temporal_chaos':
      return await supabase.rpc('chaos_temporal_mix', {
        user_id_param: userId,
        post_count: count
      })
      
    case 'anti_algorithmic':
      const antiPatterns = await generateAntiPatterns(userId, supabase)
      return await supabase.rpc('search_anti_algorithmic', {
        user_id_param: userId,
        anti_patterns: antiPatterns,
        limit_count: count
      })
      
    default:
      // ランダム選択
      return await supabase
        .from('posts')
        .select('*')
        .order('random()')
        .limit(count)
  }
}
```

### 2. リアルタイム学習エンジン
```typescript
// supabase/functions/realtime-learning/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

interface LearningEvent {
  userId: string
  postId: string
  interactionType: string
  surpriseLevel: number
  timeSpent: number
  context: any
}

serve(async (req) => {
  const event: LearningEvent = await req.json()
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )
  
  // 学習イベントを記録
  await supabase
    .from('chaos_events')
    .insert({
      user_id: event.userId,
      post_id: event.postId,
      surprise_level: event.surpriseLevel,
      user_reaction: {
        interaction_type: event.interactionType,
        time_spent: event.timeSpent
      },
      context_data: event.context
    })
  
  // ユーザープロファイルの即座更新
  await updateUserProfile(event, supabase)
  
  // 次回推薦の動的調整
  const adjustments = await calculateDynamicAdjustments(event, supabase)
  
  return new Response(
    JSON.stringify({ 
      learning_recorded: true,
      profile_updated: true,
      next_recommendations_adjusted: adjustments
    }),
    { headers: { "Content-Type": "application/json" } }
  )
})

async function updateUserProfile(event: LearningEvent, supabase: any) {
  // リアルタイム適応レベル更新
  const adaptationIncrement = calculateAdaptationIncrement(event)
  
  await supabase.rpc('update_user_adaptation', {
    user_id_param: event.userId,
    surprise_feedback: event.surpriseLevel,
    adaptation_increment: adaptationIncrement
  })
}
```

## 📈 分析とモニタリング

### Grafana Dashboard クエリ
```sql
-- カオス効果の時系列分析
SELECT 
    DATE_TRUNC('hour', created_at) as time,
    chaos_strategy,
    AVG(surprise_level) as avg_surprise,
    AVG((user_reaction->>'satisfaction')::FLOAT) as avg_satisfaction,
    COUNT(*) as event_count
FROM chaos_events
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY time, chaos_strategy
ORDER BY time;

-- ユーザー適応率の追跡
SELECT 
    DATE_TRUNC('day', last_updated) as date,
    AVG(adaptation_level) as avg_adaptation,
    AVG(chaos_tolerance) as avg_tolerance,
    COUNT(*) as active_users
FROM user_chaos_profiles
WHERE last_updated > NOW() - INTERVAL '30 days'
GROUP BY date
ORDER BY date;
```

このSupabase統合設計により、couleurのカオスシステムは堅牢で拡張性のあるデータ基盤の上で動作し、リアルタイムの学習と最適化が可能になります。