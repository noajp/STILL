//======================================================================
// MARK: - ConversationHeaderView.swift
// Purpose: Reusable conversation header component for chat views
// Path: still/Features/Messages/Views/ConversationHeaderView.swift
//======================================================================

import SwiftUI

/**
 * ConversationHeaderView provides a reusable header for conversation screens.
 * 
 * Features:
 * - Back navigation button with chevron icon
 * - User/group avatar display
 * - Conversation title (user name or group name)
 * - Online status indicator (for direct messages)
 * - Action menu button for additional options
 * - Consistent styling across the app
 */
struct ConversationHeaderView: View {
    // MARK: - Properties
    
    let title: String
    let avatarUrl: String?
    let isGroup: Bool
    let isOnline: Bool
    let onBackTap: () -> Void
    let onMenuTap: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: onBackTap) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                    
                    // Avatar
                    avatarView
                    
                    // Title and status
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if !isGroup && isOnline {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Active now")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Menu button (if provided)
            if let onMenuTap = onMenuTap {
                Button(action: onMenuTap) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            MinimalDesign.Colors.background
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Avatar View
    
    @ViewBuilder
    private var avatarView: some View {
        if let avatarUrl = avatarUrl {
            RemoteImageView(imageURL: avatarUrl)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(isGroup ? Color.blue.opacity(0.2) : Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: isGroup ? "person.3.fill" : "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isGroup ? .blue : .white)
                )
        }
    }
}

// MARK: - Group Conversation Header

/**
 * GroupConversationHeaderView provides a specialized header for group chats
 * with member count display and group-specific actions.
 */
struct GroupConversationHeaderView: View {
    // MARK: - Properties
    
    let groupName: String
    let groupAvatarUrl: String?
    let memberCount: Int
    let onBackTap: () -> Void
    let onInfoTap: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Back button with group info
            Button(action: onBackTap) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                    
                    // Group avatar
                    if let avatarUrl = groupAvatarUrl {
                        RemoteImageView(imageURL: avatarUrl)
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                            )
                    }
                    
                    // Group name and member count
                    VStack(alignment: .leading, spacing: 2) {
                        Text(groupName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("\(memberCount) members")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Info button
            Button(action: onInfoTap) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            MinimalDesign.Colors.background
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Preview Provider

struct ConversationHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Direct message header
            ConversationHeaderView(
                title: "John Doe",
                avatarUrl: nil,
                isGroup: false,
                isOnline: true,
                onBackTap: {},
                onMenuTap: {}
            )
            .previewDisplayName("Direct Message - Online")
            
            // Group chat header
            ConversationHeaderView(
                title: "Design Team",
                avatarUrl: nil,
                isGroup: true,
                isOnline: false,
                onBackTap: {},
                onMenuTap: nil
            )
            .previewDisplayName("Group Chat")
            
            // Group conversation header with member count
            GroupConversationHeaderView(
                groupName: "Project Alpha",
                groupAvatarUrl: nil,
                memberCount: 12,
                onBackTap: {},
                onInfoTap: {}
            )
            .previewDisplayName("Group Header with Members")
        }
        .background(MinimalDesign.Colors.background)
    }
}