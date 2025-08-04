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
    
    // Removed: func markAsRead(_ notificationId: String) async
    
    func markAllAsRead(for userId: String) async {
        do {
            try await SupabaseManager.shared.client
                .from("notifications")
                .update(["is_read": true])
                .eq("user_id", value: userId)
                .eq("is_read", value: false)
                .execute()
            
            // Update local state to reflect all notifications as read
            notifications = notifications.map { notification in
                var updatedNotification = notification
                updatedNotification.isRead = true
                return updatedNotification
            }
            unreadCount = 0
        } catch {
            print("❌ Error marking all notifications as read: \(error)")
        }
    }
    
    // MARK: - Notification Creation
    
    func createLikeNotification(fromUserId: String, toUserId: String, postId: String, senderProfile: UserProfile) async {
        guard fromUserId != toUserId else { return }
        
        // Check if notification already exists
        let exists = await checkNotificationExists(userId: toUserId, type: .like, relatedUserId: fromUserId, relatedPostId: postId)
        if exists {
            print("ℹ️ Like notification already exists, skipping creation")
            return
        }
        
        let title = "New Like"
        let message = "\(senderProfile.displayName ?? senderProfile.username) liked your post"
        
        await createNotification(
            targetUserId: toUserId,
            relatedUserId: fromUserId,
            notificationType: AppNotification.NotificationType.like,
            title: title,
            message: message
        )
    }
    
    func createFollowNotification(fromUserId: String, toUserId: String, senderProfile: UserProfile) async {
        guard fromUserId != toUserId else { return }

        // Check if notification already exists
        let exists = await checkNotificationExists(userId: toUserId, type: .follow, relatedUserId: fromUserId)
        if exists {
            print("ℹ️ Follow notification already exists, skipping creation")
            return
        }

        let title = "New Follower"
        let message = "@\(senderProfile.username) started following you"

        await createNotification(
            targetUserId: toUserId,
            relatedUserId: fromUserId,
            notificationType: AppNotification.NotificationType.follow,
            title: title,
            message: message
        )
    }

    func createFollowRequestNotification(fromUserId: String, toUserId: String, senderProfile: UserProfile) async {
        guard fromUserId != toUserId else { return }

        // Check if notification already exists
        let exists = await checkNotificationExists(userId: toUserId, type: .followRequest, relatedUserId: fromUserId)
        if exists {
            print("ℹ️ Follow request notification already exists, skipping creation")
            return
        }

        let title = "Follow Request"
        let message = "@\(senderProfile.username) sent you a follow request"

        await createNotification(
            targetUserId: toUserId,
            relatedUserId: fromUserId,
            notificationType: AppNotification.NotificationType.followRequest,
            title: title,
            message: message
        )
    }

    func createFollowRequestApprovedNotification(fromUserId: String, toUserId: String, approverProfile: UserProfile) async {
        guard fromUserId != toUserId else { return }

        // Check if notification already exists
        let exists = await checkNotificationExists(userId: toUserId, type: .followRequestApproved, relatedUserId: fromUserId)
        if exists {
            print("ℹ️ Follow request approved notification already exists, skipping creation")
            return
        }

        let title = "Follow Request Approved"
        let message = "\(approverProfile.displayName ?? approverProfile.username) approved your follow request"

        await createNotification(
            targetUserId: toUserId,
            relatedUserId: fromUserId,
            notificationType: AppNotification.NotificationType.followRequestApproved,
            title: title,
            message: message
        )
    }

    func createCommentNotification(fromUserId: String, toUserId: String, postId: String, senderProfile: UserProfile) async {
        guard fromUserId != toUserId else { return }
        
        // Check if notification already exists
        let exists = await checkNotificationExists(userId: toUserId, type: .comment, relatedUserId: fromUserId, relatedPostId: postId)
        if exists {
            print("ℹ️ Comment notification already exists, skipping creation")
            return
        }
        
        let title = "New Comment"
        let message = "\(senderProfile.displayName ?? senderProfile.username) commented on your post"
        
        await createNotification(
            targetUserId: toUserId,
            relatedUserId: fromUserId,
            notificationType: AppNotification.NotificationType.comment,
            title: title,
            message: message
        )
    }

    // MARK: - Private RPC Call

    private func createNotification(
        targetUserId: String,
        relatedUserId: String,
        notificationType: AppNotification.NotificationType,
        title: String,
        message: String
    ) async {
        struct RpcParams: Encodable {
            let target_user_id: UUID
            let related_user_id: UUID
            let notification_type: String
            let title: String
            let message: String
        }

        guard let targetUUID = UUID(uuidString: targetUserId),
              let relatedUUID = UUID(uuidString: relatedUserId) else {
            print("❌ Error: Invalid UUID string")
            return
        }

        let params = RpcParams(
            target_user_id: targetUUID,
            related_user_id: relatedUUID,
            notification_type: notificationType.rawValue,
            title: title,
            message: message
        )

        do {
            try await SupabaseManager.shared.client
                .rpc("create_notification", params: params)
                .execute()
            print("✅ Notification created successfully via RPC for user \(targetUserId)")
        } catch {
            print("❌ Error calling create_notification RPC: \(error)")
        }
    }
    
    private func checkNotificationExists(
        userId: String,
        type: AppNotification.NotificationType,
        relatedUserId: String? = nil,
        relatedPostId: String? = nil
    ) async -> Bool {
        do {
            var query = SupabaseManager.shared.client
                .from("notifications")
                .select()
                .eq("user_id", value: userId)
                .eq("type", value: type.rawValue)
            
            // Only add related_user_id to query if it's provided
            if let relatedUserId = relatedUserId {
                query = query.eq("related_user_id", value: relatedUserId)
            } else {
                // If relatedUserId is nil, ensure we only match notifications where related_user_id is also nil
                query = query.is("related_user_id", value: nil)
            }
            
            // related_post_id はユニーク制約に含まれていないため、ここでは考慮しない
            // if let relatedPostId = relatedPostId {
            //     query = query.eq("related_post_id", value: relatedPostId)
            // } else {
            //     query = query.is("related_post_id", value: nil)
            // }
            
            let response: PostgrestResponse<[AppNotification]> = try await query
                .limit(1)
                .execute()
            
            return !response.value.isEmpty
        } catch {
            print("⚠️ Error checking existing notification: \(error)")
            return false
        }
    }
}