//======================================================================
// MARK: - Message.swift
// Purpose: Encrypted message data models with conversation management, participant handling, and secure content decryption (会話管理、参加者処理、セキュアコンテンツ復号化を持つ暗号化メッセージデータモデル)
// Path: still/Core/DataModels/Message.swift
//======================================================================
import Foundation

struct Message: Identifiable, Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String  // Content (decrypted at service layer)
    let createdAt: Date
    let updatedAt: Date
    let isEdited: Bool
    let isDeleted: Bool
    
    // Relationships - excluded from Codable synthesis
    var sender: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isEdited = "is_edited"
        case isDeleted = "is_deleted"
        // sender excluded - set manually at service layer
    }
}

struct Conversation: Identifiable, Codable {
    let id: String
    let createdAt: Date
    let updatedAt: Date
    var lastMessageAt: Date?
    var lastMessagePreview: String?
    
    // Relationships
    var participants: [ConversationParticipant]?
    var messages: [Message]?
    var unreadCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastMessageAt = "last_message_at"
        case lastMessagePreview = "last_message_preview"
        case participants = "conversation_participants"
        case messages
        case unreadCount
    }
    
    // Helper computed properties
    func otherParticipant(currentUserId: String?) -> UserProfile? {
        // Get the other participant (supports both direct messages and group chats)
        guard let participants = participants,
              let currentUserId = currentUserId else { 
            return nil 
        }
        
        // Find first participant that is not the current user (case-insensitive comparison)
        let otherParticipant = participants.first { $0.userId.lowercased() != currentUserId.lowercased() }
        return otherParticipant?.user
    }
    
    func displayName(currentUserId: String?) -> String {
        // Handle missing data gracefully
        guard let currentUserId = currentUserId else {
            return "Unknown"
        }
        
        // If no participants data, return a default message
        guard let participants = participants, !participants.isEmpty else {
            return "Loading..."
        }
        
        // Filter out current user from participants (case-insensitive comparison)
        let otherParticipants = participants.filter { $0.userId.lowercased() != currentUserId.lowercased() }
        
        if otherParticipants.isEmpty {
            // This might be a conversation with yourself or missing data
            return "Unknown"
        }
        
        // For direct messages (1 other participant)
        if otherParticipants.count == 1 {
            if let otherUser = otherParticipants.first?.user {
                return otherUser.profileDisplayName
            } else {
                // Fallback if user data isn't loaded yet
                return "User"
            }
        }
        
        // For group chats (multiple other participants)
        let participantNames = otherParticipants.compactMap { participant in
            participant.user?.profileDisplayName ?? "User"
        }
        
        if participantNames.isEmpty {
            return "Group Chat"
        } else if participantNames.count <= 3 {
            // Show all names for small groups
            return participantNames.joined(separator: ", ")
        } else {
            // Show first few names + count for large groups
            let firstNames = participantNames.prefix(2).joined(separator: ", ")
            let remainingCount = participantNames.count - 2
            return "\(firstNames) +\(remainingCount) others"
        }
    }
    
    func displayAvatar(currentUserId: String?) -> String? {
        // For direct messages, show the other participant's avatar
        // For group chats, show the first other participant's avatar (or could be a group icon)
        guard let currentUserId = currentUserId else {
            return nil
        }
        
        // Handle missing participants data gracefully
        guard let participants = participants, !participants.isEmpty else {
            return nil
        }
        
        let otherParticipants = participants.filter { $0.userId.lowercased() != currentUserId.lowercased() }
        
        // Return the first other participant's avatar
        return otherParticipants.first?.user?.avatarUrl
    }
    
    // 最後のメッセージプレビューを15文字に制限して表示
    var displayLastMessagePreview: String {
        guard let preview = lastMessagePreview else {
            return "Start a conversation"
        }
        
        // Preview should already be stored as decrypted text
        if preview.count <= 15 {
            return preview
        } else {
            return String(preview.prefix(15)) + "..."
        }
    }
}

struct ConversationParticipant: Identifiable, Codable {
    let id: String
    let conversationId: String
    let userId: String
    let joinedAt: Date
    let lastReadAt: Date?
    let hiddenForUser: Bool?
    
    // Relationships - excluded from Codable synthesis
    var user: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case lastReadAt = "last_read_at"
        case hiddenForUser = "hidden_for_user"
        // user excluded - set manually at service layer
    }
}

// MARK: - Message Request/Response Models
struct SendMessageRequest: Codable {
    let conversationId: String
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case content
    }
}

struct CreateConversationRequest: Codable {
    let participantIds: [String]
    
    enum CodingKeys: String, CodingKey {
        case participantIds = "participant_ids"
    }
}