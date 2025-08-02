//======================================================================
// MARK: - MessageRepository.swift
// Purpose: Data access layer for messages and conversations with Supabase integration
// Path: still/Core/Services/MessageRepository.swift
//======================================================================

import Foundation
import Supabase

/// Data access layer for messages and conversations
/// Handles all direct database operations without business logic
@MainActor
class MessageRepository {
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Message Operations
    
    /// Fetch messages for a conversation with optional pagination
    func fetchMessages(
        for conversationId: String, 
        limit: Int = 50, 
        before: Date? = nil,
        userId: String
    ) async throws -> [Message] {
        // Check message cutoff time for user
        let participantData: [[String: AnyJSON]] = try await supabase
            .from("conversation_participants")
            .select("messages_hidden_since")
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
            .value
        
        let messagesCutoffTime: Date?
        if let participant = participantData.first,
           let cutoffString = participant["messages_hidden_since"]?.stringValue {
            messagesCutoffTime = ISO8601DateFormatter().date(from: cutoffString)
        } else {
            messagesCutoffTime = nil
        }
        
        let query = supabase
            .from("messages")
            .select("""
                *,
                sender:profiles(*)
            """)
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: false)
            .limit(limit)
        
        var messages: [Message] = try await query.execute().value
        
        // Filter messages after cutoff time if exists
        if let cutoffTime = messagesCutoffTime {
            messages = messages.filter { message in
                message.createdAt > cutoffTime
            }
        }
        
        messages.reverse() // Show oldest first
        return messages
    }
    
    /// Insert a new message into the database
    func insertMessage(
        conversationId: String,
        senderId: String,
        encryptedContent: String
    ) async throws -> Message {
        let messageData = [
            "conversation_id": conversationId,
            "sender_id": senderId,
            "content": encryptedContent
        ]
        
        let message: Message = try await supabase
            .from("messages")
            .insert(messageData)
            .select("""
                *,
                sender:profiles(*)
            """)
            .single()
            .execute()
            .value
        
        return message
    }
    
    /// Update message content and mark as edited
    func updateMessage(messageId: String, newContent: String) async throws {
        let updateData: [String: AnyJSON] = [
            "content": AnyJSON.string(newContent),
            "is_edited": AnyJSON.bool(true),
            "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await supabase
            .from("messages")
            .update(updateData)
            .eq("id", value: messageId)
            .execute()
    }
    
    /// Fetch latest message for conversation
    func fetchLatestMessage(for conversationId: String) async throws -> [String: AnyJSON]? {
        let latestMessageData: [[String: AnyJSON]] = try await supabase
            .from("messages")
            .select("content")
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        
        return latestMessageData.first
    }
    
    // MARK: - Conversation Operations
    
    /// Fetch all conversations for a user using RPC function
    func fetchUserConversations(userId: String) async throws -> [ConversationData] {
        let conversationData: [ConversationData] = try await supabase
            .rpc("get_user_conversations", params: ["user_id_param": AnyJSON.string(userId)])
            .execute()
            .value
        
        return conversationData
    }
    
    /// Create or get direct conversation using RPC function
    func getOrCreateDirectConversation(currentUserId: String, otherUserId: String) async throws -> String {
        // Verify both users exist
        try await verifyUserExists(userId: currentUserId)
        try await verifyUserExists(userId: otherUserId)
        
        // Validate UUID format
        guard UUID(uuidString: otherUserId) != nil else {
            throw NSError(domain: "MessageRepository", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"])
        }
        
        let conversationId: String = try await supabase
            .rpc("get_or_create_direct_conversation", params: ["other_user_id": AnyJSON.string(otherUserId)])
            .execute()
            .value
        
        return conversationId
    }
    
    /// Update conversation metadata
    func updateConversation(
        conversationId: String,
        lastMessagePreview: String,
        lastMessageAt: Date
    ) async throws {
        let conversationUpdateData: [String: AnyJSON] = [
            "last_message_preview": AnyJSON.string(lastMessagePreview),
            "last_message_at": AnyJSON.string(ISO8601DateFormatter().string(from: lastMessageAt))
        ]
        
        try await supabase
            .from("conversations")
            .update(conversationUpdateData)
            .eq("id", value: conversationId)
            .execute()
    }
    
    // MARK: - Participant Operations
    
    /// Get unread message count for a conversation
    func getUnreadCount(conversationId: String, userId: String) async throws -> Int {
        do {
            struct LastReadResponse: Codable {
                let lastReadAt: Date?
                
                enum CodingKeys: String, CodingKey {
                    case lastReadAt = "last_read_at"
                }
            }
            
            let lastReadData: LastReadResponse = try await supabase
                .from("conversation_participants")
                .select("last_read_at")
                .eq("conversation_id", value: conversationId)
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            
            let lastReadAt = lastReadData.lastReadAt ?? Date.distantPast
            
            let countResponse = try await supabase
                .from("messages")
                .select("id", head: true, count: .exact)
                .eq("conversation_id", value: conversationId)
                .neq("sender_id", value: userId)
                .gt("created_at", value: ISO8601DateFormatter().string(from: lastReadAt))
                .execute()
            
            return countResponse.count ?? 0
        } catch {
            return 0
        }
    }
    
    /// Mark conversation as read for user
    func markConversationAsRead(conversationId: String, userId: String) async throws {
        let updateData: [String: AnyJSON] = [
            "last_read_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await supabase
            .from("conversation_participants")
            .update(updateData)
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    /// Ensure user participation record exists
    func ensureParticipationExists(conversationId: String, userId: String) async throws {
        let existingCount = try await supabase
            .from("conversation_participants")
            .select("id", head: true, count: .exact)
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
            .count ?? 0
        
        if existingCount == 0 {
            let participantData: [String: AnyJSON] = [
                "conversation_id": AnyJSON.string(conversationId),
                "user_id": AnyJSON.string(userId),
                "joined_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ]
            
            try await supabase
                .from("conversation_participants")
                .insert(participantData)
                .execute()
        }
    }
    
    /// Delete conversation for user (soft delete)
    func deleteConversationForUser(conversationId: String, userId: String) async throws {
        let deletionTime = Date()
        let updateData: [String: AnyJSON] = [
            "hidden_for_user": AnyJSON.bool(true),
            "hidden_at": AnyJSON.string(ISO8601DateFormatter().string(from: deletionTime)),
            "messages_hidden_since": AnyJSON.string(ISO8601DateFormatter().string(from: deletionTime))
        ]
        
        try await supabase
            .from("conversation_participants")
            .update(updateData)
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    /// Unhide conversation for all participants using RPC
    func unhideConversationForAllParticipants(conversationId: String) async throws {
        try await supabase
            .rpc("unhide_conversation_for_all_participants", params: [
                "conversation_id_param": AnyJSON.string(conversationId)
            ])
            .execute()
    }
    
    /// Clear message cutoff for user using RPC
    func clearMessageCutoffForUser(conversationId: String, userId: String) async throws {
        try await supabase
            .rpc("clear_message_cutoff_for_user", params: [
                "conversation_id_param": AnyJSON.string(conversationId),
                "user_id_param": AnyJSON.string(userId)
            ])
            .execute()
    }
    
    // MARK: - Group Operations
    
    /// Create group chat using RPC
    func createGroupChat(name: String, description: String?, memberIds: [String]) async throws -> String {
        let conversationId: String = try await supabase
            .rpc("create_group_chat", params: [
                "group_name_param": AnyJSON.string(name),
                "group_description_param": description.map { AnyJSON.string($0) } ?? AnyJSON.null,
                "member_ids": AnyJSON.array(memberIds.map { AnyJSON.string($0) })
            ])
            .execute()
            .value
        
        return conversationId
    }
    
    /// Fetch group conversations for user
    func fetchGroupConversations(userId: String) async throws -> [GroupConversation] {
        let groupConversations: [GroupConversation] = try await supabase
            .rpc("get_user_group_conversations", params: ["user_id_param": AnyJSON.string(userId)])
            .execute()
            .value
        
        return groupConversations
    }
    
    /// Add member to group chat
    func addGroupMember(conversationId: String, userId: String) async throws -> Bool {
        let result: Bool = try await supabase
            .rpc("add_group_member", params: [
                "conversation_id_param": AnyJSON.string(conversationId),
                "user_id_param": AnyJSON.string(userId)
            ])
            .execute()
            .value
        
        return result
    }
    
    /// Remove member from group chat
    func removeGroupMember(conversationId: String, userId: String) async throws -> Bool {
        let result: Bool = try await supabase
            .rpc("remove_group_member", params: [
                "conversation_id_param": AnyJSON.string(conversationId),
                "user_id_param": AnyJSON.string(userId)
            ])
            .execute()
            .value
        
        return result
    }
    
    /// Get group members
    func getGroupMembers(conversationId: String) async throws -> [GroupMember] {
        let members: [GroupMember] = try await supabase
            .from("group_members")
            .select("""
                *,
                user:profiles(*)
            """)
            .eq("conversation_id", value: conversationId)
            .execute()
            .value
        
        return members
    }
    
    // MARK: - Helper Methods
    
    /// Verify user exists in profiles table
    private func verifyUserExists(userId: String) async throws {
        let userCount = try await supabase
            .from("profiles")
            .select("id", head: true, count: .exact)
            .eq("id", value: userId)
            .execute()
            .count ?? 0
        
        if userCount == 0 {
            throw NSError(domain: "MessageRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }
    }
}

// MARK: - Supporting Types

/// Raw conversation data from RPC function
struct ConversationData: Codable {
    let conversationId: String
    let conversationCreatedAt: Date
    let conversationUpdatedAt: Date
    let conversationLastMessageAt: Date?
    let conversationLastMessagePreview: String?
    let participantId: String?
    let participantUserId: String?
    let participantJoinedAt: Date?
    let participantLastReadAt: Date?
    let userUsername: String?
    let userDisplayName: String?
    let userAvatarUrl: String?
    let userBio: String?
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case conversationCreatedAt = "conversation_created_at"
        case conversationUpdatedAt = "conversation_updated_at"
        case conversationLastMessageAt = "conversation_last_message_at"
        case conversationLastMessagePreview = "conversation_last_message_preview"
        case participantId = "participant_id"
        case participantUserId = "participant_user_id"
        case participantJoinedAt = "participant_joined_at"
        case participantLastReadAt = "participant_last_read_at"
        case userUsername = "user_username"
        case userDisplayName = "user_display_name"
        case userAvatarUrl = "user_avatar_url"
        case userBio = "user_bio"
    }
}