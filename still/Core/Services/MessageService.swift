//======================================================================
// MARK: - MessageService.swift
// Purpose: Legacy message service - DEPRECATED in favor of MessageServiceCoordinator
// Path: still/Core/Services/MessageService.swift
//======================================================================
import Foundation
import Supabase
import Combine

/// DEPRECATED: Legacy MessageService - DO NOT USE
/// This service contains circular dependencies and is being phased out.
/// Use MessageServiceReplacement.shared or MessageSystemFacade.shared instead.
/// 
/// Migration Path:
/// - MessageService.shared → MessageServiceReplacement.shared
/// - Or use MessageSystemFacade.shared.messageService for new architecture
@available(*, deprecated, message: "Use MessageServiceReplacement.shared or MessageSystemFacade.shared instead")
@MainActor
class MessageService: ObservableObject {
    static let shared = MessageService()
    
    // MARK: - Migration to New Architecture
    
    // Use the replacement instead of coordinator to avoid circular dependency
    private let replacement = MessageServiceReplacement.shared
    
    // MARK: - Legacy Properties (Forwarded to Coordinator)
    
    /// Unread conversations count - forwarded from coordinator
    @Published var unreadConversationsCount: Int = 0
    
    // MARK: - Private Legacy Properties (Deprecated)
    
    private let supabase = SupabaseManager.shared.client
    private var updateTimer: Timer?
    
    private init() {
        setupCoordinatorBinding()
        setupAuthenticationListener()
    }
    
    /// Setup binding to forward replacement properties
    private func setupCoordinatorBinding() {
        // Forward unread count from replacement
        replacement.$unreadConversationsCount
            .receive(on: DispatchQueue.main)
            .assign(to: &$unreadConversationsCount)
    }
    
    private func setupAuthenticationListener() {
        // Listen for authentication changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthStateChanged),
            name: .authStateChanged,
            object: nil
        )
        
        // Setup immediately if user is already authenticated
        if AuthManager.shared.currentUser != nil {
            setupRealtimeSubscriptions()
        }
    }
    
    @objc private func handleAuthStateChanged() {
        if AuthManager.shared.currentUser != nil {
            // User logged in - setup subscriptions
            setupRealtimeSubscriptions()
        } else {
            // User logged out - cleanup and reset state
            cleanupUserSession()
        }
    }
    
    private func cleanupUserSession() {
        replacement.cleanupUserSession()
        updateTimer?.invalidate()
        updateTimer = nil
        unreadConversationsCount = 0
        objectWillChange.send()
    }
    
    deinit {
        // Timer will be automatically cleaned up when the object is deallocated
    }
    
    // MARK: - Realtime Setup (Forwarded to Coordinator)
    
    private func setupRealtimeSubscriptions() {
        replacement.startRealtimeSubscriptions()
        startPollingForUpdates()
    }
    
    private func startPollingForUpdates() {
        updateTimer?.invalidate()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.replacement.refreshUnreadCount()
            }
        }
        
        replacement.refreshUnreadCount()
    }
    
    private func setupSupabaseRealtime() {
        // Handled by RealtimeSubscriptionManager
    }
    
    private func checkForUpdates() async {
        replacement.refreshUnreadCount()
    }
    
    // MARK: - Legacy API Methods (Forwarded to Coordinator)
    
    /// Fetch all conversations for the current user
    /// DEPRECATED: Use MessageServiceCoordinator.shared.fetchConversations() instead
    func fetchConversations() async throws -> [Conversation] {
        return try await replacement.fetchConversations()
    }
    
    /// Get or create a direct conversation with another user
    /// DEPRECATED: Use MessageServiceCoordinator.shared.getOrCreateDirectConversation() instead
    func getOrCreateDirectConversation(with userId: String) async throws -> String {
        return try await replacement.getOrCreateDirectConversation(with: userId)
    }
    
    /// Fetch messages for a conversation
    /// DEPRECATED: Use MessageServiceCoordinator.shared.fetchMessages() instead
    func fetchMessages(for conversationId: String, limit: Int = 50, before: Date? = nil) async throws -> [Message] {
        return try await replacement.fetchMessages(for: conversationId)
    }
    
    /// Send a message
    /// DEPRECATED: Use MessageServiceCoordinator.shared.sendMessage() instead
    func sendMessage(to conversationId: String, content: String) async throws -> Message {
        return try await replacement.sendMessage(conversationId: conversationId, content: content)
    }
    
    /// Mark a conversation as read
    /// DEPRECATED: Use MessageServiceCoordinator.shared.markConversationAsRead() instead
    func markConversationAsRead(_ conversationId: String) async throws {
        try await replacement.markConversationAsRead(conversationId)
    }
    
    /// Edit a message
    /// DEPRECATED: Use MessageServiceCoordinator.shared.editMessage() instead
    func editMessage(_ messageId: String, newContent: String) async throws {
        try await replacement.editMessage(messageId, newContent: newContent)
    }
    
    /// Delete a conversation from current user's view only (soft delete)
    /// DEPRECATED: Use MessageServiceCoordinator.shared.deleteConversation() instead
    func deleteConversation(_ conversationId: String) async throws {
        try await replacement.deleteConversation(conversationId)
    }
    
    // MARK: - Group Chat Functions (Forwarded to Coordinator)
    
    /// Create a new group chat
    /// DEPRECATED: Use MessageServiceCoordinator.shared.createGroupChat() instead
    func createGroupChat(name: String, description: String? = nil, memberIds: [String] = []) async throws -> String {
        return try await replacement.createGroupChat(name: name, description: description, memberIds: memberIds)
    }
    
    /// Fetch group conversations for current user
    /// DEPRECATED: Use MessageServiceCoordinator.shared.fetchGroupConversations() instead
    func fetchGroupConversations() async throws -> [GroupConversation] {
        return try await replacement.fetchGroupConversations()
    }
    
    /// Add member to group chat
    /// DEPRECATED: Use MessageServiceCoordinator.shared.addGroupMember() instead
    func addGroupMember(conversationId: String, userId: String) async throws -> Bool {
        return try await replacement.addGroupMember(conversationId: conversationId, userId: userId)
    }
    
    /// Remove member from group chat
    /// DEPRECATED: Use MessageServiceCoordinator.shared.removeGroupMember() instead
    func removeGroupMember(conversationId: String, userId: String) async throws -> Bool {
        return try await replacement.removeGroupMember(conversationId: conversationId, userId: userId)
    }
    
    /// Get group members
    /// DEPRECATED: Use MessageServiceCoordinator.shared.getGroupMembers() instead
    func getGroupMembers(conversationId: String) async throws -> [GroupMember] {
        return try await replacement.getGroupMembers(conversationId: conversationId)
    }
}