# メッセージシステム循環依存解消 - 移行手順

## 🎯 目的
既存のメッセージシステムの循環依存を解消し、3層アーキテクチャに移行する

## 📊 現在の循環依存
```
MessageService → MessageRepository → SupabaseManager
     ↑                                      ↓
ConversationManager ← MessageServiceCoordinator
     ↑                                      ↓
RealtimeSubscriptionManager ← MessageEncryptionService
```

## 🏗️ 新しいアーキテクチャ
```
Presentation Layer (ViewModels)
         ↓
Business Logic Layer (Services)
         ↓
Data Access Layer (Repositories)
         ↓
External Services (Supabase)
```

## 📝 移行手順

### Phase 1: 準備（完了済み）
- ✅ 新しい3層アーキテクチャの実装
- ✅ 移行用のファサードとアダプターの作成
- ✅ 後方互換性のある置き換えクラスの実装

### Phase 2: 段階的置き換え（実施中）

#### Step 1: MessageServiceの置き換え
```swift
// Old (循環依存あり)
let service = MessageService.shared

// New (循環依存なし)
let service = MessageServiceReplacement.shared
// または
let service = MessageSystemFacade.shared.messageService
```

**対象ファイル:**
- `still/Features/Messages/Views/MessagesView.swift`
- `still/Features/Messages/Views/ConversationView.swift`
- その他MessageService.sharedを使用している全ファイル

#### Step 2: ConversationManagerの置き換え
```swift
// Old
let manager = ConversationManager.shared

// New
let manager = ConversationManagerReplacement.shared
// または
let manager = MessageSystemFacade.shared.conversationService
```

**対象ファイル:**
- `still/Core/Services/ConversationManager.swift` → 削除予定
- 参照している全ファイル

#### Step 3: MessageServiceCoordinatorの削除
```swift
// Old
let coordinator = MessageServiceCoordinator.shared

// New
let facade = MessageSystemFacade.shared
```

#### Step 4: ViewModelの更新
```swift
// Old ViewModel
class MessagesViewModel: ObservableObject {
    private let messageService = MessageService.shared
    private let conversationManager = ConversationManager.shared
    // 循環依存のリスク
}

// New ViewModel
class MessagesViewModel: ObservableObject {
    private let messageService: MessageBusinessLogicProtocol
    
    init(messageService: MessageBusinessLogicProtocol = MessageSystemFacade.shared.messageService) {
        self.messageService = messageService
    }
    // 依存性注入、循環依存なし
}
```

### Phase 3: 古いコードの削除

#### 削除対象ファイル:
1. `still/Core/Services/MessageService.swift` (Deprecated)
2. `still/Core/Services/ConversationManager.swift`
3. `still/Core/Services/MessageServiceCoordinator.swift`
4. `still/Core/Services/RealtimeSubscriptionManager.swift` (該当部分)

#### 更新が必要なファイル:
1. `still/Core/DependencyInjection/ServiceAdapters.swift`
   - 新しいファサードを使用するように更新

2. `still/Core/DependencyInjection/DependencyContainer.swift`
   - 新しいサービスを返すように更新

## 🔧 実装例

### Before (循環依存あり):
```swift
// MessageService.swift
class MessageService {
    private let conversationManager = ConversationManager.shared // 循環依存！
    private let repository = MessageRepository()
    private let encryption = MessageEncryptionService.shared
    
    func sendMessage() {
        // conversationManagerを使用
        // repositoryを使用
        // encryptionを使用
    }
}

// ConversationManager.swift
class ConversationManager {
    private let messageService = MessageService.shared // 循環依存！
    private let repository = MessageRepository()
}
```

### After (循環依存なし):
```swift
// MessageBusinessLogic.swift (BLL)
class MessageBusinessLogic: MessageBusinessLogicProtocol {
    // 下位層のみに依存
    private let messageDataAccess: MessageDataAccessProtocol
    private let encryptionService: EncryptionServiceProtocol
    
    init(messageDataAccess: MessageDataAccessProtocol, 
         encryptionService: EncryptionServiceProtocol) {
        self.messageDataAccess = messageDataAccess
        self.encryptionService = encryptionService
    }
}

// MessageDataAccess.swift (DAL)
class MessageDataAccess: MessageDataAccessProtocol {
    // 外部サービスのみに依存
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
}
```

## 🧪 テスト戦略

### 1. 単体テスト
各層を独立してテスト:
```swift
// DAL層のテスト
func testMessageDataAccess() {
    let mockSupabase = MockSupabaseClient()
    let dataAccess = MessageDataAccess(supabaseClient: mockSupabase)
    // テスト実行
}

// BLL層のテスト
func testMessageBusinessLogic() {
    let mockDataAccess = MockMessageDataAccess()
    let mockEncryption = MockEncryptionService()
    let businessLogic = MessageBusinessLogic(
        messageDataAccess: mockDataAccess,
        encryptionService: mockEncryption
    )
    // テスト実行
}
```

### 2. 統合テスト
新旧システムの互換性確認:
```swift
func testBackwardCompatibility() {
    let oldResult = MessageService.shared.fetchMessages()
    let newResult = MessageServiceReplacement.shared.fetchMessages()
    XCTAssertEqual(oldResult, newResult)
}
```

## ⚠️ 注意事項

1. **段階的移行**: 一度に全てを置き換えず、機能ごとに段階的に移行
2. **テストカバレッジ**: 各段階でテストを実行し、機能が壊れていないことを確認
3. **ロールバック計画**: 問題が発生した場合に備えて、旧コードを保持
4. **パフォーマンス監視**: 新アーキテクチャのパフォーマンスを監視

## 📈 進捗状況

- [x] 新アーキテクチャの設計と実装
- [x] 移行用ファサードの作成
- [ ] MessageServiceの置き換え
- [ ] ConversationManagerの置き換え
- [ ] MessageServiceCoordinatorの削除
- [ ] ViewModelの更新
- [ ] 古いコードの削除
- [ ] 統合テストの実行
- [ ] パフォーマンステスト

## 🎯 完了基準

1. 全ての循環依存が解消されている
2. 既存の機能が全て動作している
3. テストカバレッジが80%以上
4. パフォーマンスの劣化がない
5. コードレビューの承認