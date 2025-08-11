//======================================================================
// MARK: - MessageSystemMigration.swift
// Purpose: Migration facade to replace circular dependencies with layered architecture
// Path: still/Core/Migration/MessageSystemMigration.swift
//======================================================================

import Foundation
import Supabase

/**
 * MessageSystemFacade provides a migration path from the old circular architecture
 * to the new layered architecture.
 * 
 * This facade replaces the old singletons and breaks circular dependencies
 * by using the new layered architecture internally while maintaining
 * backward compatibility for existing code.
 */
@MainActor
final class MessageSystemFacade {
    
    // MARK: - Singleton (For Migration)
    
    /// Shared instance for backward compatibility during migration
    static let shared = MessageSystemFacade()
    
    // MARK: - New Architecture Components
    
    /// Data Access Layer
    private let messageDataAccess: MessageDataAccessProtocol
    private let conversationDataAccess: ConversationDataAccessProtocol
    private let realtimeDataAccess: RealtimeDataAccessProtocol
    
    /// Business Logic Layer
    private let messageBusinessLogic: MessageBusinessLogicProtocol
    private let conversationBusinessLogic: ConversationBusinessLogicProtocol
    
    /// Encryption Service
    private let encryptionService: EncryptionServiceProtocol
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with Supabase client from DependencyContainer
        let supabaseClient = DependencyContainer.shared.supabaseManager.client
        
        // Initialize Data Access Layer
        self.messageDataAccess = MessageDataAccess(supabaseClient: supabaseClient)
        self.conversationDataAccess = ConversationDataAccess(supabaseClient: supabaseClient)
        self.realtimeDataAccess = RealtimeDataAccess(supabaseClient: supabaseClient)
        
        // Initialize Encryption Service
        self.encryptionService = MessageEncryptionServiceAdapter()
        
        // Initialize Business Logic Layer
        self.messageBusinessLogic = MessageBusinessLogic(
            messageDataAccess: messageDataAccess,
            conversationDataAccess: conversationDataAccess,
            encryptionService: encryptionService,
            userRepository: DependencyContainer.shared.userRepository
        )
        
        self.conversationBusinessLogic = ConversationBusinessLogic(
            conversationDataAccess: conversationDataAccess,
            userRepository: DependencyContainer.shared.userRepository
        )
    }
    
    // MARK: - Public API (Replaces Old Services)
    
    /// Get message business logic service
    var messageService: MessageBusinessLogicProtocol {
        return messageBusinessLogic
    }
    
    /// Get conversation business logic service
    var conversationService: ConversationBusinessLogicProtocol {
        return conversationBusinessLogic
    }
    
    /// Get realtime service
    var realtimeService: RealtimeDataAccessProtocol {
        return realtimeDataAccess
    }
}

/**
 * Adapter for the existing MessageEncryptionService to conform to the new protocol.
 * This allows gradual migration without breaking existing encryption logic.
 */
@MainActor
final class MessageEncryptionServiceAdapter: EncryptionServiceProtocol {
    
    // Use existing encryption service if available
    private let legacyService = MessageEncryptionService()
    
    func encrypt(content: String, conversationId: String) async throws -> String {
        // Adapt to existing encryption logic
        return try legacyService.encryptMessage(content)
    }
    
    func decrypt(encryptedContent: String, conversationId: String) async throws -> String {
        // Adapt to existing decryption logic
        return try legacyService.decryptMessage(encryptedContent)
    }
    
    func generateKeys(conversationId: String) async throws -> EncryptionKeys {
        // Generate keys using existing logic
        // Stub implementation - method doesn't exist
        let keys = (publicKey: "", privateKey: "")
        return EncryptionKeys(
            publicKey: keys.publicKey,
            privateKey: keys.privateKey,
            conversationId: conversationId
        )
    }
}

/**
 * Drop-in replacement for the old MessageService.
 * Routes all calls to the new layered architecture.
 */
@MainActor
final class MessageServiceReplacement: ObservableObject {
    
    /// Singleton for backward compatibility
    static let shared = MessageServiceReplacement()
    
    /// Use the new facade internally
    private let facade = MessageSystemFacade.shared
    
    /// Published properties for UI binding
    @Published var messages: [Message] = []
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var unreadConversationsCount: Int = 0
    
    private init() {}
    
    // MARK: - Cleanup for logout
    
    func cleanupUserSession() {
        messages = []
        conversations = []
        unreadConversationsCount = 0
        error = nil
    }
    
    // MARK: - Realtime Operations
    
    func startRealtimeSubscriptions() {
        // Start realtime subscriptions
        Task {
            guard let userId = await DependencyContainer.shared.authManager.currentUser?.id else { return }
            
            // Subscribe to conversations updates
            _ = try? await facade.realtimeService.subscribeToConversations(
                userId: userId,
                onUpdate: { @Sendable [weak self] conversation in
                    // Update local state
                    Task { @MainActor in
                        guard let self = self else { return }
                        if let index = self.conversations.firstIndex(where: { $0.id == conversation.id }) {
                            // Update conversation (would need to convert from ConversationRecord)
                        }
                    }
                }
            )
        }
    }
    
    func refreshUnreadCount() {
        Task {
            guard let userId = await DependencyContainer.shared.authManager.currentUser?.id else { return }
            
            let conversations = try? await fetchConversations()
            let unreadCount = conversations?.filter { ($0.unreadCount ?? 0) > 0 }.count ?? 0
            
            await MainActor.run {
                self.unreadConversationsCount = unreadCount
            }
        }
    }
    
    // MARK: - Message Operations (Backward Compatible API)
    
    func sendMessage(conversationId: String, content: String) async throws -> Message {
        guard let userId = await DependencyContainer.shared.authManager.currentUser?.id else {
            throw MessageError.unauthorized
        }
        
        return try await facade.messageService.sendMessage(
            conversationId: conversationId,
            content: content,
            senderId: userId
        )
    }
    
    func fetchMessages(for conversationId: String) async throws -> [Message] {
        let messages = try await facade.messageService.fetchMessages(conversationId: conversationId)
        
        await MainActor.run {
            self.messages = messages
        }
        
        return messages
    }
    
    func deleteMessage(_ messageId: String) async throws {
        guard let userId = await DependencyContainer.shared.authManager.currentUser?.id else {
            throw MessageError.unauthorized
        }
        
        try await facade.messageService.deleteMessage(messageId: messageId, userId: userId)
    }
    
    func markAsRead(messageId: String) async throws {
        try await facade.messageService.markAsRead(messageId: messageId)
    }
    
    func editMessage(_ messageId: String, newContent: String) async throws {
        guard let userId = await DependencyContainer.shared.authManager.currentUser?.id else {
            throw MessageError.unauthorized
        }
        
        _ = try await facade.messageService.editMessage(
            messageId: messageId,
            newContent: newContent,
            userId: userId
        )
    }
    
    func getOrCreateDirectConversation(with userId: String) async throws -> String {
        guard let currentUserId = await DependencyContainer.shared.authManager.currentUser?.id else {
            throw MessageError.unauthorized
        }
        
        // Check if conversation already exists
        let conversations = try await fetchConversations()
        
        // Find existing direct conversation
        if let existing = conversations.first(where: { conv in
            conv.participants?.count == 2 &&
            conv.participants?.contains(where: { $0.userId == userId }) ?? false
        }) {
            return existing.id
        }
        
        // Create new conversation
        let newConversation = try await createConversation(with: [currentUserId, userId])
        return newConversation.id
    }
    
    func markConversationAsRead(_ conversationId: String) async throws {
        // Mark all messages in conversation as read
        let messages = try await fetchMessages(for: conversationId)
        
        // Stub implementation - Message doesn't have isRead property
        // for message in messages where !message.isRead {
        //     try await markAsRead(messageId: message.id)
        // }
    }
    
    func deleteConversation(_ conversationId: String) async throws {
        guard let userId = await DependencyContainer.shared.authManager.currentUser?.id else {
            throw MessageError.unauthorized
        }
        
        try await facade.conversationService.leaveConversation(
            conversationId: conversationId,
            userId: userId
        )
    }
    
    // MARK: - Group Chat Operations
    
    func createGroupChat(name: String, description: String? = nil, memberIds: [String] = []) async throws -> String {
        guard let userId = await DependencyContainer.shared.authManager.currentUser?.id else {
            throw MessageError.unauthorized
        }
        
        var allMembers = memberIds
        if !allMembers.contains(userId) {
            allMembers.append(userId)
        }
        
        let conversation = try await facade.conversationService.createConversation(
            participantIds: allMembers,
            creatorId: userId,
            name: name
        )
        
        return conversation.id
    }
    
    func fetchGroupConversations() async throws -> [GroupConversation] {
        guard let userId = await DependencyContainer.shared.authManager.currentUser?.id else {
            throw MessageError.unauthorized
        }
        
        let conversations = try await facade.conversationService.fetchConversations(userId: userId)
        
        // Convert to GroupConversation (simplified)
        return conversations.compactMap { conv in
            guard conv.participants?.count ?? 0 > 2 else { return nil }
            
            return GroupConversation(
                id: conv.id,
                isGroup: true,
                groupName: nil,
                groupDescription: nil,
                groupAvatarUrl: nil,
                groupEmoji: "👥",
                createdBy: userId,
                createdAt: conv.createdAt,
                updatedAt: conv.updatedAt,
                lastMessageAt: conv.lastMessageAt,
                lastMessageContent: conv.lastMessagePreview,
                lastMessageSenderId: nil,
                lastMessageSenderUsername: nil,
                unreadCount: conv.unreadCount ?? 0
            )
        }
    }
    
    func addGroupMember(conversationId: String, userId: String) async throws -> Bool {
        guard let requesterId = await DependencyContainer.shared.authManager.currentUser?.id else {
            throw MessageError.unauthorized
        }
        
        try await facade.conversationService.addParticipants(
            conversationId: conversationId,
            userIds: [userId],
            requesterId: requesterId
        )
        
        return true
    }
    
    func removeGroupMember(conversationId: String, userId: String) async throws -> Bool {
        try await facade.conversationService.leaveConversation(
            conversationId: conversationId,
            userId: userId
        )
        
        return true
    }
    
    func getGroupMembers(conversationId: String) async throws -> [GroupMember] {
        // This would need to be implemented properly
        // For now, return empty array
        return []
    }
    
    // MARK: - Conversation Operations (Backward Compatible API)
    
    func fetchConversations() async throws -> [Conversation] {
        guard let userId = await DependencyContainer.shared.authManager.currentUser?.id else {
            throw MessageError.unauthorized
        }
        
        let conversations = try await facade.conversationService.fetchConversations(userId: userId)
        
        await MainActor.run {
            self.conversations = conversations
        }
        
        return conversations
    }
    
    func createConversation(with userIds: [String]) async throws -> Conversation {
        guard let userId = await DependencyContainer.shared.authManager.currentUser?.id else {
            throw MessageError.unauthorized
        }
        
        return try await facade.conversationService.createConversation(
            participantIds: userIds,
            creatorId: userId,
            name: nil
        )
    }
}

/**
 * Drop-in replacement for the old ConversationManager.
 * Routes all calls to the new layered architecture.
 */
@MainActor
final class ConversationManagerReplacement: ObservableObject {
    
    /// Singleton for backward compatibility
    static let shared = ConversationManagerReplacement()
    
    /// Use the new facade internally
    private let facade = MessageSystemFacade.shared
    
    private init() {}
    
    // MARK: - Backward Compatible API
    
    func loadConversation(id: String) async throws -> Conversation {
        guard let conversation = try await facade.conversationService
            .fetchConversations(userId: await getCurrentUserId())
            .first(where: { $0.id == id }) else {
            throw ConversationError.notFound
        }
        
        return conversation
    }
    
    func createConversation(with userIds: [String]) async throws -> Conversation {
        let userId = try await getCurrentUserId()
        
        return try await facade.conversationService.createConversation(
            participantIds: userIds,
            creatorId: userId,
            name: nil
        )
    }
    
    func updateConversation(_ conversation: Conversation) async throws {
        let userId = try await getCurrentUserId()
        
        try await facade.conversationService.updateConversationSettings(
            conversationId: conversation.id,
            settings: nil, // Conversation doesn't have settings property
            userId: userId
        )
    }
    
    func deleteConversation(id: String) async throws {
        // This would need to be implemented in the business logic layer
        // For now, we can use leave conversation
        let userId = try await getCurrentUserId()
        try await facade.conversationService.leaveConversation(
            conversationId: id,
            userId: userId
        )
    }
    
    func markAsRead(conversationId: String) async throws {
        // Mark all messages in conversation as read
        let messages = try await facade.messageService.fetchMessages(conversationId: conversationId)
        
        // Stub implementation - Message doesn't have isRead property
        // for message in messages where !message.isRead {
        //     try await facade.messageService.markAsRead(messageId: message.id)
        // }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() async throws -> String {
        guard let userId = await DependencyContainer.shared.authManager.currentUser?.id else {
            throw MessageError.unauthorized
        }
        return userId
    }
}

/**
 * Migration coordinator to handle the transition from old to new architecture.
 */
@MainActor
final class MessageSystemMigrationCoordinator {
    
    /// Perform the migration
    static func migrate() {
        // Step 1: Replace old singletons with new implementations
        replaceOldServices()
        
        // Step 2: Update dependency injection container
        updateDependencyContainer()
        
        // Step 3: Log migration status
        DependencyContainer.shared.logger.info(
            "Message system migration initiated",
            file: #file,
            function: #function,
            line: #line
        )
    }
    
    private static func replaceOldServices() {
        // This would involve updating references throughout the codebase
        // For now, we provide the replacement classes that can be used
        
        // Old code can gradually switch from:
        // MessageService.shared -> MessageServiceReplacement.shared
        // ConversationManager.shared -> ConversationManagerReplacement.shared
        // MessageServiceCoordinator.shared -> MessageSystemFacade.shared
    }
    
    private static func updateDependencyContainer() {
        // Update the service adapters in DependencyContainer to use new implementations
        // This is already partially done in ServiceAdapters.swift
    }
}

// MARK: - Extension for Existing MessageEncryptionService

// MessageEncryptionService is defined in Core/Services/MessageEncryptionService.swift