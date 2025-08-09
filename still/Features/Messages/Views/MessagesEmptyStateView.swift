//======================================================================
// MARK: - MessagesEmptyStateView.swift
// Purpose: Empty state views for Messages feature
// Path: still/Features/Messages/Views/MessagesEmptyStateView.swift
//======================================================================

import SwiftUI

/**
 * MessagesEmptyStateView displays when there are no direct message conversations.
 * 
 * Features:
 * - Informative message for new users
 * - Clean minimal design
 * - Centered layout with proper spacing
 */
struct MessagesEmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()
            Spacer()
            
            Text("Start a conversation with someone")
                .font(.body)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/**
 * GroupChatEmptyStateView displays when there are no group chat conversations.
 * 
 * Features:
 * - Group chat specific messaging
 * - Icon illustration
 * - Multi-line descriptive text
 * - Call-to-action guidance
 */
struct GroupChatEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Group icon
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            // Title
            Text("No group chats yet")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            // Description
            Text("Create a group chat to start\nchatting with multiple people")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}