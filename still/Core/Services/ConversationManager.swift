//======================================================================
// MARK: - ConversationManager.swift
// Purpose: Business logic layer for conversation management and orchestration
// Path: still/Core/Services/ConversationManager.swift
//======================================================================

import Foundation

/// DEPRECATED: Legacy ConversationManager - DO NOT USE
/// This service contains circular dependencies and is being phased out.
/// Use ConversationManagerReplacement.shared or MessageSystemFacade.shared instead.
/// 
/// Migration Path:
/// - ConversationManager.shared → ConversationManagerReplacement.shared
/// - Or use MessageSystemFacade.shared.conversationService for new architecture
@available(*, deprecated, message: "Use ConversationManagerReplacement.shared or MessageSystemFacade.shared instead")
@MainActor
class ConversationManager: ObservableObject {
    // DEPRECATED: These create circular dependencies
    private let repository = MessageRepository()
    private let encryption = MessageEncryptionService()
    
    // MARK: - Conversation Operations
    
    /// Fetch and transform conversations for display
    func fetchConversations(for userId: String) async throws -> [Conversation] {
        // Fetch raw conversation data from repository
        let conversationData = try await repository.fetchUserConversations(userId: userId)
        
        // Transform raw data into conversation objects
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
            
            // Create user profile if available
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
            }
            
            // Create participant if data is complete
            if let participantId = data.participantId,
               let participantUserId = data.participantUserId,
               let participantJoinedAt = data.participantJoinedAt {
                let participant = ConversationParticipant(
                    id: participantId,
                    conversationId: conversationId,
                    userId: participantUserId,
                    joinedAt: participantJoinedAt,
                    lastReadAt: data.participantLastReadAt,
                    hiddenForUser: nil,
                    user: userProfile
                )
                
                conversationDict[conversationId]?.participants?.append(participant)
            }
        }
        
        let userConversations = Array(conversationDict.values).sorted { (c1, c2) in
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
        
        // Enrich conversations with unread counts and decrypted previews
        var enrichedConversations: [Conversation] = []
        
        for var conversation in userConversations {
            // Get unread count
            let unreadCount = try await repository.getUnreadCount(
                conversationId: conversation.id,
                userId: userId
            )
            conversation.unreadCount = unreadCount
            
            // Get and decrypt latest message preview
            if let latestMessageData = try await repository.fetchLatestMessage(for: conversation.id),
               let encryptedContent = latestMessageData["content"]?.stringValue {
                let decryptedPreview = try? encryption.decryptMessagePreview(encryptedContent)
                conversation.lastMessagePreview = decryptedPreview ?? "Message"
            }
            
            enrichedConversations.append(conversation)
        }
        
        return enrichedConversations
    }
    
    /// Get or create direct conversation between users
    func getOrCreateDirectConversation(currentUserId: String, with otherUserId: String) async throws -> String {
        return try await repository.getOrCreateDirectConversation(
            currentUserId: currentUserId,
            otherUserId: otherUserId
        )
    }
    
    /// Mark conversation as read and update state
    func markConversationAsRead(_ conversationId: String, userId: String) async throws {
        try await repository.markConversationAsRead(
            conversationId: conversationId,
            userId: userId
        )
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .conversationMarkedAsRead,
            object: conversationId
        )
    }
    
    /// Delete conversation for current user
    func deleteConversation(_ conversationId: String, userId: String) async throws {
        try await repository.deleteConversationForUser(
            conversationId: conversationId,
            userId: userId
        )
    }
    
    /// Calculate total unread conversations count
    func calculateUnreadConversationsCount(for userId: String) async -> Int {
        do {
            // Fetch basic conversation data
            let conversationData = try await repository.fetchUserConversations(userId: userId)
            let conversationIds = Set(conversationData.map { $0.conversationId })
            
            var unreadConversationsCount = 0
            
            for conversationId in conversationIds {
                let unreadCount = try await repository.getUnreadCount(
                    conversationId: conversationId,
                    userId: userId
                )
                if unreadCount > 0 {
                    unreadConversationsCount += 1
                }
            }
            
            return unreadConversationsCount
        } catch {
            return 0
        }
    }
    
    // MARK: - Group Conversation Operations
    
    /// Create a new group conversation
    func createGroupConversation(
        name: String,
        description: String? = nil,
        memberIds: [String] = []
    ) async throws -> String {
        return try await repository.createGroupChat(
            name: name,
            description: description,
            memberIds: memberIds
        )
    }
    
    /// Fetch group conversations with decrypted previews
    func fetchGroupConversations(for userId: String) async throws -> [GroupConversation] {
        let groupConversations = try await repository.fetchGroupConversations(userId: userId)
        
        // Decrypt message previews for each group conversation
        var updatedGroupConversations: [GroupConversation] = []
        
        for var groupConversation in groupConversations {
            // Fetch and decrypt latest message
            if let latestMessageData = try await repository.fetchLatestMessage(for: groupConversation.id),
               let encryptedContent = latestMessageData["content"]?.stringValue {
                let decryptedPreview = try? encryption.decryptMessagePreview(encryptedContent)
                let preview = decryptedPreview ?? "Message"
                
                // Create updated group conversation with decrypted preview
                groupConversation = GroupConversation(
                    id: groupConversation.id,
                    isGroup: groupConversation.isGroup,
                    groupName: groupConversation.groupName,
                    groupDescription: groupConversation.groupDescription,
                    groupAvatarUrl: groupConversation.groupAvatarUrl,
                    groupEmoji: groupConversation.groupEmoji,
                    createdBy: groupConversation.createdBy,
                    createdAt: groupConversation.createdAt,
                    updatedAt: groupConversation.updatedAt,
                    lastMessageAt: groupConversation.lastMessageAt,
                    lastMessageContent: preview,
                    lastMessageSenderId: groupConversation.lastMessageSenderId,
                    lastMessageSenderUsername: groupConversation.lastMessageSenderUsername,
                    unreadCount: groupConversation.unreadCount
                )
            }
            
            updatedGroupConversations.append(groupConversation)
        }
        
        return updatedGroupConversations
    }
    
    /// Add member to group conversation
    func addMemberToGroup(conversationId: String, userId: String) async throws -> Bool {
        return try await repository.addGroupMember(
            conversationId: conversationId,
            userId: userId
        )
    }
    
    /// Remove member from group conversation
    func removeMemberFromGroup(conversationId: String, userId: String) async throws -> Bool {
        return try await repository.removeGroupMember(
            conversationId: conversationId,
            userId: userId
        )
    }
    
    /// Get members of group conversation
    func getGroupMembers(conversationId: String) async throws -> [GroupMember] {
        return try await repository.getGroupMembers(conversationId: conversationId)
    }
    
    // MARK: - Message Operations
    
    /// Fetch messages for a conversation
    func fetchMessages(
        for conversationId: String,
        limit: Int = 50,
        before: Date? = nil,
        userId: String
    ) async throws -> [Message] {
        let encryptedMessages = try await repository.fetchMessages(
            for: conversationId,
            limit: limit,
            before: before,
            userId: userId
        )
        
        // Decrypt message contents and create new Message instances
        var decryptedMessages: [Message] = []
        for message in encryptedMessages {
            let decryptedContent: String
            if let content = try? encryption.decryptMessage(message.content) {
                decryptedContent = content
            } else {
                decryptedContent = "Unable to decrypt message"
            }
            
            // Create new Message instance with decrypted content
            let decryptedMessage = Message(
                id: message.id,
                conversationId: message.conversationId,
                senderId: message.senderId,
                content: decryptedContent,
                createdAt: message.createdAt,
                updatedAt: message.updatedAt,
                isEdited: message.isEdited,
                isDeleted: message.isDeleted,
                sender: message.sender
            )
            decryptedMessages.append(decryptedMessage)
        }
        
        return decryptedMessages
    }
    
    /// Send message with encryption and state management
    func sendMessage(
        to conversationId: String,
        content: String,
        senderId: String
    ) async throws -> Message {
        // Encrypt message content
        let encryptedContent = try encryption.encryptMessage(content)
        
        // Insert message into database
        let insertedMessage = try await repository.insertMessage(
            conversationId: conversationId,
            senderId: senderId,
            encryptedContent: encryptedContent
        )
        
        // Update conversation metadata with plain text preview
        let previewText = content.count > 50 ? String(content.prefix(50)) + "..." : content
        try await repository.updateConversation(
            conversationId: conversationId,
            lastMessagePreview: previewText,
            lastMessageAt: Date()
        )
        
        // Ensure sender participation exists
        try await repository.ensureParticipationExists(
            conversationId: conversationId,
            userId: senderId
        )
        
        // Unhide conversation for all participants
        try await repository.unhideConversationForAllParticipants(conversationId: conversationId)
        
        // Clear message cutoff for sender
        try await repository.clearMessageCutoffForUser(
            conversationId: conversationId,
            userId: senderId
        )
        
        // Mark conversation as read for sender
        try await markConversationAsRead(conversationId, userId: senderId)
        
        // Create new message instance with decrypted content for return
        let message = Message(
            id: insertedMessage.id,
            conversationId: insertedMessage.conversationId,
            senderId: insertedMessage.senderId,
            content: content, // Use original plain text content
            createdAt: insertedMessage.createdAt,
            updatedAt: insertedMessage.updatedAt,
            isEdited: insertedMessage.isEdited,
            isDeleted: insertedMessage.isDeleted,
            sender: insertedMessage.sender
        )
        
        // Post notification for immediate UI update
        NotificationCenter.default.post(name: .messageWasSent, object: message)
        
        return message
    }
    
    /// Edit message content
    func editMessage(_ messageId: String, newContent: String) async throws {
        let encryptedContent = try encryption.encryptMessage(newContent)
        try await repository.updateMessage(messageId: messageId, newContent: encryptedContent)
    }
}