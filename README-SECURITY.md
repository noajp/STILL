# セキュリティ設定ガイド

## 🚨 重要：機密情報の管理

このプロジェクトでは、API キーや機密情報を安全に管理するため、以下の方法を使用しています。

## 設定方法

### 1. 開発環境での設定

`Development.xcconfig`ファイルを作成し、実際のキーを設定：

```
SUPABASE_URL = https://yccjlkcxqybxqewzchen.supabase.co
SUPABASE_ANON_KEY = your_actual_supabase_anon_key_here
```

### 2. Xcodeプロジェクト設定

1. Xcodeでプロジェクトを開く
2. プロジェクト設定 → Target → Build Settings
3. "Based on Configuration File" で `Development.xcconfig` を選択

### 3. 本番環境での設定

アプリ初回起動時に `SecureConfig.shared.setSupabaseConfig()` を呼び出してKeyChainに保存

## ⚠️ 注意事項

- **絶対に機密情報をGitにコミットしない**
- `Development.xcconfig` は `.gitignore` に含まれています
- 本番環境では環境変数またはKeyChainを使用
- API リークが疑われる場合は即座にキーをローテート

## キーの取得方法

1. [Supabase Dashboard](https://supabase.com/dashboard/project/yccjlkcxqybxqewzchen/settings/api) にアクセス
2. "Project API keys" セクションから `anon` キーをコピー
3. `Development.xcconfig` の `YOUR_ACTUAL_ANON_KEY_HERE` を置き換え

## トラブルシューティング

### エラー: "SUPABASE_ANON_KEY not configured"

1. `Development.xcconfig` ファイルが存在するか確認
2. Xcode プロジェクト設定で xcconfig ファイルが適用されているか確認
3. 実際のキーが正しく設定されているか確認

### Git 履歴のクリーンアップ

機密情報が誤ってコミットされた場合：

```bash
# 特定ファイルを履歴から削除
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch still.xcodeproj/project.pbxproj' --prune-empty --tag-name-filter cat -- --all

# 強制プッシュ（注意：チーム開発の場合は要相談）
git push --force-with-lease origin main
```