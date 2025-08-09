//======================================================================
// MARK: - MessagesView.swift
// Purpose: Messages interface with conversation list and real-time messaging functionality
// Path: still/Features/Messages/Views/MessagesView.swift
//======================================================================

import SwiftUI

// Helper struct for navigation
struct ConversationNavigation: Identifiable, Hashable, Equatable {
    let id: String
}

/**
 * MessagesView provides the main messaging interface for the STILL app.
 * 
 * This view displays a list of conversations and supports:
 * - Dual mode switching between direct messages and group chats
 * - Real-time conversation updates and message previews
 * - Context menu actions for conversation management
 * - Navigation to individual conversations and message composition
 * - Empty state handling for new users
 * - Pull-to-refresh and automatic data synchronization
 * 
 * The interface adapts based on the current mode (direct or group chat)
 * and provides appropriate UI elements and navigation flows.
 */
struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var showNewMessage = false
    @State private var selectedConversation: ConversationNavigation?
    @State private var isNavigatingToNewMessage = false
    @State private var isNavigatingToCreateGroup = false
    @EnvironmentObject var authManager: AuthManager
    @Binding var isGroupChatMode: Bool
    
    var body: some View {
        let headerTitle = isGroupChatMode ? "GROUP CHATS" : "MESSAGES"
        let headerIcon = isGroupChatMode ? "person.2.fill" : "square.and.pencil"
        let headerAction: () -> Void = {
            if isGroupChatMode {
                // Navigate to group chat creation
                isNavigatingToCreateGroup = true
            } else {
                isNavigatingToNewMessage = true 
            }
        }
        
        return ScrollableHeaderView(
            title: headerTitle,
            rightButton: HeaderButton(
                icon: headerIcon,
                action: headerAction
            )
        ) {
            if viewModel.isLoading {
                LoadingStateView()
            } else {
                MessageListSection(
                    conversations: viewModel.conversations,
                    groupConversations: viewModel.groupConversations,
                    isGroupChatMode: isGroupChatMode,
                    authManager: authManager,
                    viewModel: viewModel,
                    formatTimestamp: viewModel.formatTimestamp,
                    onConversationTap: { conversation in
                        AnyView(getDestinationView(for: conversation))
                    },
                    onDeleteConversation: { conversationId in
                        await viewModel.deleteConversation(conversationId)
                    }
                )
            }
        }
        .onAppear {
            Task {
                // 常にリストを更新して最新の状態を保つ
                await viewModel.refreshConversations()
            }
        }
        .navigationDestination(isPresented: $isNavigatingToNewMessage) {
                NewMessageView { userId in
                    Task {
                        print("🔄 Starting conversation creation with user: \(userId)")
                        print("🔍 Debug: Current conversations count before creation: \(viewModel.conversations.count)")
                        
                        if let conversationId = await viewModel.createNewConversation(with: userId) {
                            print("✅ Conversation created with ID: \(conversationId)")
                            print("🔍 Debug: Current conversations count after creation: \(viewModel.conversations.count)")
                            
                            // 会話リストを強制更新してUIに反映
                            await viewModel.refreshConversations()
                            print("🔍 Debug: Current conversations count after refresh: \(viewModel.conversations.count)")
                            
                            // 少し待ってから最終確認
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            print("🔍 Debug: Final conversations list:")
                            for (index, conv) in viewModel.conversations.enumerated() {
                                print("   [\(index)] ID: \(conv.id)")
                                conv.participants?.forEach { participant in
                                    print("       - \(participant.user?.username ?? "unknown") (\(participant.userId))")
                                }
                            }
                            
                            // 会話作成が完了してから画面遷移
                            await MainActor.run {
                                print("🎯 Setting selectedConversation to: \(conversationId)")
                                selectedConversation = ConversationNavigation(id: conversationId)
                                isNavigatingToNewMessage = false
                            }
                        } else {
                            print("❌ Failed to create conversation with user: \(userId)")
                            print("🔍 Error message: \(viewModel.errorMessage ?? "No error message available")")
                            await MainActor.run {
                                isNavigatingToNewMessage = false
                            }
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedConversation) { navItem in
                // Simplified navigation - determine view type based on conversation data
                let conversationId = navItem.id
                if let groupConv = viewModel.groupConversations.first(where: { $0.id == conversationId }) {
                    GroupConversationView(conversationId: conversationId, groupConversation: groupConv)
                } else if let conversation = viewModel.conversations.first(where: { $0.id == conversationId }) {
                    ConversationView(conversationId: conversationId, conversation: conversation)
                } else {
                    // Fallback - let the view load its own data
                    ConversationView(conversationId: conversationId, conversation: nil)
                }
            }
            .onChange(of: selectedConversation) { oldValue, newValue in
                // チャットルームから戻った時（selectedConversationがnilになった時）にサイレント更新
                if oldValue != nil && newValue == nil {
                    Task {
                        await viewModel.silentRefreshConversations()
                    }
                }
            }
            .navigationDestination(isPresented: $isNavigatingToCreateGroup) {
                CreateGroupChatView { selectedUserIds in
                    Task {
                        print("🔄 Creating group chat with users: \(selectedUserIds)")
                        if let conversationId = await viewModel.createGroupChat(name: "Group Chat", with: selectedUserIds) {
                            print("✅ Group chat created with ID: \(conversationId)")
                            await MainActor.run {
                                selectedConversation = ConversationNavigation(id: conversationId)
                                isNavigatingToCreateGroup = false
                            }
                        } else {
                            print("❌ Failed to create group chat")
                        }
                    }
                }
            }
        .accentColor(MinimalDesign.Colors.accentRed)
        .background(MinimalDesign.Colors.background)
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    private func getDestinationView(for conversation: Conversation) -> some View {
        if isGroupChatMode {
            // グループチャットの場合はGroupConversationViewを使用
            if let groupConv = viewModel.groupConversations.first(where: { $0.id == conversation.id }) {
                GroupConversationView(conversationId: conversation.id, groupConversation: groupConv)
            } else {
                GroupConversationView(conversationId: conversation.id, groupConversation: nil)
            }
        } else {
            // 通常のチャットの場合はConversationViewを使用
            ConversationView(conversationId: conversation.id, conversation: conversation)
        }
    }
    
}

// MARK: - Loading State View

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading conversations...")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - New Message View


struct NewMessageView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = UserSearchViewModel()
    @State private var searchText = ""
    let onSelectUser: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // ミニマルな検索バー
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.system(size: 16))
                
                TextField("Search users", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .onChange(of: searchText) { _, newValue in
                        Task {
                            await viewModel.searchUsers(query: newValue)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.top, 20)
                
            // User list
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.users.isEmpty && !searchText.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("No users found")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    Spacer()
                }
            } else if searchText.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.2")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("Search for users to start a conversation")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.users, id: \.id) { user in
                            UserRowView(user: user) {
                                onSelectUser(user.id)
                                dismiss()
                            }
                            
                            if user.id != viewModel.users.last?.id {
                                Divider()
                                    .padding(.leading, 70)
                            }
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
        .navigationTitle("New Message")
        .navigationBarTitleDisplayMode(.inline)
        .accentColor(MinimalDesign.Colors.accentRed)
        .background(MinimalDesign.Colors.background)
        .navigationBarHidden(false)
    }
}

struct UserRowView: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Profile image - より洗練されたデザイン
                if let avatarUrl = user.avatarUrl {
                    RemoteImageView(imageURL: avatarUrl)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(String(user.profileDisplayName.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    // 表示名を最初に表示
                    Text(user.profileDisplayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    // ユーザーIDを小さい文字で表示
                    Text("@\(user.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 13))
                            .foregroundColor(.gray.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Conversation Preview is now in ConversationPreview.swift

// MARK: - Message Bubble Preview

struct MessageBubblePreview: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        MessageBubbleView(
            message: message,
            isCurrentUser: isCurrentUser,
            showTimestamp: false
        )
        .padding(.horizontal, 20)
    }
}

