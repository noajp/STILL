//======================================================================
// MARK: - MessageSystemProtocols.swift
// Purpose: Protocol definitions for the message system migration
// Path: still/Core/Migration/MessageSystemProtocols.swift
//======================================================================

import Foundation
import Supabase

// MARK: - Data Access Layer Protocols

/**
 * Protocol for message data access operations.
 */
@MainActor
protocol MessageDataAccessProtocol {
    func fetchMessages(conversationId: String, limit: Int, offset: Int) async throws -> [MessageRecord]
    func insertMessage(_ record: MessageRecord) async throws -> MessageRecord
    func updateMessage(id: String, content: String) async throws -> MessageRecord
    func deleteMessage(id: String) async throws
    func markAsRead(messageId: String) async throws
    func updateConversationPreview(conversationId: String, lastMessagePreview: String, lastMessageAt: Date) async throws
}

/**
 * Protocol for conversation data access operations.
 */
@MainActor
protocol ConversationDataAccessProtocol {
    func fetchConversations(userId: String) async throws -> [ConversationRecord]
    func fetchConversation(id: String) async throws -> ConversationRecord?
    func createConversation(_ record: ConversationRecord) async throws -> ConversationRecord
    func updateConversation(_ record: ConversationRecord) async throws -> ConversationRecord
    func deleteConversation(id: String) async throws
    func addParticipant(conversationId: String, userId: String) async throws
    func removeParticipant(conversationId: String, userId: String) async throws
    func fetchConversationParticipants(conversationId: String) async throws -> [ConversationParticipant]
    func hideConversationForUser(conversationId: String, userId: String) async throws
}

/**
 * Protocol for realtime data access operations.
 */
@MainActor
protocol RealtimeDataAccessProtocol {
    func subscribeToMessages(
        conversationId: String,
        onMessage: @escaping @Sendable (MessageRecord) -> Void
    ) async throws -> SubscriptionToken
    
    func subscribeToConversations(
        userId: String,
        onUpdate: @escaping @Sendable (ConversationRecord) -> Void
    ) async throws -> SubscriptionToken
    
    func unsubscribe(token: SubscriptionToken) async
}

// MARK: - Business Logic Layer Protocols

/**
 * Protocol for message business logic operations.
 */
@MainActor
protocol MessageBusinessLogicProtocol {
    func sendMessage(
        conversationId: String,
        content: String,
        senderId: String
    ) async throws -> Message
    
    func fetchMessages(conversationId: String) async throws -> [Message]
    func markAsRead(messageId: String) async throws
    func deleteMessage(messageId: String, userId: String) async throws
    func editMessage(
        messageId: String,
        newContent: String,
        userId: String
    ) async throws -> Message
}

/**
 * Protocol for conversation business logic operations.
 */
@MainActor
protocol ConversationBusinessLogicProtocol {
    func createConversation(
        participantIds: [String],
        creatorId: String,
        name: String?
    ) async throws -> Conversation
    
    func fetchConversations(userId: String) async throws -> [Conversation]
    func updateConversationSettings(
        conversationId: String,
        settings: ConversationSettings?,
        userId: String
    ) async throws
    
    func addParticipants(
        conversationId: String,
        userIds: [String],
        requesterId: String
    ) async throws
    
    func leaveConversation(
        conversationId: String,
        userId: String
    ) async throws
}

/**
 * Protocol for encryption service operations.
 */
@MainActor
protocol EncryptionServiceProtocol {
    func encrypt(content: String, conversationId: String) async throws -> String
    func decrypt(encryptedContent: String, conversationId: String) async throws -> String
    func generateKeys(conversationId: String) async throws -> EncryptionKeys
}

// MARK: - Data Models

/**
 * Database record for messages.
 */
struct MessageRecord: Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let createdAt: Date
    let updatedAt: Date?
    let isEdited: Bool
    let isDeleted: Bool
    let metadata: [String: String]?
    let encryptionType: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isEdited = "is_edited"
        case isDeleted = "is_deleted"
        case metadata
        case encryptionType = "encryption_type"
    }
}

/**
 * Database record for conversations.
 */
struct ConversationRecord: Codable {
    let id: String
    let createdAt: Date
    let updatedAt: Date
    let lastMessageAt: Date?
    let lastMessagePreview: String?
    let isGroup: Bool
    let groupName: String?
    let groupDescription: String?
    let groupAvatarUrl: String?
    let createdBy: String?
    let settings: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastMessageAt = "last_message_at"
        case lastMessagePreview = "last_message_preview"
        case isGroup = "is_group"
        case groupName = "group_name"
        case groupDescription = "group_description"
        case groupAvatarUrl = "group_avatar_url"
        case createdBy = "created_by"
        case settings
    }
}

/**
 * Encryption keys for a conversation.
 */
struct EncryptionKeys {
    let publicKey: String
    let privateKey: String
    let conversationId: String
}

/**
 * Subscription token for realtime updates.
 */
struct SubscriptionToken {
    let id: String
    let channel: String
}

/**
 * Conversation settings.
 */
struct ConversationSettings: Codable {
    var muteNotifications: Bool = false
    var theme: ConversationTheme?
    var autoDeleteMessages: Bool = false
    var autoDeleteDuration: TimeInterval?
}

/**
 * Conversation theme.
 */
struct ConversationTheme: Codable {
    let primaryColor: String
    let backgroundImage: String?
    let emoji: String?
}

/**
 * User information for display.
 */
struct UserInfo: Identifiable, Codable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let isOnline: Bool = false
    let lastSeen: Date?
}

// MARK: - Error Types

/**
 * Message-related errors.
 */
enum MessageError: LocalizedError {
    case unauthorized
    case messageNotFound
    case invalidContent
    case encryptionFailed
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "User is not authorized to perform this action"
        case .messageNotFound:
            return "Message not found"
        case .invalidContent:
            return "Invalid message content"
        case .encryptionFailed:
            return "Failed to encrypt message"
        case .decryptionFailed:
            return "Failed to decrypt message"
        }
    }
}

/**
 * Conversation-related errors.
 */
enum ConversationError: LocalizedError {
    case notFound
    case unauthorized
    case invalidParticipants
    case alreadyExists
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Conversation not found"
        case .unauthorized:
            return "User is not authorized to access this conversation"
        case .invalidParticipants:
            return "Invalid participants for conversation"
        case .alreadyExists:
            return "Conversation already exists"
        }
    }
}