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
        let response = try await supabaseClient
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: false)
            .limit(limit)
            .range(from: offset, to: offset + limit - 1)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([MessageRecord].self, from: response.data)
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
 * Implementation of conversation data access.
 */
@MainActor
final class ConversationDataAccess: ConversationDataAccessProtocol {
    
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    func fetchConversations(userId: String) async throws -> [ConversationRecord] {
        let response = try await supabaseClient
            .from("conversation_participants")
            .select("conversation_id, conversations(*)")
            .eq("user_id", value: userId)
            .execute()
        
        // Parse the nested response
        // This is simplified - actual implementation would properly parse the joined data
        return []
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
    
    func createConversation(_ record: ConversationRecord) async throws -> ConversationRecord {
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
        try await supabaseClient
            .from("conversations")
            .delete()
            .eq("id", value: id)
            .execute()
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