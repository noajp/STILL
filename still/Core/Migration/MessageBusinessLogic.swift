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
            metadata: nil,
            encryptionType: "legacy" // Default to legacy for now
        )
        
        // Insert into database
        let insertedRecord = try await messageDataAccess.insertMessage(messageRecord)
        
        // Update conversation preview with decrypted content
        try await messageDataAccess.updateConversationPreview(
            conversationId: conversationId,
            lastMessagePreview: content, // Store decrypted content as preview
            lastMessageAt: insertedRecord.createdAt
        )
        
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
            // Decrypt message content
            let decryptedContent = try await encryptionService.decrypt(
                encryptedContent: record.content,
                conversationId: conversationId
            )
            
            // Fetch sender profile
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
        try await messageDataAccess.deleteMessage(id: messageId)
    }
    
    func editMessage(
        messageId: String,
        newContent: String,
        userId: String
    ) async throws -> Message {
        // Encrypt the new content
        let encryptedContent = try await encryptionService.encrypt(
            content: newContent,
            conversationId: "" // We need to get this from the message
        )
        
        // Update message
        let updatedRecord = try await messageDataAccess.updateMessage(
            id: messageId,
            content: encryptedContent
        )
        
        // Fetch sender profile
        let senderProfile = try await userRepository.fetchUserProfile(userId: updatedRecord.senderId)
        
        return Message(
            id: updatedRecord.id,
            conversationId: updatedRecord.conversationId,
            senderId: updatedRecord.senderId,
            content: newContent, // Return decrypted content
            createdAt: updatedRecord.createdAt,
            updatedAt: updatedRecord.updatedAt ?? updatedRecord.createdAt,
            isEdited: updatedRecord.isEdited,
            isDeleted: updatedRecord.isDeleted,
            sender: senderProfile
        )
    }
}

// MARK: - Conversation Business Logic

/**
 * Implementation of conversation business logic.
 */
@MainActor
final class ConversationBusinessLogic: ConversationBusinessLogicProtocol {
    
    private let conversationDataAccess: ConversationDataAccessProtocol
    private let userRepository: UserRepositoryProtocol
    
    init(
        conversationDataAccess: ConversationDataAccessProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.conversationDataAccess = conversationDataAccess
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
        
        // Insert conversation
        let insertedRecord = try await conversationDataAccess.createConversation(conversationRecord)
        
        // Add participants
        for participantId in participantIds {
            try await conversationDataAccess.addParticipant(
                conversationId: insertedRecord.id,
                userId: participantId
            )
        }
        
        // Fetch participants with user data
        let participants = try await conversationDataAccess.fetchConversationParticipants(
            conversationId: insertedRecord.id
        )
        
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
        let records = try await conversationDataAccess.fetchConversations(userId: userId)
        var conversations: [Conversation] = []
        
        for record in records {
            let participants = try await conversationDataAccess.fetchConversationParticipants(
                conversationId: record.id
            )
            
            print("📋 Conversation \(record.id) has \(participants.count) participants")
            for participant in participants {
                print("  👤 User \(participant.userId): \(participant.user?.username ?? "no username"), avatar: \(participant.user?.avatarUrl ?? "no avatar")")
            }
            
            let conversation = Conversation(
                id: record.id,
                createdAt: record.createdAt,
                updatedAt: record.updatedAt,
                lastMessageAt: record.lastMessageAt,
                lastMessagePreview: record.lastMessagePreview,
                participants: participants,
                messages: nil,
                unreadCount: 0
            )
            
            conversations.append(conversation)
        }
        
        print("✅ ConversationBusinessLogic: Returning \(conversations.count) conversations")
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
        // Instead of removing participant completely, hide conversation for this user
        try await conversationDataAccess.hideConversationForUser(
            conversationId: conversationId,
            userId: userId
        )
        
        // If this is a direct message (2 participants), we can soft delete the entire conversation
        let participants = try await conversationDataAccess.fetchConversationParticipants(
            conversationId: conversationId
        )
        
        if participants.count == 2 {
            // For direct messages, soft delete the entire conversation when user "deletes" it
            try await conversationDataAccess.deleteConversation(id: conversationId)
        }
    }
}

// MARK: - Hybrid Encryption Migration Service

/**
 * Service to handle migration from legacy encryption to E2EE
 * Supports both encryption methods during transition period
 */
@MainActor 
class HybridEncryptionService {
    
    private let legacyEncryption = MessageEncryptionService()
    private let e2eeEncryption = E2EEMessageEncryptionService()
    private let authManager = AuthManager.shared
    
    // MARK: - Message Encryption
    
    /**
     * Encrypt message using appropriate method based on conversation participants
     * - Uses E2EE if all participants have public keys
     * - Falls back to legacy encryption otherwise
     */
    func encryptMessage(_ content: String, participants: [ConversationParticipant]) async throws -> (encryptedContent: String, encryptionType: String) {
        print("🔄 Determining encryption method for message")
        
        // Check if all participants have public keys for E2EE
        let canUseE2EE = await checkE2EESupport(for: participants)
        
        if canUseE2EE && participants.count == 2 {
            // Use E2EE for direct messages when both users have keys
            return try await encryptWithE2EE(content, participants: participants)
        } else {
            // Use legacy encryption as fallback
            print("📊 Using legacy encryption (E2EE not supported by all participants)")
            let encryptedContent = try legacyEncryption.encryptMessage(content)
            return (encryptedContent, "legacy")
        }
    }
    
    /**
     * Decrypt message using appropriate method based on encryption type
     */
    func decryptMessage(_ encryptedContent: String, encryptionType: String, senderInfo: ConversationParticipant?) async throws -> String {
        print("🔓 Decrypting message with type: \(encryptionType)")
        
        switch encryptionType {
        case "e2ee":
            guard let senderPublicKey = senderInfo?.user?.publicKey else {
                throw HybridEncryptionError.senderPublicKeyMissing
            }
            return try e2eeEncryption.decryptMessage(encryptedContent, senderPublicKey: senderPublicKey)
            
        case "legacy":
            return try legacyEncryption.decryptMessage(encryptedContent)
            
        default:
            print("⚠️ Unknown encryption type: \(encryptionType), trying legacy")
            return try legacyEncryption.decryptMessage(encryptedContent)
        }
    }
    
    /**
     * Safely decrypt message with fallback handling
     */
    func safeDecryptMessage(_ encryptedContent: String, encryptionType: String, senderInfo: ConversationParticipant?) async -> String {
        do {
            return try await decryptMessage(encryptedContent, encryptionType: encryptionType, senderInfo: senderInfo)
        } catch {
            print("❌ Failed to decrypt message: \(error)")
            return "Unable to decrypt message"
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Check if all participants support E2EE
     */
    private func checkE2EESupport(for participants: [ConversationParticipant]) async -> Bool {
        for participant in participants {
            // Skip current user check - they should have E2EE initialized
            guard let currentUserId = authManager.currentUser?.id,
                  participant.userId != currentUserId else { continue }
            
            // Check if participant has public key
            guard participant.user?.publicKey != nil else {
                print("❌ Participant \(participant.userId) missing public key")
                return false
            }
        }
        
        // Also ensure current user has E2EE set up
        guard e2eeEncryption.isE2EEInitialized() else {
            print("❌ Current user doesn't have E2EE initialized")
            return false
        }
        
        print("✅ All participants support E2EE")
        return true
    }
    
    /**
     * Encrypt message using E2EE for direct conversation
     */
    private func encryptWithE2EE(_ content: String, participants: [ConversationParticipant]) async throws -> (String, String) {
        print("🔒 Encrypting with E2EE")
        
        guard let currentUserId = authManager.currentUser?.id else {
            throw HybridEncryptionError.userNotAuthenticated
        }
        
        // Find the other participant (not current user)
        guard let otherParticipant = participants.first(where: { $0.userId != currentUserId }),
              let recipientPublicKey = otherParticipant.user?.publicKey else {
            throw HybridEncryptionError.recipientPublicKeyMissing
        }
        
        let encryptedContent = try e2eeEncryption.encryptMessage(content, recipientPublicKey: recipientPublicKey)
        return (encryptedContent, "e2ee")
    }
}

// MARK: - Hybrid Encryption Errors

enum HybridEncryptionError: LocalizedError {
    case userNotAuthenticated
    case senderPublicKeyMissing
    case recipientPublicKeyMissing
    case encryptionTypeMismatch
    case migrationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated for encryption"
        case .senderPublicKeyMissing:
            return "Sender's public key missing for E2EE decryption"
        case .recipientPublicKeyMissing:
            return "Recipient's public key missing for E2EE encryption"
        case .encryptionTypeMismatch:
            return "Encryption type doesn't match message format"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        }
    }
}
