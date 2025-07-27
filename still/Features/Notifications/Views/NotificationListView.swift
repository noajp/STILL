//======================================================================
// MARK: - NotificationListView.swift
// Purpose: Notification list view displaying all user notifications with read/unread states (ユーザーの全通知を既読/未読状態で表示する通知一覧ビュー)  
// Path: still/Features/Notifications/Views/NotificationListView.swift
//======================================================================

import SwiftUI

struct NotificationListView: View {
    @StateObject private var notificationService = NotificationService.shared
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                UnifiedHeader(
                    title: "Notifications",
                    rightButton: HeaderButton(
                        icon: "xmark",
                        action: { dismiss() }
                    ),
                    extraRightButton: notificationService.unreadCount > 0 ? HeaderButton(
                        icon: "checkmark.circle",
                        action: {
                            Task {
                                if let userId = authManager.currentUser?.id {
                                    await notificationService.markAllAsRead(for: userId)
                                }
                            }
                        }
                    ) : nil
                )
                
                if notificationService.isLoading {
                    // Loading State
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading notifications...")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notificationService.notifications.isEmpty {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Notifications")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("You'll see notifications for likes, follows,\nand messages here")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    // Notification List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(notificationService.notifications) { notification in
                                NotificationRowView(notification: notification)
                                    .onTapGesture {
                                        Task {
                                            if !notification.isRead {
                                                await notificationService.markAsRead(notification.id)
                                            }
                                        }
                                    }
                                
                                if notification.id != notificationService.notifications.last?.id {
                                    Divider()
                                        .padding(.leading, 70)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .background(MinimalDesign.Colors.background)
            .task {
                if let userId = authManager.currentUser?.id {
                    await notificationService.fetchNotifications(for: userId)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct NotificationRowView: View {
    let notification: AppNotification
    @State private var navigateToProfile = false
    @State private var isAccepting = false
    @State private var hasAccepted = false
    @State private var isFollowing = false
    @State private var isFollowingUser = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with badge
            HStack(spacing: 0) {
                // Unread Badge
                if !notification.isRead {
                    Circle()
                        .fill(MinimalDesign.Colors.accentRed)
                        .frame(width: 8, height: 8)
                } else {
                    // Invisible spacer to maintain consistent spacing
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
                    .frame(width: 8)
                
                // Tappable Avatar
                Button(action: {
                    navigateToProfile = true
                }) {
                    AsyncImage(url: URL(string: notification.metadata?.senderAvatarUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 20))
                            )
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Title and Message
                HStack(alignment: .top, spacing: 8) {
                    Button(action: {
                        navigateToProfile = true
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(notification.displayMessage)
                                .font(.system(size: 14, weight: notification.isRead ? .regular : .medium))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    // Action buttons for follow notifications
                    if notification.type == .follow || notification.type == .followRequest {
                        HStack(spacing: 8) {
                            // Accept button for follow requests (only show if not yet accepted)
                            if notification.type == .followRequest && !hasAccepted {
                                Button(action: {
                                    acceptFollowRequest()
                                }) {
                                    if isAccepting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Accept")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(.green)
                                .cornerRadius(6)
                                .disabled(isAccepting)
                            }
                            
                            // Follow button (appears after accepting follow request or for regular follow notifications)
                            if hasAccepted || notification.type == .follow {
                                Button(action: {
                                    followUser()
                                }) {
                                    if isFollowingUser {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(isFollowing ? "Following" : "Follow")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(isFollowing ? .gray : MinimalDesign.Colors.accentRed)
                                .cornerRadius(6)
                                .disabled(isFollowingUser)
                            }
                            
                            // View profile button (always show)
                            Button(action: {
                                navigateToProfile = true
                            }) {
                                Text("View")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.blue)
                                    .cornerRadius(6)
                            }
                        }
                    } else {
                        // Type Icon for other notifications
                        Image(systemName: notification.type.icon)
                            .foregroundColor(Color(notification.type.color))
                            .font(.system(size: 16))
                    }
                }
                
                // Post Image (for like notifications)
                if notification.type == .like, 
                   let postImageUrl = notification.metadata?.postImageUrl {
                    AsyncImage(url: URL(string: postImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(notification.isRead ? Color.clear : Color.gray.opacity(0.05))
        .navigationDestination(isPresented: $navigateToProfile) {
            if let userId = notification.relatedUserId {
                OtherUserProfileView(userId: userId)
            }
        }
        .onAppear {
            // Check follow status when view appears
            checkFollowStatus()
        }
    }
    
    private func acceptFollowRequest() {
        guard let fromUserId = notification.relatedUserId,
              let currentUserId = AuthManager.shared.currentUser?.id else { return }
        
        isAccepting = true
        
        Task {
            do {
                // Update the follow status from pending to accepted
                let _ = try await SupabaseManager.shared.client
                    .from("follows")
                    .update(["status": "accepted"])
                    .eq("follower_id", value: fromUserId)
                    .eq("following_id", value: currentUserId)
                    .eq("status", value: "pending")
                    .execute()
                
                // Create follow notification now that the request is accepted
                await createAcceptedFollowNotification(fromUserId: fromUserId, toUserId: currentUserId)
                
                // Update UI state
                await MainActor.run {
                    hasAccepted = true
                    isAccepting = false
                }
                
                // Refresh notifications to update any counts or states
                if let currentUserId = AuthManager.shared.currentUser?.id {
                    await NotificationService.shared.fetchNotifications(for: currentUserId)
                }
                
                print("✅ Follow request accepted from notification")
                
            } catch {
                await MainActor.run {
                    isAccepting = false
                }
                print("❌ Error accepting follow request from notification: \(error)")
            }
        }
    }
    
    private func createAcceptedFollowNotification(fromUserId: String, toUserId: String) async {
        do {
            let senderProfile = try await UserRepository.shared.fetchUserProfile(userId: toUserId)
            await NotificationService.shared.createFollowNotification(
                fromUserId: fromUserId,
                toUserId: toUserId,
                senderProfile: senderProfile
            )
        } catch {
            print("❌ Failed to create accepted follow notification: \(error)")
        }
    }
    
    private func checkFollowStatus() {
        guard let targetUserId = notification.relatedUserId else { return }
        
        Task {
            do {
                let followStatus = try await FollowService.shared.checkFollowStatus(userId: targetUserId)
                await MainActor.run {
                    isFollowing = followStatus.isFollowing
                }
            } catch {
                print("❌ Error checking follow status in notification: \(error)")
            }
        }
    }
    
    private func followUser() {
        guard let targetUserId = notification.relatedUserId else { return }
        
        isFollowingUser = true
        
        Task {
            do {
                if isFollowing {
                    // Unfollow
                    try await FollowService.shared.unfollowUser(userId: targetUserId)
                    await MainActor.run {
                        isFollowing = false
                        isFollowingUser = false
                    }
                } else {
                    // Follow
                    try await FollowService.shared.followUser(userId: targetUserId)
                    let followStatus = try await FollowService.shared.checkFollowStatus(userId: targetUserId)
                    await MainActor.run {
                        isFollowing = followStatus.isFollowing
                        isFollowingUser = false
                    }
                }
                
                print("✅ Follow action completed from notification")
                
            } catch {
                await MainActor.run {
                    isFollowingUser = false
                }
                print("❌ Error in follow action from notification: \(error)")
            }
        }
    }
}

#if DEBUG
struct NotificationListView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationListView()
            .environmentObject(AuthManager.shared)
    }
}
#endif