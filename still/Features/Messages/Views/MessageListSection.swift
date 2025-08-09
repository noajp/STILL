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
    let isGroupChatMode: Bool
    let authManager: AuthManager
    let viewModel: MessagesViewModel
    let formatTimestamp: (Date?) -> String
    let onConversationTap: (Conversation) -> AnyView
    let onDeleteConversation: (String) async -> Void
    
    // MARK: - Computed Properties
    
    private var filteredConversations: [Conversation] {
        if isGroupChatMode {
            // Convert GroupConversation to Conversation for unified display
            return groupConversations.map { groupConv in
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
        } else {
            // Return only direct message conversations
            return conversations
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        if filteredConversations.isEmpty {
            // Show appropriate empty state
            if isGroupChatMode {
                GroupChatEmptyStateView()
            } else {
                MessagesEmptyStateView()
            }
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
        if isGroupChatMode {
            // Display group conversation row
            if let groupConv = groupConversations.first(where: { $0.id == conversation.id }) {
                GroupConversationRow(
                    groupConversation: groupConv,
                    timestamp: formatTimestamp(conversation.lastMessageAt)
                )
            } else {
                // Fallback group conversation row
                GroupConversationRow(
                    groupConversation: GroupConversation(
                        id: conversation.id,
                        isGroup: true,
                        groupName: "Group Chat",
                        groupDescription: nil,
                        groupAvatarUrl: nil,
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
            }
        } else {
            // Display direct message conversation row
            ConversationRow(
                conversation: conversation,
                timestamp: formatTimestamp(conversation.lastMessageAt)
            )
        }
    }
}