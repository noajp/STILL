//======================================================================
// MARK: - ConversationView.swift
// Purpose: Direct message conversation view with encrypted messaging, 
// real-time updates, and participant management 
// (暗号化メッセージング、リアルタイム更新、参加者管理を持つダイレクトメッセージ会話ビュー)
// Path: still/Features/Messages/Views/ConversationView.swift
//======================================================================
import SwiftUI
import Combine

@MainActor
class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    
    let conversationId: String
    let conversation: Conversation?
    private let messageService = MessageService.shared
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedInitialMessages = false
    @Published var hasScrolledOnce = false
    
    init(conversationId: String, conversation: Conversation? = nil) {
        self.conversationId = conversationId
        self.conversation = conversation
        
        print("🔄 ConversationViewModel init - ID: \(conversationId), hasConversation: \(conversation != nil)")
        
        Task {
            await loadMessages()
            await markAsRead()
        }
        
        setupRealtimeListeners()
    }
    
    private func setupRealtimeListeners() {
        // Disable automatic listeners to prevent infinite loops and flickering
        // Messages will update when user sends a message or manually refreshes
        // messageService.objectWillChange
        //     .receive(on: DispatchQueue.main)
        //     .sink { [weak self] _ in
        //         Task {
        //             await self?.refreshMessages()
        //         }
        //     }
        //     .store(in: &cancellables)
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
            print("📱 ConversationViewModel - Skipping message reload (already loaded)")
            return
        }
        
        isLoading = true
        print("📱 ConversationViewModel - Loading messages for: \(conversationId)")
        
        do {
            let fetchedMessages = try await messageService.fetchMessages(for: conversationId)
            // Filter out deleted messages as a safety check
            messages = fetchedMessages.filter { !$0.isDeleted }
            hasLoadedInitialMessages = true
            print("📱 ConversationViewModel - Loaded \(messages.count) messages")
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
            print("❌ ConversationViewModel - Failed to load messages: \(error)")
        }
        
        isLoading = false
    }
    
    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSending = true
        
        do {
            let newMessage = try await messageService.sendMessage(to: conversationId, content: content)
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

struct ConversationView: View {
    @StateObject private var viewModel: ConversationViewModel
    @State private var messageText = ""
    @State private var showingProfile = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    init(conversationId: String, conversation: Conversation? = nil) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(conversationId: conversationId, conversation: conversation))
    }
    
    var body: some View {
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
                                    .foregroundColor(.white)
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
                                MessageBubble(message: message)
                                .environmentObject(authManager)
                                .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { oldCount, newCount in
                    // Only scroll to bottom when a new message is added, not when loading
                    if newCount > oldCount && !viewModel.isLoading {
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
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
            }
            
            // Message input
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .accentColor(MinimalDesign.Colors.accentRed)
        .overlay(
            // Custom Navigation Bar
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.accentRed)
                    }
                    
                    // User content - aligned to left
                    HStack(spacing: 8) {
                        if let conversation = viewModel.conversation,
                           let currentUserId = authManager.currentUser?.id,
                           let otherParticipant = conversation.participants?.first(where: { $0.userId.lowercased() != currentUserId.lowercased() }) {
                            
                            NavigationLink(destination: OtherUserProfileView(userId: otherParticipant.userId)) {
                                HStack(spacing: 8) {
                                    // プロフィール画像
                                    if let avatarUrl = conversation.displayAvatar(currentUserId: authManager.currentUser?.id) {
                                        RemoteImageView(imageURL: avatarUrl)
                                            .frame(width: 32, height: 32)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text(String(conversation.displayName(currentUserId: authManager.currentUser?.id).prefix(1)))
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                    
                                    // ユーザー名
                                    Text(conversation.displayName(currentUserId: authManager.currentUser?.id))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Text("Message")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(MinimalDesign.Colors.background)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            // Debug navigation
            if let conversation = viewModel.conversation,
               let currentUserId = authManager.currentUser?.id,
               let otherParticipant = conversation.participants?.first(where: { $0.userId.lowercased() != currentUserId.lowercased() }) {
                
                print("🔍 ConversationView Navigation - currentUserId: \(currentUserId)")
                print("🔍 ConversationView Navigation - otherParticipant.userId: \(otherParticipant.userId)")
                print("🔍 ConversationView Navigation - otherParticipant.user?.username: \(otherParticipant.user?.username ?? "nil")")
                print("🔍 ConversationView Navigation - All participants:")
                conversation.participants?.forEach { participant in
                    print("    - \(participant.userId) (\(participant.user?.username ?? "unknown"))")
                }
            }
            
            Task {
                await viewModel.markAsRead()
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    @EnvironmentObject var authManager: AuthManager
    
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
        HStack(alignment: .bottom, spacing: 0) {
            if isCurrentUser { 
                Spacer(minLength: 50) 
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.decryptedContent)
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
    }
}

struct MessageInputView: View {
    @Binding var text: String
    let isSending: Bool
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField("Type a message...", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .disabled(isSending)
                    .onSubmit {
                        onSend()
                    }
                
                Button(action: onSend) {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(MinimalDesign.Colors.accentRed)
                    }
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Spacer to account for custom tab bar
            Rectangle()
                .fill(Color.clear)
                .frame(height: 60) // Height to clear the custom tab bar
        }
    }
}