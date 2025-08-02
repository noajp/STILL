//======================================================================
// MARK: - MessageService.swift
// Purpose: Message service with encrypted messaging, conversation management, and real-time subscription handling (暗号化メッセージング、会話管理、リアルタイム購読処理を持つメッセージサービス)
// Path: still/Core/Services/MessageService.swift
//======================================================================
import Foundation
import Supabase

@MainActor
class MessageService: ObservableObject {
    static let shared = MessageService()
    private let supabase = SupabaseManager.shared.client
    
    // Timer for polling updates
    private var updateTimer: Timer?
    
    // Published property for unread conversations count (how many people sent messages)
    @Published var unreadConversationsCount: Int = 0
    
    private init() {
        // Setup subscriptions when user authenticates
        setupAuthenticationListener()
    }
    
    private func setupAuthenticationListener() {
        // Listen for authentication changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(authStateChanged),
            name: .authStateChanged,
            object: nil
        )
        
        // Setup immediately if user is already authenticated
        if AuthManager.shared.currentUser != nil {
            setupRealtimeSubscriptions()
        }
    }
    
    @objc private func authStateChanged() {
        if AuthManager.shared.currentUser != nil {
            // User logged in - setup subscriptions
            setupRealtimeSubscriptions()
        } else {
            // User logged out - cleanup and reset state
            cleanupUserSession()
        }
    }
    
    private func cleanupUserSession() {
        
        // Cleanup timer
        updateTimer?.invalidate()
        updateTimer = nil
        
        // Reset unread count
        unreadConversationsCount = 0
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    deinit {
        // Note: In Swift 6, deinit cannot access MainActor-isolated properties
        // Timer will be automatically cleaned up when the object is deallocated
    }
    
    // MARK: - Realtime Setup (Simplified polling approach)
    
    private func setupRealtimeSubscriptions() {
        // Start proper realtime updates for unread count
        startPollingForUpdates()
        
        // Setup realtime subscription for new messages
        setupSupabaseRealtime()
    }
    
    private func startPollingForUpdates() {
        // Invalidate existing timer
        updateTimer?.invalidate()
        
        // Poll for unread count updates every 10 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateUnreadCount()
            }
        }
        
        // Update immediately
        Task { @MainActor in
            await updateUnreadCount()
        }
    }
    
    private func setupSupabaseRealtime() {
        // TODO: Implement Supabase realtime subscription for messages table
        // This would provide instant notifications when new messages arrive
    }
    
    private func checkForUpdates() async {
        await updateUnreadCount()
    }
    
    // MARK: - Conversations
    
    /// Fetch all conversations for the current user
    func fetchConversations() async throws -> [Conversation] {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("🔍 DEBUG - Using currentUserId: \(currentUserId)")
        print("🔍 DEBUG - About to call RPC 'get_user_conversations' with params: [\"user_id_param\": \"\(currentUserId)\"]")
        
        // Use RPC function to bypass RLS recursion issues
        struct ConversationData: Codable {
            let conversationId: String
            let conversationCreatedAt: Date
            let conversationUpdatedAt: Date
            let conversationLastMessageAt: Date?
            let conversationLastMessagePreview: String?
            let participantId: String?
            let participantUserId: String?
            let participantJoinedAt: Date?
            let participantLastReadAt: Date?
            let userUsername: String?
            let userDisplayName: String?
            let userAvatarUrl: String?
            let userBio: String?
            
            enum CodingKeys: String, CodingKey {
                case conversationId = "conversation_id"
                case conversationCreatedAt = "conversation_created_at"
                case conversationUpdatedAt = "conversation_updated_at"
                case conversationLastMessageAt = "conversation_last_message_at"
                case conversationLastMessagePreview = "conversation_last_message_preview"
                case participantId = "participant_id"
                case participantUserId = "participant_user_id"
                case participantJoinedAt = "participant_joined_at"
                case participantLastReadAt = "participant_last_read_at"
                case userUsername = "user_username"
                case userDisplayName = "user_display_name"
                case userAvatarUrl = "user_avatar_url"
                case userBio = "user_bio"
            }
        }
        
        // Use RPC function instead of view to avoid auth.uid() issues
        print("🔍 DEBUG - Using RPC function for user conversations")
        let conversationData: [ConversationData] = try await supabase
            .rpc("get_user_conversations", params: ["user_id_param": AnyJSON.string(currentUserId)])
            .execute()
            .value
        
        print("🧪 RAW RESPONSE DEBUG: Successfully decoded \(conversationData.count) items")
        
        // Manual JSON test for debugging
        if let firstItem = conversationData.first {
            print("🧪 FIRST ITEM DETAILED ANALYSIS:")
            print("   conversationId: '\(firstItem.conversationId)'")
            print("   participantId: '\(firstItem.participantId ?? "NIL")'")
            print("   participantUserId: '\(firstItem.participantUserId ?? "NIL")'")
            print("   userUsername: '\(firstItem.userUsername ?? "NIL")'")
            print("   userDisplayName: '\(firstItem.userDisplayName ?? "NIL")'")
            print("   participantJoinedAt: '\(firstItem.participantJoinedAt?.description ?? "NIL")'")
        }
        
        // TEST: Add logging to show exact raw data from RPC call
        print("🧪 TEST - Exact count of items returned from RPC call: \(conversationData.count)")
        print("🧪 TEST - Raw data details for each item:")
        for (index, item) in conversationData.enumerated() {
            print("   Item \(index): conversationId=\(item.conversationId)")
            print("      participantUserId=\(item.participantUserId ?? "NIL")")
            print("      userUsername=\(item.userUsername ?? "NIL")")
            print("      userDisplayName=\(item.userDisplayName ?? "NIL")")
            print("      participantId=\(item.participantId ?? "NIL")")
            print("      participantJoinedAt=\(item.participantJoinedAt?.description ?? "NIL")")
        }
        
        print("🔍 DEBUG - RPC call completed successfully")
        print("🔍 DEBUG - Raw count returned from RPC: \(conversationData.count)")
        print("🔍 DEBUG - First few items from RPC response:")
        for (index, item) in conversationData.enumerated() {
            if index < 5 { // Show first 5 items
                print("   Item \(index): conversationId=\(item.conversationId), participantUserId=\(item.participantUserId ?? "nil"), userUsername=\(item.userUsername ?? "nil")")
            }
        }
        
        print("📋 MessageService - fetchConversations: Got \(conversationData.count) conversation data items")
        print("🔍 DEBUG - Raw conversation data: \(conversationData)")
        
        
        // Group by conversation ID and build Conversation objects
        var conversationDict: [String: Conversation] = [:]
        
        print("🔍 DEBUG - Starting conversion loop with \(conversationData.count) items")
        
        for (index, data) in conversationData.enumerated() {
            print("🔍 DEBUG - Processing item \(index + 1)/\(conversationData.count): conversationId=\(data.conversationId)")
            let conversationId = data.conversationId
            
            // Create or get existing conversation
            if conversationDict[conversationId] == nil {
                print("🔍 DEBUG - Creating new conversation object for ID: \(conversationId)")
                conversationDict[conversationId] = Conversation(
                    id: conversationId,
                    createdAt: data.conversationCreatedAt,
                    updatedAt: data.conversationUpdatedAt,
                    lastMessageAt: data.conversationLastMessageAt,
                    lastMessagePreview: data.conversationLastMessagePreview,
                    participants: [],
                    messages: nil,
                    unreadCount: nil
                )
            } else {
                print("🔍 DEBUG - Conversation \(conversationId) already exists in dictionary")
            }
            
            // Create UserProfile if we have user data
            var userProfile: UserProfile? = nil
            if let username = data.userUsername, let participantUserId = data.participantUserId {
                userProfile = UserProfile(
                    id: participantUserId,
                    username: username,
                    displayName: data.userDisplayName,
                    avatarUrl: data.userAvatarUrl,
                    bio: data.userBio,
                    createdAt: nil
                )
                print("🔍 DEBUG - Created UserProfile for conversation \(conversationId): username=\(username), displayName=\(data.userDisplayName ?? "nil"), userId=\(participantUserId)")
            } else {
                print("🔍 DEBUG - No username or participantUserId for conversation \(conversationId) - username: \(data.userUsername ?? "nil"), participantUserId: \(data.participantUserId ?? "nil")")
            }
            
            // Create participant only if we have required data
            if let participantId = data.participantId, 
               let participantUserId = data.participantUserId,
               let participantJoinedAt = data.participantJoinedAt {
                let participant = ConversationParticipant(
                    id: participantId,
                    conversationId: conversationId,
                    userId: participantUserId,
                    joinedAt: participantJoinedAt,
                    lastReadAt: data.participantLastReadAt,
                    user: userProfile
                )
                
                // Add participant to conversation
                conversationDict[conversationId]?.participants?.append(participant)
                print("🔍 DEBUG - Added participant \(participantUserId) to conversation \(conversationId)")
            } else {
                print("🔍 DEBUG - Missing participant data for conversation \(conversationId) - participantId: \(data.participantId ?? "nil"), participantUserId: \(data.participantUserId ?? "nil"), participantJoinedAt: \(data.participantJoinedAt?.description ?? "nil")")
            }
            
            // Debug: Show participants array after adding
            if let conversation = conversationDict[conversationId] {
                print("🔍 DEBUG - Conversation \(conversationId) now has \(conversation.participants?.count ?? 0) participants:")
                conversation.participants?.forEach { participant in
                    print("   - Participant: userId=\(participant.userId), username=\(participant.user?.username ?? "nil"), displayName=\(participant.user?.displayName ?? "nil")")
                }
            }
        }
        
        print("🔍 DEBUG - Conversion loop completed")
        print("🔍 DEBUG - Final conversationDict contains \(conversationDict.count) unique conversations:")
        for (convId, conversation) in conversationDict {
            print("   Conversation \(convId): \(conversation.participants?.count ?? 0) participants")
            conversation.participants?.forEach { participant in
                print("      - Final participant: userId=\(participant.userId), username=\(participant.user?.username ?? "nil")")
            }
        }
        
        let userConversations = Array(conversationDict.values).sorted { (c1, c2) in
            // Sort by last_message_at descending, with nil values last
            if let date1 = c1.lastMessageAt, let date2 = c2.lastMessageAt {
                return date1 > date2
            } else if c1.lastMessageAt != nil {
                return true
            } else if c2.lastMessageAt != nil {
                return false
            } else {
                return c1.createdAt > c2.createdAt
            }
        }
        
        
        
        
        
        
        // Calculate unread count and fetch latest message for each conversation
        var conversationsWithUnread: [Conversation] = []
        var conversationsWithUnreadMessages = 0
        
        for var conversation in userConversations {
            let unreadCount = try await getUnreadCount(for: conversation.id)
            conversation.unreadCount = unreadCount
            if unreadCount > 0 {
                conversationsWithUnreadMessages += 1
            }
            
            // Fetch the latest message to get the actual decrypted content
            do {
                // Fetch only the latest message without join
                let latestMessageData: [[String: AnyJSON]] = try await supabase
                    .from("messages")
                    .select("content")
                    .eq("conversation_id", value: conversation.id)
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()
                    .value
                
                if let messageData = latestMessageData.first,
                   let encryptedContent = messageData["content"]?.stringValue {
                    // Decrypt the content
                    do {
                        let keyData = try KeychainManager.shared.getUserKey()
                        let key = CryptoManager.shared.dataToKey(keyData)
                        let decryptedContent = try CryptoManager.shared.decryptFromBase64(base64String: encryptedContent, using: key)
                        
                        // Use the decrypted content for preview
                        conversation.lastMessagePreview = decryptedContent.count > 50 ? String(decryptedContent.prefix(50)) + "..." : decryptedContent
                        print("✅ Successfully decrypted preview for conversation \(conversation.id): \(conversation.lastMessagePreview ?? "")")
                    } catch {
                        print("❌ Failed to decrypt message preview: \(error)")
                        // Fallback to "Message" if decryption fails
                        conversation.lastMessagePreview = "Message"
                    }
                }
            } catch {
                print("❌ Failed to fetch latest message for conversation \(conversation.id): \(error)")
            }
            
            conversationsWithUnread.append(conversation)
        }
        
        // Update the count of conversations with unread messages
        self.unreadConversationsCount = conversationsWithUnreadMessages
        
        print("📋 MessageService - fetchConversations: Returning \(conversationsWithUnread.count) conversations")
        print("🔍 DEBUG - Final conversations array being returned to MessagesView:")
        for (index, conversation) in conversationsWithUnread.enumerated() {
            print("   [\(index)] ID: \(conversation.id)")
            print("       Participants: \(conversation.participants?.count ?? 0)")
            conversation.participants?.forEach { participant in
                print("         - \(participant.user?.username ?? "unknown") (\(participant.userId))")
            }
            print("       Last message: \(conversation.lastMessagePreview ?? "none")")
            print("       Unread count: \(conversation.unreadCount ?? 0)")
        }
        return conversationsWithUnread
    }
    
    /// Get or create a direct conversation with another user
    func getOrCreateDirectConversation(with userId: String) async throws -> String {
        print("🔄 MessageService: Starting getOrCreateDirectConversation with userId: \(userId)")
        
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            print("❌ MessageService: User not authenticated")
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("🔍 MessageService: Current user ID: \(currentUserId)")
        
        
        // Verify both users exist in user_profiles table using count instead of full object
        do {
            let currentUserCount = try await supabase
                .from("profiles")
                .select("id", head: true, count: .exact)
                .eq("id", value: currentUserId)
                .execute()
                .count ?? 0
            
            if currentUserCount == 0 {
                throw NSError(domain: "MessageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Current user profile not found"])
            }
        } catch {
            throw NSError(domain: "MessageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Current user profile not found"])
        }
        
        do {
            let targetUserCount = try await supabase
                .from("profiles")
                .select("id", head: true, count: .exact)
                .eq("id", value: userId)
                .execute()
                .count ?? 0
            
            if targetUserCount == 0 {
                throw NSError(domain: "MessageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Target user profile not found"])
            }
        } catch {
            throw NSError(domain: "MessageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Target user profile not found"])
        }
        
        
        // Try to get session
        do {
            _ = try await supabase.auth.session
        } catch {
        }
        
        // Now safely call the RPC function
        do {
            // Ensure userId is a valid UUID format
            guard UUID(uuidString: userId) != nil else {
                print("❌ CREATE CONVERSATION: Invalid user ID format: \(userId)")
                throw NSError(domain: "MessageService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"])
            }
            
            print("🔄 MessageService: Calling RPC get_or_create_direct_conversation with userId: \(userId)")
            let conversationId: String = try await supabase
                .rpc("get_or_create_direct_conversation", params: ["other_user_id": AnyJSON.string(userId)])
                .execute()
                .value
            print("✅ MessageService: RPC returned conversation ID: \(conversationId)")
            return conversationId
        } catch {
            print("❌ CREATE CONVERSATION: RPC failed with error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain), code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
            }
            throw error
        }
    }
    
    /// Get unread message count for a conversation
    private func getUnreadCount(for conversationId: String) async throws -> Int {
        guard let userId = AuthManager.shared.currentUser?.id else { 
            return 0 
        }
        
        do {
            // Get the user's last read timestamp
            struct LastReadResponse: Codable {
                let lastReadAt: Date?
                
                enum CodingKeys: String, CodingKey {
                    case lastReadAt = "last_read_at"
                }
            }
            
            let lastReadData: LastReadResponse = try await supabase
                .from("conversation_participants")
                .select("last_read_at")
                .eq("conversation_id", value: conversationId)
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            let lastReadAt = lastReadData.lastReadAt ?? Date.distantPast
            
            
            // Count messages after last read
            let countResponse = try await supabase
                .from("messages")
                .select("id", head: true, count: .exact)
                .eq("conversation_id", value: conversationId)
                .neq("sender_id", value: userId)
                .gt("created_at", value: ISO8601DateFormatter().string(from: lastReadAt))
                .execute()
            
            let unreadCount = countResponse.count ?? 0
            
            return unreadCount
        } catch {
            return 0
        }
    }
    
    // MARK: - Messages
    
    /// Fetch messages for a conversation
    func fetchMessages(for conversationId: String, limit: Int = 50, before: Date? = nil) async throws -> [Message] {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Check if there's a message cutoff time for this user
        let participantData: [[String: AnyJSON]] = try await supabase
            .from("conversation_participants")
            .select("messages_hidden_since")
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: currentUserId)
            .execute()
            .value
        
        let messagesCutoffTime: Date?
        if let participant = participantData.first,
           let cutoffString = participant["messages_hidden_since"]?.stringValue {
            messagesCutoffTime = ISO8601DateFormatter().date(from: cutoffString)
            print("📅 Messages cutoff time for user \(currentUserId): \(cutoffString)")
        } else {
            messagesCutoffTime = nil
            print("📅 No message cutoff time for user \(currentUserId)")
        }
        
        let query = supabase
            .from("messages")
            .select("""
                *,
                sender:profiles(*)
            """)
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: false)
            .limit(limit)
        
        var messages: [Message] = try await query.execute().value
        
        // If there's a cutoff time, filter messages after that time on the client side
        if let cutoffTime = messagesCutoffTime {
            messages = messages.filter { message in
                message.createdAt > cutoffTime
            }
            print("📅 Filtered messages after cutoff: \(ISO8601DateFormatter().string(from: cutoffTime))")
            print("📅 \(messages.count) messages remain after filtering")
        }
        
        messages.reverse() // Reverse to show oldest first
        
        print("📨 Fetched \(messages.count) messages for conversation \(conversationId)")
        return messages
    }
    
    /// Send a message
    func sendMessage(to conversationId: String, content: String) async throws -> Message {
        guard let userId = AuthManager.shared.currentUser?.id else {
            print("❌ SEND MESSAGE: User not authenticated")
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // 暗号化キーを取得または生成
        let encryptedContent: String
        do {
            let keyData = try KeychainManager.shared.getUserKey()
            let key = CryptoManager.shared.dataToKey(keyData)
            encryptedContent = try CryptoManager.shared.encryptToBase64(text: content, using: key)
        } catch KeychainError.keyNotFound {
            // 初回の場合はキーを生成
            let newKey = CryptoManager.shared.generateUserKey()
            let keyData = CryptoManager.shared.keyToData(newKey)
            try KeychainManager.shared.saveUserKey(keyData)
            encryptedContent = try CryptoManager.shared.encryptToBase64(text: content, using: newKey)
        }
        
        let messageData = [
            "conversation_id": conversationId,
            "sender_id": userId,
            "content": encryptedContent  // 暗号化されたコンテンツを保存
        ]
        
        let message: Message = try await supabase
            .from("messages")
            .insert(messageData)
            .select("""
                *,
                sender:profiles(*)
            """)
            .single()
            .execute()
            .value
        
        // Update conversation's last_message_preview with the plain text
        // This ensures the preview can be displayed without decryption issues
        let previewText = content.count > 50 ? String(content.prefix(50)) + "..." : content
        let conversationUpdateData: [String: AnyJSON] = [
            "last_message_preview": AnyJSON.string(previewText),
            "last_message_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await supabase
            .from("conversations")
            .update(conversationUpdateData)
            .eq("id", value: conversationId)
            .execute()
        
        // Ensure sender's participation record exists (in case they deleted the conversation)
        try await ensureParticipationExists(conversationId: conversationId, userId: userId)
        
        // Unhide conversation for all participants when a new message is sent
        // This ensures that even if someone deleted the chat, they'll see new messages
        print("🔄 About to unhide conversation \(conversationId) for all participants")
        try await unhideConversationForAllParticipants(conversationId: conversationId)
        
        // Clear message cutoff for the sender only (they should see all messages after sending)
        try await clearMessageCutoffForSender(conversationId: conversationId, senderId: userId)
        
        // Mark conversation as read after sending
        do {
            try await markConversationAsRead(conversationId)
        } catch {
            // Silently handle error
        }
        
        // Update unread count for all users (sender's count might decrease, receiver's might increase)
        Task {
            await updateUnreadCount()
        }
        
        // Post notification for immediate UI update
        await MainActor.run {
            NotificationCenter.default.post(name: .messageWasSent, object: message)
        }
        
        return message
    }
    
    /// Mark a conversation as read
    func markConversationAsRead(_ conversationId: String) async throws {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        
        let updateData: [String: AnyJSON] = [
            "last_read_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await supabase
            .from("conversation_participants")
            .update(updateData)
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
        
        // Post notification that conversation was marked as read
        await MainActor.run {
            NotificationCenter.default.post(name: .conversationMarkedAsRead, object: conversationId)
        }
        
        // Update unread count after marking as read
        Task {
            await updateUnreadCount()
        }
    }
    
    
    /// Edit a message
    func editMessage(_ messageId: String, newContent: String) async throws {
        let updateData: [String: AnyJSON] = [
            "content": AnyJSON.string(newContent),
            "is_edited": AnyJSON.bool(true),
            "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await supabase
            .from("messages")
            .update(updateData)
            .eq("id", value: messageId)
            .execute()
    }
    
    /// Delete a conversation from current user's view only (soft delete)
    func deleteConversation(_ conversationId: String) async throws {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let deletionTime = Date()
        
        // Mark conversation as hidden for the current user (soft delete)
        // Also record when messages should be hidden from (for future restoration)
        let updateData: [String: AnyJSON] = [
            "hidden_for_user": AnyJSON.bool(true),
            "hidden_at": AnyJSON.string(ISO8601DateFormatter().string(from: deletionTime)),
            "messages_hidden_since": AnyJSON.string(ISO8601DateFormatter().string(from: deletionTime))
        ]
        
        try await supabase
            .from("conversation_participants")
            .update(updateData)
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: currentUserId)
            .execute()
        
        // Note: Messages and conversation record remain intact for the other participant
        print("🗑️ Conversation \(conversationId) marked as hidden for user \(currentUserId) with message cutoff at \(deletionTime)")
    }
    
    // MARK: - Helper Methods
    
    /// Update unread conversation count without triggering full UI refresh
    private func updateUnreadCount() async {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { 
            await MainActor.run {
                self.unreadConversationsCount = 0
            }
            return 
        }
        
        do {
            
            // Use RPC function to get user's conversations
            struct ConversationData: Codable {
                let conversationId: String
                
                enum CodingKeys: String, CodingKey {
                    case conversationId = "conversation_id"
                }
            }
            
            let conversationData: [ConversationData] = try await supabase
                .rpc("get_user_conversations", params: ["user_id_param": AnyJSON.string(currentUserId)])
                .execute()
                .value
            
            // Group by conversation ID 
            let conversationIds = Set(conversationData.map { $0.conversationId })
            
            var unreadConversationsCount = 0
            
            for conversationId in conversationIds {
                let unreadCount = try await getUnreadCount(for: conversationId)
                if unreadCount > 0 {
                    unreadConversationsCount += 1
                }
            }
            
            await MainActor.run {
                self.unreadConversationsCount = unreadConversationsCount
            }
        } catch {
            await MainActor.run {
                self.unreadConversationsCount = 0
            }
        }
    }
    
    // MARK: - Group Chat Functions
    
    /// Create a new group chat
    func createGroupChat(name: String, description: String? = nil, memberIds: [String] = []) async throws -> String {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("📱 Creating group chat - Name: \(name), Members: \(memberIds)")
        print("📱 Current user ID: \(currentUserId)")
        
        do {
            let conversationId: String = try await supabase
                .rpc("create_group_chat", params: [
                    "group_name_param": AnyJSON.string(name),
                    "group_description_param": description.map { AnyJSON.string($0) } ?? AnyJSON.null,
                    "member_ids": AnyJSON.array(memberIds.map { AnyJSON.string($0) })
                ])
                .execute()
                .value
            
            print("✅ Group chat created successfully with ID: \(conversationId)")
            return conversationId
        } catch {
            print("❌ Failed to create group chat: \(error)")
            throw error
        }
    }
    
    /// Fetch group conversations for current user
    func fetchGroupConversations() async throws -> [GroupConversation] {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("📱 Fetching group conversations for user: \(currentUserId)")
        
        do {
            let groupConversations: [GroupConversation] = try await supabase
                .rpc("get_user_group_conversations", params: ["user_id_param": AnyJSON.string(currentUserId)])
                .execute()
                .value
            
            print("✅ Fetched \(groupConversations.count) group conversations")
            
            // 各グループチャットの最新メッセージを復号化（通常のメッセージと同じ方法）
            var updatedGroupConversations: [GroupConversation] = []
            
            for var groupConversation in groupConversations {
                // 最新メッセージを個別に取得して復号化
                do {
                    let latestMessageData: [[String: AnyJSON]] = try await supabase
                        .from("messages")
                        .select("content")
                        .eq("conversation_id", value: groupConversation.id)
                        .order("created_at", ascending: false)
                        .limit(1)
                        .execute()
                        .value
                    
                    if let messageData = latestMessageData.first,
                       let encryptedContent = messageData["content"]?.stringValue {
                        // Decrypt the content
                        do {
                            let keyData = try KeychainManager.shared.getUserKey()
                            let key = CryptoManager.shared.dataToKey(keyData)
                            let decryptedContent = try CryptoManager.shared.decryptFromBase64(base64String: encryptedContent, using: key)
                            
                            // Use the decrypted content for preview
                            let preview = decryptedContent.count > 50 ? String(decryptedContent.prefix(50)) + "..." : decryptedContent
                            
                            print("✅ Successfully decrypted group preview for \(groupConversation.displayName): \(preview)")
                            
                            // GroupConversationのlastMessageContentを更新（構造体なので、新しいインスタンスを作成）
                            groupConversation = GroupConversation(
                                id: groupConversation.id,
                                isGroup: groupConversation.isGroup,
                                groupName: groupConversation.groupName,
                                groupDescription: groupConversation.groupDescription,
                                groupAvatarUrl: groupConversation.groupAvatarUrl,
                                createdBy: groupConversation.createdBy,
                                createdAt: groupConversation.createdAt,
                                updatedAt: groupConversation.updatedAt,
                                lastMessageAt: groupConversation.lastMessageAt,
                                lastMessageContent: preview, // 復号化されたコンテンツ
                                lastMessageSenderId: groupConversation.lastMessageSenderId,
                                lastMessageSenderUsername: groupConversation.lastMessageSenderUsername,
                                unreadCount: groupConversation.unreadCount
                            )
                        } catch {
                            print("❌ Failed to decrypt group message preview: \(error)")
                            // 復号化に失敗した場合は "Message" を表示
                            groupConversation = GroupConversation(
                                id: groupConversation.id,
                                isGroup: groupConversation.isGroup,
                                groupName: groupConversation.groupName,
                                groupDescription: groupConversation.groupDescription,
                                groupAvatarUrl: groupConversation.groupAvatarUrl,
                                createdBy: groupConversation.createdBy,
                                createdAt: groupConversation.createdAt,
                                updatedAt: groupConversation.updatedAt,
                                lastMessageAt: groupConversation.lastMessageAt,
                                lastMessageContent: "Message",
                                lastMessageSenderId: groupConversation.lastMessageSenderId,
                                lastMessageSenderUsername: groupConversation.lastMessageSenderUsername,
                                unreadCount: groupConversation.unreadCount
                            )
                        }
                    }
                } catch {
                    print("❌ Failed to fetch latest message for group \(groupConversation.id): \(error)")
                }
                
                updatedGroupConversations.append(groupConversation)
                print("  Group: \(groupConversation.displayName) - Preview: \(groupConversation.displayLastMessagePreview)")
            }
            
            return updatedGroupConversations
        } catch {
            print("❌ Failed to fetch group conversations: \(error)")
            throw error
        }
    }
    
    /// Add member to group chat
    func addGroupMember(conversationId: String, userId: String) async throws -> Bool {
        let result: Bool = try await supabase
            .rpc("add_group_member", params: [
                "conversation_id_param": AnyJSON.string(conversationId),
                "user_id_param": AnyJSON.string(userId)
            ])
            .execute()
            .value
        
        return result
    }
    
    /// Remove member from group chat
    func removeGroupMember(conversationId: String, userId: String) async throws -> Bool {
        let result: Bool = try await supabase
            .rpc("remove_group_member", params: [
                "conversation_id_param": AnyJSON.string(conversationId),
                "user_id_param": AnyJSON.string(userId)
            ])
            .execute()
            .value
        
        return result
    }
    
    /// Get group members
    func getGroupMembers(conversationId: String) async throws -> [GroupMember] {
        let members: [GroupMember] = try await supabase
            .from("group_members")
            .select("""
                *,
                user:profiles(*)
            """)
            .eq("conversation_id", value: conversationId)
            .execute()
            .value
        
        return members
    }
    
    // MARK: - Helper Functions for Participation Management
    
    /// Ensure user's participation record exists for a conversation
    private func ensureParticipationExists(conversationId: String, userId: String) async throws {
        // Check if participation record already exists
        let existingCount = try await supabase
            .from("conversation_participants")
            .select("id", head: true, count: .exact)
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
            .count ?? 0
        
        // If no participation record exists, create one
        if existingCount == 0 {
            let participantData: [String: AnyJSON] = [
                "conversation_id": AnyJSON.string(conversationId),
                "user_id": AnyJSON.string(userId),
                "joined_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ]
            
            try await supabase
                .from("conversation_participants")
                .insert(participantData)
                .execute()
            
            print("🔄 Restored participation for user \(userId) in conversation \(conversationId)")
        }
    }
    
    /// Unhide conversation for all participants when a new message is sent
    private func unhideConversationForAllParticipants(conversationId: String) async throws {
        print("🔄 unhideConversationForAllParticipants called for conversation: \(conversationId)")
        
        // Use RPC function with SECURITY DEFINER to bypass RLS restrictions
        try await supabase
            .rpc("unhide_conversation_for_all_participants", params: [
                "conversation_id_param": AnyJSON.string(conversationId)
            ])
            .execute()
        
        print("👁️ Conversation \(conversationId) unhidden for all participants via RPC")
    }
    
    /// Clear message cutoff for sender when they send a message
    private func clearMessageCutoffForSender(conversationId: String, senderId: String) async throws {
        print("🔄 clearMessageCutoffForSender called for conversation: \(conversationId), sender: \(senderId)")
        
        // Use RPC function to clear message cutoff for sender only
        try await supabase
            .rpc("clear_message_cutoff_for_user", params: [
                "conversation_id_param": AnyJSON.string(conversationId),
                "user_id_param": AnyJSON.string(senderId)
            ])
            .execute()
        
        print("✅ Message cutoff cleared for sender \(senderId) in conversation \(conversationId)")
    }
}
