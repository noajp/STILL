#!/bin/bash

# crontabにエントリを追加するスクリプト
# 毎日23:55に日記作成スクリプトを実行

SCRIPT_PATH="/Users/nakanotakanori/Dev/TETE/diary_automation.sh"

# 現在のcrontabを取得
crontab -l > /tmp/current_cron 2>/dev/null || touch /tmp/current_cron

# 既存のエントリをチェック
if grep -q "diary_automation.sh" /tmp/current_cron; then
    echo "日記自動化のcronジョブは既に設定されています。"
else
    # 新しいcronジョブを追加
    echo "55 23 * * * $SCRIPT_PATH" >> /tmp/current_cron
    
    # crontabを更新
    crontab /tmp/current_cron
    echo "日記自動化のcronジョブが設定されました。"
    echo "毎日23:55に新しい日記エントリが作成されます。"
fi

# 一時ファイルを削除
rm /tmp/current_cron

echo ""
echo "現在のcrontab設定:"
crontab -l | grep -E "(diary|TETE)" || echo "TETE関連のcronジョブは見つかりませんでした。"

echo ""
echo "=========================================="
echo "日記システムのセットアップ完了！"
echo "=========================================="
echo ""
echo "📝 作業日記: /Users/nakanotakanori/Dev/TETE/work_diary.md"
echo "⏰ 自動実行: 毎日23:55"
echo "🔔 通知: macOS通知センター"
echo ""
echo "💡 使い方:"
echo "1. 毎朝作業開始時に work_diary.md を読む"
echo "2. 毎日23:55に自動で新しいエントリが作成される"
echo "3. その日の進捗、感情、学びを記録する"
echo ""
echo "手動で日記エントリを作成する場合:"
echo "$SCRIPT_PATH"