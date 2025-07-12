//======================================================================
// MARK: - RealtimeMessageService.swift
// Purpose: Service layer for business operations (RealtimeMessageServiceのビジネス操作サービス層)
// Path: still/Core/Services/RealtimeMessageService.swift
//======================================================================
//
//  RealtimeMessageService.swift
//  tete
//
//  リアルタイムメッセージングシステム（完全版）
//

import Foundation
import Supabase
import Combine

// MARK: - Realtime Message Service
@MainActor
final class RealtimeMessageService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var messages: [Message] = []
    @Published var conversations: [MessageConversation] = []
    @Published var isConnected = false
    @Published var typingUsers: [String] = []
    
    // MARK: - Private Properties
    private let client = SupabaseManager.shared.client
    private var messageChannel: RealtimeChannelV2?
    private var conversationChannel: RealtimeChannelV2?
    private var typingTimer: Timer?
    private let currentUserId: String
    
    // MARK: - Initialization
    init(userId: String) {
        self.currentUserId = userId
    }
    
    deinit {
        // Cleanup is handled by disconnect() being called explicitly
    }
    
    // MARK: - Public Methods
    
    /// メッセージを送信
    func sendMessage(to conversationId: String, content: String, type: MessageContentType = .text) async throws {
        let messageId = UUID().uuidString
        let now = Date()
        
        let messageData = MessageInsert(
            id: messageId,
            conversationId: conversationId,
            senderId: currentUserId,
            content: content,
            messageType: type.rawValue,
            createdAt: now,
            updatedAt: now,
            isRead: false,
            isEdited: false,
            isDeleted: false
        )
        
        do {
            // Database insert
            try await client
                .from("messages")
                .insert(messageData)
                .execute()
            
            // Update conversation last message
            try await updateConversationLastMessage(conversationId: conversationId, content: content, timestamp: now)
            
            print("✅ Message sent successfully")
            
        } catch {
            print("❌ Failed to send message: \(error)")
            throw error
        }
    }
    
    /// 会話を作成
    func createConversation(with participantIds: [String], title: String? = nil) async throws -> String {
        let conversationId = UUID().uuidString
        let now = Date()
        
        // Note: participants will be handled separately in a join table
        
        let conversationData = ConversationInsert(
            id: conversationId,
            title: title,
            createdAt: now,
            updatedAt: now,
            lastMessageAt: now,
            lastMessagePreview: nil
        )
        
        do {
            try await client
                .from("conversations")
                .insert(conversationData)
                .execute()
            
            return conversationId
            
        } catch {
            print("❌ Failed to create conversation: \(error)")
            throw error
        }
    }
    
    /// 会話リストを取得
    func loadConversations() async {
        do {
            let conversations: [MessageConversation] = try await client
                .from("conversations")
                .select("*")
                .contains("user_id", value: currentUserId)
                .order("last_message_at", ascending: false)
                .execute()
                .value
            
            self.conversations = conversations
            print("✅ Loaded \(conversations.count) conversations")
            
        } catch {
            print("❌ Failed to load conversations: \(error)")
        }
    }
    
    /// 特定の会話のメッセージを取得
    func loadMessages(for conversationId: String) async {
        do {
            let messages: [Message] = try await client
                .from("messages")
                .select("*")
                .eq("conversation_id", value: conversationId)
                .eq("is_deleted", value: false)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            self.messages = messages
            
            // Mark messages as read
            await markMessagesAsRead(conversationId: conversationId)
            
            print("✅ Loaded \(messages.count) messages")
            
        } catch {
            print("❌ Failed to load messages: \(error)")
        }
    }
    
    /// メッセージを既読にする
    func markMessagesAsRead(conversationId: String) async {
        do {
            try await client
                .from("messages")
                .update(["is_read": true])
                .eq("conversation_id", value: conversationId)
                .neq("sender_id", value: currentUserId)
                .eq("is_read", value: false)
                .execute()
            
        } catch {
            print("❌ Failed to mark messages as read: \(error)")
        }
    }
    
    /// メッセージを編集
    func editMessage(messageId: String, newContent: String) async throws {
        let updateData = MessageUpdate(
            content: newContent,
            isEdited: true,
            updatedAt: Date()
        )
        
        do {
            try await client
                .from("messages")
                .update(updateData)
                .eq("id", value: messageId)
                .eq("sender_id", value: currentUserId)
                .execute()
            
            print("✅ Message edited successfully")
            
        } catch {
            print("❌ Failed to edit message: \(error)")
            throw error
        }
    }
    
    /// メッセージを削除
    func deleteMessage(messageId: String) async throws {
        let updateData = MessageDelete(
            isDeleted: true,
            updatedAt: Date()
        )
        
        do {
            try await client
                .from("messages")
                .update(updateData)
                .eq("id", value: messageId)
                .eq("sender_id", value: currentUserId)
                .execute()
            
            print("✅ Message deleted successfully")
            
        } catch {
            print("❌ Failed to delete message: \(error)")
            throw error
        }
    }
    
    /// タイピング状態を送信
    func sendTypingStatus(conversationId: String, isTyping: Bool) {
        // Send typing event through realtime channel
        let _ : [String: Any] = [
            "user_id": currentUserId,
            "conversation_id": conversationId,
            "is_typing": isTyping,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Simplified typing notification
        print("⌨️ Typing status: \(isTyping ? "started" : "stopped")")
        
        if isTyping {
            // Auto-stop typing after 3 seconds
            typingTimer?.invalidate()
            typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                Task { @MainActor in
                    self.sendTypingStatus(conversationId: conversationId, isTyping: false)
                }
            }
        } else {
            typingTimer?.invalidate()
        }
    }
    
    /// 接続を開始
    func connect() async {
        await setupRealtimeChannels()
        isConnected = true
        print("🔗 Realtime message service connected")
    }
    
    /// 接続を切断
    func disconnect() async {
        await messageChannel?.unsubscribe()
        await conversationChannel?.unsubscribe()
        messageChannel = nil
        conversationChannel = nil
        typingTimer?.invalidate()
        isConnected = false
        print("🔌 Realtime message service disconnected")
    }
    
    // MARK: - Private Methods
    
    private func setupRealtimeChannels() async {
        // Simplified realtime setup
        messageChannel = client.realtimeV2.channel("messages:\(currentUserId)")
        
        // Basic subscription without complex filters for now
        await messageChannel?.subscribe()
        
        // Conversations channel
        conversationChannel = client.realtimeV2.channel("conversations:\(currentUserId)")
        await conversationChannel?.subscribe()
        
        print("🔗 Realtime channels subscribed")
    }
    
    private func handleNewMessage(_ realtimeMessage: RealtimeMessage) async {
        // Simplified message handling - will be enhanced later
        print("📨 New message received via realtime")
        
        // For now, just reload messages for active conversation
        // TODO: Parse the actual message and add to array
    }
    
    private func handleTypingEvent(_ realtimeMessage: RealtimeMessage) {
        // Simplified typing handling
        print("⌨️ Typing event received")
    }
    
    private func handleConversationUpdate(_ realtimeMessage: RealtimeMessage) async {
        // Simplified conversation update handling
        print("💬 Conversation updated via realtime")
        
        // For now, just reload conversations
        await loadConversations()
    }
    
    private func updateConversationLastMessage(conversationId: String, content: String, timestamp: Date) async throws {
        let updateData = ConversationUpdate(
            lastMessagePreview: content,
            lastMessageAt: timestamp,
            updatedAt: timestamp
        )
        
        try await client
            .from("conversations")
            .update(updateData)
            .eq("id", value: conversationId)
            .execute()
    }
    
    private func updateConversationWithNewMessage(_ message: Message) async {
        if let index = conversations.firstIndex(where: { $0.id == message.conversationId }) {
            conversations[index].lastMessagePreview = message.content
            conversations[index].lastMessageAt = message.createdAt
            
            // Move to top and resort
            let updatedConversation = conversations.remove(at: index)
            conversations.insert(updatedConversation, at: 0)
        }
    }
}

// MARK: - Supporting Types

struct MessageConversation: Codable, Identifiable {
    let id: String
    let title: String?
    var lastMessagePreview: String?
    var lastMessageAt: Date
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title
        case lastMessagePreview = "last_message_preview"
        case lastMessageAt = "last_message_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct MessageInsert: Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let messageType: String
    let createdAt: Date
    let updatedAt: Date
    let isRead: Bool
    let isEdited: Bool
    let isDeleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case messageType = "message_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isRead = "is_read"
        case isEdited = "is_edited"
        case isDeleted = "is_deleted"
    }
}

struct ConversationInsert: Codable {
    let id: String
    let title: String?
    let createdAt: Date
    let updatedAt: Date
    let lastMessageAt: Date
    let lastMessagePreview: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastMessageAt = "last_message_at"
        case lastMessagePreview = "last_message_preview"
    }
}

struct MessageUpdate: Codable {
    let content: String
    let isEdited: Bool
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case content
        case isEdited = "is_edited"
        case updatedAt = "updated_at"
    }
}

struct MessageDelete: Codable {
    let isDeleted: Bool
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case isDeleted = "is_deleted"
        case updatedAt = "updated_at"
    }
}

struct ConversationUpdate: Codable {
    let lastMessagePreview: String
    let lastMessageAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case lastMessagePreview = "last_message_preview"
        case lastMessageAt = "last_message_at"
        case updatedAt = "updated_at"
    }
}

enum MessageContentType: String, Codable {
    case text
    case image
    case system
}