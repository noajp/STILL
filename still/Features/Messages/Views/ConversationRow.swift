//======================================================================
// MARK: - ConversationRow.swift
// Purpose: Conversation row components for message list display
// Path: still/Features/Messages/Views/ConversationRow.swift
//======================================================================

import SwiftUI

/**
 * ConversationRow displays a single conversation in the messages list.
 * 
 * Features:
 * - User avatar and name display
 * - Last message preview
 * - Timestamp formatting
 * - Unread message count badge
 * - Visual indicators for message status
 */
struct ConversationRow: View {
    // MARK: - Properties
    
    let conversation: Conversation
    let timestamp: String
    @EnvironmentObject var authManager: AuthManager
    
    // MARK: - Computed Properties
    
    private var hasUnread: Bool {
        (conversation.unreadCount ?? 0) > 0
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            avatarView
            
            // Conversation details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayName(currentUserId: authManager.currentUser?.id))
                        .font(.system(size: 16, weight: hasUnread ? .semibold : .regular))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timestamp)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Text(conversation.displayLastMessagePreview)
                    .font(.system(size: 14))
                    .foregroundColor(hasUnread ? MinimalDesign.Colors.primary : MinimalDesign.Colors.secondary)
                    .lineLimit(1)
            }
            
            // Unread badge
            if hasUnread {
                unreadBadge
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(MinimalDesign.Colors.background)
    }
    
    // MARK: - Avatar View
    
    @ViewBuilder
    private var avatarView: some View {
        Group {
            if let avatarUrl = conversation.displayAvatar(currentUserId: authManager.currentUser?.id) {
                RemoteImageView(imageURL: avatarUrl)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white, lineWidth: 2)
        )
    }
    
    // MARK: - Unread Badge
    
    @ViewBuilder
    private var unreadBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.red)
                .frame(width: 20, height: 20)
            
            Text("\(conversation.unreadCount ?? 0)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

/**
 * GroupConversationRow displays a group chat in the messages list.
 * 
 * Features:
 * - Group icon and name display
 * - Last message with sender name
 * - Member count indicator
 * - Unread message count badge
 */
struct GroupConversationRow: View {
    // MARK: - Properties
    
    let groupConversation: GroupConversation
    let timestamp: String
    @EnvironmentObject var authManager: AuthManager
    
    // MARK: - Computed Properties
    
    private var hasUnread: Bool {
        (groupConversation.unreadCount ?? 0) > 0
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Group avatar
            groupAvatarView
            
            // Group details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(groupConversation.displayName)
                        .font(.system(size: 16, weight: hasUnread ? .semibold : .regular))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timestamp)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                // Last message with sender name
                Text(groupConversation.displayLastMessagePreview)
                    .font(.system(size: 14))
                    .foregroundColor(hasUnread ? MinimalDesign.Colors.primary : MinimalDesign.Colors.secondary)
                    .lineLimit(1)
            }
            
            // Unread badge
            if hasUnread {
                unreadBadge
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(MinimalDesign.Colors.background)
    }
    
    // MARK: - Group Avatar View
    
    @ViewBuilder
    private var groupAvatarView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
            
            if let emoji = groupConversation.groupEmoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: 24))
            } else {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Unread Badge
    
    @ViewBuilder
    private var unreadBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.red)
                .frame(width: 20, height: 20)
            
            Text("\(groupConversation.unreadCount ?? 0)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}