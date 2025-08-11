//======================================================================
// MARK: - MessageListSection.swift
// Purpose: Reusable conversation list component for Messages feature
// Path: still/Features/Messages/Views/MessageListSection.swift
//======================================================================

import SwiftUI

/**
 * MessageListSection displays a list of conversations with appropriate UI
 * based on the current mode (direct messages or group chats).
 * 
 * Features:
 * - Displays conversation rows with avatars, names, and last messages
 * - Shows unread count badges when applicable
 * - Provides context menu actions for conversation management
 * - Supports both direct and group chat display modes
 * - Handles empty state presentation
 */
struct MessageListSection: View {
    // MARK: - Properties
    
    let conversations: [Conversation]
    let groupConversations: [GroupConversation]
    let authManager: AuthManager
    let viewModel: MessagesViewModel
    let formatTimestamp: (Date?) -> String
    let onConversationTap: (Conversation) -> AnyView
    let onDeleteConversation: (String) async -> Void
    
    // MARK: - Computed Properties
    
    private var filteredConversations: [Conversation] {
        // Merge both direct messages and group conversations
        var allConversations = conversations
        
        // Convert GroupConversation to Conversation for unified display
        let convertedGroupConversations = groupConversations.map { groupConv in
            var conversation = Conversation(
                id: groupConv.id,
                createdAt: groupConv.createdAt,
                updatedAt: groupConv.updatedAt,
                lastMessageAt: groupConv.lastMessageAt,
                lastMessagePreview: groupConv.lastMessageContent
            )
            conversation.participants = [] // Group members are handled separately
            conversation.unreadCount = groupConv.unreadCount
            return conversation
        }
        
        allConversations.append(contentsOf: convertedGroupConversations)
        
        // Sort by last message time (most recent first)
        return allConversations.sorted { 
            ($0.lastMessageAt ?? $0.updatedAt) > ($1.lastMessageAt ?? $1.updatedAt)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        if filteredConversations.isEmpty {
            // Show unified empty state
            MessagesEmptyStateView()
        } else {
            // Display conversation list
            VStack(spacing: 0) {
                ForEach(filteredConversations) { conversation in
                    // Create navigation destination
                    let destinationView = onConversationTap(conversation)
                    
                    NavigationLink(destination: destinationView) {
                        conversationRow(for: conversation)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        // Delete action in context menu
                        Button("Delete", role: .destructive) {
                            Task {
                                await onDeleteConversation(conversation.id)
                            }
                        }
                    } preview: {
                        // Preview of conversation
                        ConversationPreviewFullScreen(conversation: conversation)
                            .environmentObject(authManager)
                    }
                    
                    // Add divider between conversations
                    if conversation.id != filteredConversations.last?.id {
                        Divider()
                            .padding(.leading, 70)
                    }
                }
                
                // Bottom padding for tab bar
                Color.clear
                    .frame(height: 110)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    @ViewBuilder
    private func conversationRow(for conversation: Conversation) -> some View {
        // Check if this is a group conversation by looking for it in the group conversations
        if let groupConv = groupConversations.first(where: { $0.id == conversation.id }) {
            // Display group conversation row
            GroupConversationRow(
                groupConversation: groupConv,
                timestamp: formatTimestamp(conversation.lastMessageAt)
            )
        } else if let participants = conversation.participants, participants.count > 2 {
            // Multi-participant direct conversation - treat as group
            GroupConversationRow(
                groupConversation: GroupConversation(
                    id: conversation.id,
                    isGroup: true,
                    groupName: "Group Chat",
                    groupDescription: nil,
                    groupAvatarUrl: nil,
                    groupEmoji: "👥",
                    createdBy: "",
                    createdAt: conversation.createdAt,
                    updatedAt: conversation.updatedAt,
                    lastMessageAt: conversation.lastMessageAt,
                    lastMessageContent: conversation.lastMessagePreview,
                    lastMessageSenderId: nil,
                    lastMessageSenderUsername: nil,
                    unreadCount: conversation.unreadCount
                ),
                timestamp: formatTimestamp(conversation.lastMessageAt)
            )
        } else {
            // Display direct message conversation row
            ConversationRow(
                conversation: conversation,
                timestamp: formatTimestamp(conversation.lastMessageAt)
            )
        }
    }
}