//======================================================================
// MARK: - Message.swift
// Path: foodai/Core/DataModels/Message.swift
//======================================================================
import Foundation

struct Message: Identifiable, Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let isEdited: Bool
    let isDeleted: Bool
    
    // Relationships
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
        case sender
    }
}

struct Conversation: Identifiable, Codable {
    let id: String
    let createdAt: Date
    let updatedAt: Date
    let lastMessageAt: Date?
    let lastMessagePreview: String?
    
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
        guard let participants = participants, let currentUserId = currentUserId else {
            return "Unknown"
        }
        
        // Filter out current user from participants (case-insensitive comparison)
        let otherParticipants = participants.filter { $0.userId.lowercased() != currentUserId.lowercased() }
        
        if otherParticipants.isEmpty {
            return "Unknown"
        }
        
        // For direct messages (1 other participant)
        if otherParticipants.count == 1 {
            if let otherUser = otherParticipants.first?.user {
                // 表示名のみを表示（display_nameがあればそれを、なければusernameを使用）
                return otherUser.profileDisplayName
            } else {
                return "User-\(String(otherParticipants.first!.userId.prefix(8)))"
            }
        }
        
        // For group chats (multiple other participants)
        let participantNames = otherParticipants.compactMap { participant in
            participant.user?.profileDisplayName ?? "User-\(String(participant.userId.prefix(8)))"
        }
        
        if participantNames.count <= 3 {
            // Show all names for small groups
            let groupName = participantNames.joined(separator: ", ")
            return groupName
        } else {
            // Show first few names + count for large groups
            let firstNames = participantNames.prefix(2).joined(separator: ", ")
            let remainingCount = participantNames.count - 2
            let groupName = "\(firstNames) +\(remainingCount) others"
            return groupName
        }
    }
    
    func displayAvatar(currentUserId: String?) -> String? {
        // For direct messages, show the other participant's avatar
        // For group chats, show the first other participant's avatar (or could be a group icon)
        guard let participants = participants, let currentUserId = currentUserId else {
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
        
        if preview.count <= 15 {
            return preview
        } else {
            return String(preview.prefix(15)) + "..."
        }
    }
}

struct ConversationParticipant: Codable {
    let id: String
    let conversationId: String
    let userId: String
    let joinedAt: Date
    let lastReadAt: Date?
    
    // Relationships
    var user: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case lastReadAt = "last_read_at"
        case user
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