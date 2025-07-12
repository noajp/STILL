# Cost-Optimized Infrastructure Strategy - Couleur App

**戦略**: Supabaseフル活用 + AWS最小補完  
**目標**: 月額コスト $3,000-8,000 (100万DAU想定)  
**最終更新**: 2025-06-16

---

## 🎯 コスト最適化の基本方針

### 1. Supabase機能の最大活用
```yaml
✅ 既存機能で対応可能:
- Database (PostgreSQL + RLS)
- Authentication & Authorization  
- Real-time subscriptions
- File Storage (画像・動画)
- Edge Functions (サーバーレス)
- Auto-generated APIs
- Connection pooling
- Automatic backups

❌ AWS移行不要:
- Application Load Balancer
- RDS/Aurora
- Lambda Functions  
- API Gateway
- ElastiCache
- ECS/EKS
```

### 2. AWS補完は「絶対必要」のみ
```yaml
🔥 必須 (セキュリティ・法的要件):
- CloudFront (CDN) - 画像配信必須
- Route 53 (DNS) - カスタムドメイン
- Certificate Manager (SSL) - 無料SSL

⚠️ 最小限 (コスト重視):
- CloudWatch (基本監視のみ)
- S3 (バックアップのみ)

❌ 不要 (Supabaseで代替):
- WAF (Supabase Edge Functionsで実装)
- Shield Advanced (基本保護で十分)
- Rekognition (Apple Vision Frameworkで代替)
```

---

## 💰 超コスト最適化プラン

### Supabase料金最適化

#### Pro Plan活用戦略
```yaml
Base Plan: $25/月
- Database: 8GB included
- Auth: 100,000 MAU included  
- Storage: 100GB included
- Edge Functions: 500,000 invocations included

スケール時の追加料金:
- Database: $0.0173/GB/hour (約$12.5/GB/月)
- Auth: $0.00325/MAU (100,000超過分)
- Storage: $0.021/GB/月
- Bandwidth: $0.09/GB
```

#### 100万DAU想定コスト
```yaml
Database (50GB): $25 + (42GB × $12.5) = $550/月
Auth (1M MAU): $25 + (900K × $0.00325) = $2,950/月
Storage (10TB): $25 + (9.9TB × $21.5) = $213,350/月 ❌

# Storage最適化が重要！
Storage最適化後 (1TB): $25 + (900GB × $0.021) = $44/月 ✅
Bandwidth (5TB): 5,000GB × $0.09 = $450/月

合計: $3,994/月 (Storage最適化後)
```

### AWS最小補完コスト
```yaml
CloudFront:
- 1TB転送: $85/月
- 10M requests: $7.5/月

Route 53:
- Hosted Zone: $0.50/月
- Queries (100M): $40/月

Certificate Manager: $0/月 (無料)

S3 (バックアップのみ):
- 100GB: $2.3/月
- Glacier (1TB): $4/月

CloudWatch (基本):
- Logs (10GB): $5/月
- Metrics: $1/月

合計: $145/月
```

### **総コスト: $4,139/月 (年間 $49,668)**

---

## 🛠️ Supabase最大活用戦略

### 1. Storage料金激減テクニック

#### 画像最適化戦略
```typescript
// Edge Function: 画像最適化
export default async function optimizeImage(request: Request) {
  const url = new URL(request.url)
  const imageUrl = url.searchParams.get('url')
  const width = url.searchParams.get('w') || '800'
  const quality = url.searchParams.get('q') || '80'
  
  // Supabase Storage URLs transform
  const optimizedUrl = `${imageUrl}?width=${width}&quality=${quality}&format=webp`
  
  return new Response(null, {
    status: 302,
    headers: { 'Location': optimizedUrl }
  })
}
```

#### 自動削除・アーカイブ
```sql
-- 古い画像の自動削除 (30日後)
CREATE OR REPLACE FUNCTION cleanup_old_images()
RETURNS void AS $$
BEGIN
  DELETE FROM storage.objects 
  WHERE bucket_id = 'photos' 
    AND created_at < NOW() - INTERVAL '30 days'
    AND metadata->>'permanent' IS NULL;
END;
$$ LANGUAGE plpgsql;

-- 毎日実行
SELECT cron.schedule('cleanup-images', '0 2 * * *', 'SELECT cleanup_old_images();');
```

### 2. Edge Functions活用でAWS Lambda代替

#### コンテンツモデレーション
```typescript
// Edge Function: Apple Vision代替
import { createClient } from '@supabase/supabase-js'

export default async function moderateContent(request: Request) {
  const { imageUrl, userId } = await request.json()
  
  // Apple Vision Framework結果をキャッシュ
  const moderationResult = await checkCache(imageUrl)
  
  if (!moderationResult) {
    // クライアント側Apple Vision結果を受信・検証
    const result = await validateClientModeration(imageUrl, userId)
    await cacheResult(imageUrl, result)
    return new Response(JSON.stringify(result))
  }
  
  return new Response(JSON.stringify(moderationResult))
}
```

#### リアルタイムゲーム管理
```typescript
// Edge Function: AR宝探しロジック
export default async function treasureHuntLogic(request: Request) {
  const { userId, location, action } = await request.json()
  
  switch (action) {
    case 'find_nearby':
      return await findNearbyTreasures(location)
    case 'claim_treasure':
      return await claimTreasure(userId, treasureId)
    case 'update_score':
      return await updateUserScore(userId, points)
  }
}
```

### 3. Database最適化でコスト削減

#### パーティショニング戦略
```sql
-- 月別パーティション (古いデータ自動削除)
CREATE TABLE posts_2024_01 PARTITION OF posts
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- 自動パーティション作成
CREATE OR REPLACE FUNCTION create_monthly_partitions()
RETURNS void AS $$
DECLARE
  start_date date;
  end_date date;
  table_name text;
BEGIN
  start_date := date_trunc('month', CURRENT_DATE);
  end_date := start_date + interval '1 month';
  table_name := 'posts_' || to_char(start_date, 'YYYY_MM');
  
  EXECUTE format('CREATE TABLE %I PARTITION OF posts FOR VALUES FROM (%L) TO (%L)',
    table_name, start_date, end_date);
END;
$$ LANGUAGE plpgsql;
```

#### インデックス最適化
```sql
-- 効率的な複合インデックス
CREATE INDEX CONCURRENTLY idx_posts_user_created 
ON posts (user_id, created_at DESC) 
WHERE deleted_at IS NULL;

-- 部分インデックス (アクティブユーザーのみ)
CREATE INDEX CONCURRENTLY idx_active_users
ON profiles (id) 
WHERE last_seen_at > NOW() - INTERVAL '30 days';
```

---

## 🔒 セキュリティをSupabaseで実装

### 1. Edge Functions WAF代替
```typescript
// Edge Function: 基本WAF機能
export default async function wafProtection(request: Request) {
  const clientIP = request.headers.get('x-forwarded-for')
  const userAgent = request.headers.get('user-agent')
  
  // Rate limiting check
  const rateLimit = await checkRateLimit(clientIP)
  if (rateLimit.exceeded) {
    return new Response('Rate limit exceeded', { status: 429 })
  }
  
  // Basic bot detection
  if (isSuspiciousUserAgent(userAgent)) {
    return new Response('Blocked', { status: 403 })
  }
  
  // Geographic restriction (if needed)
  const country = request.headers.get('cf-ipcountry')
  if (isBlockedCountry(country)) {
    return new Response('Geographic restriction', { status: 403 })
  }
  
  return new Response('OK')
}
```

### 2. Database-level Security
```sql
-- IP-based access control
CREATE OR REPLACE FUNCTION check_ip_access()
RETURNS boolean AS $$
BEGIN
  -- Allow only from app servers and CDN
  RETURN inet_client_addr() << ANY(ARRAY[
    '::1/128'::inet,  -- localhost
    '10.0.0.0/8'::inet,  -- private networks
    -- CloudFront IP ranges
    '13.32.0.0/15'::inet,
    '13.35.0.0/16'::inet
  ]);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply to sensitive operations
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY ip_access_policy ON profiles
FOR ALL TO authenticated
USING (check_ip_access());
```

---

## 📊 段階的コスト削減プラン

### Phase 1: 即座実装 (コスト: $145/月)
```yaml
必須最小構成:
✅ CloudFront (CDN) - $92.5/月
✅ Route 53 (DNS) - $40.5/月  
✅ S3 Backup (100GB) - $2.3/月
✅ CloudWatch基本 - $6/月
✅ Certificate Manager - $0/月

削減効果: AWS Shield/WAF不要で $3,500/月削減
```

### Phase 2: Supabase最適化 (1-2ヶ月後)
```yaml
Storage最適化:
- 画像圧縮・WebP変換: 70%削減
- 自動削除ポリシー: 50%削減  
- キャッシュ戦略: 30%削減

削減効果: Storage $200,000/月 → $50/月
```

### Phase 3: Edge Functions活用 (2-3ヶ月後)
```yaml
AWS Lambda代替:
- WAF機能: Edge Functions
- 画像処理: Edge Functions + Supabase Transform
- コンテンツモデレーション: クライアント側AI

削減効果: Lambda/API Gateway $2,000/月削減
```

---

## 🌍 グローバル展開のコスト最適化

### CDN最適化戦略
```yaml
CloudFront設定:
- Origin: Supabase Storage直接
- Cache TTL: 86400秒 (24時間)
- Compress: 有効 (30%削減)
- HTTP/2: 有効

Price Class: US/Europe/Asia のみ (南米/アフリカ除外)
削減効果: 40%転送料金削減
```

### 地域別Supabase活用
```yaml
Primary: Supabase Asia (東京)
- 日本・韓国・台湾ユーザー

Secondary: Supabase US East (バージニア)  
- 北米ユーザー

Tertiary: Supabase EU West (アイルランド)
- ヨーロッパユーザー

Read Replicas: Edge Functions経由で最適ルーティング
```

---

## 📈 スケール時のコスト管理

### 自動スケーリング戦略
```typescript
// Edge Function: 動的品質調整
export default async function adaptiveQuality(request: Request) {
  const usage = await getCurrentUsage()
  
  if (usage.bandwidth > THRESHOLD_HIGH) {
    // 緊急時: 品質下げて帯域削減
    return { quality: 60, format: 'webp' }
  } else if (usage.bandwidth < THRESHOLD_LOW) {
    // 余裕時: 品質上げてUX向上
    return { quality: 85, format: 'avif' }
  }
  
  return { quality: 75, format: 'webp' }
}
```

### コスト監視・アラート
```sql
-- Supabase使用量監視
CREATE OR REPLACE FUNCTION check_usage_alerts()
RETURNS void AS $$
BEGIN
  -- Storage警告 (80%使用時)
  IF (SELECT count(*) FROM storage.objects) > 800000 THEN
    PERFORM notify_slack('Storage usage > 80%');
  END IF;
  
  -- Auth使用量警告
  IF (SELECT count(DISTINCT user_id) FROM auth.audit_log_entries 
      WHERE created_at > NOW() - INTERVAL '1 month') > 80000 THEN
    PERFORM notify_slack('Auth MAU > 80%');
  END IF;
END;
$$ LANGUAGE plpgsql;
```

---

## 🎯 最終コスト目標

### 目標別コスト試算

#### 小規模 (10万DAU)
```yaml
Supabase:
- Database: $50/月
- Auth: $350/月  
- Storage: $25/月
- Bandwidth: $45/月

AWS補完: $145/月

合計: $615/月 (年間 $7,380)
```

#### 中規模 (100万DAU)
```yaml
Supabase:
- Database: $550/月
- Auth: $2,950/月
- Storage: $44/月 (最適化後)
- Bandwidth: $450/月

AWS補完: $145/月

合計: $4,139/月 (年間 $49,668)
```

#### 大規模 (500万DAU)
```yaml
Supabase:
- Database: $2,000/月
- Auth: $14,750/月
- Storage: $150/月
- Bandwidth: $2,250/月

AWS補完: $500/月 (CDN増強)

合計: $19,650/月 (年間 $235,800)
```

---

## ✅ 実装優先順位

### 週1: 必須インフラ
- [ ] CloudFront設定
- [ ] Route 53設定  
- [ ] SSL証明書設定

### 週2-3: Supabase最適化
- [ ] Storage自動最適化
- [ ] Database パーティショニング
- [ ] Edge Functions WAF

### 週4: 監視・アラート
- [ ] コスト監視設定
- [ ] パフォーマンス監視
- [ ] 自動スケーリング

### 月2以降: 継続最適化
- [ ] 使用量ベース調整
- [ ] キャッシュ戦略改善
- [ ] 新機能コスト評価

---

## 🏆 期待される効果

**従来のフルAWS構成と比較:**
- 初期構築コスト: $200,000 → $5,000 (96%削減)
- 月額運用コスト: $36,000 → $4,139 (88%削減)  
- 構築期間: 6ヶ月 → 1ヶ月 (83%短縮)
- 運用負荷: 高 → 低 (マネージドサービス活用)

**ROI**: 第1年で $350,000以上のコスト削減