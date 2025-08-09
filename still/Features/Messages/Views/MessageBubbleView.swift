//======================================================================
// MARK: - MessageBubbleView.swift
// Purpose: Reusable message bubble component for displaying chat messages
// Path: still/Features/Messages/Views/MessageBubbleView.swift
//======================================================================

import SwiftUI

/**
 * MessageBubbleView displays individual messages in a conversation
 * with appropriate styling based on the sender.
 * 
 * Features:
 * - Different styling for sent vs received messages
 * - Support for text messages with proper formatting
 * - Edit indicator for modified messages
 * - Timestamp display
 * - Long press actions (copy, delete, etc.)
 * - Smooth animations and transitions
 */
struct MessageBubbleView: View {
    // MARK: - Properties
    
    let message: Message
    let isCurrentUser: Bool
    let showTimestamp: Bool
    let onDelete: (() -> Void)?
    let onEdit: (() -> Void)?
    
    // MARK: - State
    
    @State private var showActions = false
    
    // MARK: - Initialization
    
    init(
        message: Message,
        isCurrentUser: Bool,
        showTimestamp: Bool = false,
        onDelete: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil
    ) {
        self.message = message
        self.isCurrentUser = isCurrentUser
        self.showTimestamp = showTimestamp
        self.onDelete = onDelete
        self.onEdit = onEdit
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message bubble
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .foregroundColor(textColor)
                    .cornerRadius(18)
                    .contextMenu {
                        contextMenuItems
                    }
                
                // Message metadata
                HStack(spacing: 4) {
                    if showTimestamp {
                        Text(formatTimestamp(message.createdAt))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    if message.isEdited {
                        Text("• Edited")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    // Read receipts can be implemented later when readAt is added to Message model
                }
            }
            .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
            
            if !isCurrentUser {
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal, 16)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Computed Properties
    
    private var bubbleBackground: some View {
        Group {
            if isCurrentUser {
                MinimalDesign.Colors.accentRed
            } else {
                Color.gray.opacity(0.2)
            }
        }
    }
    
    private var textColor: Color {
        isCurrentUser ? MinimalDesign.Colors.background : MinimalDesign.Colors.primary
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Button(action: {
            UIPasteboard.general.string = message.content
        }) {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        if isCurrentUser && onEdit != nil {
            Button(action: {
                onEdit?()
            }) {
                Label("Edit", systemImage: "pencil")
            }
        }
        
        if isCurrentUser && onDelete != nil {
            Button(role: .destructive, action: {
                onDelete?()
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Compact Message Bubble

/**
 * CompactMessageBubbleView provides a more condensed version of message bubbles
 * suitable for preview contexts or dense conversation views.
 */
struct CompactMessageBubbleView: View {
    // MARK: - Properties
    
    let message: Message
    let isCurrentUser: Bool
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            Text(message.content)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .font(.system(size: 14))
                .foregroundColor(
                    isCurrentUser ? MinimalDesign.Colors.background : MinimalDesign.Colors.primary
                )
                .frame(maxWidth: 200, alignment: isCurrentUser ? .trailing : .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isCurrentUser ? MinimalDesign.Colors.primary : Color.gray.opacity(0.2)
                        )
                )
            
            if !isCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Message Group View

/**
 * MessageGroupView displays multiple messages from the same sender
 * grouped together with appropriate spacing and sender information.
 */
struct MessageGroupView: View {
    // MARK: - Properties
    
    let messages: [Message]
    let senderName: String?
    let senderAvatar: String?
    let isCurrentUser: Bool
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            // Sender info (for received messages)
            if !isCurrentUser, let name = senderName {
                HStack(spacing: 8) {
                    if let avatar = senderAvatar {
                        RemoteImageView(imageURL: avatar)
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                    }
                    
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.leading, 16)
            }
            
            // Messages
            ForEach(messages) { message in
                MessageBubbleView(
                    message: message,
                    isCurrentUser: isCurrentUser,
                    showTimestamp: message.id == messages.last?.id
                )
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview Provider

struct MessageBubbleView_Previews: PreviewProvider {
    static let sampleMessage = Message(
        id: "1",
        conversationId: "conv1",
        senderId: "user1",
        content: "Hello! How are you doing today?",
        createdAt: Date(),
        updatedAt: Date(),
        isEdited: false,
        isDeleted: false
    )
    
    static let editedMessage = Message(
        id: "2",
        conversationId: "conv1",
        senderId: "user2",
        content: "I'm doing great, thanks for asking!",
        createdAt: Date(),
        updatedAt: Date(),
        isEdited: true,
        isDeleted: false
    )
    
    static var previews: some View {
        VStack(spacing: 20) {
            // Sent message
            MessageBubbleView(
                message: sampleMessage,
                isCurrentUser: true,
                showTimestamp: true
            )
            
            // Received message
            MessageBubbleView(
                message: editedMessage,
                isCurrentUser: false,
                showTimestamp: true
            )
            
            // Compact versions
            CompactMessageBubbleView(
                message: sampleMessage,
                isCurrentUser: true
            )
            
            CompactMessageBubbleView(
                message: editedMessage,
                isCurrentUser: false
            )
        }
        .padding()
        .background(MinimalDesign.Colors.background)
    }
}