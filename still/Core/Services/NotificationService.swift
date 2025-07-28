//======================================================================
// MARK: - NotificationService.swift
// Purpose: Service for managing app notifications including fetching, creating, and updating notification states (アプリ通知の取得、作成、状態更新を管理するサービス)
// Path: still/Core/Services/NotificationService.swift
//======================================================================

import Foundation
import Supabase

/// A comprehensive notification service that manages all notification operations
/// This service handles fetching, creating, updating, and managing notifications
/// Supports real-time updates and maintains global notification state
@MainActor
class NotificationService: ObservableObject {
    // MARK: - Singleton
    
    /// Shared instance of the notification service
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    
    /// Array of all notifications for the current user
    @Published var notifications: [AppNotification] = []
    
    /// Count of unread notifications
    @Published var unreadCount: Int = 0
    
    /// Loading state indicator
    @Published var isLoading: Bool = false
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Public Methods
    
    /// Fetches all notifications for a specific user from the database
    /// Updates the local notifications array and unread count
    /// - Parameter userId: The ID of the user to fetch notifications for
    func fetchNotifications(for userId: String) async {
        isLoading = true
        
        do {
            // Query notifications from Supabase, ordered by creation date (newest first)
            let response: [AppNotification] = try await SupabaseManager.shared.client
                .from("notifications")
                .select("*")
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            
            // Update local state
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
        
        // Check if like notification already exists for this user and post
        let exists = await checkLikeNotificationExists(fromUserId: fromUserId, toUserId: toUserId, postId: postId)
        if exists {
            print("ℹ️ Like notification already exists, skipping creation")
            return
        }
        
        let notification = AppNotification(
            id: UUID().uuidString,
            userId: toUserId,
            type: .like,
            title: "New Like",
            message: "\(senderProfile.displayName ?? senderProfile.username) liked your post",
            isRead: false,
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
        
        // Check if notification already exists - if so, just ignore (don't create duplicate)
        let exists = await checkFollowNotificationExists(fromUserId: fromUserId, toUserId: toUserId)
        if exists {
            print("ℹ️ Follow notification already exists, skipping creation")
            return
        }
        
        let notification = AppNotification(
            id: UUID().uuidString,
            userId: toUserId,
            type: .follow,
            title: "New Follower",
            message: "@\(senderProfile.username) started following you",
            isRead: false,
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
    
    func createFollowRequestNotification(
        fromUserId: String,
        toUserId: String,
        senderProfile: UserProfile
    ) async {
        print("🔔 NotificationService.createFollowRequestNotification called:")
        print("  - fromUserId: \(fromUserId)")
        print("  - toUserId: \(toUserId)")
        print("  - senderProfile: \(senderProfile.username)")
        
        guard fromUserId != toUserId else { 
            print("⚠️ Skipping notification creation: same user")
            return 
        }
        
        // Check if follow request notification already exists
        let exists = await checkFollowRequestNotificationExists(fromUserId: fromUserId, toUserId: toUserId)
        if exists {
            print("ℹ️ Follow request notification already exists, skipping creation")
            return
        }
        
        let notification = AppNotification(
            id: UUID().uuidString,
            userId: toUserId,
            type: .followRequest,
            title: "Follow Request",
            message: "@\(senderProfile.username) sent you a follow request",
            isRead: false,
            relatedUserId: fromUserId,
            relatedPostId: nil,
            metadata: AppNotification.NotificationMetadata(
                postImageUrl: nil,
                senderAvatarUrl: senderProfile.avatarUrl,
                senderDisplayName: senderProfile.displayName,
                senderUsername: senderProfile.username
            )
        )
        
        print("🔔 Follow request notification object created, calling saveNotification...")
        await saveNotification(notification)
    }
    
    func createFollowRequestApprovedNotification(
        fromUserId: String,
        toUserId: String,
        approverProfile: UserProfile
    ) async {
        print("🔔 NotificationService.createFollowRequestApprovedNotification called:")
        print("  - fromUserId: \(fromUserId)")
        print("  - toUserId: \(toUserId)")
        print("  - approverProfile: \(approverProfile.username)")
        
        guard fromUserId != toUserId else { 
            print("⚠️ Skipping notification creation: same user")
            return 
        }
        
        // Check if follow request approved notification already exists
        let exists = await checkFollowRequestApprovedNotificationExists(fromUserId: fromUserId, toUserId: toUserId)
        if exists {
            print("ℹ️ Follow request approved notification already exists, skipping creation")
            return
        }
        
        let notification = AppNotification(
            id: UUID().uuidString,
            userId: toUserId,
            type: .followRequestApproved,
            title: "Follow Request Approved",
            message: "\(approverProfile.displayName ?? approverProfile.username)があなたのフォローリクエストを承認しました",
            isRead: false,
            relatedUserId: fromUserId,
            relatedPostId: nil,
            metadata: AppNotification.NotificationMetadata(
                postImageUrl: nil,
                senderAvatarUrl: approverProfile.avatarUrl,
                senderDisplayName: approverProfile.displayName,
                senderUsername: approverProfile.username
            )
        )
        
        print("🔔 Follow request approved notification object created, calling saveNotification...")
        await saveNotification(notification)
    }
    
    private func checkFollowRequestApprovedNotificationExists(fromUserId: String, toUserId: String) async -> Bool {
        print("🔔 Checking if follow request approved notification exists:")
        print("  - fromUserId: \(fromUserId)")
        print("  - toUserId: \(toUserId)")
        
        do {
            let response: PostgrestResponse<[AppNotification]> = try await SupabaseManager.shared.client
                .from("notifications")
                .select()
                .eq("user_id", value: toUserId)
                .eq("type", value: "follow_request_approved")
                .eq("related_user_id", value: fromUserId)
                .limit(1)
                .execute()
            
            let exists = !response.value.isEmpty
            print(exists ? "ℹ️ Follow request approved notification exists" : "ℹ️ No existing follow request approved notification found")
            return exists
            
        } catch {
            print("⚠️ Error checking existing follow request approved notification: \(error)")
            return false
        }
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
                related_user_id: notification.relatedUserId != nil ? UUID(uuidString: notification.relatedUserId!) : nil,
                related_post_id: notification.relatedPostId != nil ? UUID(uuidString: notification.relatedPostId!) : nil,
                metadata: notification.metadata
            )
            
            print("🔔 Insert data prepared:")
            print("  - user_id: \(insertData.user_id)")
            print("  - type: \(insertData.type)")
            
            let response = try await SupabaseManager.shared.client
                .from("notifications")
                .upsert(insertData)
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
    
    private func upsertNotification(_ notification: AppNotification) async {
        print("🔔 Attempting to upsert notification:")
        print("  - UserID: \(notification.userId)")
        print("  - Type: \(notification.type)")
        print("  - RelatedUserID: \(notification.relatedUserId ?? "nil")")
        
        guard notification.relatedUserId != nil else {
            print("⚠️ Cannot upsert notification without related_user_id, falling back to insert")
            await saveNotification(notification)
            return
        }
        
        do {
            struct NotificationUpsert: Encodable {
                let user_id: UUID
                let type: String
                let title: String
                let message: String
                let is_read: Bool
                let related_user_id: UUID?
                let related_post_id: UUID?
                let metadata: AppNotification.NotificationMetadata?
            }
            
            let upsertData = NotificationUpsert(
                user_id: UUID(uuidString: notification.userId) ?? UUID(),
                type: notification.type.rawValue,
                title: notification.title,
                message: notification.message,
                is_read: false,
                related_user_id: notification.relatedUserId != nil ? UUID(uuidString: notification.relatedUserId!) : nil,
                related_post_id: notification.relatedPostId != nil ? UUID(uuidString: notification.relatedPostId!) : nil,
                metadata: notification.metadata
            )
            
            print("🔔 Upsert data prepared:")
            print("  - user_id: \(upsertData.user_id)")
            print("  - related_user_id: \(upsertData.related_user_id?.uuidString ?? "nil")")
            
            let response = try await SupabaseManager.shared.client
                .from("notifications")
                .upsert(upsertData)
                .execute()
            
            print("✅ Notification upserted successfully")
            print("  - Response status: \(response.status)")
            
        } catch {
            print("❌ Error upserting notification: \(error)")
            print("❌ Falling back to regular insert")
            await saveNotification(notification)
        }
    }
    
    private func checkLikeNotificationExists(fromUserId: String, toUserId: String, postId: String) async -> Bool {
        print("🔔 Checking if like notification exists:")
        print("  - fromUserId: \(fromUserId)")
        print("  - toUserId: \(toUserId)")
        print("  - postId: \(postId)")
        
        do {
            let response: PostgrestResponse<[AppNotification]> = try await SupabaseManager.shared.client
                .from("notifications")
                .select()
                .eq("user_id", value: toUserId)
                .eq("type", value: "like")
                .eq("related_user_id", value: fromUserId)
                .eq("related_post_id", value: postId)
                .limit(1)
                .execute()
            
            let exists = !response.value.isEmpty
            print(exists ? "ℹ️ Like notification exists" : "ℹ️ No existing like notification found")
            return exists
            
        } catch {
            print("⚠️ Error checking existing like notification: \(error)")
            return false
        }
    }
    
    private func checkFollowNotificationExists(fromUserId: String, toUserId: String) async -> Bool {
        print("🔔 Checking if follow notification exists:")
        print("  - fromUserId: \(fromUserId)")
        print("  - toUserId: \(toUserId)")
        
        do {
            let response: PostgrestResponse<[AppNotification]> = try await SupabaseManager.shared.client
                .from("notifications")
                .select()
                .eq("user_id", value: toUserId)
                .eq("type", value: "follow")
                .eq("related_user_id", value: fromUserId)
                .limit(1)
                .execute()
            
            let exists = !response.value.isEmpty
            print(exists ? "ℹ️ Follow notification exists" : "ℹ️ No existing follow notification found")
            return exists
            
        } catch {
            print("⚠️ Error checking existing notification: \(error)")
            return false
        }
    }
    
    private func checkFollowRequestNotificationExists(fromUserId: String, toUserId: String) async -> Bool {
        print("🔔 Checking if follow request notification exists:")
        print("  - fromUserId: \(fromUserId)")
        print("  - toUserId: \(toUserId)")
        
        do {
            let response: PostgrestResponse<[AppNotification]> = try await SupabaseManager.shared.client
                .from("notifications")
                .select()
                .eq("user_id", value: toUserId)
                .eq("type", value: "follow_request")
                .eq("related_user_id", value: fromUserId)
                .limit(1)
                .execute()
            
            let exists = !response.value.isEmpty
            print(exists ? "ℹ️ Follow request notification exists" : "ℹ️ No existing follow request notification found")
            return exists
            
        } catch {
            print("⚠️ Error checking existing follow request notification: \(error)")
            return false
        }
    }
    
    private func deleteExistingFollowNotification(fromUserId: String, toUserId: String) async {
        print("🔔 Attempting to delete existing follow notification:")
        print("  - fromUserId: \(fromUserId)")
        print("  - toUserId: \(toUserId)")
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("notifications")
                .delete()
                .eq("user_id", value: toUserId)
                .eq("type", value: "follow")
                .eq("related_user_id", value: fromUserId)
                .execute()
            
            print("✅ Existing follow notification deleted (if any)")
            print("  - Response status: \(response.status)")
            
        } catch {
            print("⚠️ Error deleting existing notification (might not exist): \(error)")
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