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

    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        let headerTitle = "MESSAGES"
        let headerIcon = "square.and.pencil"
        let headerAction: () -> Void = {
            isNavigatingToNewMessage = true 
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
        .task {
            // Only load if data is not already cached
            await viewModel.loadConversationsIfNeeded()
        }
        .refreshable {
            // Allow manual refresh via pull-to-refresh
            await viewModel.refreshConversations()
        }
        .navigationDestination(isPresented: $isNavigatingToNewMessage) {
            NewMessageView { userIds in
                Task {
                    print("🔄 Starting conversation creation with users: \(userIds)")
                    
                    let conversationId: String?
                    
                    if userIds.count == 1 {
                        // Direct message with single user
                        conversationId = await viewModel.createNewConversation(with: userIds[0])
                        print("✅ Direct conversation created with ID: \(conversationId ?? "nil")")
                    } else {
                        // Group chat with multiple users
                        conversationId = await viewModel.createGroupChat(name: "Group Chat", emoji: "👥", with: userIds)
                        print("✅ Group conversation created with ID: \(conversationId ?? "nil")")
                    }
                    
                    if let conversationId = conversationId {
                        // Refresh conversations list
                        await viewModel.refreshConversations()
                        
                        // Navigate to the created conversation
                        await MainActor.run {
                            selectedConversation = ConversationNavigation(id: conversationId)
                            isNavigatingToNewMessage = false
                        }
                    } else {
                        print("❌ Failed to create conversation")
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

        .onReceive(NotificationCenter.default.publisher(for: .resetMessagesNavigation)) { _ in
            selectedConversation = nil
            isNavigatingToNewMessage = false
            showNewMessage = false
        }
        .accentColor(MinimalDesign.Colors.accentRed)
        .background(MinimalDesign.Colors.background)
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    private func getDestinationView(for conversation: Conversation) -> some View {
        // Determine if this is a group conversation by checking participant count
        if let participants = conversation.participants, participants.count > 2 {
            // Group conversation - use GroupConversationView
            if let groupConv = viewModel.groupConversations.first(where: { $0.id == conversation.id }) {
                GroupConversationView(conversationId: conversation.id, groupConversation: groupConv)
            } else {
                GroupConversationView(conversationId: conversation.id, groupConversation: nil)
            }
        } else {
            // Direct message - use ConversationView
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
    @State private var selectedUserIds: Set<String> = []
    @State private var selectedUserProfiles: [UserProfile] = []
    let onCreateConversation: ([String]) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Selected users bar
            if !selectedUserProfiles.isEmpty {
                selectedUsersDisplayBar
            }
            
            // Search bar
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
                            MultiSelectUserRowView(
                                user: user,
                                isSelected: selectedUserIds.contains(user.id)
                            ) {
                                toggleUserSelection(user)
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
    
    // MARK: - Selected Users Display Bar
    private var selectedUsersDisplayBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(selectedUserProfiles, id: \.id) { user in
                        SelectedUserChip(user: user) {
                            removeUserSelection(user)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 60)
            
            HStack(spacing: 12) {
                Text("\(selectedUserProfiles.count) selected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Start Chat") {
                    let selectedUserIdArray = Array(selectedUserIds)
                    onCreateConversation(selectedUserIdArray)
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(MinimalDesign.Colors.accentRed)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
    }
    
    // MARK: - Selected Users Bar (legacy)
    private var selectedUsersBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("\(selectedUserIds.count) selected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Start Chat") {
                    let selectedUserIdArray = Array(selectedUserIds)
                    onCreateConversation(selectedUserIdArray)
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(MinimalDesign.Colors.accentRed)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
    }
    
    // MARK: - Methods
    private func toggleUserSelection(_ user: UserProfile) {
        if selectedUserIds.contains(user.id) {
            selectedUserIds.remove(user.id)
            selectedUserProfiles.removeAll { $0.id == user.id }
        } else {
            selectedUserIds.insert(user.id)
            if !selectedUserProfiles.contains(where: { $0.id == user.id }) {
                selectedUserProfiles.append(user)
            }
        }
    }
    
    private func removeUserSelection(_ user: UserProfile) {
        selectedUserIds.remove(user.id)
        selectedUserProfiles.removeAll { $0.id == user.id }
    }
}



struct MultiSelectUserRowView: View {
    let user: UserProfile
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Profile image
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
                    Text(user.profileDisplayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
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
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? MinimalDesign.Colors.accentRed : .gray.opacity(0.5))
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
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

