//======================================================================
// MARK: - MessagesView.swift
// Purpose: Messages interface with conversation list and real-time messaging (会話リストとリアルタイムメッセージングのメッセージインターフェース)
// Path: still/Features/Messages/Views/MessagesView.swift
//======================================================================
import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var showNewMessage = false
    @State private var selectedConversationId: String?
    @State private var isNavigatingToNewMessage = false
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ScrollableHeaderView(
            title: "Messages",
            rightButton: HeaderButton(
                icon: "square.and.pencil",
                action: { isNavigatingToNewMessage = true }
            )
        ) {
            if viewModel.isLoading {
                ProgressView("Loading conversations...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.conversations.isEmpty {
                MessagesEmptyStateView()
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.conversations) { conversation in
                        NavigationLink(destination: ConversationView(conversationId: conversation.id, conversation: conversation)) {
                            ConversationRow(
                                conversation: conversation,
                                timestamp: viewModel.formatTimestamp(conversation.lastMessageAt)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                Task {
                                    await viewModel.deleteConversation(conversation.id)
                                }
                            }
                        } preview: {
                            ConversationPreview(conversation: conversation)
                                .environmentObject(authManager)
                                .frame(width: 300, height: 400)
                        }
                        
                        if conversation.id != viewModel.conversations.last?.id {
                            Divider()
                                .padding(.leading, 70)
                        }
                    }
                }
                .padding(.bottom, 100) // タブバー分のスペース
            }
        }
        .refreshable {
                await viewModel.refreshConversations()
            }
            .onAppear {
                Task {
                    // 初回読み込みでない場合はサイレント更新を使用
                    if viewModel.conversations.isEmpty {
                        await viewModel.refreshConversations()
                    } else {
                        await viewModel.silentRefreshConversations()
                    }
                }
            }
            .navigationDestination(isPresented: $isNavigatingToNewMessage) {
                NewMessageView { userId in
                    Task {
                        if let conversationId = await viewModel.createNewConversation(with: userId) {
                            isNavigatingToNewMessage = false
                            // Navigate directly to the conversation
                            selectedConversationId = conversationId
                        }
                    }
                }
            }
            .navigationDestination(item: Binding(
                get: { selectedConversationId.map { ConversationDestination(id: $0) } },
                set: { _ in selectedConversationId = nil }
            )) { destination in
                if let conversation = viewModel.conversations.first(where: { $0.id == destination.id }) {
                    ConversationView(conversationId: destination.id, conversation: conversation)
                }
            }
            .onChange(of: selectedConversationId) { oldValue, newValue in
                // チャットルームから戻った時（selectedConversationIdがnilになった時）にサイレント更新
                if oldValue != nil && newValue == nil {
                    Task {
                        await viewModel.silentRefreshConversations()
                    }
                }
            }
        .accentColor(MinimalDesign.Colors.accentRed)
    }
}

struct ConversationDestination: Identifiable, Hashable {
    let id: String
}

struct ConversationRow: View {
    let conversation: Conversation
    let timestamp: String
    @EnvironmentObject var authManager: AuthManager
    
    private var hasUnread: Bool {
        (conversation.unreadCount ?? 0) > 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // プロフィール画像
            if let avatarUrl = conversation.displayAvatar(currentUserId: authManager.currentUser?.id) {
                RemoteImageView(imageURL: avatarUrl)
                    .frame(width: 50, height: 50)
                    .clipShape(Rectangle())
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(MinimalDesign.Colors.secondary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text({
                        conversation.displayName(currentUserId: authManager.currentUser?.id)
                    }())
                        .font(.system(size: 16, weight: hasUnread ? .semibold : .regular))
                        .foregroundColor(MinimalDesign.Colors.primary)
                    
                    Spacer()
                    
                    Text(timestamp)
                        .font(.system(size: 14))
                        .foregroundColor(MinimalDesign.Colors.secondary)
                }
                
                Text(conversation.displayLastMessagePreview)
                    .font(.system(size: 14))
                    .foregroundColor(hasUnread ? MinimalDesign.Colors.primary : MinimalDesign.Colors.secondary)
                    .lineLimit(1)
            }
            
            if hasUnread {
                ZStack {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                    
                    Text("\(conversation.unreadCount ?? 0)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(MinimalDesign.Colors.background)
    }
}

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
            .background(Color.gray.opacity(0.1))
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
                        .foregroundColor(.gray)
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
                        .foregroundColor(.gray)
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
                        .foregroundColor(.gray)
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
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(String(user.profileDisplayName.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    // 表示名を最初に表示
                    Text(user.profileDisplayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(MinimalDesign.Colors.primary)
                    
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
                
                // 選択インジケーター
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Conversation Preview

struct ConversationPreview: View {
    let conversation: Conversation
    @StateObject private var previewModel = ConversationPreviewModel()
    @EnvironmentObject var authManager: AuthManager
    
    private var currentUserId: String? {
        authManager.currentUser?.id
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            messagesView
        }
        .background(MinimalDesign.Colors.background)
        .onAppear {
            Task {
                await previewModel.loadMessages(for: conversation.id)
            }
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            // Avatar
            Group {
                if let avatarUrl = conversation.displayAvatar(currentUserId: currentUserId) {
                    RemoteImageView(imageURL: avatarUrl)
                        .frame(width: 32, height: 32)
                        .clipShape(Rectangle())
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
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
                        .foregroundColor(MinimalDesign.Colors.secondary)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(MinimalDesign.Colors.background)
    }
    
    @ViewBuilder
    private var messagesView: some View {
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
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(MinimalDesign.Colors.background)
    }
    
    private func isCurrentUserMessage(_ message: Message) -> Bool {
        guard let currentUserId = currentUserId else { return false }
        return message.senderId.lowercased() == currentUserId.lowercased()
    }
}

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
                    Rectangle()
                        .fill(isCurrentUser ? MinimalDesign.Colors.primary : Color.gray.opacity(0.2))
                )
            
            if !isCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal, 12)
    }
}

// Preview用のシンプルなViewModel
@MainActor
class ConversationPreviewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    
    private let messageService = MessageService.shared
    
    func loadMessages(for conversationId: String) async {
        isLoading = true
        do {
            messages = try await messageService.fetchMessages(for: conversationId, limit: 10)
        } catch {
            print("❌ Error loading preview messages: \(error)")
        }
        isLoading = false
    }
}