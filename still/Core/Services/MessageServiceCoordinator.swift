//======================================================================
// MARK: - MessageServiceCoordinator.swift  
// Purpose: Main facade service that coordinates all messaging operations
// Path: still/Core/Services/MessageServiceCoordinator.swift
//======================================================================

import Foundation
import Combine

/// DEPRECATED: Legacy MessageServiceCoordinator - DO NOT USE
/// This service contains circular dependencies and is being phased out.
/// Use MessageSystemFacade.shared instead for coordinated messaging operations.
/// 
/// Migration Path:
/// - MessageServiceCoordinator.shared → MessageSystemFacade.shared
/// - All messaging operations should go through the new layered architecture
@available(*, deprecated, message: "Use MessageSystemFacade.shared instead")
@MainActor
class MessageServiceCoordinator: ObservableObject {
    
    // MARK: - Singleton Instance
    
    static let shared = MessageServiceCoordinator()
    
    // MARK: - Service Dependencies
    
    private let repository = MessageRepository()
    private let conversationManager = ConversationManager()
    private let encryptionService = MessageEncryptionService()
    private let realtimeManager = RealtimeSubscriptionManager()
    
    // MARK: - Published Properties
    
    /// Number of conversations with unread messages
    @Published var unreadConversationsCount: Int = 0
    
    /// Real-time connection status
    @Published var isConnected: Bool = false
    
    // MARK: - Initialization
    
    private init() {
        setupBindings()
    }
    
    // MARK: - Conversation Operations
    
    /// Fetch all conversations for the current user
    func fetchConversations() async throws -> [Conversation] {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageServiceCoordinator", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await conversationManager.fetchConversations(for: currentUserId)
    }
    
    /// Get or create a direct conversation with another user
    func getOrCreateDirectConversation(with userId: String) async throws -> String {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageServiceCoordinator", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await conversationManager.getOrCreateDirectConversation(
            currentUserId: currentUserId,
            with: userId
        )
    }
    
    /// Mark a conversation as read
    func markConversationAsRead(_ conversationId: String) async throws {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        
        try await conversationManager.markConversationAsRead(conversationId, userId: userId)
        
        // Trigger unread count update
        realtimeManager.updateUnreadCountImmediately()
    }
    
    /// Delete a conversation from current user's view
    func deleteConversation(_ conversationId: String) async throws {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageServiceCoordinator", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await conversationManager.deleteConversation(conversationId, userId: currentUserId)
    }
    
    // MARK: - Message Operations
    
    /// Fetch messages for a conversation
    func fetchMessages(for conversationId: String, limit: Int = 50, before: Date? = nil) async throws -> [Message] {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageServiceCoordinator", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await conversationManager.fetchMessages(
            for: conversationId,
            limit: limit,
            before: before,
            userId: userId
        )
    }
    
    /// Send a message to a conversation
    func sendMessage(to conversationId: String, content: String) async throws -> Message {
        guard let userId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageServiceCoordinator", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let message = try await conversationManager.sendMessage(
            to: conversationId,
            content: content,
            senderId: userId
        )
        
        // Trigger unread count update for all users
        realtimeManager.updateUnreadCountImmediately()
        
        return message
    }
    
    /// Edit a message
    func editMessage(_ messageId: String, newContent: String) async throws {
        try await conversationManager.editMessage(messageId, newContent: newContent)
    }
    
    // MARK: - Group Chat Operations
    
    /// Create a new group chat
    func createGroupChat(name: String, description: String? = nil, memberIds: [String] = []) async throws -> String {
        return try await conversationManager.createGroupConversation(
            name: name,
            description: description,
            memberIds: memberIds
        )
    }
    
    /// Fetch group conversations for current user
    func fetchGroupConversations() async throws -> [GroupConversation] {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "MessageServiceCoordinator", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await conversationManager.fetchGroupConversations(for: currentUserId)
    }
    
    /// Add member to group chat
    func addGroupMember(conversationId: String, userId: String) async throws -> Bool {
        return try await conversationManager.addMemberToGroup(
            conversationId: conversationId,
            userId: userId
        )
    }
    
    /// Remove member from group chat  
    func removeGroupMember(conversationId: String, userId: String) async throws -> Bool {
        return try await conversationManager.removeMemberFromGroup(
            conversationId: conversationId,
            userId: userId
        )
    }
    
    /// Get group members
    func getGroupMembers(conversationId: String) async throws -> [GroupMember] {
        return try await conversationManager.getGroupMembers(conversationId: conversationId)
    }
    
    // MARK: - Real-time & State Management
    
    /// Start real-time subscriptions
    func startRealtimeSubscriptions() {
        realtimeManager.startSubscriptions()
    }
    
    /// Stop real-time subscriptions
    func stopRealtimeSubscriptions() {
        realtimeManager.stopSubscriptions()
    }
    
    /// Force refresh of unread count
    func refreshUnreadCount() {
        realtimeManager.updateUnreadCountImmediately()
    }
    
    /// Manual data refresh
    func refreshData() {
        realtimeManager.refreshData()
    }
    
    // MARK: - Encryption Operations
    
    /// Check if user has encryption key
    func hasEncryptionKey() -> Bool {
        return encryptionService.hasUserKey()
    }
    
    /// Generate new encryption key for user
    func generateNewEncryptionKey() throws {
        _ = try encryptionService.generateNewUserKey()
    }
    
    // MARK: - Private Methods
    
    /// Setup bindings between services
    private func setupBindings() {
        // Bind realtime manager's published properties to coordinator
        realtimeManager.$unreadConversationsCount
            .receive(on: DispatchQueue.main)
            .assign(to: &$unreadConversationsCount)
        
        realtimeManager.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)
    }
    
    // MARK: - Legacy Support Methods
    
    /// Cleanup user session (for logout scenarios)
    func cleanupUserSession() {
        stopRealtimeSubscriptions()
    }
}

// MARK: - Backward Compatibility

/// Legacy MessageService methods for gradual migration
extension MessageServiceCoordinator {
    
    /// Legacy method name for unread count updates  
    @available(*, deprecated, renamed: "refreshUnreadCount")
    func updateUnreadCount() async {
        refreshUnreadCount()
    }
    
    /// Legacy method for setting up real-time
    @available(*, deprecated, renamed: "startRealtimeSubscriptions")
    func setupRealtimeSubscriptions() {
        startRealtimeSubscriptions()
    }
}