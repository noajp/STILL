//======================================================================
// MARK: - GroupConversationView.swift
// Path: still/Features/Messages/Views/GroupConversationView.swift
//======================================================================
import SwiftUI
import Combine

@MainActor
class GroupConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    
    let conversationId: String
    let groupConversation: GroupConversation?
    private let messageService = MessageServiceReplacement.shared
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedInitialMessages = false
    var hasScrolledOnce = false
    
    init(conversationId: String, groupConversation: GroupConversation? = nil) {
        self.conversationId = conversationId
        self.groupConversation = groupConversation
        
        print("🔄 GroupConversationViewModel init - ID: \(conversationId), hasGroupConversation: \(groupConversation != nil)")
        
        Task {
            await loadMessages()
            await markAsRead()
        }
        
        setupRealtimeListeners()
    }
    
    private func setupRealtimeListeners() {
        // Disable automatic listeners to prevent infinite loops and flickering
        // Messages will update when user sends a message or manually refreshes
    }
    
    private func addNewMessage(_ message: Message) {
        messages.append(message)
        
        // Auto-mark as read when viewing the conversation
        Task {
            await markAsRead()
        }
    }
    
    private func refreshMessages() async {
        // Only refresh if we haven't loaded recently to avoid excessive API calls
        let now = Date()
        if now.timeIntervalSince(lastRefresh) > 3.0 { // Minimum 3 seconds between refreshes
            lastRefresh = now
            await forceLoadMessages()
        }
    }
    
    func forceLoadMessages() async {
        
        isLoading = true
        
        do {
            let fetchedMessages = try await messageService.fetchMessages(for: conversationId)
            // Filter out deleted messages as a safety check
            messages = fetchedMessages.filter { !$0.isDeleted }
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private var lastRefresh = Date.distantPast
    
    func loadMessages() async {
        
        // Skip reload if already loaded to preserve local changes (like deletions)
        guard !hasLoadedInitialMessages else {
            print("📱 GroupConversationViewModel - Skipping message reload (already loaded)")
            return
        }
        
        isLoading = true
        print("📱 GroupConversationViewModel - Loading messages for: \(conversationId)")
        
        do {
            let fetchedMessages = try await messageService.fetchMessages(for: conversationId)
            // Filter out deleted messages as a safety check
            messages = fetchedMessages.filter { !$0.isDeleted }
            hasLoadedInitialMessages = true
            print("📱 GroupConversationViewModel - Loaded \(messages.count) messages")
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
            print("❌ GroupConversationViewModel - Failed to load messages: \(error)")
        }
        
        isLoading = false
    }
    
    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSending = true
        
        do {
            let newMessage = try await messageService.sendMessage(conversationId: conversationId, content: content)
            // Only add message if it's not already in the list (prevent duplicates)
            if !messages.contains(where: { $0.id == newMessage.id }) {
                messages.append(newMessage)
            }
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }
        
        isSending = false
    }
    
    func markAsRead() async {
        do {
            try await messageService.markConversationAsRead(conversationId)
        } catch {
        }
    }
    
}

struct GroupConversationView: View {
    @StateObject private var viewModel: GroupConversationViewModel
    @State private var messageText = ""
    @State private var showingProfile = false
    @State private var selectedUserId: String?
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    init(conversationId: String, groupConversation: GroupConversation? = nil) {
        _viewModel = StateObject(wrappedValue: GroupConversationViewModel(conversationId: conversationId, groupConversation: groupConversation))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Add space for custom header
                            Spacer()
                                .frame(height: 60) // Height for custom navigation bar
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 8) {
                                Text("Error loading messages")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("Retry") {
                                    Task {
                                        await viewModel.forceLoadMessages()
                                    }
                                }
                            }
                            .padding()
                        } else {
                            ForEach(viewModel.messages) { message in
                                GroupMessageBubble(message: message)
                                .environmentObject(authManager)
                                .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    // Scroll to bottom when new message is added
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    // Scroll to bottom only on first load, not on every appear
                    if !viewModel.hasScrolledOnce && !viewModel.messages.isEmpty {
                        if let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            viewModel.hasScrolledOnce = true
                        }
                    }
                }
                
                // Bottom padding for input area
                Spacer()
                    .frame(height: 80)
            }
        }
            
            // Message input - positioned at bottom
            VStack {
                Spacer()
                MessageInputView(
                    text: $messageText,
                    isSending: viewModel.isSending,
                    isTextFieldFocused: $isTextFieldFocused,
                    onSend: {
                        Task {
                            await viewModel.sendMessage(messageText)
                            messageText = ""
                            isTextFieldFocused = false
                        }
                    }
                )
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .background(MinimalDesign.Colors.background)
        .accentColor(MinimalDesign.Colors.accentRed)
        .toolbar {
            // Custom back button with group name
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 8) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.accentRed)
                    }
                    
                    HStack(spacing: 8) {
                        // グループアイコン
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                        
                        // グループ名
                        Text(viewModel.groupConversation?.displayName ?? "Group Chat")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.primary)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.markAsRead()
            }
        }
        .fullScreenCover(isPresented: $showingProfile) {
            if let userId = selectedUserId, userId != authManager.currentUser?.id {
                OtherUserProfileView(userId: userId)
            }
        }
    }
}

struct GroupMessageBubble: View {
    let message: Message
    @EnvironmentObject var authManager: AuthManager
    @State private var showingProfile = false
    
    private var isCurrentUser: Bool {
        guard let currentUserId = authManager.currentUser?.id else { 
                return false 
        }
        
        // Compare with lowercase to handle UUID case differences  
        let senderIdLower = message.senderId.lowercased()
        let currentIdLower = currentUserId.lowercased()
        let result = senderIdLower == currentIdLower
        
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 送信者名（グループチャットでは表示、自分のメッセージ以外）
            if !isCurrentUser {
                HStack {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Text(message.sender?.username ?? "Unknown")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black) // 黒字に変更
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.leading, 40) // プロフィール画像の幅分だけ左にずらす
            }
            
            HStack(alignment: .top, spacing: 8) {
                if !isCurrentUser {
                    // 送信者のプロフィール画像（グループチャットでは常に表示）
                    Button(action: {
                        showingProfile = true
                    }) {
                        Group {
                            if let avatarUrl = message.sender?.avatarUrl {
                                RemoteImageView(imageURL: avatarUrl)
                                    .frame(width: 32, height: 32)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(String(message.sender?.username.prefix(1) ?? "?").uppercased())
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Spacer(minLength: 40) // 自分のメッセージの場合は左側にスペース
                }
                
                HStack(alignment: .bottom, spacing: 0) {
                    if isCurrentUser { 
                        Spacer(minLength: 50) 
                    }
                    
                    VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isCurrentUser ? MinimalDesign.Colors.accentRed : Color.gray.opacity(0.2))
                            .foregroundColor(isCurrentUser ? MinimalDesign.Colors.background : MinimalDesign.Colors.primary)
                            .cornerRadius(18)
                        
                        if message.isEdited {
                            Text("Edited")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
                    
                    if !isCurrentUser { 
                        Spacer(minLength: 50) 
                    }
                }
                
                if isCurrentUser {
                    Spacer(minLength: 40) // 自分のメッセージの場合は右側にアバター用のスペース
                }
            }
        }
        .fullScreenCover(isPresented: $showingProfile) {
            if let senderId = message.sender?.id, senderId != authManager.currentUser?.id {
                OtherUserProfileView(userId: senderId)
            }
        }
    }
}