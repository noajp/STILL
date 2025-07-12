#!/bin/bash

# TETE開発 日記自動化スクリプト
# 毎日23:55に実行され、新しい日記エントリを作成

DIARY_FILE="/Users/nakanotakanori/Dev/TETE/work_diary.md"
TODAY=$(date +"%Y年%m月%d日")
WEEKDAY=$(date +"%a" | tr '[:upper:]' '[:lower:]')

# 曜日を日本語に変換
case $WEEKDAY in
    "mon") WEEKDAY_JP="月" ;;
    "tue") WEEKDAY_JP="火" ;;
    "wed") WEEKDAY_JP="水" ;;
    "thu") WEEKDAY_JP="木" ;;
    "fri") WEEKDAY_JP="金" ;;
    "sat") WEEKDAY_JP="土" ;;
    "sun") WEEKDAY_JP="日" ;;
esac

# 新しい日記エントリのテンプレート
NEW_ENTRY="
## $TODAY ($WEEKDAY_JP)

### 実装した機能 ✅
- 

### うまくいかなかったところ ❌
- 

### 明日に引き継ぎたいこと 📋
1. 
2. 
3. 

### 今日の感情・進歩 💭
**感情**: 

**進歩したこと**:
- 

**学んだこと**:
- 

### 技術的なメモ 📝
- 

---

"

# 日記ファイルの先頭に新しいエントリを追加
if [ -f "$DIARY_FILE" ]; then
    # 既存ファイルがある場合、先頭に新しいエントリを追加
    temp_file=$(mktemp)
    echo "# TETE開発 作業日記" > "$temp_file"
    echo "$NEW_ENTRY" >> "$temp_file"
    tail -n +2 "$DIARY_FILE" >> "$temp_file"
    mv "$temp_file" "$DIARY_FILE"
else
    # ファイルが存在しない場合、新規作成
    echo "# TETE開発 作業日記" > "$DIARY_FILE"
    echo "$NEW_ENTRY" >> "$DIARY_FILE"
fi

echo "新しい日記エントリが作成されました: $TODAY"

# 通知を送信（macOSの場合）
osascript -e "display notification \"新しい作業日記エントリが作成されました\" with title \"TETE開発日記\" subtitle \"$TODAY の日記を書く時間です\""