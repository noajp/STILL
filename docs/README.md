# Couleur Project Documentation

Couleurプロジェクトのドキュメント管理システムへようこそ。

## 📁 ドキュメント構成

```
docs/
├── README.md                    # このファイル
├── meetings/                    # 議事録
├── requirements/               # 要件定義
├── decisions/                  # 技術的意思決定記録（ADR）
├── security/                   # セキュリティ関連
├── legal/                     # 法的要件
└── architecture/              # システム設計
```

## 📋 議事録管理（meetings/）

### ファイル命名規則
- `MEETING_MINUTES_YYYYMMDD.md`
- 例: `MEETING_MINUTES_20250616.md`

### 議事録テンプレート
新しい議事録は `meetings/template.md` をコピーして作成してください。

## 📖 要件定義（requirements/）

- `security-requirements.md` - セキュリティ要件
- `legal-requirements.md` - 法的要件  
- `technical-specifications.md` - 技術仕様
- `functional-requirements.md` - 機能要件

## 🏗️ Architecture Decision Records（decisions/）

重要な技術的決定事項を記録します。

### ADR命名規則
- `ADR-XXX-title.md`
- 例: `ADR-001-content-moderation-approach.md`

## 🔒 セキュリティドキュメント（security/）

- セキュリティ監査結果
- 脆弱性対応記録
- セキュリティポリシー

## ⚖️ 法的ドキュメント（legal/）

- プライバシーポリシー
- 利用規約
- コンプライアンス確認書

## 🏛️ システム設計（architecture/）

- システム全体図
- API設計書
- データベース設計書

---

## 📝 ドキュメント作成ガイドライン

### 1. 全てのドキュメントはMarkdown形式
### 2. 英語・日本語併記（国際展開対応）
### 3. 定期的な更新（最低月1回）
### 4. 重要な決定事項は必ずADRとして記録

## 🔄 更新履歴

| 日付 | 更新者 | 概要 |
|------|--------|------|
| 2025-06-16 | Claude | ドキュメント管理体制初期構築 |

---

## 🤝 貢献方法

1. 新しいドキュメントを作成する場合は、適切なフォルダに配置
2. 既存ドキュメントを更新する場合は、更新履歴を記載
3. 重要な技術的決定はADRとして記録
4. 月次でドキュメントレビューを実施