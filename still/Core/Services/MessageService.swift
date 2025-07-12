//======================================================================
// MARK: - MessageService.swift
// Path: foodai/Core/Services/MessageService.swift
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
        
        
        // Use RPC function to bypass RLS recursion issues
        struct ConversationData: Codable {
            let conversationId: String
            let conversationCreatedAt: Date
            let conversationUpdatedAt: Date
            let conversationLastMessageAt: Date?
            let conversationLastMessagePreview: String?
            let participantId: String
            let participantUserId: String
            let participantJoinedAt: Date
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
        
        let conversationData: [ConversationData] = try await supabase
            .rpc("get_user_conversations", params: ["user_id_param": AnyJSON.string(currentUserId)])
            .execute()
            .value
        
        
        // Group by conversation ID and build Conversation objects
        var conversationDict: [String: Conversation] = [:]
        
        for data in conversationData {
            let conversationId = data.conversationId
            
            // Create or get existing conversation
            if conversationDict[conversationId] == nil {
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
            }
            
            // Create UserProfile if we have user data
            var userProfile: UserProfile? = nil
            if let username = data.userUsername {
                userProfile = UserProfile(
                    id: data.participantUserId,
                    username: username,
                    displayName: data.userDisplayName,
                    avatarUrl: data.userAvatarUrl,
                    bio: data.userBio,
                    createdAt: nil
                )
            }
            
            // Create participant
            let participant = ConversationParticipant(
                id: data.participantId,
                conversationId: conversationId,
                userId: data.participantUserId,
                joinedAt: data.participantJoinedAt,
                lastReadAt: data.participantLastReadAt,
                user: userProfile
            )
            
            // Add participant to conversation
            conversationDict[conversationId]?.participants?.append(participant)
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
        
        
        
        
        
        
        // Calculate unread count for each conversation
        var conversationsWithUnread: [Conversation] = []
        var conversationsWithUnreadMessages = 0
        
        for var conversation in userConversations {
            let unreadCount = try await getUnreadCount(for: conversation.id)
            conversation.unreadCount = unreadCount
            if unreadCount > 0 {
                conversationsWithUnreadMessages += 1
            }
            conversationsWithUnread.append(conversation)
        }
        
        // Update the count of conversations with unread messages
        self.unreadConversationsCount = conversationsWithUnreadMessages
        
        return conversationsWithUnread
    }
    
    /// Get or create a direct conversation with another user
    func getOrCreateDirectConversation(with userId: String) async throws -> String {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        
        // Verify both users exist in user_profiles table using count instead of full object
        do {
            let currentUserCount = try await supabase
                .from("user_profiles")
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
                .from("user_profiles")
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
            
            let conversationId: String = try await supabase
                .rpc("get_or_create_direct_conversation", params: ["other_user_id": AnyJSON.string(userId)])
                .execute()
                .value
            return conversationId
        } catch {
            print("❌ CREATE CONVERSATION: RPC failed: \(error)")
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
        
        let query = supabase
            .from("messages")
            .select("""
                *,
                sender:user_profiles(*)
            """)
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: false)
            .limit(limit)
        
        var messages: [Message] = try await query.execute().value
        messages.reverse() // Reverse to show oldest first
        
        
        return messages
    }
    
    /// Send a message
    func sendMessage(to conversationId: String, content: String) async throws -> Message {
        guard let userId = AuthManager.shared.currentUser?.id else {
            print("❌ SEND MESSAGE: User not authenticated")
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let messageData = [
            "conversation_id": conversationId,
            "sender_id": userId,
            "content": content
        ]
        
        let message: Message = try await supabase
            .from("messages")
            .insert(messageData)
            .select("""
                *,
                sender:user_profiles(*)
            """)
            .single()
            .execute()
            .value
        
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
    
    /// Delete a conversation completely (hard delete)
    func deleteConversation(_ conversationId: String) async throws {
        guard AuthManager.shared.currentUser?.id != nil else {
            throw NSError(domain: "MessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // First, delete all messages in the conversation
        try await supabase
            .from("messages")
            .delete()
            .eq("conversation_id", value: conversationId)
            .execute()
        
        // Then, delete all participant records
        try await supabase
            .from("conversation_participants")
            .delete()
            .eq("conversation_id", value: conversationId)
            .execute()
        
        // Finally, delete the conversation itself
        try await supabase
            .from("conversations")
            .delete()
            .eq("id", value: conversationId)
            .execute()
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
}
