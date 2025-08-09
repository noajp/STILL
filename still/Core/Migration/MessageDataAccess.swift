//======================================================================
// MARK: - MessageDataAccess.swift
// Purpose: Data access layer implementation for message operations
// Path: still/Core/Migration/MessageDataAccess.swift
//======================================================================

import Foundation
import Supabase

/**
 * Implementation of message data access.
 */
@MainActor
final class MessageDataAccess: MessageDataAccessProtocol {
    
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    func fetchMessages(conversationId: String, limit: Int, offset: Int) async throws -> [MessageRecord] {
        // Fetch messages in descending order (latest first) to get the most recent messages
        let response = try await supabaseClient
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: false) // Get latest messages first
            .limit(limit)
            .range(from: offset, to: offset + limit - 1)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let records = try decoder.decode([MessageRecord].self, from: response.data)
        
        // Return in chronological order (oldest first) for display
        return records.reversed()
    }
    
    func insertMessage(_ record: MessageRecord) async throws -> MessageRecord {
        let response = try await supabaseClient
            .from("messages")
            .insert(record)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MessageRecord.self, from: response.data)
    }
    
    func updateConversationPreview(conversationId: String, lastMessagePreview: String, lastMessageAt: Date) async throws {
        struct ConversationUpdate: Codable {
            let last_message_preview: String
            let last_message_at: String
            let updated_at: String
        }
        
        let updateData = ConversationUpdate(
            last_message_preview: lastMessagePreview,
            last_message_at: lastMessageAt.ISO8601Format(),
            updated_at: Date().ISO8601Format()
        )
        
        try await supabaseClient
            .from("conversations")
            .update(updateData)
            .eq("id", value: conversationId)
            .execute()
    }
    
    func updateMessage(id: String, content: String) async throws -> MessageRecord {
        // Create JSON data manually
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let updateValues = [
            "content": content,
            "is_edited": "true",
            "updated_at": Date().ISO8601Format()
        ] as [String: Any]
        
        let jsonData = try JSONSerialization.data(withJSONObject: updateValues)
        
        let response = try await supabaseClient
            .from("messages")
            .update(jsonData)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MessageRecord.self, from: response.data)
    }
    
    func deleteMessage(id: String) async throws {
        try await supabaseClient
            .from("messages")
            .update(["is_deleted": true])
            .eq("id", value: id)
            .execute()
    }
    
    func markAsRead(messageId: String) async throws {
        try await supabaseClient
            .from("messages")
            .update(["is_read": true])
            .eq("id", value: messageId)
            .execute()
    }
}

/**
 * Temporary structure for decoding conversations with participant data
 */
private struct ConversationWithParticipants: Codable {
    let id: String
    let createdAt: Date
    let updatedAt: Date
    let lastMessageAt: Date?
    let lastMessagePreview: String?
    let isGroup: Bool
    let groupName: String?
    let groupDescription: String?
    let groupAvatarUrl: String?
    let createdBy: String?
    let settings: [String: String]?
    let conversationParticipants: [ParticipantWithUser]
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastMessageAt = "last_message_at"
        case lastMessagePreview = "last_message_preview"
        case isGroup = "is_group"
        case groupName = "group_name"
        case groupDescription = "group_description"
        case groupAvatarUrl = "group_avatar_url"
        case createdBy = "created_by"
        case settings
        case conversationParticipants = "conversation_participants"
    }
}

/**
 * Structure for decoding participant with user profile
 */
private struct ParticipantWithUser: Codable {
    let id: String
    let userId: String
    let joinedAt: Date
    let lastReadAt: Date?
    let user: UserProfileData?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case joinedAt = "joined_at"
        case lastReadAt = "last_read_at"
        case user
    }
}

/**
 * Structure for user profile data from joined query
 */
private struct UserProfileData: Codable {
    let id: String
    let displayName: String?
    let avatarUrl: String?
    let username: String?
    let publicKey: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case username
        case publicKey = "public_key"
    }
}

/**
 * Implementation of conversation data access.
 */
@MainActor
final class ConversationDataAccess: ConversationDataAccessProtocol {
    
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    func fetchConversations(userId: String) async throws -> [ConversationRecord] {
        print("🔍 ConversationDataAccess: Fetching conversations for user: \(userId)")
        
        // First, get the conversations where the user is a participant (excluding hidden ones)
        let participantResponse = try await supabaseClient
            .from("conversation_participants")
            .select("conversation_id")
            .eq("user_id", value: userId)
            .neq("hidden_for_user", value: true) // Exclude conversations hidden by user
            .execute()
        
        let participantData = try JSONDecoder().decode([[String: String]].self, from: participantResponse.data)
        let conversationIds = participantData.compactMap { $0["conversation_id"] }
        
        guard !conversationIds.isEmpty else {
            print("✅ ConversationDataAccess: No conversations found for user")
            return []
        }
        
        print("🔍 ConversationDataAccess: Found \(conversationIds.count) conversations for user")
        
        // Now fetch the full conversation details, excluding soft-deleted conversations
        let response = try await supabaseClient
            .from("conversations")
            .select("*")
            .in("id", values: conversationIds)
            .is("deleted_at", value: nil) // Exclude soft-deleted conversations
            .order("updated_at", ascending: false)
            .execute()
        
        print("🔍 ConversationDataAccess: Raw response data size: \(response.data.count)")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let allConversations = try decoder.decode([ConversationRecord].self, from: response.data)
            print("✅ ConversationDataAccess: Successfully parsed \(allConversations.count) conversations")
            return allConversations
        } catch {
            print("❌ ConversationDataAccess: Failed to decode conversations: \(error)")
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error details: \(decodingError)")
            }
            return []
        }
    }
    
    func fetchConversation(id: String) async throws -> ConversationRecord? {
        let response = try await supabaseClient
            .from("conversations")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ConversationRecord.self, from: response.data)
    }
    
    func fetchConversationParticipants(conversationId: String) async throws -> [ConversationParticipant] {
        print("🔍 ConversationDataAccess: Fetching participants for conversation: \(conversationId)")
        
        let response = try await supabaseClient
            .from("conversation_participants")
            .select("""
                id,
                conversation_id,
                user_id,
                joined_at,
                last_read_at,
                user:profiles!user_id (
                    id,
                    display_name,
                    avatar_url,
                    username,
                    public_key
                )
            """)
            .eq("conversation_id", value: conversationId)
            .execute()
        
        print("🔍 Raw participants response size: \(response.data.count)")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let participantsData = try decoder.decode([ParticipantWithUser].self, from: response.data)
            print("✅ Decoded \(participantsData.count) participants with user data")
            
            let participants = participantsData.map { data in
                let userProfile = data.user.map { userData in
                    UserProfile(
                        id: userData.id,
                        username: userData.username ?? "unknown",
                        displayName: userData.displayName,
                        avatarUrl: userData.avatarUrl,
                        bio: nil,
                        createdAt: nil,
                        publicKey: userData.publicKey
                    )
                }
                
                print("  🔍 Participant \(data.userId) has user data: \(userProfile != nil), username: \(userProfile?.username ?? "nil")")
                
                return ConversationParticipant(
                    id: data.id,
                    conversationId: conversationId,
                    userId: data.userId,
                    joinedAt: data.joinedAt,
                    lastReadAt: data.lastReadAt,
                    hiddenForUser: nil,
                    user: userProfile
                )
            }
            
            print("✅ Converted to \(participants.count) ConversationParticipant objects")
            return participants
        } catch {
            print("❌ Failed to decode participants: \(error)")
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error details: \(decodingError)")
            }
            return []
        }
    }
    
    func createConversation(_ record: ConversationRecord) async throws -> ConversationRecord {
        print("🔍 Creating conversation with auth session:")
        do {
            let session = try await supabaseClient.auth.session
            print("  ✅ Auth session exists")
            print("  🔑 Access token: \(session.accessToken.prefix(20))...")
            print("  👤 User ID: \(session.user.id)")
        } catch {
            print("  ❌ No auth session found: \(error)")
        }
        
        print("🔍 Conversation record to insert:")
        print("  📝 ID: \(record.id)")
        print("  👤 Created by: \(record.createdBy ?? "nil")")
        print("  📅 Created at: \(record.createdAt)")
        
        let response = try await supabaseClient
            .from("conversations")
            .insert(record)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ConversationRecord.self, from: response.data)
    }
    
    func updateConversation(_ record: ConversationRecord) async throws -> ConversationRecord {
        let response = try await supabaseClient
            .from("conversations")
            .update(record)
            .eq("id", value: record.id)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ConversationRecord.self, from: response.data)
    }
    
    func deleteConversation(id: String) async throws {
        // Soft delete approach - mark as deleted but preserve data for legal/audit purposes
        struct DeleteData: Codable {
            let deleted_at: String
            let deleted_by: String
        }
        
        let deleteData = DeleteData(
            deleted_at: Date().ISO8601Format(),
            deleted_by: try await getCurrentUserId()
        )
        
        try await supabaseClient
            .from("conversations")
            .update(deleteData)
            .eq("id", value: id)
            .execute()
    }
    
    func hideConversationForUser(conversationId: String, userId: String) async throws {
        // Hide conversation from user's view without affecting other participants
        struct HideData: Codable {
            let hidden_for_user: Bool
            let hidden_at: String
        }
        
        let hideData = HideData(
            hidden_for_user: true,
            hidden_at: Date().ISO8601Format()
        )
        
        try await supabaseClient
            .from("conversation_participants")
            .update(hideData)
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    private func getCurrentUserId() async throws -> String {
        let session = try await supabaseClient.auth.session
        return session.user.id.uuidString
    }
    
    func addParticipant(conversationId: String, userId: String) async throws {
        let participant = [
            "id": UUID().uuidString,
            "conversation_id": conversationId,
            "user_id": userId,
            "joined_at": Date().ISO8601Format()
        ]
        
        try await supabaseClient
            .from("conversation_participants")
            .insert(participant)
            .execute()
    }
    
    func removeParticipant(conversationId: String, userId: String) async throws {
        try await supabaseClient
            .from("conversation_participants")
            .delete()
            .eq("conversation_id", value: conversationId)
            .eq("user_id", value: userId)
            .execute()
    }
}

/**
 * Implementation of realtime data access.
 */
@MainActor
final class RealtimeDataAccess: RealtimeDataAccessProtocol {
    
    private let supabaseClient: SupabaseClient
    private var subscriptions: [String: RealtimeChannelV2] = [:]
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    func subscribeToMessages(
        conversationId: String,
        onMessage: @escaping @Sendable (MessageRecord) -> Void
    ) async throws -> SubscriptionToken {
        let channelId = "messages:\(conversationId)"
        
        let channel = supabaseClient.realtimeV2.channel(channelId)
        
        // Set up the channel with postgres changes for INSERT events
        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages"
        ) { change in
            // Check if this message is for our conversation
            if let convId = change.record["conversation_id"] as? String,
               convId == conversationId {
                // Handle new message
                let data = change.record
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let message = try decoder.decode(MessageRecord.self, from: jsonData)
                    Task { @MainActor in
                        onMessage(message)
                    }
                } catch {
                    print("Failed to decode message: \(error)")
                }
            }
        }
        
        // Subscribe to the channel
        await channel.subscribe()
        
        subscriptions[channelId] = channel
        
        return SubscriptionToken(id: channelId, channel: channelId)
    }
    
    func subscribeToConversations(
        userId: String,
        onUpdate: @escaping @Sendable (ConversationRecord) -> Void
    ) async throws -> SubscriptionToken {
        let channelId = "conversations:\(userId)"
        
        let channel = supabaseClient.realtimeV2.channel(channelId)
        
        // Set up the channel with postgres changes for UPDATE events
        _ = channel.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "conversations"
        ) { change in
            // Handle conversation update
            let data = change.record
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let conversation = try decoder.decode(ConversationRecord.self, from: jsonData)
                Task { @MainActor in
                    onUpdate(conversation)
                }
            } catch {
                print("Failed to decode conversation: \(error)")
            }
        }
        
        // Subscribe to the channel
        await channel.subscribe()
        
        subscriptions[channelId] = channel
        
        return SubscriptionToken(id: channelId, channel: channelId)
    }
    
    func unsubscribe(token: SubscriptionToken) async {
        if let channel = subscriptions[token.id] {
            await channel.unsubscribe()
            subscriptions.removeValue(forKey: token.id)
        }
    }
}