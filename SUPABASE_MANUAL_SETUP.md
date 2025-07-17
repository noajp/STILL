# Supabase Manual Setup Instructions

## 関数の作成が必要な理由

MessagesViewModelが正しく動作するためには、`get_user_conversations` SQL関数をSupabaseデータベースに作成する必要があります。

## 手動でSQL関数を作成する手順

1. **Supabaseコンソールにアクセス**
   - https://app.supabase.com/ にアクセス
   - プロジェクト `yccjlkcxqybxqewzchen` を選択

2. **SQLエディタを開く**
   - 左側のメニューから "SQL Editor" を選択
   - 新しいクエリを作成

3. **以下のSQLを実行**

```sql
-- Create get_user_conversations function
CREATE OR REPLACE FUNCTION get_user_conversations(user_id uuid)
RETURNS TABLE (
    id uuid,
    created_at timestamptz,
    updated_at timestamptz,
    last_message_at timestamptz,
    last_message_preview text,
    participant_count bigint,
    participants json
) 
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.created_at,
        c.updated_at,
        c.last_message_at,
        c.last_message_preview,
        COUNT(cp.user_id) as participant_count,
        json_agg(
            json_build_object(
                'id', p.id,
                'username', p.username,
                'display_name', p.display_name,
                'avatar_url', p.avatar_url
            )
        ) as participants
    FROM conversations c
    JOIN conversation_participants cp ON c.id = cp.conversation_id
    JOIN profiles p ON cp.user_id = p.id
    WHERE c.id IN (
        SELECT conversation_id 
        FROM conversation_participants 
        WHERE user_id = get_user_conversations.user_id
    )
    GROUP BY c.id, c.created_at, c.updated_at, c.last_message_at, c.last_message_preview
    ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_conversations(uuid) TO authenticated;
```

4. **実行**
   - "Run" ボタンをクリックしてSQLを実行
   - 成功メッセージが表示されることを確認

## 関数の機能

この関数は以下の機能を提供します：

- 指定されたユーザーIDに関連するすべての会話を取得
- 各会話の参加者情報を含む
- 最新のメッセージ時刻でソート
- 参加者数の集計
- JSON形式で参加者情報を返す

## 確認方法

関数が正しく作成されたかを確認するには：

1. SQLエディタで以下のクエリを実行:
```sql
SELECT * FROM get_user_conversations('00000000-0000-0000-0000-000000000000');
```

2. エラーが発生しなければ関数は正常に作成されています。

## 注意事項

- この関数は `SECURITY DEFINER` として作成されるため、実行時にはサービスロールの権限で実行されます
- `authenticated` ロールにのみ実行権限が付与されます
- 関数の実行には有効なSupabaseユーザーセッションが必要です