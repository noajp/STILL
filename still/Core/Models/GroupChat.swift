//======================================================================
// MARK: - GroupChat.swift
// Purpose: Group chat data models with conversation management, member roles, and unread message tracking (会話管理、メンバーロール、未読メッセージ追跡を持つグループチャットデータモデル)
// Path: still/Core/Models/GroupChat.swift
//======================================================================
import Foundation

// MARK: - Group Conversation Model
struct GroupConversation: Codable, Identifiable {
    let id: String
    let isGroup: Bool
    let groupName: String?
    let groupDescription: String?
    let groupAvatarUrl: String?
    let groupEmoji: String?
    let createdBy: String
    let createdAt: Date
    let updatedAt: Date
    let lastMessageAt: Date?
    let lastMessageContent: String?
    let lastMessageSenderId: String?
    let lastMessageSenderUsername: String?
    var unreadCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case isGroup = "is_group"
        case groupName = "group_name"
        case groupDescription = "group_description"
        case groupAvatarUrl = "group_avatar_url"
        case groupEmoji = "group_emoji"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastMessageAt = "last_message_at"
        case lastMessageContent = "last_message_content"
        case lastMessageSenderId = "last_message_sender_id"
        case lastMessageSenderUsername = "last_message_sender_username"
        case unreadCount = "unread_count"
    }
    
    // Display helpers
    var displayName: String {
        return groupName ?? "Group Chat"
    }
    
    var displayLastMessagePreview: String {
        guard let content = lastMessageContent, !content.isEmpty else {
            return "No messages yet"
        }
        
        if let senderUsername = lastMessageSenderUsername {
            return "\(senderUsername): \(content)"
        }
        
        return content
    }
}

// MARK: - Group Member Model
struct GroupMember: Codable, Identifiable {
    let id: String
    let conversationId: String
    let userId: String
    let role: GroupRole
    let joinedAt: Date
    let user: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
        case user
    }
}

// MARK: - Group Role Enum
enum GroupRole: String, Codable, CaseIterable {
    case admin = "admin"
    case member = "member"
    
    var displayName: String {
        switch self {
        case .admin:
            return "Admin"
        case .member:
            return "Member"
        }
    }
    
    var canManageMembers: Bool {
        return self == .admin
    }
}

// MARK: - Group Chat Creation Request
struct GroupChatCreationRequest {
    let name: String
    let description: String?
    let memberIds: [String]
    
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}