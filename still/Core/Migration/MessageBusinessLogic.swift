//======================================================================
// MARK: - MessageBusinessLogic.swift
// Purpose: Business logic implementation for message operations
// Path: still/Core/Migration/MessageBusinessLogic.swift
//======================================================================

import Foundation

/**
 * Implementation of message business logic.
 */
@MainActor
final class MessageBusinessLogic: MessageBusinessLogicProtocol {
    
    private let messageDataAccess: MessageDataAccessProtocol
    private let conversationDataAccess: ConversationDataAccessProtocol
    private let encryptionService: EncryptionServiceProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(
        messageDataAccess: MessageDataAccessProtocol,
        conversationDataAccess: ConversationDataAccessProtocol,
        encryptionService: EncryptionServiceProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.messageDataAccess = messageDataAccess
        self.conversationDataAccess = conversationDataAccess
        self.encryptionService = encryptionService
        self.userRepository = userRepository
    }
    
    func sendMessage(
        conversationId: String,
        content: String,
        senderId: String
    ) async throws -> Message {
        // Encrypt the message content
        let encryptedContent = try await encryptionService.encrypt(
            content: content,
            conversationId: conversationId
        )
        
        // Create message record
        let messageRecord = MessageRecord(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: senderId,
            content: encryptedContent,
            createdAt: Date(),
            updatedAt: nil,
            isEdited: false,
            isDeleted: false,
            metadata: nil
        )
        
        // Insert into database
        let insertedRecord = try await messageDataAccess.insertMessage(messageRecord)
        
        // Fetch sender info
        let senderProfile = try await userRepository.fetchUserProfile(userId: senderId)
        
        // Return decrypted message
        return Message(
            id: insertedRecord.id,
            conversationId: insertedRecord.conversationId,
            senderId: insertedRecord.senderId,
            content: content, // Return decrypted content
            createdAt: insertedRecord.createdAt,
            updatedAt: insertedRecord.updatedAt ?? insertedRecord.createdAt,
            isEdited: insertedRecord.isEdited,
            isDeleted: insertedRecord.isDeleted,
            sender: senderProfile
        )
    }
    
    func fetchMessages(conversationId: String) async throws -> [Message] {
        // Fetch message records
        let records = try await messageDataAccess.fetchMessages(
            conversationId: conversationId,
            limit: 50,
            offset: 0
        )
        
        // Decrypt and transform to domain models
        var messages: [Message] = []
        
        for record in records {
            // Decrypt content
            let decryptedContent = try await encryptionService.decrypt(
                encryptedContent: record.content,
                conversationId: conversationId
            )
            
            // Fetch sender info
            let senderProfile = try await userRepository.fetchUserProfile(userId: record.senderId)
            
            let message = Message(
                id: record.id,
                conversationId: record.conversationId,
                senderId: record.senderId,
                content: decryptedContent,
                createdAt: record.createdAt,
                updatedAt: record.updatedAt ?? record.createdAt,
                isEdited: record.isEdited,
                isDeleted: record.isDeleted,
                sender: senderProfile
            )
            
            messages.append(message)
        }
        
        return messages
    }
    
    func markAsRead(messageId: String) async throws {
        try await messageDataAccess.markAsRead(messageId: messageId)
    }
    
    func deleteMessage(messageId: String, userId: String) async throws {
        // Verify user has permission (would check if user is sender)
        // For now, just delete
        try await messageDataAccess.deleteMessage(id: messageId)
    }
    
    func editMessage(
        messageId: String,
        newContent: String,
        userId: String
    ) async throws -> Message {
        // Would verify user is sender
        // Encrypt new content
        let encryptedContent = try await encryptionService.encrypt(
            content: newContent,
            conversationId: "" // Would need to fetch conversation ID
        )
        
        // Update message
        let updatedRecord = try await messageDataAccess.updateMessage(
            id: messageId,
            content: encryptedContent
        )
        
        // Fetch sender info
        let senderProfile = try await userRepository.fetchUserProfile(userId: updatedRecord.senderId)
        
        return Message(
            id: updatedRecord.id,
            conversationId: updatedRecord.conversationId,
            senderId: updatedRecord.senderId,
            content: newContent,
            createdAt: updatedRecord.createdAt,
            updatedAt: updatedRecord.updatedAt ?? updatedRecord.createdAt,
            isEdited: true,
            isDeleted: updatedRecord.isDeleted,
            sender: senderProfile
        )
    }
}

/**
 * Implementation of conversation business logic.
 */
@MainActor
final class ConversationBusinessLogic: ConversationBusinessLogicProtocol {
    
    private let conversationDataAccess: ConversationDataAccessProtocol
    private let messageDataAccess: MessageDataAccessProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(
        conversationDataAccess: ConversationDataAccessProtocol,
        messageDataAccess: MessageDataAccessProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.conversationDataAccess = conversationDataAccess
        self.messageDataAccess = messageDataAccess
        self.userRepository = userRepository
    }
    
    func createConversation(
        participantIds: [String],
        creatorId: String,
        name: String?
    ) async throws -> Conversation {
        // Create conversation record
        let conversationRecord = ConversationRecord(
            id: UUID().uuidString,
            createdAt: Date(),
            updatedAt: Date(),
            lastMessageAt: nil,
            lastMessagePreview: nil,
            isGroup: participantIds.count > 2,
            groupName: name,
            groupDescription: nil,
            groupAvatarUrl: nil,
            createdBy: creatorId,
            settings: nil
        )
        
        // Insert into database
        let insertedRecord = try await conversationDataAccess.createConversation(conversationRecord)
        
        // Add participants
        for participantId in participantIds {
            try await conversationDataAccess.addParticipant(
                conversationId: insertedRecord.id,
                userId: participantId
            )
        }
        
        // Fetch participant profiles
        var participants: [ConversationParticipant] = []
        for participantId in participantIds {
            let profile = try await userRepository.fetchUserProfile(userId: participantId)
            let participant = ConversationParticipant(
                id: UUID().uuidString,
                conversationId: insertedRecord.id,
                userId: participantId,
                joinedAt: Date(),
                lastReadAt: nil,
                user: profile
            )
            participants.append(participant)
        }
        
        return Conversation(
            id: insertedRecord.id,
            createdAt: insertedRecord.createdAt,
            updatedAt: insertedRecord.updatedAt,
            lastMessageAt: insertedRecord.lastMessageAt,
            lastMessagePreview: insertedRecord.lastMessagePreview,
            participants: participants,
            messages: nil,
            unreadCount: 0
        )
    }
    
    func fetchConversations(userId: String) async throws -> [Conversation] {
        // Fetch conversation records
        let records = try await conversationDataAccess.fetchConversations(userId: userId)
        
        // Transform to domain models
        var conversations: [Conversation] = []
        
        for record in records {
            // For simplicity, create conversation without full participant info
            let conversation = Conversation(
                id: record.id,
                createdAt: record.createdAt,
                updatedAt: record.updatedAt,
                lastMessageAt: record.lastMessageAt,
                lastMessagePreview: record.lastMessagePreview,
                participants: [],
                messages: nil,
                unreadCount: 0
            )
            
            conversations.append(conversation)
        }
        
        return conversations
    }
    
    func updateConversationSettings(
        conversationId: String,
        settings: ConversationSettings?,
        userId: String
    ) async throws {
        // Would update conversation settings
        // For now, this is a no-op
    }
    
    func addParticipants(
        conversationId: String,
        userIds: [String],
        requesterId: String
    ) async throws {
        for userId in userIds {
            try await conversationDataAccess.addParticipant(
                conversationId: conversationId,
                userId: userId
            )
        }
    }
    
    func leaveConversation(
        conversationId: String,
        userId: String
    ) async throws {
        try await conversationDataAccess.removeParticipant(
            conversationId: conversationId,
            userId: userId
        )
    }
}