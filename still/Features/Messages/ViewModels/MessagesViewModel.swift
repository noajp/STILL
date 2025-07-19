//======================================================================
// MARK: - MessagesViewModel.swift
// Path: foodai/Features/Messages/ViewModels/MessagesViewModel.swift
//======================================================================
import Foundation
import SwiftUI
import Combine

extension Notification.Name {
    static let conversationMarkedAsRead = Notification.Name("conversationMarkedAsRead")
    static let messageWasSent = Notification.Name("messageWasSent")
}

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var groupConversations: [GroupConversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let messageService = MessageService.shared
    private var hasLoadedInitially = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            await loadConversationsIfNeeded()
        }
        
        // Listen for real-time updates
        setupRealtimeListeners()
        
        // Listen for auth state changes to reset the loaded flag
        NotificationCenter.default.publisher(for: .authStateChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.hasLoadedInitially = false
                self?.conversations = []
                Task {
                    await self?.loadConversationsIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupRealtimeListeners() {
        // Listen for conversation read status changes
        NotificationCenter.default.publisher(for: .conversationMarkedAsRead)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let conversationId = notification.object as? String else { return }
                
                // Update the specific conversation's unread count to 0
                if let index = self.conversations.firstIndex(where: { $0.id == conversationId }) {
                    self.conversations[index].unreadCount = 0
                    // Force UI update
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
        
        // Listen for new messages sent
        NotificationCenter.default.publisher(for: .messageWasSent)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let message = notification.object as? Message else { return }
                
                // Update conversation with new message immediately
                self.updateConversationWithNewMessage(message)
            }
            .store(in: &cancellables)
    }
    
    private func updateConversationInList(_ updatedConversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == updatedConversation.id }) {
            conversations[index] = updatedConversation
            // Re-sort by last message time
            conversations.sort { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }
        }
    }
    
    private func updateConversationWithNewMessage(_ message: Message) {
        if let index = conversations.firstIndex(where: { $0.id == message.conversationId }) {
            // Update last message preview and timestamp
            conversations[index].lastMessagePreview = message.content  // This is encrypted content
            conversations[index].lastMessageAt = message.createdAt
            
            // Move conversation to top
            let updatedConversation = conversations.remove(at: index)
            conversations.insert(updatedConversation, at: 0)
            
            // Force UI update
            objectWillChange.send()
        }
    }
    
    func loadConversationsIfNeeded() async {
        // 既に読み込み済みの場合はスキップ
        guard !hasLoadedInitially else { 
            return 
        }
        await loadConversations()
    }
    
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let directConversations = messageService.fetchConversations()
            async let groupChats = messageService.fetchGroupConversations()
            
            conversations = try await directConversations
            groupConversations = try await groupChats
            
            print("📋 MessagesViewModel - Loaded \(conversations.count) direct conversations and \(groupConversations.count) group chats")
            hasLoadedInitially = true
        } catch {
            print("❌ MessagesViewModel - Failed to load conversations: \(error.localizedDescription)")
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // 会話リストを強制的に更新（チャットルームから戻った時など）
    func refreshConversations() async {
        await loadConversations()
    }
    
    // サイレント更新（ローディング表示なし、チラつき防止）
    func silentRefreshConversations() async {
        // ローディング表示をせずにバックグラウンドで更新
        do {
            async let newDirectConversations = messageService.fetchConversations()
            async let newGroupConversations = messageService.fetchGroupConversations()
            
            let directChats = try await newDirectConversations
            let groupChats = try await newGroupConversations
            
            // UIの更新はメインスレッドで、アニメーション付きで行う
            withAnimation(.easeInOut(duration: 0.2)) {
                conversations = directChats
                groupConversations = groupChats
            }
        } catch {
            // エラーの場合はサイレントに失敗（UIは既存データを保持）
        }
    }
    
    func createNewConversation(with userId: String) async -> String? {
        do {
            let conversationId = try await messageService.getOrCreateDirectConversation(with: userId)
            
            // 会話リストを更新して、新しい会話が確実に含まれるようにする
            await refreshConversations()
            
            // 新しい会話がリストに追加されたことを確認
            if conversations.contains(where: { $0.id == conversationId }) {
                print("✅ New conversation created and added to list: \(conversationId)")
                return conversationId
            } else {
                print("⚠️ New conversation created but not found in list: \(conversationId)")
                return conversationId  // Still return the ID even if not in list yet
            }
        } catch {
            errorMessage = "Failed to create conversation: \(error.localizedDescription)"
            print("❌ Failed to create conversation: \(error)")
            return nil
        }
    }
    
    func formatTimestamp(_ date: Date?) -> String {
        guard let date = date else { return "" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        // 1分未満
        if timeInterval < 60 {
            return "今"
        }
        // 1時間未満（分単位）
        else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分前"
        }
        // 24時間未満（時間単位）
        else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)時間前"
        }
        // 7日未満（日単位）
        else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days)日前"
        }
        // それ以上は日付表示
        else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
    
    func deleteConversation(_ conversationId: String) async {
        do {
            try await messageService.deleteConversation(conversationId)
            // Remove from local list
            conversations.removeAll { $0.id == conversationId }
            groupConversations.removeAll { $0.id == conversationId }
        } catch {
            errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Group Chat Functions
    
    func createGroupChat(name: String, description: String? = nil, memberIds: [String] = []) async -> String? {
        do {
            let conversationId = try await messageService.createGroupChat(
                name: name,
                description: description,
                memberIds: memberIds
            )
            
            // Refresh group conversations to include the new one
            await refreshConversations()
            
            return conversationId
        } catch {
            errorMessage = "Failed to create group chat: \(error.localizedDescription)"
            print("❌ Failed to create group chat: \(error)")
            return nil
        }
    }
    
    func addGroupMember(conversationId: String, userId: String) async -> Bool {
        do {
            let success = try await messageService.addGroupMember(conversationId: conversationId, userId: userId)
            if success {
                await silentRefreshConversations()
            }
            return success
        } catch {
            errorMessage = "Failed to add member: \(error.localizedDescription)"
            return false
        }
    }
    
    func removeGroupMember(conversationId: String, userId: String) async -> Bool {
        do {
            let success = try await messageService.removeGroupMember(conversationId: conversationId, userId: userId)
            if success {
                await silentRefreshConversations()
            }
            return success
        } catch {
            errorMessage = "Failed to remove member: \(error.localizedDescription)"
            return false
        }
    }
}