//======================================================================
// MARK: - MessagesViewModel.swift
// Purpose: View model for managing conversations and messaging functionality
// Path: still/Features/Messages/ViewModels/MessagesViewModel.swift
//======================================================================

import Foundation
import SwiftUI
import Combine

// MARK: - Notification Extensions

/**
 * Notification names for messaging system communication.
 */
extension Notification.Name {
    /// Posted when a conversation is marked as read
    static let conversationMarkedAsRead = Notification.Name("conversationMarkedAsRead")
    
    /// Posted when a new message is sent
    static let messageWasSent = Notification.Name("messageWasSent")
}

/**
 * MessagesViewModel manages conversation lists and messaging operations.
 * 
 * This view model handles:
 * - Loading and caching conversation lists (direct and group)
 * - Real-time updates for message status and new messages
 * - Conversation creation and management
 * - Group chat functionality
 * - Timestamp formatting for message display
 * - Silent refresh operations to prevent UI flickering
 * 
 * The view model maintains separate lists for direct conversations and group chats,
 * and provides efficient caching with real-time synchronization.
 */
@MainActor
class MessagesViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// List of direct conversations (one-on-one chats)
    @Published var conversations: [Conversation] = []
    
    /// List of group conversations (multi-participant chats)
    @Published var groupConversations: [GroupConversation] = []
    
    /// Loading state for conversation operations
    @Published var isLoading = false
    
    /// Current error message to display to user
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Service for message and conversation operations
    private let messageService = MessageService.shared
    
    /// Flag to prevent redundant initial loads
    private var hasLoadedInitially = false
    
    /// Combine subscriptions for memory management
    private var cancellables = Set<AnyCancellable>()
    
    /// Current conversation loading task for cancellation
    private var conversationLoadTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /**
     * Initializes the messages view model with real-time listeners.
     */
    init() {
        Task {
            await loadConversationsIfNeeded()
        }
        
        // Setup real-time message and status listeners
        setupRealtimeListeners()
        
        // Reset state when authentication changes
        NotificationCenter.default.publisher(for: .authStateChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.hasLoadedInitially = false
                self?.conversations = []
                Task {
                    await self?.loadConversationsIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Real-time Listeners
    
    /**
     * Sets up notification listeners for real-time conversation updates.
     */
    private func setupRealtimeListeners() {
        // Listen for conversation read status changes
        NotificationCenter.default.publisher(for: .conversationMarkedAsRead)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let conversationId = notification.object as? String else { return }
                
                // Update the specific conversation's unread count to 0
                if let index = self.conversations.firstIndex(where: { $0.id == conversationId }) {
                    self.conversations[index].unreadCount = 0
                    // Force UI update
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
        
        // Listen for new messages sent
        NotificationCenter.default.publisher(for: .messageWasSent)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let message = notification.object as? Message else { return }
                
                // Update conversation with new message immediately
                self.updateConversationWithNewMessage(message)
            }
            .store(in: &cancellables)
    }
    
    /**
     * Updates a conversation in the local list and re-sorts by recency.
     * 
     * - Parameter updatedConversation: The updated conversation to replace
     */
    private func updateConversationInList(_ updatedConversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == updatedConversation.id }) {
            conversations[index] = updatedConversation
            // Re-sort by last message time (most recent first)
            conversations.sort { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }
        }
    }
    
    /**
     * Updates conversation with new message and moves it to top of list.
     * 
     * - Parameter message: The new message to incorporate
     */
    private func updateConversationWithNewMessage(_ message: Message) {
        if let index = conversations.firstIndex(where: { $0.id == message.conversationId }) {
            // Update last message preview and timestamp
            conversations[index].lastMessagePreview = message.content  // Note: This is encrypted content
            conversations[index].lastMessageAt = message.createdAt
            
            // Move conversation to top of list for recency
            let updatedConversation = conversations.remove(at: index)
            conversations.insert(updatedConversation, at: 0)
            
            // Force UI update
            objectWillChange.send()
        }
    }
    
    // MARK: - Conversation Loading
    
    /**
     * Loads conversations only if they haven't been loaded initially.
     * 
     * This method prevents redundant API calls by checking the load status.
     */
    func loadConversationsIfNeeded() async {
        // Skip if already loaded to avoid redundant API calls
        guard !hasLoadedInitially else { 
            return 
        }
        await loadConversations()
    }
    
    /**
     * Loads conversations from the server with cancellation support.
     * 
     * This method fetches both direct and group conversations concurrently
     * and handles cancellation gracefully for better user experience.
     */
    func loadConversations() async {
        // Cancel any existing load operation
        conversationLoadTask?.cancel()
        
        conversationLoadTask = Task {
            isLoading = true
            errorMessage = nil
            
            do {
                // Check if task was cancelled
                try Task.checkCancellation()
                
                // Fetch both conversation types concurrently
                async let directConversations = messageService.fetchConversations()
                async let groupChats = messageService.fetchGroupConversations()
                
                // Check if task was cancelled before updating UI
                try Task.checkCancellation()
                
                conversations = try await directConversations
                groupConversations = try await groupChats
                
                print("📋 MessagesViewModel - Loaded \(conversations.count) direct conversations and \(groupConversations.count) group chats")
                hasLoadedInitially = true
            } catch is CancellationError {
                print("🔄 MessagesViewModel - Load conversations was cancelled")
                return
            } catch {
                print("❌ MessagesViewModel - Failed to load conversations: \(error.localizedDescription)")
                errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
        
        await conversationLoadTask?.value
    }
    
    /**
     * Forces a refresh of the conversation list.
     * 
     * Used when returning from chat rooms or when explicit refresh is needed.
     * Shows loading indicators during the refresh process.
     */
    func refreshConversations() async {
        await loadConversations()
    }
    
    /**
     * Silently refreshes conversations without loading indicators.
     * 
     * This method updates conversations in the background with smooth animations
     * to prevent UI flickering. Errors are handled silently to maintain existing data.
     */
    func silentRefreshConversations() async {
        // Update in background without loading indicators
        do {
            async let newDirectConversations = messageService.fetchConversations()
            async let newGroupConversations = messageService.fetchGroupConversations()
            
            let directChats = try await newDirectConversations
            let groupChats = try await newGroupConversations
            
            // Update UI on main thread with smooth animation
            withAnimation(.easeInOut(duration: 0.2)) {
                conversations = directChats
                groupConversations = groupChats
            }
        } catch {
            // Fail silently to maintain existing data on error
        }
    }
    
    // MARK: - Conversation Management
    
    /**
     * Creates a new direct conversation with the specified user.
     * 
     * - Parameter userId: ID of the user to start conversation with
     * - Returns: Conversation ID if successful, nil otherwise
     */
    func createNewConversation(with userId: String) async -> String? {
        do {
            let conversationId = try await messageService.getOrCreateDirectConversation(with: userId)
            
            // Force fresh data retrieval
            hasLoadedInitially = false
            await refreshConversations()
            
            // Wait briefly and verify conversation was added
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if new conversation appears in list
            if !conversations.contains(where: { $0.id == conversationId }) {
                // Retry refresh if conversation not yet visible
                await refreshConversations()
            }
            
            print("✅ New conversation created: \(conversationId)")
            return conversationId
        } catch {
            errorMessage = "Failed to create conversation: \(error.localizedDescription)"
            print("❌ Failed to create conversation: \(error)")
            return nil
        }
    }
    
    // MARK: - Utility Methods
    
    /**
     * Formats a timestamp for display in conversation list.
     * 
     * Provides human-readable relative time formatting:
     * - Under 1 minute: "Now"
     * - Under 1 hour: "X min ago"
     * - Under 24 hours: "X hours ago"
     * - Under 7 days: "X days ago"
     * - Older: "M/d" format
     * 
     * - Parameter date: The date to format
     * - Returns: Formatted time string
     */
    func formatTimestamp(_ date: Date?) -> String {
        guard let date = date else { return "" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        // Less than 1 minute
        if timeInterval < 60 {
            return "Now"
        }
        // Less than 1 hour (show minutes)
        else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) min ago"
        }
        // Less than 24 hours (show hours)
        else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) hours ago"
        }
        // Less than 7 days (show days)
        else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days) days ago"
        }
        // Older messages show date
        else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
    
    /**
     * Creates a group chat with specified members.
     * 
     * - Parameters:
     *   - name: Name of the group chat
     *   - memberIds: Array of user IDs to include in the group
     * - Returns: Conversation ID if successful, nil otherwise
     */
    func createGroupChat(name: String, with memberIds: [String]) async -> String? {
        do {
            // Create the group chat
            let conversationId = try await messageService.createGroupChat(
                name: name,
                description: nil,
                memberIds: memberIds
            )
            
            // Refresh conversation list to include new group
            await refreshConversations()
            
            return conversationId
        } catch {
            print("❌ Failed to create group chat: \(error)")
            errorMessage = "Failed to create group chat"
            return nil
        }
    }
    
    /**
     * Deletes a conversation from both server and local cache.
     * 
     * - Parameter conversationId: ID of conversation to delete
     */
    func deleteConversation(_ conversationId: String) async {
        do {
            try await messageService.deleteConversation(conversationId)
            // Remove from local lists immediately
            conversations.removeAll { $0.id == conversationId }
            groupConversations.removeAll { $0.id == conversationId }
        } catch {
            errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Group Chat Functions
    
    /**
     * Creates a group chat with optional description and members.
     * 
     * This is an overloaded version that supports description parameter.
     * 
     * - Parameters:
     *   - name: Name of the group chat
     *   - description: Optional description for the group
     *   - memberIds: Array of user IDs to include (defaults to empty)
     * - Returns: Conversation ID if successful, nil otherwise
     */
    func createGroupChat(name: String, description: String? = nil, memberIds: [String] = []) async -> String? {
        do {
            let conversationId = try await messageService.createGroupChat(
                name: name,
                description: description,
                memberIds: memberIds
            )
            
            // Refresh group conversations to include the new one
            await refreshConversations()
            
            return conversationId
        } catch {
            errorMessage = "Failed to create group chat: \(error.localizedDescription)"
            print("❌ Failed to create group chat: \(error)")
            return nil
        }
    }
    
    /**
     * Adds a member to an existing group chat.
     * 
     * - Parameters:
     *   - conversationId: ID of the group conversation
     *   - userId: ID of the user to add
     * - Returns: True if successful, false otherwise
     */
    func addGroupMember(conversationId: String, userId: String) async -> Bool {
        do {
            let success = try await messageService.addGroupMember(conversationId: conversationId, userId: userId)
            if success {
                await silentRefreshConversations()
            }
            return success
        } catch {
            errorMessage = "Failed to add member: \(error.localizedDescription)"
            return false
        }
    }
    
    /**
     * Removes a member from an existing group chat.
     * 
     * - Parameters:
     *   - conversationId: ID of the group conversation
     *   - userId: ID of the user to remove
     * - Returns: True if successful, false otherwise
     */
    func removeGroupMember(conversationId: String, userId: String) async -> Bool {
        do {
            let success = try await messageService.removeGroupMember(conversationId: conversationId, userId: userId)
            if success {
                await silentRefreshConversations()
            }
            return success
        } catch {
            errorMessage = "Failed to remove member: \(error.localizedDescription)"
            return false
        }
    }
}