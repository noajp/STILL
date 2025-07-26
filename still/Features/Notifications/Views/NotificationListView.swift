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
                
                // Avatar
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
            
            VStack(alignment: .leading, spacing: 4) {
                // Title and Message
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(notification.displayMessage)
                            .font(.system(size: 14, weight: notification.isRead ? .regular : .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(notification.relativeTimeString)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // View Button for follow notifications
                    if notification.type == .follow {
                        Button(action: {
                            navigateToProfile = true
                        }) {
                            Text("View")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(MinimalDesign.Colors.accentRed)
                                .cornerRadius(6)
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