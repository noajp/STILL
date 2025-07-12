# 完全Supabaseクエリ集：即実装可能版

## 🗄️ テーブル作成クエリ（実行準備完了）

### 1. メインテーブル群
```sql
-- ===== CHAOS EVENTS TABLE =====
CREATE TABLE IF NOT EXISTS chaos_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    chaos_strategy TEXT NOT NULL CHECK (chaos_strategy IN (
        'random_chaos', 'algorithm_sabotage', 'human_curation',
        'temporal_break', 'popularity_inversion', 'context_destruction'
    )),
    surprise_level FLOAT CHECK (surprise_level >= 0 AND surprise_level <= 1),
    user_reaction JSONB DEFAULT '{}',
    context_data JSONB DEFAULT '{}',
    learning_outcome FLOAT DEFAULT 0,
    session_id UUID,
    chaos_position INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- インデックス作成
    INDEX idx_chaos_events_user_id (user_id),
    INDEX idx_chaos_events_created_at (created_at),
    INDEX idx_chaos_events_strategy (chaos_strategy),
    INDEX idx_chaos_events_session (session_id),
    INDEX idx_chaos_events_surprise (surprise_level)
);

-- ===== USER CHAOS PROFILES TABLE =====
CREATE TABLE IF NOT EXISTS user_chaos_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- 基本カオス設定
    chaos_tolerance FLOAT DEFAULT 0.2 CHECK (chaos_tolerance >= 0 AND chaos_tolerance <= 1),
    preferred_chaos_level FLOAT DEFAULT 0.3 CHECK (preferred_chaos_level >= 0 AND preferred_chaos_level <= 1),
    adaptation_level FLOAT DEFAULT 0.0 CHECK (adaptation_level >= 0 AND adaptation_level <= 1),
    
    -- 学習とパフォーマンス
    total_sessions INTEGER DEFAULT 0,
    successful_adaptations INTEGER DEFAULT 0,
    failed_adaptations INTEGER DEFAULT 0,
    exploration_score FLOAT DEFAULT 0.0,
    diversity_exposure_index FLOAT DEFAULT 0.0,
    average_learning_gain FLOAT DEFAULT 0.0,
    
    -- 戦略別重み（JSONBで保存）
    strategy_preferences JSONB DEFAULT '{
        "random_chaos": 0.25,
        "algorithm_sabotage": 0.20,
        "human_curation": 0.15,
        "temporal_break": 0.15,
        "popularity_inversion": 0.15,
        "context_destruction": 0.10
    }',
    
    -- 認知特性
    cognitive_load_threshold FLOAT DEFAULT 0.8,
    surprise_tolerance FLOAT DEFAULT 0.6,
    learning_style JSONB DEFAULT '{}',
    aesthetic_preferences JSONB DEFAULT '{}',
    
    -- タイムスタンプ
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- インデックス
    INDEX idx_user_chaos_profiles_tolerance (chaos_tolerance),
    INDEX idx_user_chaos_profiles_adaptation (adaptation_level),
    INDEX idx_user_chaos_profiles_updated (last_updated)
);

-- ===== ALGORITHM PREDICTIONS TABLE =====
CREATE TABLE IF NOT EXISTS algorithm_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id UUID,
    
    -- 予測データ
    predicted_posts JSONB NOT NULL,
    prediction_confidence JSONB DEFAULT '{}',
    prediction_method TEXT DEFAULT 'traditional',
    
    -- 実際の結果
    actual_engagement JSONB DEFAULT '{}',
    actual_selections JSONB DEFAULT '{}',
    chaos_intervention BOOLEAN DEFAULT FALSE,
    
    -- 精度メトリクス
    prediction_accuracy FLOAT,
    surprise_factor FLOAT,
    learning_impact FLOAT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    INDEX idx_algorithm_predictions_user (user_id),
    INDEX idx_algorithm_predictions_session (session_id),
    INDEX idx_algorithm_predictions_accuracy (prediction_accuracy)
);

-- ===== DAILY CHAOS CHALLENGES TABLE =====
CREATE TABLE IF NOT EXISTS daily_chaos_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_date DATE NOT NULL UNIQUE,
    
    -- チャレンジ内容
    challenge_type TEXT NOT NULL CHECK (challenge_type IN (
        'exploration_quest', 'style_discovery', 'temporal_journey',
        'hidden_gems', 'surprise_master', 'learning_sprint'
    )),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    parameters JSONB DEFAULT '{}',
    
    -- 報酬
    reward_points INTEGER DEFAULT 100,
    bonus_multiplier FLOAT DEFAULT 1.0,
    special_reward JSONB DEFAULT '{}',
    
    -- 完了条件
    completion_criteria JSONB DEFAULT '{}',
    difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    INDEX idx_daily_challenges_date (challenge_date),
    INDEX idx_daily_challenges_type (challenge_type)
);

-- ===== USER CHALLENGE PROGRESS TABLE =====
CREATE TABLE IF NOT EXISTS user_challenge_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    challenge_id UUID REFERENCES daily_chaos_challenges(id) ON DELETE CASCADE,
    
    -- 進捗
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    current_metrics JSONB DEFAULT '{}',
    milestones_achieved JSONB DEFAULT '[]',
    
    -- 完了情報
    completed_at TIMESTAMP WITH TIME ZONE,
    points_earned INTEGER DEFAULT 0,
    bonus_earned INTEGER DEFAULT 0,
    
    -- タイムスタンプ
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, challenge_id),
    INDEX idx_user_challenge_progress_user (user_id),
    INDEX idx_user_challenge_progress_completed (completed_at)
);

-- ===== CHAOS EXPERIMENTS TABLE =====
CREATE TABLE IF NOT EXISTS chaos_experiments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_name TEXT NOT NULL,
    description TEXT,
    
    -- 実験期間
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    
    -- 実験設定
    parameters JSONB DEFAULT '{}',
    target_metrics JSONB DEFAULT '{}',
    hypothesis TEXT,
    
    -- ステータス
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),
    
    -- 結果
    results JSONB DEFAULT '{}',
    conclusions TEXT,
    
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    INDEX idx_chaos_experiments_status (status),
    INDEX idx_chaos_experiments_dates (start_date, end_date)
);

-- ===== EXPERIMENT PARTICIPANTS TABLE =====
CREATE TABLE IF NOT EXISTS experiment_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_id UUID REFERENCES chaos_experiments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- グループ割り当て
    experiment_group TEXT NOT NULL CHECK (experiment_group IN (
        'control', 'low_chaos', 'medium_chaos', 'high_chaos', 'custom'
    )),
    group_parameters JSONB DEFAULT '{}',
    
    -- 参加情報
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    dropped_out_at TIMESTAMP WITH TIME ZONE,
    completion_status TEXT DEFAULT 'active' CHECK (completion_status IN (
        'active', 'completed', 'dropped_out', 'excluded'
    )),
    
    -- 個人結果
    personal_metrics JSONB DEFAULT '{}',
    feedback JSONB DEFAULT '{}',
    
    UNIQUE(experiment_id, user_id),
    INDEX idx_experiment_participants_group (experiment_group),
    INDEX idx_experiment_participants_status (completion_status)
);
```

## 🔧 カスタム関数群（即実装可能）

### 1. 隠れた名作発見関数
```sql
-- ===== HIDDEN GEMS DISCOVERY =====
CREATE OR REPLACE FUNCTION find_hidden_gems(
    user_id_param UUID,
    quality_threshold FLOAT DEFAULT 0.7,
    max_likes INTEGER DEFAULT 50,
    limit_count INTEGER DEFAULT 10,
    time_range_days INTEGER DEFAULT 180
)
RETURNS TABLE (
    post_id UUID,
    hidden_gem_score FLOAT,
    quality_score FLOAT,
    technical_excellence FLOAT,
    artistic_merit FLOAT,
    like_count INTEGER,
    save_count INTEGER,
    authenticity_score FLOAT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as post_id,
        -- 隠れた名作スコア = (品質 × 技術 × 芸術性) ÷ (人気度 + 1)
        (p.quality_score * p.technical_excellence * p.artistic_merit) / 
        GREATEST((p.like_count + p.save_count + p.share_count)::FLOAT, 1.0) as hidden_gem_score,
        
        p.quality_score,
        p.technical_excellence,
        p.artistic_merit,
        p.like_count,
        p.save_count,
        p.authenticity_score,
        p.created_at
        
    FROM posts p
    LEFT JOIN user_interactions ui ON p.id = ui.post_id AND ui.user_id = user_id_param
    WHERE 
        -- 基本条件
        p.is_active = true
        AND p.quality_score >= quality_threshold
        AND p.like_count <= max_likes
        AND p.technical_excellence > 0.6
        AND p.artistic_merit > 0.5
        AND p.created_at > NOW() - INTERVAL concat(time_range_days, ' days')
        
        -- ユーザーが未体験
        AND ui.id IS NULL
        
        -- バイラル要素を避ける
        AND (p.viral_potential IS NULL OR p.viral_potential < 0.3)
        AND (p.has_viral_elements IS NULL OR p.has_viral_elements = false)
        
        -- 商業的要素を避ける
        AND (p.commercial_intent IS NULL OR p.commercial_intent < 0.2)
        
    ORDER BY hidden_gem_score DESC, p.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 使用例: SELECT * FROM find_hidden_gems('user-uuid', 0.8, 30, 15, 90);
```

### 2. アンチアルゴリズム検索関数
```sql
-- ===== ANTI-ALGORITHMIC SEARCH =====
CREATE OR REPLACE FUNCTION search_anti_algorithmic(
    user_id_param UUID,
    excluded_themes TEXT[] DEFAULT '{}',
    opposite_styles TEXT[] DEFAULT '{}',
    opposite_colors TEXT[] DEFAULT '{}',
    limit_count INTEGER DEFAULT 25
)
RETURNS TABLE (
    post_id UUID,
    anti_match_score FLOAT,
    style_divergence FLOAT,
    color_divergence FLOAT,
    theme_divergence FLOAT,
    temporal_divergence FLOAT,
    post_data JSONB
) AS $$
DECLARE
    user_recent_themes TEXT[];
    user_recent_styles TEXT[];
    user_recent_colors TEXT[];
    user_avg_view_time INTERVAL;
BEGIN
    -- ユーザーの最近の傾向を分析
    SELECT 
        array_agg(DISTINCT theme),
        array_agg(DISTINCT style),
        array_agg(DISTINCT dominant_color)
    INTO 
        user_recent_themes,
        user_recent_styles, 
        user_recent_colors
    FROM (
        SELECT 
            unnest(p.themes) as theme,
            p.style,
            p.dominant_color
        FROM posts p
        JOIN user_interactions ui ON p.id = ui.post_id
        WHERE ui.user_id = user_id_param
        AND ui.created_at > NOW() - INTERVAL '30 days'
        AND ui.interaction_type IN ('like', 'save', 'view_long')
    ) recent_preferences;
    
    -- ユーザーの平均視聴時間を取得
    SELECT AVG(ui.view_duration) 
    INTO user_avg_view_time
    FROM user_interactions ui
    WHERE ui.user_id = user_id_param
    AND ui.view_duration IS NOT NULL
    AND ui.created_at > NOW() - INTERVAL '7 days';
    
    RETURN QUERY
    SELECT 
        p.id as post_id,
        
        -- 総合アンチマッチスコア
        (
            -- テーマの乖離度 (0-1)
            CASE 
                WHEN p.themes && user_recent_themes THEN 0.0
                ELSE 1.0
            END * 0.3 +
            
            -- スタイルの乖離度 (0-1)
            CASE 
                WHEN p.style = ANY(user_recent_styles) THEN 0.0
                WHEN p.style = ANY(opposite_styles) THEN 1.0
                ELSE 0.5
            END * 0.25 +
            
            -- 色彩の乖離度 (0-1)
            CASE 
                WHEN p.dominant_color = ANY(user_recent_colors) THEN 0.0
                WHEN p.dominant_color = ANY(opposite_colors) THEN 1.0
                ELSE 0.5
            END * 0.25 +
            
            -- 時間的乖離度 (0-1)
            GREATEST(0, LEAST(1, 
                EXTRACT(EPOCH FROM (NOW() - p.created_at)) / (86400 * 30)
            )) * 0.2
            
        ) as anti_match_score,
        
        -- 個別乖離度スコア
        CASE WHEN p.themes && user_recent_themes THEN 0.0 ELSE 1.0 END as style_divergence,
        CASE WHEN p.style = ANY(user_recent_styles) THEN 0.0 ELSE 1.0 END as color_divergence,
        CASE WHEN p.dominant_color = ANY(user_recent_colors) THEN 0.0 ELSE 1.0 END as theme_divergence,
        GREATEST(0, LEAST(1, EXTRACT(EPOCH FROM (NOW() - p.created_at)) / (86400 * 30))) as temporal_divergence,
        
        -- 投稿データ
        jsonb_build_object(
            'title', p.title,
            'image_url', p.image_url,
            'creator_id', p.creator_id,
            'themes', p.themes,
            'style', p.style,
            'dominant_color', p.dominant_color,
            'quality_score', p.quality_score,
            'created_at', p.created_at
        ) as post_data
        
    FROM posts p
    LEFT JOIN user_interactions ui ON p.id = ui.post_id AND ui.user_id = user_id_param
    WHERE 
        -- 基本フィルター
        p.is_active = true
        AND p.quality_score >= 0.6
        AND ui.id IS NULL  -- 未見の投稿
        
        -- テーマ除外
        AND (
            excluded_themes = '{}' OR 
            NOT (p.themes && excluded_themes)
        )
        
        -- 最低限の品質保証
        AND (p.technical_excellence IS NULL OR p.technical_excellence >= 0.5)
        
    ORDER BY anti_match_score DESC, RANDOM()
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 使用例: 
-- SELECT * FROM search_anti_algorithmic(
--     'user-uuid', 
--     ARRAY['portrait', 'landscape'], 
--     ARRAY['minimalist', 'modern'], 
--     ARRAY['blue', 'green'], 
--     20
-- );
```

### 3. 時系列混沌生成関数
```sql
-- ===== TEMPORAL CHAOS GENERATION =====
CREATE OR REPLACE FUNCTION generate_temporal_chaos(
    user_id_param UUID,
    post_count INTEGER DEFAULT 25
)
RETURNS TABLE (
    post_id UUID,
    original_rank INTEGER,
    chaos_rank INTEGER,
    temporal_category TEXT,
    chaos_factor FLOAT,
    post_data JSONB
) AS $$
DECLARE
    very_recent_count INTEGER := post_count / 5;
    recent_count INTEGER := post_count / 5;
    medium_count INTEGER := post_count / 5;
    old_count INTEGER := post_count / 5;
    ancient_count INTEGER := post_count - (very_recent_count + recent_count + medium_count + old_count);
BEGIN
    RETURN QUERY
    WITH temporal_categories AS (
        SELECT 
            p.id,
            p.title,
            p.image_url,
            p.creator_id,
            p.quality_score,
            p.like_count,
            p.created_at,
            CASE 
                WHEN p.created_at > NOW() - INTERVAL '2 hours' THEN 'very_recent'
                WHEN p.created_at > NOW() - INTERVAL '1 day' THEN 'recent' 
                WHEN p.created_at > NOW() - INTERVAL '1 week' THEN 'medium'
                WHEN p.created_at > NOW() - INTERVAL '1 month' THEN 'old'
                ELSE 'ancient'
            END as temporal_category,
            ROW_NUMBER() OVER (ORDER BY p.created_at DESC) as original_rank
        FROM posts p
        LEFT JOIN user_interactions ui ON p.id = ui.post_id AND ui.user_id = user_id_param
        WHERE 
            p.is_active = true
            AND p.quality_score >= 0.6
            AND ui.id IS NULL  -- 未見の投稿
    ),
    sampled_posts AS (
        -- 各時間カテゴリーからランダムサンプリング
        (SELECT *, 1 as selection_order FROM temporal_categories WHERE temporal_category = 'very_recent' ORDER BY RANDOM() LIMIT very_recent_count)
        UNION ALL
        (SELECT *, 2 as selection_order FROM temporal_categories WHERE temporal_category = 'recent' ORDER BY RANDOM() LIMIT recent_count)
        UNION ALL  
        (SELECT *, 3 as selection_order FROM temporal_categories WHERE temporal_category = 'medium' ORDER BY RANDOM() LIMIT medium_count)
        UNION ALL
        (SELECT *, 4 as selection_order FROM temporal_categories WHERE temporal_category = 'old' ORDER BY RANDOM() LIMIT old_count)
        UNION ALL
        (SELECT *, 5 as selection_order FROM temporal_categories WHERE temporal_category = 'ancient' ORDER BY RANDOM() LIMIT ancient_count)
    ),
    chaos_arranged AS (
        SELECT 
            *,
            -- フラクタル的なカオス配置
            ROW_NUMBER() OVER (ORDER BY 
                SIN(EXTRACT(EPOCH FROM created_at) * 0.001) + 
                COS(selection_order * 1.618) +
                RANDOM()
            ) as chaos_rank,
            
            -- カオス度計算
            GREATEST(0, LEAST(1,
                ABS(EXTRACT(EPOCH FROM (created_at - NOW())) / (86400 * 30)) +
                (RANDOM() * 0.3)
            )) as chaos_factor
        FROM sampled_posts
    )
    SELECT 
        ca.id as post_id,
        ca.original_rank::INTEGER,
        ca.chaos_rank::INTEGER,
        ca.temporal_category,
        ca.chaos_factor,
        jsonb_build_object(
            'title', ca.title,
            'image_url', ca.image_url, 
            'creator_id', ca.creator_id,
            'quality_score', ca.quality_score,
            'like_count', ca.like_count,
            'created_at', ca.created_at,
            'temporal_category', ca.temporal_category,
            'chaos_disruption', CASE 
                WHEN ABS(ca.chaos_rank - ca.original_rank) > post_count / 3 THEN 'high'
                WHEN ABS(ca.chaos_rank - ca.original_rank) > post_count / 6 THEN 'medium'
                ELSE 'low'
            END
        ) as post_data
    FROM chaos_arranged ca
    ORDER BY ca.chaos_rank;
END;
$$ LANGUAGE plpgsql;

-- 使用例: SELECT * FROM generate_temporal_chaos('user-uuid', 30);
```

### 4. 人間的キュレーション関数
```sql
-- ===== HUMAN-LIKE CURATION =====
CREATE OR REPLACE FUNCTION human_curated_selection(
    user_id_param UUID DEFAULT NULL,
    count INTEGER DEFAULT 20,
    mood_factor FLOAT DEFAULT NULL,
    weather_context TEXT DEFAULT NULL,
    time_context TEXT DEFAULT NULL
)
RETURNS TABLE (
    post_id UUID,
    human_appeal_score FLOAT,
    aesthetic_resonance FLOAT,
    emotional_appeal FLOAT,
    narrative_strength FLOAT,
    serendipity_factor FLOAT,
    selection_reason TEXT,
    post_data JSONB
) AS $$
DECLARE
    current_hour INTEGER := EXTRACT(HOUR FROM NOW());
    current_season TEXT;
    global_mood_factor FLOAT;
    intuitive_weight FLOAT;
BEGIN
    -- 季節を決定
    current_season := CASE 
        WHEN EXTRACT(MONTH FROM NOW()) IN (12, 1, 2) THEN 'winter'
        WHEN EXTRACT(MONTH FROM NOW()) IN (3, 4, 5) THEN 'spring'
        WHEN EXTRACT(MONTH FROM NOW()) IN (6, 7, 8) THEN 'summer'
        ELSE 'autumn'
    END;
    
    -- グローバル気分要素（時間、季節、天候から推定）
    global_mood_factor := COALESCE(mood_factor, 
        (SIN(current_hour * PI() / 12) + 1) / 2 * 0.3 +  -- 時間による気分変化
        CASE current_season
            WHEN 'spring' THEN 0.8
            WHEN 'summer' THEN 0.9  
            WHEN 'autumn' THEN 0.6
            WHEN 'winter' THEN 0.4
        END * 0.7
    );
    
    -- 直感的重み（日や時間によって変化）
    intuitive_weight := (RANDOM() + 0.5) * global_mood_factor;
    
    RETURN QUERY
    SELECT 
        p.id as post_id,
        
        -- 人間的魅力度スコア
        (
            -- 美学的共鳴 (30%)
            COALESCE(p.aesthetic_complexity, 0.5) * 
            (0.7 + SIN(EXTRACT(DOY FROM NOW()) * 0.017) * 0.3) * 0.30 +
            
            -- 感情的アピール (25%)
            COALESCE(p.emotional_resonance, 0.5) * global_mood_factor * 0.25 +
            
            -- 物語性 (20%)
            COALESCE(p.storytelling_score, 0.5) * 
            CASE 
                WHEN current_hour BETWEEN 19 AND 23 THEN 1.2  -- 夜は物語性を重視
                WHEN current_hour BETWEEN 6 AND 10 THEN 0.8   -- 朝は軽めを好む
                ELSE 1.0
            END * 0.20 +
            
            -- アンチアルゴリズム要素 (15%)
            (1.0 - COALESCE(p.algorithmic_appeal, 0.5)) * 0.15 +
            
            -- 直感的要素 (10%) - 説明困難な人間的判断
            intuitive_weight * 
            (COALESCE(p.uniqueness_score, 0.5) + RANDOM() * 0.3) * 0.10
            
        ) as human_appeal_score,
        
        -- 個別スコア
        COALESCE(p.aesthetic_complexity, 0.5) as aesthetic_resonance,
        COALESCE(p.emotional_resonance, 0.5) * global_mood_factor as emotional_appeal,
        COALESCE(p.storytelling_score, 0.5) as narrative_strength,
        intuitive_weight * COALESCE(p.uniqueness_score, 0.5) as serendipity_factor,
        
        -- 選択理由
        CASE 
            WHEN COALESCE(p.aesthetic_complexity, 0) > 0.8 THEN 'aesthetic_excellence'
            WHEN COALESCE(p.emotional_resonance, 0) > 0.7 THEN 'emotional_connection'
            WHEN COALESCE(p.storytelling_score, 0) > 0.7 THEN 'narrative_appeal'
            WHEN COALESCE(p.uniqueness_score, 0) > 0.8 THEN 'uniqueness'
            ELSE 'intuitive_choice'
        END as selection_reason,
        
        -- 投稿データ
        jsonb_build_object(
            'title', p.title,
            'image_url', p.image_url,
            'creator_id', p.creator_id,
            'created_at', p.created_at,
            'quality_score', p.quality_score,
            'human_curated_at', NOW(),
            'curation_context', jsonb_build_object(
                'season', current_season,
                'hour', current_hour,
                'global_mood', global_mood_factor,
                'intuitive_weight', intuitive_weight
            )
        ) as post_data
        
    FROM posts p
    LEFT JOIN user_interactions ui ON p.id = ui.post_id AND ui.user_id = user_id_param
    WHERE 
        p.is_active = true
        AND p.quality_score >= 0.6
        AND (user_id_param IS NULL OR ui.id IS NULL)  -- 未見またはユーザー指定なし
        
        -- 「人間らしい」選択バイアス
        AND (
            p.created_at BETWEEN 
                NOW() - INTERVAL concat((RANDOM() * 168 + 1)::INTEGER, ' hours') AND  -- 1-168時間前
                NOW() - INTERVAL concat((RANDOM() * 24)::INTEGER, ' hours')            -- 0-24時間前
        )
        
        -- 商業的でない
        AND (p.commercial_intent IS NULL OR p.commercial_intent < 0.3)
        
    ORDER BY human_appeal_score DESC, RANDOM()
    LIMIT count;
END;
$$ LANGUAGE plpgsql;

-- 使用例:
-- SELECT * FROM human_curated_selection('user-uuid', 25, 0.7, 'rainy', 'evening');
```

### 5. カオスメトリクス分析関数
```sql
-- ===== CHAOS EFFECTIVENESS ANALYSIS =====
CREATE OR REPLACE FUNCTION analyze_chaos_effectiveness(
    user_id_param UUID DEFAULT NULL,
    days_back INTEGER DEFAULT 7,
    strategy_filter TEXT DEFAULT NULL
)
RETURNS TABLE (
    analysis_type TEXT,
    strategy TEXT,
    total_events INTEGER,
    avg_surprise_level FLOAT,
    avg_learning_outcome FLOAT,
    satisfaction_rate FLOAT,
    exploration_improvement FLOAT,
    adaptation_progress FLOAT,
    recommendation TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH chaos_metrics AS (
        SELECT 
            ce.chaos_strategy,
            COUNT(*) as event_count,
            AVG(ce.surprise_level) as avg_surprise,
            AVG(ce.learning_outcome) as avg_learning,
            AVG((ce.user_reaction->>'satisfaction')::FLOAT) as avg_satisfaction,
            AVG((ce.user_reaction->>'time_spent')::FLOAT) as avg_time_spent,
            COUNT(CASE WHEN (ce.user_reaction->>'positive_reaction')::BOOLEAN THEN 1 END)::FLOAT / COUNT(*) as positive_rate
        FROM chaos_events ce
        WHERE 
            (user_id_param IS NULL OR ce.user_id = user_id_param)
            AND ce.created_at > NOW() - INTERVAL concat(days_back, ' days')
            AND (strategy_filter IS NULL OR ce.chaos_strategy = strategy_filter)
        GROUP BY ce.chaos_strategy
    ),
    user_progress AS (
        SELECT 
            ucp.adaptation_level,
            ucp.exploration_score,
            LAG(ucp.adaptation_level) OVER (ORDER BY ucp.last_updated) as prev_adaptation,
            LAG(ucp.exploration_score) OVER (ORDER BY ucp.last_updated) as prev_exploration
        FROM user_chaos_profiles ucp
        WHERE user_id_param IS NULL OR ucp.user_id = user_id_param
        ORDER BY ucp.last_updated DESC
        LIMIT 1
    )
    SELECT 
        'strategy_performance'::TEXT as analysis_type,
        cm.chaos_strategy as strategy,
        cm.event_count as total_events,
        cm.avg_surprise,
        cm.avg_learning,
        cm.avg_satisfaction as satisfaction_rate,
        COALESCE(up.exploration_score - up.prev_exploration, 0) as exploration_improvement,
        COALESCE(up.adaptation_level - up.prev_adaptation, 0) as adaptation_progress,
        
        -- 戦略別推奨事項
        CASE 
            WHEN cm.avg_satisfaction < 0.4 THEN 'Reduce intensity - user overwhelmed'
            WHEN cm.avg_surprise < 0.3 THEN 'Increase chaos level - too predictable'
            WHEN cm.avg_learning < 0.2 THEN 'Add learning support - low educational value'
            WHEN cm.positive_rate > 0.8 AND cm.avg_surprise > 0.6 THEN 'Optimal performance - maintain current approach'
            ELSE 'Monitor and adjust based on user feedback'
        END as recommendation
        
    FROM chaos_metrics cm
    CROSS JOIN user_progress up
    
    UNION ALL
    
    -- 全体サマリー
    SELECT 
        'overall_summary'::TEXT,
        'all_strategies'::TEXT,
        SUM(cm.event_count)::INTEGER,
        AVG(cm.avg_surprise),
        AVG(cm.avg_learning), 
        AVG(cm.avg_satisfaction),
        MAX(COALESCE(up.exploration_score - up.prev_exploration, 0)),
        MAX(COALESCE(up.adaptation_level - up.prev_adaptation, 0)),
        CASE 
            WHEN AVG(cm.avg_satisfaction) > 0.7 THEN 'System performing well'
            WHEN AVG(cm.avg_surprise) < 0.4 THEN 'Increase overall chaos level'
            ELSE 'Continue monitoring and fine-tuning'
        END
    FROM chaos_metrics cm
    CROSS JOIN user_progress up;
END;
$$ LANGUAGE plpgsql;

-- 使用例:
-- SELECT * FROM analyze_chaos_effectiveness('user-uuid', 14, 'random_chaos');
-- SELECT * FROM analyze_chaos_effectiveness(NULL, 30, NULL); -- 全ユーザー分析
```

## 📊 ビュー定義（リアルタイム分析用）

```sql
-- ===== REAL-TIME CHAOS DASHBOARD VIEW =====
CREATE OR REPLACE VIEW chaos_dashboard AS
WITH recent_activity AS (
    SELECT 
        DATE_TRUNC('hour', created_at) as activity_hour,
        chaos_strategy,
        COUNT(*) as events_count,
        AVG(surprise_level) as avg_surprise,
        AVG(learning_outcome) as avg_learning,
        AVG((user_reaction->>'satisfaction')::FLOAT) as avg_satisfaction
    FROM chaos_events
    WHERE created_at > NOW() - INTERVAL '24 hours'
    GROUP BY activity_hour, chaos_strategy
),
user_adaptation_trends AS (
    SELECT 
        COUNT(*) as total_users,
        AVG(adaptation_level) as avg_adaptation,
        AVG(chaos_tolerance) as avg_tolerance,
        COUNT(CASE WHEN adaptation_level > 0.7 THEN 1 END) as advanced_users,
        COUNT(CASE WHEN adaptation_level < 0.3 THEN 1 END) as novice_users
    FROM user_chaos_profiles
    WHERE last_updated > NOW() - INTERVAL '7 days'
)
SELECT 
    'realtime_metrics' as metric_type,
    ra.activity_hour,
    ra.chaos_strategy,
    ra.events_count,
    ra.avg_surprise,
    ra.avg_learning,
    ra.avg_satisfaction,
    uat.total_users,
    uat.avg_adaptation,
    uat.avg_tolerance,
    uat.advanced_users,
    uat.novice_users
FROM recent_activity ra
CROSS JOIN user_adaptation_trends uat
ORDER BY ra.activity_hour DESC, ra.chaos_strategy;

-- ===== USER CHAOS EVOLUTION VIEW =====
CREATE OR REPLACE VIEW user_chaos_evolution AS
SELECT 
    ucp.user_id,
    ucp.adaptation_level,
    ucp.chaos_tolerance,
    ucp.total_sessions,
    ucp.successful_adaptations,
    
    -- 進歩率計算
    CASE 
        WHEN ucp.total_sessions > 0 
        THEN ucp.successful_adaptations::FLOAT / ucp.total_sessions 
        ELSE 0 
    END as success_rate,
    
    -- 最近の活動
    (
        SELECT COUNT(*) 
        FROM chaos_events ce 
        WHERE ce.user_id = ucp.user_id 
        AND ce.created_at > NOW() - INTERVAL '7 days'
    ) as recent_chaos_events,
    
    -- 平均驚きレベル
    (
        SELECT AVG(surprise_level) 
        FROM chaos_events ce 
        WHERE ce.user_id = ucp.user_id 
        AND ce.created_at > NOW() - INTERVAL '7 days'
    ) as recent_avg_surprise,
    
    -- 成長段階分類
    CASE 
        WHEN ucp.adaptation_level < 0.2 THEN 'chaos_novice'
        WHEN ucp.adaptation_level < 0.5 THEN 'adapting_user'
        WHEN ucp.adaptation_level < 0.8 THEN 'chaos_veteran'
        ELSE 'chaos_master'
    END as user_segment,
    
    ucp.last_updated
FROM user_chaos_profiles ucp
WHERE ucp.total_sessions > 0;

-- ===== STRATEGY EFFECTIVENESS VIEW =====
CREATE OR REPLACE VIEW strategy_effectiveness AS
SELECT 
    chaos_strategy,
    COUNT(*) as total_uses,
    AVG(surprise_level) as avg_surprise_generated,
    AVG(learning_outcome) as avg_learning_impact,
    
    -- 満足度分布
    COUNT(CASE WHEN (user_reaction->>'satisfaction')::FLOAT > 0.7 THEN 1 END)::FLOAT / COUNT(*) as high_satisfaction_rate,
    COUNT(CASE WHEN (user_reaction->>'satisfaction')::FLOAT < 0.3 THEN 1 END)::FLOAT / COUNT(*) as low_satisfaction_rate,
    
    -- 学習効果分布
    COUNT(CASE WHEN learning_outcome > 0.6 THEN 1 END)::FLOAT / COUNT(*) as high_learning_rate,
    COUNT(CASE WHEN learning_outcome < 0.2 THEN 1 END)::FLOAT / COUNT(*) as low_learning_rate,
    
    -- 推奨度計算
    CASE 
        WHEN AVG((user_reaction->>'satisfaction')::FLOAT) > 0.7 AND AVG(learning_outcome) > 0.5 THEN 'highly_effective'
        WHEN AVG((user_reaction->>'satisfaction')::FLOAT) > 0.5 AND AVG(learning_outcome) > 0.3 THEN 'moderately_effective'
        WHEN AVG((user_reaction->>'satisfaction')::FLOAT) < 0.4 OR AVG(learning_outcome) < 0.2 THEN 'needs_improvement'
        ELSE 'under_evaluation'
    END as effectiveness_rating,
    
    MAX(created_at) as last_used
FROM chaos_events
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY chaos_strategy
ORDER BY avg_learning_impact DESC, avg_surprise_generated DESC;
```

これらのクエリはすべて即座に実装可能で、couleurのカオスシステムの完全な動作に必要なデータ操作を提供します。