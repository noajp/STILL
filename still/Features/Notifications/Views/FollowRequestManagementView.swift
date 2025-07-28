//======================================================================
// MARK: - FollowRequestManagementView.swift
// Purpose: Follow request management view accessible from notifications section (通知セクションからアクセス可能なフォローリクエスト管理ビュー)
// Path: still/Features/Notifications/Views/FollowRequestManagementView.swift
//======================================================================

import SwiftUI

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
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Balance for centering
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
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
            } else if viewModel.pendingRequests.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("No Follow Requests")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text("When people request to follow you, they'll appear here.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.pendingRequests) { request in
                            FollowRequestManagementRow(
                                request: request,
                                onAccept: { await viewModel.acceptFollowRequest(request) },
                                onDecline: { await viewModel.rejectFollowRequest(request) }
                            )
                            
                            if request.id != viewModel.pendingRequests.last?.id {
                                Divider()
                                    .padding(.leading, 70)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .task {
            if let currentUser = authManager.currentUser {
                await viewModel.loadPendingRequests(for: currentUser.id)
            }
        }
        .refreshable {
            if let currentUser = authManager.currentUser {
                await viewModel.loadPendingRequests(for: currentUser.id)
            }
        }
    }
}

// Follow Request Row for Management View
struct FollowRequestManagementRow: View {
    let request: FollowRequest
    let onAccept: () async -> Void
    let onDecline: () async -> Void
    
    @State private var isAccepting = false
    @State private var isDeclining = false
    @State private var showProfile = false
    @State private var hasAccepted = false
    @State private var isFollowing = false
    @State private var isFollowingUser = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            Button(action: {
                showProfile = true
            }) {
                if let avatarUrl = request.followerProfile?.avatarUrl {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(request.followerProfile?.username.prefix(1) ?? "?").uppercased())
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // User Info
            Button(action: {
                showProfile = true
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.followerProfile?.profileDisplayName ?? "Unknown")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("@\(request.followerProfile?.username ?? "unknown")")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let bio = request.followerProfile?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                if !hasAccepted {
                    // Decline Button (only show if not accepted)
                    Button(action: {
                        Task {
                            isDeclining = true
                            await onDecline()
                            isDeclining = false
                        }
                    }) {
                        HStack {
                            if isDeclining {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Decline")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .foregroundColor(.secondary)
                        .frame(width: 70, height: 32)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .disabled(isDeclining || isAccepting)
                    
                    // Accept Button (only show if not accepted)
                    Button(action: {
                        Task {
                            isAccepting = true
                            await onAccept()
                            hasAccepted = true
                            isAccepting = false
                        }
                    }) {
                        HStack {
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
                        .frame(width: 70, height: 32)
                        .background(MinimalDesign.Colors.accentRed)
                        .cornerRadius(16)
                    }
                    .disabled(isAccepting || isDeclining)
                } else {
                    // Follow Button (show after accepting)
                    Button(action: {
                        followUser()
                    }) {
                        HStack {
                            if isFollowingUser {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(isFollowing ? "Following" : "Follow")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .foregroundColor(isFollowing ? .primary : .white)
                        .frame(width: 80, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isFollowing ? Color.clear : MinimalDesign.Colors.accentRed)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(isFollowing ? Color.primary : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .disabled(isFollowingUser)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $showProfile) {
            if let followerProfile = request.followerProfile {
                OtherUserProfileView(userId: followerProfile.id)
            }
        }
        .onAppear {
            // Check if already accepted and follow status
            checkAcceptedStatus()
        }
    }
    
    private func checkAcceptedStatus() {
        guard let followerProfile = request.followerProfile else { return }
        
        Task {
            do {
                // Check if this follow request has been accepted
                let followStatus = try await FollowService.shared.checkFollowStatus(userId: followerProfile.id)
                await MainActor.run {
                    if followStatus.isFollowedBy {
                        // This user is following us (request was accepted)
                        hasAccepted = true
                        isFollowing = followStatus.isFollowing
                    }
                }
            } catch {
                print("❌ Error checking accepted status: \(error)")
            }
        }
    }
    
    private func followUser() {
        guard let followerProfile = request.followerProfile else { return }
        
        isFollowingUser = true
        
        Task {
            do {
                if isFollowing {
                    // Unfollow
                    try await FollowService.shared.unfollowUser(userId: followerProfile.id)
                    await MainActor.run {
                        isFollowing = false
                        isFollowingUser = false
                    }
                } else {
                    // Follow
                    try await FollowService.shared.followUser(userId: followerProfile.id)
                    let followStatus = try await FollowService.shared.checkFollowStatus(userId: followerProfile.id)
                    await MainActor.run {
                        isFollowing = followStatus.isFollowing
                        isFollowingUser = false
                    }
                }
                
                print("✅ Follow action completed from notification management")
                
            } catch {
                await MainActor.run {
                    isFollowingUser = false
                }
                print("❌ Error in follow action from notification management: \(error)")
            }
        }
    }
}

// ViewModel for Follow Request Management
@MainActor
class FollowRequestManagementViewModel: ObservableObject {
    @Published var pendingRequests: [FollowRequest] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var currentUserId: String?
    
    func loadPendingRequests(for userId: String) async {
        currentUserId = userId
        isLoading = true
        errorMessage = nil
        
        do {
            // Get pending follow requests
            let requests: [FollowRequest] = try await SupabaseManager.shared.client
                .from("follows")
                .select("*")
                .eq("following_id", value: userId)
                .eq("status", value: "pending")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // Load follower profiles for each request
            var requestsWithProfiles: [FollowRequest] = []
            for var request in requests {
                do {
                    let profile: UserProfile = try await SupabaseManager.shared.client
                        .from("profiles")
                        .select("*")
                        .eq("id", value: request.follower_id)
                        .single()
                        .execute()
                        .value
                    
                    request.followerProfile = profile
                    requestsWithProfiles.append(request)
                } catch {
                    print("❌ Error loading profile for follower \(request.follower_id): \(error)")
                    // Include request even without profile
                    requestsWithProfiles.append(request)
                }
            }
            
            pendingRequests = requestsWithProfiles
            print("✅ Loaded \(pendingRequests.count) pending follow requests")
            
        } catch {
            print("❌ Error loading pending requests: \(error)")
            errorMessage = "Failed to load follow requests"
        }
        
        isLoading = false
    }
    
    func acceptFollowRequest(_ request: FollowRequest) async {
        do {
            // Update follow status to accepted
            try await SupabaseManager.shared.client
                .from("follows")
                .update(["status": "accepted"])
                .eq("id", value: request.id)
                .execute()
            
            // Create follow request approved notification to the requester
            if let currentUser = AuthManager.shared.currentUser {
                let approverProfile = try await UserRepository.shared.fetchUserProfile(userId: currentUser.id)
                await NotificationService.shared.createFollowRequestApprovedNotification(
                    fromUserId: currentUser.id,
                    toUserId: request.follower_id,
                    approverProfile: approverProfile
                )
            }
            
            // Remove from pending list since it's now accepted
            pendingRequests.removeAll { $0.id == request.id }
            
            // Send notification to update follower counts across the app
            NotificationCenter.default.post(name: .followStatusChanged, object: nil)
            
            print("✅ Follow request accepted - new follower added")
            
        } catch {
            print("❌ Error accepting follow request: \(error)")
            errorMessage = "Failed to accept follow request"
        }
    }
    
    func rejectFollowRequest(_ request: FollowRequest) async {
        do {
            // Delete the follow request
            try await SupabaseManager.shared.client
                .from("follows")
                .delete()
                .eq("id", value: request.id)
                .execute()
            
            // Remove from pending list
            pendingRequests.removeAll { $0.id == request.id }
            
            print("✅ Follow request declined")
            
        } catch {
            print("❌ Error declining follow request: \(error)")
            errorMessage = "Failed to decline follow request"
        }
    }
}

#Preview {
    FollowRequestManagementView()
        .environmentObject(AuthManager.shared)
}