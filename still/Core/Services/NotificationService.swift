//======================================================================
// MARK: - NotificationService.swift
// Purpose: Service for managing app notifications including fetching, creating, and updating notification states (アプリ通知の取得、作成、状態更新を管理するサービス)
// Path: still/Core/Services/NotificationService.swift
//======================================================================

import Foundation
import Supabase

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    
    private init() {}
    
    func fetchNotifications(for userId: String) async {
        isLoading = true
        
        do {
            let response: [AppNotification] = try await SupabaseManager.shared.client
                .from("notifications")
                .select("*")
                .eq("userId", value: userId)
                .order("createdAt", ascending: false)
                .limit(50)
                .execute()
                .value
            
            self.notifications = response
            self.unreadCount = response.filter { !$0.isRead }.count
        } catch {
            print("❌ Error fetching notifications: \(error)")
        }
        
        isLoading = false
    }
    
    func markAsRead(_ notificationId: String) async {
        do {
            try await SupabaseManager.shared.client
                .from("notifications")
                .update(["isRead": true])
                .eq("id", value: notificationId)
                .execute()
            
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                notifications[index] = AppNotification(
                    id: notifications[index].id,
                    userId: notifications[index].userId,
                    type: notifications[index].type,
                    title: notifications[index].title,
                    message: notifications[index].message,
                    isRead: true,
                    createdAt: notifications[index].createdAt,
                    relatedUserId: notifications[index].relatedUserId,
                    relatedPostId: notifications[index].relatedPostId,
                    metadata: notifications[index].metadata
                )
                unreadCount = notifications.filter { !$0.isRead }.count
            }
        } catch {
            print("❌ Error marking notification as read: \(error)")
        }
    }
    
    func markAllAsRead(for userId: String) async {
        do {
            try await SupabaseManager.shared.client
                .from("notifications")
                .update(["isRead": true])
                .eq("userId", value: userId)
                .eq("isRead", value: false)
                .execute()
            
            notifications = notifications.map { notification in
                AppNotification(
                    id: notification.id,
                    userId: notification.userId,
                    type: notification.type,
                    title: notification.title,
                    message: notification.message,
                    isRead: true,
                    createdAt: notification.createdAt,
                    relatedUserId: notification.relatedUserId,
                    relatedPostId: notification.relatedPostId,
                    metadata: notification.metadata
                )
            }
            unreadCount = 0
        } catch {
            print("❌ Error marking all notifications as read: \(error)")
        }
    }
    
    func createLikeNotification(
        fromUserId: String,
        toUserId: String,
        postId: String,
        senderProfile: UserProfile
    ) async {
        guard fromUserId != toUserId else { return }
        
        let notification = AppNotification(
            id: UUID().uuidString,
            userId: toUserId,
            type: .like,
            title: "New Like",
            message: "\(senderProfile.displayName ?? senderProfile.username) liked your post",
            isRead: false,
            createdAt: Date(),
            relatedUserId: fromUserId,
            relatedPostId: postId,
            metadata: AppNotification.NotificationMetadata(
                postImageUrl: nil,
                senderAvatarUrl: senderProfile.avatarUrl,
                senderDisplayName: senderProfile.displayName,
                senderUsername: senderProfile.username
            )
        )
        
        await saveNotification(notification)
    }
    
    func createFollowNotification(
        fromUserId: String,
        toUserId: String,
        senderProfile: UserProfile
    ) async {
        guard fromUserId != toUserId else { return }
        
        let notification = AppNotification(
            id: UUID().uuidString,
            userId: toUserId,
            type: .follow,
            title: "New Follower",
            message: "\(senderProfile.displayName ?? senderProfile.username) started following you",
            isRead: false,
            createdAt: Date(),
            relatedUserId: fromUserId,
            relatedPostId: nil,
            metadata: AppNotification.NotificationMetadata(
                postImageUrl: nil,
                senderAvatarUrl: senderProfile.avatarUrl,
                senderDisplayName: senderProfile.displayName,
                senderUsername: senderProfile.username
            )
        )
        
        await saveNotification(notification)
    }
    
    private func saveNotification(_ notification: AppNotification) async {
        do {
            struct NotificationInsert: Encodable {
                let id: String
                let userId: String
                let type: String
                let title: String
                let message: String
                let isRead: Bool
                let createdAt: Double
                let relatedUserId: String?
                let relatedPostId: String?
                let metadata: AppNotification.NotificationMetadata?
            }
            
            let insertData = NotificationInsert(
                id: notification.id,
                userId: notification.userId,
                type: notification.type.rawValue,
                title: notification.title,
                message: notification.message,
                isRead: notification.isRead,
                createdAt: notification.createdAt.timeIntervalSince1970,
                relatedUserId: notification.relatedUserId,
                relatedPostId: notification.relatedPostId,
                metadata: notification.metadata
            )
            
            try await SupabaseManager.shared.client
                .from("notifications")
                .insert(insertData)
                .execute()
            
        } catch {
            print("❌ Error saving notification: \(error)")
        }
    }
}