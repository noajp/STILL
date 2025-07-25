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
    @State private var isNavigatingToCreateGroup = false
    @EnvironmentObject var authManager: AuthManager
    @Binding var isGroupChatMode: Bool
    
    var body: some View {
        let headerTitle = isGroupChatMode ? "Group Chats" : "Messages"
        let headerIcon = isGroupChatMode ? "person.2.fill" : "square.and.pencil"
        let headerAction: () -> Void = {
            if isGroupChatMode {
                // グループチャット作成画面へ
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
                ProgressView("Loading conversations...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if viewModel.conversations.isEmpty {
                if isGroupChatMode {
                    GroupChatEmptyStateView()
                } else {
                    MessagesEmptyStateView()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredConversations) { conversation in
                        let destinationView = getDestinationView(for: conversation)
                        NavigationLink(destination: destinationView) {
                            if isGroupChatMode {
                                // GroupConversationを取得
                                if let groupConv = viewModel.groupConversations.first(where: { $0.id == conversation.id }) {
                                    GroupConversationRow(
                                        groupConversation: groupConv,
                                        timestamp: viewModel.formatTimestamp(conversation.lastMessageAt)
                                    )
                                } else {
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
                                        timestamp: viewModel.formatTimestamp(conversation.lastMessageAt)
                                    )
                                }
                            } else {
                                ConversationRow(
                                    conversation: conversation,
                                    timestamp: viewModel.formatTimestamp(conversation.lastMessageAt)
                                )
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                Task {
                                    await viewModel.deleteConversation(conversation.id)
                                }
                            }
                        } preview: {
                            ConversationPreviewFullScreen(conversation: conversation)
                                .environmentObject(authManager)
                        }
                        
                        if conversation.id != filteredConversations.last?.id {
                            Divider()
                                .padding(.leading, 70)
                        }
                    }
                    
                    // タブバー用の下部余白
                    Color.clear
                        .frame(height: 110)
                }
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
                        if let conversationId = await viewModel.createNewConversation(with: userId) {
                            print("✅ Conversation created with ID: \(conversationId)")
                            
                            // 会話リストを強制更新してUIに反映
                            await viewModel.refreshConversations()
                            
                            // 会話作成が完了してから画面遷移
                            await MainActor.run {
                                print("🎯 Setting selectedConversationId to: \(conversationId)")
                                selectedConversationId = conversationId
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
            .navigationDestination(item: Binding(
                get: { selectedConversationId.map { ConversationDestination(id: $0) } },
                set: { _ in selectedConversationId = nil }
            )) { destination in
                // 会話データがない場合でも適切なViewを表示
                // View内で会話データを取得する
                let conversation = viewModel.conversations.first(where: { $0.id == destination.id })
                let groupConversation = viewModel.groupConversations.first(where: { $0.id == destination.id })
                let _ = print("🎯 Navigating to conversation with ID: \(destination.id), hasConversation: \(conversation != nil), hasGroupConversation: \(groupConversation != nil)")
                
                if let groupConv = groupConversation {
                    return AnyView(GroupConversationView(conversationId: destination.id, groupConversation: groupConv))
                } else {
                    return AnyView(ConversationView(conversationId: destination.id, conversation: conversation))
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
            .navigationDestination(isPresented: $isNavigatingToCreateGroup) {
                CreateGroupChatView { selectedUserIds in
                    Task {
                        print("🔄 Creating group chat with users: \(selectedUserIds)")
                        if let conversationId = await viewModel.createGroupChat(name: "Group Chat", with: selectedUserIds) {
                            print("✅ Group chat created with ID: \(conversationId)")
                            await MainActor.run {
                                selectedConversationId = conversationId
                                isNavigatingToCreateGroup = false
                            }
                        } else {
                            print("❌ Failed to create group chat")
                        }
                    }
                }
            }
        .accentColor(MinimalDesign.Colors.accentRed)
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
    
    private var filteredConversations: [Conversation] {
        if isGroupChatMode {
            // グループチャットモードでは、GroupConversationをConversationに変換して表示
            return viewModel.groupConversations.map { groupConv in
                var conversation = Conversation(
                    id: groupConv.id,
                    createdAt: groupConv.createdAt,
                    updatedAt: groupConv.updatedAt,
                    lastMessageAt: groupConv.lastMessageAt,
                    lastMessagePreview: groupConv.lastMessageContent
                )
                conversation.participants = [] // グループメンバーは別途取得
                conversation.unreadCount = groupConv.unreadCount
                return conversation
            }
        } else {
            // 個人チャットのみ表示
            return viewModel.conversations
        }
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
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
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
                    RoundedRectangle(cornerRadius: 4)
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

struct GroupChatEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            Text("No group chats yet")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Text("Create a group chat to start\nchatting with multiple people")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GroupConversationRow: View {
    let groupConversation: GroupConversation
    let timestamp: String
    @EnvironmentObject var authManager: AuthManager
    
    private var hasUnread: Bool {
        (groupConversation.unreadCount ?? 0) > 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // グループチャット用のアイコン（とりあえずシンプルに）
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(groupConversation.displayName)
                        .font(.system(size: 16, weight: hasUnread ? .semibold : .regular))
                        .foregroundColor(MinimalDesign.Colors.primary)
                    
                    Spacer()
                    
                    Text(timestamp)
                        .font(.system(size: 14))
                        .foregroundColor(MinimalDesign.Colors.secondary)
                }
                
                // displayLastMessagePreviewを使用（既に送信者名が含まれている）
                Text(groupConversation.displayLastMessagePreview)
                    .font(.system(size: 14))
                    .foregroundColor(hasUnread ? MinimalDesign.Colors.primary : MinimalDesign.Colors.secondary)
                    .lineLimit(1)
            }
            
            if hasUnread {
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
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(MinimalDesign.Colors.background)
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
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
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
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Conversation Preview

struct ConversationPreviewFullScreen: View {
    let conversation: Conversation
    @StateObject private var previewModel = ConversationPreviewModel()
    @EnvironmentObject var authManager: AuthManager
    
    private var currentUserId: String? {
        authManager.currentUser?.id
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
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
                        .foregroundColor(MinimalDesign.Colors.primary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            
            // Messages area
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
                            Color(.systemGray6).opacity(0.3),
                            Color(.systemBackground)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .defaultScrollAnchor(.bottom)
                .onChange(of: previewModel.messages.count) { _, newCount in
                    // Only scroll to bottom once when messages are first loaded, not during loading
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
            
            // Message input area
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
            .background(Color(.systemBackground))
            
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
    
    private func isCurrentUserMessage(_ message: Message) -> Bool {
        guard let currentUserId = currentUserId else { return false }
        return message.senderId.lowercased() == currentUserId.lowercased()
    }
}

struct MessageBubblePreview: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isCurrentUser { 
                Spacer(minLength: 40) 
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 6) {
                Text(message.decryptedContent)
                    .font(.system(size: 16))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        Group {
                            if isCurrentUser {
                                MinimalDesign.Colors.accentRed
                            } else {
                                Color(.systemGray5)
                                    .opacity(0.9)
                            }
                        }
                    )
                    .foregroundColor(
                        isCurrentUser ? 
                        MinimalDesign.Colors.background : 
                        Color(.label)
                    )
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                
                if message.isEdited {
                    Text("Edited")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
            
            if !isCurrentUser { 
                Spacer(minLength: 40) 
            }
        }
    }
}

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
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
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
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
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
            
            Text(message.decryptedContent)
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

// Preview用のシンプルなViewModel
@MainActor
class ConversationPreviewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    var hasScrolledToBottom = false
    
    private let messageService = MessageService.shared
    
    func loadMessages(for conversationId: String) async {
        isLoading = true
        hasScrolledToBottom = false
        do {
            messages = try await messageService.fetchMessages(for: conversationId, limit: 10)
        } catch {
            print("❌ Error loading preview messages: \(error)")
        }
        isLoading = false
    }
}