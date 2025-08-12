//======================================================================
// MARK: - FollowRequestManagementView.swift
// Purpose: Follow request management view accessible from notifications section (通知セクションからアクセス可能なフォローリクエスト管理ビュー)
// Path: still/Features/Notifications/Views/FollowRequestManagementView.swift
//======================================================================

import SwiftUI
import Supabase

struct FollowRequestManagementView: View {
    @StateObject private var viewModel = FollowRequestManagementViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                }
                
                Spacer()
                
                Text("Follow Requests")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Balance for centering
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(MinimalDesign.Colors.background)
            
            // Content
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Loading requests...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.requests.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("No Follow Requests")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Text("When people request to follow you, they\'ll appear here.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach($viewModel.requests) { $request in // Use $request for Binding
                            FollowRequestManagementRow(
                                request: $request,
                                onAccept: { await viewModel.acceptFollowRequest(request) },
                                onDecline: { await viewModel.rejectFollowRequest(request) }
                            )
                            
                            if request.id != viewModel.requests.last?.id {
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
        .navigationBarHidden(true)
        .task {
            if let currentUser = authManager.currentUser {
                await viewModel.loadRequests(for: currentUser.id)
                await markFollowRequestNotificationsAsRead(for: currentUser.id)
            }
        }
        .refreshable {
            if let currentUser = authManager.currentUser {
                await viewModel.loadRequests(for: currentUser.id)
            }
        }
    }
    
    private func markFollowRequestNotificationsAsRead(for userId: String) async {
        do {
            try await SupabaseManager.shared.client
                .from("notifications")
                .update(["is_read": true])
                .eq("user_id", value: userId)
                .eq("type", value: "follow_request")
                .eq("is_read", value: false)
                .execute()
        } catch {
            print("❌ Error marking follow request notifications as read: \(error)")
        }
    }
}

// Follow Request Row for Management View
struct FollowRequestManagementRow: View {
    @Binding var request: Follow // Use Binding to allow status update
    let onAccept: () async -> Void
    let onDecline: () async -> Void
    
    @State private var isProcessing = false
    @State private var showProfile = false

    var body: some View {
        HStack(spacing: 12) {
            // Profile Image and Info
            Button(action: { showProfile = true }) {
                HStack(spacing: 12) {
                    if let avatarUrl = request.follower?.avatarUrl, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(request.follower?.username.prefix(1) ?? "?").uppercased())
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.follower?.profileDisplayName ?? "Unknown")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("@\(request.follower?.username ?? "unknown")")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Action Buttons or Status
            if request.status == .pending {
                HStack(spacing: 8) {
                    // Decline Button
                    Button(action: { Task { @MainActor in isProcessing = true; await onDecline() } }) {
                        Text("Decline")
                    }
                    .buttonStyle(FollowActionButtonStyle(isPrimary: false))
                    .disabled(isProcessing)
                    
                    // Accept Button
                    Button(action: { Task { @MainActor in isProcessing = true; await onAccept() } }) {
                        Text("Accept")
                    }
                    .buttonStyle(FollowActionButtonStyle(isPrimary: true))
                    .disabled(isProcessing)
                }
            } else if request.status == .accepted {
                // Removed: Follow/Following button for accepted requests
                // Now, accepted requests will simply disappear from the list
                EmptyView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(MinimalDesign.Colors.background)
        .fullScreenCover(isPresented: $showProfile) {
            if let follower = request.follower {
                OtherUserProfileView(userId: follower.id)
            }
        }
    }
}

struct FollowActionButtonStyle: ButtonStyle {
    let isPrimary: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isPrimary ? .white : .secondary)
            .frame(width: 70, height: 32)
            .background(isPrimary ? MinimalDesign.Colors.accentRed : Color.gray.opacity(0.1))
            .cornerRadius(16)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// ViewModel for Follow Request Management
@MainActor
class FollowRequestManagementViewModel: ObservableObject {
    @Published var requests: [Follow] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func loadRequests(for userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedRequests: [Follow] = try await SupabaseManager.shared.client
                .from("follows")
                .select("*, follower:follower_id(*)")
                .eq("following_id", value: userId)
                .in("status", values: ["pending", "accepted"])
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.requests = fetchedRequests
        } catch {
            print("❌ Error loading follow requests: \(error)")
            errorMessage = "Failed to load requests"
        }
        
        isLoading = false
    }
    
    func acceptFollowRequest(_ request: Follow) async {
        _ = request.followingId // Use _ to ignore the value
        do {
            try await SupabaseManager.shared.client
                .from("follows")
                .update(["status": "accepted"])
                .eq("id", value: request.id)
                .execute()
            
            // Remove the request from the list immediately after acceptance
            requests.removeAll { $0.id == request.id }

            // Mark the related follow request notification as read
            await markFollowRequestNotificationAsRead(for: request.followerId, to: request.followingId)
            
            NotificationCenter.default.post(name: .followStatusChanged, object: nil)
            
            if let currentUser = AuthManager.shared.currentUser {
                Task {
                    if let approverProfile = try? await UserRepository.shared.fetchUserProfile(userId: currentUser.id) {
                        await NotificationService.shared.createFollowRequestApprovedNotification(
                            fromUserId: currentUser.id,
                            toUserId: request.followerId,
                            approverProfile: approverProfile
                        )
                    }
                }
            }
        } catch {
            print("❌ Error accepting follow request: \(error)")
            errorMessage = "Failed to accept request"
            // Reload even on error to reset state
            await loadRequests(for: request.followingId)
        }
    }
    
    func rejectFollowRequest(_ request: Follow) async {
        _ = request.followingId // Use _ to ignore the value
        do {
            try await SupabaseManager.shared.client
                .from("follows")
                .delete()
                .eq("id", value: request.id)
                .execute()
            
            // Mark the related follow request notification as read
            await markFollowRequestNotificationAsRead(for: request.followerId, to: request.followingId)

            requests.removeAll { $0.id == request.id }
        } catch {
            print("❌ Error declining follow request: \(error)")
            errorMessage = "Failed to decline request"
        }
    }

    private func markFollowRequestNotificationAsRead(for fromUserId: String, to toUserId: String) async {
        do {
            try await SupabaseManager.shared.client
                .from("notifications")
                .update(["is_read": true])
                .eq("user_id", value: toUserId)
                .eq("type", value: "follow_request")
                .eq("related_user_id", value: fromUserId)
                .execute()
            print("✅ Marked related follow request notification as read.")
        } catch {
            print("❌ Error marking related follow request notification as read: \(error)")
        }
    }
}

#Preview {
    FollowRequestManagementView()
        .environmentObject(AuthManager.shared)
}
