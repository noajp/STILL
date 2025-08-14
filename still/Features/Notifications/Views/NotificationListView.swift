//======================================================================
// MARK: - NotificationListView.swift
// Purpose: Notification list view displaying all user notifications with read/unread states (ユーザーの全通知を既読/未読状態で表示する通知一覧ビュー)  
// Path: still/Features/Notifications/Views/NotificationListView.swift
//======================================================================

import SwiftUI

/// A comprehensive notification list view that displays all user notifications
/// Supports different notification types including likes, follows, and follow requests
/// Features read/unread states, follow request management, and real-time updates
struct NotificationListView: View {
    // MARK: - Properties
    
    /// Shared notification service that manages all notification operations
    @StateObject private var notificationService = NotificationService.shared
    
    /// Authentication manager to access current user information
    @EnvironmentObject var authManager: AuthManager
    
    /// Environment value for dismissing this view
    @Environment(\.dismiss) private var dismiss
    
    /// Controls the presentation of follow request management screen
    @State private var showFollowRequestManagement = false
    
    /// Number of pending follow requests for the current user
    @State private var pendingRequestsCount = 0
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header Section
                // Unified header with title, close button, and optional mark-all-read button
                UnifiedHeader(
                    title: "Notifications",
                    rightButton: HeaderButton(
                        icon: "xmark",
                        action: { dismiss() }
                    ),
                    // Removed: extraRightButton for mark-all-read
                    extraRightButton: nil
                )
                
                // MARK: - Follow Requests Section
                // Special section for follow requests (only shown when there are pending requests)
                if pendingRequestsCount > 0 {
                    Button(action: {
                        // Navigate to follow request management screen
                        showFollowRequestManagement = true
                    }) {
                        HStack {
                            // Follow request icon
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(MinimalDesign.Colors.accentRed)
                                .font(.system(size: 20))
                            
                            // Section title
                            Text("Follow Requests")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Badge showing the number of pending requests
                            Text("\(pendingRequestsCount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(MinimalDesign.Colors.accentRed)
                                .cornerRadius(12)
                            
                            // Navigation indicator
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                
                // MARK: - Content Area
                // Main content area that displays different states: loading, empty, or notification list
                if notificationService.isLoading {
                    // MARK: Loading State
                    // Show loading indicator while fetching notifications
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading notifications...")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
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
                            .foregroundColor(.white)
                        
                        Text("You'll see notifications for likes, follows, and messages here")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
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
                                    // Removed: onTapGesture for markAsRead
                                
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
                    await loadPendingRequestsCount(for: userId)
                    // Mark all notifications as read when the view appears
                    await notificationService.markAllAsRead(for: userId)
                }
            }
        }
        .navigationBarHidden(true)
        // Present follow request management screen as full screen cover
        .fullScreenCover(isPresented: $showFollowRequestManagement) {
            FollowRequestManagementView()
                .environmentObject(authManager)
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads the count of pending follow requests for the specified user
    /// This count is displayed in the follow requests section badge
    /// - Parameter userId: The ID of the user to load pending requests for
    private func loadPendingRequestsCount(for userId: String) async {
        do {
            // Query the follows table for pending requests where this user is being followed
            let count: Int = try await SupabaseManager.shared.client
                .from("follows")
                .select("id", count: .exact)
                .eq("following_id", value: userId)
                .eq("status", value: "pending")
                .execute()
                .count ?? 0
            
            // Update the UI on the main actor
            await MainActor.run {
                pendingRequestsCount = count
            }
            
        } catch {
            print("❌ Error loading pending requests count: \(error)")
        }
    }
}

/// Individual notification row view that displays a single notification
/// Handles different notification types with appropriate actions and UI elements
/// Supports follow request acceptance, profile navigation, and follow actions
struct NotificationRowView: View {
    // MARK: - Properties
    
    /// The notification data to display
    let notification: AppNotification
    
    /// Controls navigation to the sender's profile
    @State private var navigateToProfile = false
    
    /// Tracks if currently accepting a follow request
    @State private var isAccepting = false
    
    /// Tracks if the follow request has been accepted
    @State private var hasAccepted = false
    
    /// Tracks the current follow status of the notification sender
    @State private var isFollowing = false
    
    /// Tracks if currently performing a follow/unfollow action
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
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    // Action buttons for follow notifications
                    if notification.type == .follow || notification.type == .followRequest {
                        HStack(spacing: 8) {
                            // Removed: Accept button for follow requests
                            // Removed: Follow button (appears after accepting follow request or for regular follow notifications)
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
        .background(MinimalDesign.Colors.background)
        .navigationDestination(isPresented: $navigateToProfile) {
            if let userId = notification.relatedUserId {
                OtherUserProfileView(userId: userId)
            }
        }
        .onAppear {
            // Removed: checkFollowStatus
        }
    }
    
    // Removed: acceptFollowRequest method
    // Removed: checkFollowStatus method
    // Removed: followUser method
}

#if DEBUG
struct NotificationListView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationListView()
            .environmentObject(AuthManager.shared)
    }
}
#endif