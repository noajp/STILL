//======================================================================
// MARK: - ConversationPreview.swift
// Purpose: Conversation preview components for context menus
// Path: still/Features/Messages/Views/ConversationPreview.swift
//======================================================================

import SwiftUI

/**
 * ConversationPreviewFullScreen displays a full-screen preview of a conversation
 * typically used in context menu previews.
 * 
 * Features:
 * - Navigation bar with back button styling
 * - Message list with automatic scrolling
 * - Disabled message input area
 * - Loading states
 */
struct ConversationPreviewFullScreen: View {
    // MARK: - Properties
    
    let conversation: Conversation
    @StateObject private var previewModel = ConversationPreviewModel()
    @EnvironmentObject var authManager: AuthManager
    
    // MARK: - Computed Properties
    
    private var currentUserId: String? {
        authManager.currentUser?.id
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            navigationBar
            
            // Messages area
            messagesScrollView
            
            // Message input area (disabled)
            disabledInputArea
            
            // Bottom spacer
            Rectangle()
                .fill(Color.clear)
                .frame(height: 60)
        }
        .onAppear {
            Task {
                await previewModel.loadMessages(for: conversation.id)
            }
        }
    }
    
    // MARK: - Navigation Bar
    
    @ViewBuilder
    private var navigationBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MinimalDesign.Colors.accentRed)
                
                if let avatarUrl = conversation.displayAvatar(currentUserId: currentUserId) {
                    RemoteImageView(imageURL: avatarUrl)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Text(conversation.displayName(currentUserId: currentUserId))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            MinimalDesign.Colors.background
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Messages ScrollView
    
    @ViewBuilder
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    if previewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        // Add spacer at top to push messages to bottom
                        Spacer()
                            .frame(minHeight: 80)
                        
                        ForEach(previewModel.messages.suffix(20)) { message in
                            MessageBubblePreview(
                                message: message,
                                isCurrentUser: isCurrentUserMessage(message)
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        MinimalDesign.Colors.background.opacity(0.3),
                        MinimalDesign.Colors.background
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .defaultScrollAnchor(.bottom)
            .onChange(of: previewModel.messages.count) { _, newCount in
                // Only scroll to bottom once when messages are first loaded
                if newCount > 0 && !previewModel.hasScrolledToBottom && !previewModel.isLoading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let lastMessage = previewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            previewModel.hasScrolledToBottom = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Disabled Input Area
    
    @ViewBuilder
    private var disabledInputArea: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: .constant(""))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(true)
            
            Button(action: {}) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(MinimalDesign.Colors.accentRed)
            }
            .disabled(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(MinimalDesign.Colors.background)
    }
    
    // MARK: - Helper Methods
    
    private func isCurrentUserMessage(_ message: Message) -> Bool {
        guard let currentUserId = currentUserId else { return false }
        return message.senderId.lowercased() == currentUserId.lowercased()
    }
}

/**
 * ConversationPreview displays a compact preview of a conversation
 * suitable for smaller preview contexts.
 */
struct ConversationPreview: View {
    // MARK: - Properties
    
    let conversation: Conversation
    @StateObject private var previewModel = ConversationPreviewModel()
    @EnvironmentObject var authManager: AuthManager
    
    // MARK: - Computed Properties
    
    private var currentUserId: String? {
        authManager.currentUser?.id
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            messagesView
        }
        .background(MinimalDesign.Colors.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            Task {
                await previewModel.loadMessages(for: conversation.id)
            }
        }
    }
    
    // MARK: - Header View
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            // Avatar
            Group {
                if let avatarUrl = conversation.displayAvatar(currentUserId: currentUserId) {
                    RemoteImageView(imageURL: avatarUrl)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        )
                }
            }
            
            // Name and time
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.displayName(currentUserId: currentUserId))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MinimalDesign.Colors.primary)
                
                if let lastMessageAt = conversation.lastMessageAt {
                    Text(lastMessageAt.timeAgoDisplay())
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(MinimalDesign.Colors.background)
    }
    
    // MARK: - Messages View
    
    @ViewBuilder
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    if previewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        ForEach(previewModel.messages.suffix(10)) { message in
                            MessagePreviewRow(
                                message: message,
                                isCurrentUser: isCurrentUserMessage(message)
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .background(MinimalDesign.Colors.background)
            .onAppear {
                // Scroll to the last message when preview appears
                if let lastMessage = previewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
            .onChange(of: previewModel.messages.count) { _, _ in
                // Scroll to the last message when messages are loaded
                if let lastMessage = previewModel.messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isCurrentUserMessage(_ message: Message) -> Bool {
        guard let currentUserId = currentUserId else { return false }
        return message.senderId.lowercased() == currentUserId.lowercased()
    }
}

/**
 * MessagePreviewRow displays a single message in the preview context.
 */
struct MessagePreviewRow: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            Text(message.content)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .font(.system(size: 14))
                .foregroundColor(isCurrentUser ? MinimalDesign.Colors.background : MinimalDesign.Colors.primary)
                .frame(maxWidth: 200, alignment: isCurrentUser ? .trailing : .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isCurrentUser ? MinimalDesign.Colors.primary : Color.gray.opacity(0.2))
                )
            
            if !isCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Preview ViewModel

/**
 * ConversationPreviewModel handles data loading for conversation previews.
 */
@MainActor
class ConversationPreviewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    var hasScrolledToBottom = false
    
    private let messageService = MessageServiceReplacement.shared
    
    func loadMessages(for conversationId: String) async {
        isLoading = true
        hasScrolledToBottom = false
        do {
            messages = try await messageService.fetchMessages(for: conversationId)
        } catch {
            print("❌ Error loading preview messages: \(error)")
        }
        isLoading = false
    }
}