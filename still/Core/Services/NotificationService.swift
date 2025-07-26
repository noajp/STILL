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
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
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
                .update(["is_read": true])
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
                .update(["is_read": true])
                .eq("user_id", value: userId)
                .eq("is_read", value: false)
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
        print("🔔 NotificationService.createLikeNotification called:")
        print("  - fromUserId: \(fromUserId)")
        print("  - toUserId: \(toUserId)")
        print("  - postId: \(postId)")
        print("  - senderProfile: \(senderProfile.username)")
        
        guard fromUserId != toUserId else { 
            print("⚠️ Skipping notification creation: same user")
            return 
        }
        
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
        
        print("🔔 Like notification object created, calling saveNotification...")
        await saveNotification(notification)
    }
    
    func createFollowNotification(
        fromUserId: String,
        toUserId: String,
        senderProfile: UserProfile
    ) async {
        print("🔔 NotificationService.createFollowNotification called:")
        print("  - fromUserId: \(fromUserId)")
        print("  - toUserId: \(toUserId)")
        print("  - senderProfile: \(senderProfile.username)")
        
        guard fromUserId != toUserId else { 
            print("⚠️ Skipping notification creation: same user")
            return 
        }
        
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
        
        print("🔔 Follow notification object created, calling saveNotification...")
        await saveNotification(notification)
    }
    
    private func saveNotification(_ notification: AppNotification) async {
        print("🔔 Attempting to save notification:")
        print("  - ID: \(notification.id)")
        print("  - UserID: \(notification.userId)")
        print("  - Type: \(notification.type)")
        print("  - Title: \(notification.title)")
        print("  - Message: \(notification.message)")
        
        do {
            struct NotificationInsert: Encodable {
                let id: UUID
                let user_id: UUID
                let type: String
                let title: String
                let message: String
                let is_read: Bool
                let created_at: Date
                let related_user_id: UUID?
                let related_post_id: UUID?
                let metadata: AppNotification.NotificationMetadata?
            }
            
            let insertData = NotificationInsert(
                id: UUID(uuidString: notification.id) ?? UUID(),
                user_id: UUID(uuidString: notification.userId) ?? UUID(),
                type: notification.type.rawValue,
                title: notification.title,
                message: notification.message,
                is_read: notification.isRead,
                created_at: notification.createdAt,
                related_user_id: notification.relatedUserId != nil ? UUID(uuidString: notification.relatedUserId!) : nil,
                related_post_id: notification.relatedPostId != nil ? UUID(uuidString: notification.relatedPostId!) : nil,
                metadata: notification.metadata
            )
            
            print("🔔 Insert data prepared:")
            print("  - user_id: \(insertData.user_id)")
            print("  - type: \(insertData.type)")
            print("  - created_at: \(insertData.created_at)")
            
            let response = try await SupabaseManager.shared.client
                .from("notifications")
                .insert(insertData)
                .execute()
            
            print("✅ Notification saved successfully")
            print("  - Response status: \(response.status)")
            
        } catch {
            print("❌ Error saving notification: \(error)")
            print("❌ Error type: \(type(of: error))")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Debug Methods
    
    func createTestNotification(for userId: String) async {
        print("🔔 Creating test notification for user: \(userId)")
        
        let testNotification = AppNotification(
            id: UUID().uuidString,
            userId: userId,
            type: .follow,
            title: "Test Notification",
            message: "This is a test notification to verify the system is working",
            isRead: false,
            createdAt: Date(),
            relatedUserId: nil,
            relatedPostId: nil,
            metadata: AppNotification.NotificationMetadata(
                postImageUrl: nil,
                senderAvatarUrl: nil,
                senderDisplayName: "Test User",
                senderUsername: "testuser"
            )
        )
        
        await saveNotification(testNotification)
    }
}