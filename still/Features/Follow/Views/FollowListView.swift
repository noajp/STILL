//======================================================================
// MARK: - FollowListView.swift
// Purpose: Display followers or following list for a user
// Path: still/Features/Follow/Views/FollowListView.swift
//======================================================================
import SwiftUI

extension Notification.Name {
    static let followStatusChanged = Notification.Name("followStatusChanged")
}

enum FollowListType {
    case followers
    case following
    
    var title: String {
        switch self {
        case .followers:
            return "Followers"
        case .following:
            return "Following"
        }
    }
}

struct FollowListView: View {
    let userId: String
    let listType: FollowListType
    @StateObject private var viewModel = FollowListViewModel()
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
                
                Text(listType.title)
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
            
            // User List
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.users.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: listType == .followers ? "person.crop.circle" : "person.crop.circle.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("No \(listType.title.lowercased()) yet")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(listType == .followers ? "When people follow this account, they'll appear here." : "When this account follows people, they'll appear here.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Show pending requests first (only for current user's followers)
                        if listType == .followers && userId == authManager.currentUser?.id && !viewModel.pendingRequests.isEmpty {
                            // Pending Requests Header
                            HStack {
                                Text("Follow Requests")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(viewModel.pendingRequests.count)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(MinimalDesign.Colors.accentRed)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.05))
                            
                            // Pending Requests List
                            ForEach(viewModel.pendingRequests) { request in
                                FollowRequestRow(
                                    request: request,
                                    onAccept: { await viewModel.acceptFollowRequest(request) },
                                    onDecline: { await viewModel.rejectFollowRequest(request) }
                                )
                                
                                if request.id != viewModel.pendingRequests.last?.id {
                                    Divider()
                                        .padding(.leading, 70)
                                }
                            }
                            
                            // Separator if there are both pending requests and followers
                            if !viewModel.users.isEmpty {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 8)
                                    .padding(.vertical, 8)
                            }
                        }
                        
                        // Regular followers/following list
                        ForEach(viewModel.users, id: \.id) { user in
                            FollowUserRow(user: user)
                                .environmentObject(authManager)
                            
                            if user.id != viewModel.users.last?.id {
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
        .onAppear {
            Task {
                await viewModel.loadUsers(userId: userId, listType: listType)
            }
        }
        .refreshable {
            await viewModel.loadUsers(userId: userId, listType: listType)
        }
        .onReceive(NotificationCenter.default.publisher(for: .followStatusChanged)) { notification in
            // フォロー状態が変更された時は、リスト全体を再読み込みせずにカウントのみ更新
            // リスト自体の変更はFollowUserRowで個別に処理される
        }
    }
}

// Follow Request Row for Follower List
struct FollowRequestRow: View {
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
                        .foregroundColor(.white)
                        .frame(width: 80, height: 32)
                        .background(MinimalDesign.Colors.accentRed)
                        .cornerRadius(16)
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
                // 自分のプロフィールかチェック
                if followerProfile.id.lowercased() == AuthManager.shared.currentUser?.id.lowercased() {
                    MyPageView(isInProfileSingleView: .constant(false), isUserSearchMode: .constant(false))
                        .environmentObject(AuthManager.shared)
                } else {
                    OtherUserProfileView(userId: followerProfile.id)
                }
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
                
                print("✅ Follow action completed from follower list")
                
            } catch {
                await MainActor.run {
                    isFollowingUser = false
                }
                print("❌ Error in follow action from follower list: \(error)")
            }
        }
    }
}

struct FollowUserRow: View {
    let user: UserProfile
    @State private var isFollowing = false
    @State private var requestStatus: FollowRequestStatus?
    @State private var isLoading = false
    @State private var showProfile = false
    @State private var hasCheckedFollowStatus = false
    @EnvironmentObject var authManager: AuthManager
    
    private var isCurrentUser: Bool {
        user.id.lowercased() == authManager.currentUser?.id.lowercased()
    }
    
    private var buttonText: String {
        switch requestStatus {
        case .pending:
            return "Requested"
        case .accepted:
            return "Following"
        case .declined:
            return "Follow"
        case .none:
            return "Follow"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            Button(action: {
                if !isCurrentUser {
                    showProfile = true
                }
            }) {
                if let avatarUrl = user.avatarUrl {
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
                            Text(String(user.username.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // User Info
            Button(action: {
                if !isCurrentUser {
                    showProfile = true
                }
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName ?? user.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("@\(user.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let bio = user.bio, !bio.isEmpty {
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
            
            // Follow Button (only for other users)
            if !isCurrentUser {
                Button(action: {
                    toggleFollow()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: isFollowing ? .primary : .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(buttonText)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(isFollowing ? .primary : .white)
                    .frame(width: 90, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isFollowing ? Color.clear : MinimalDesign.Colors.accentRed)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isFollowing ? Color.primary : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .disabled(isLoading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .onAppear {
            if !isCurrentUser && !hasCheckedFollowStatus {
                checkFollowStatus()
            }
        }
        .fullScreenCover(isPresented: $showProfile) {
            if isCurrentUser {
                MyPageView(isInProfileSingleView: .constant(false), isUserSearchMode: .constant(false))
                    .environmentObject(AuthManager.shared)
            } else {
                OtherUserProfileView(userId: user.id)
            }
        }
    }
    
    private func checkFollowStatus() {
        Task { @MainActor in
            do {
                let followStatus = try await FollowService.shared.checkFollowStatus(userId: user.id)
                isFollowing = followStatus.isFollowing
                requestStatus = followStatus.requestStatus
                hasCheckedFollowStatus = true
            } catch {
                print("Error checking follow status: \(error)")
                hasCheckedFollowStatus = true
            }
        }
    }
    
    private func toggleFollow() {
        isLoading = true
        
        Task { @MainActor in
            do {
                if requestStatus == .accepted {
                    // Unfollow
                    try await FollowService.shared.unfollowUser(userId: user.id)
                    requestStatus = nil
                    isFollowing = false
                } else if requestStatus == .pending {
                    // Cancel request
                    try await FollowService.shared.unfollowUser(userId: user.id)
                    requestStatus = nil
                    isFollowing = false
                } else {
                    // Send new follow request
                    try await FollowService.shared.followUser(userId: user.id)
                    // Refresh status to get correct state
                    let followStatus = try await FollowService.shared.checkFollowStatus(userId: user.id)
                    requestStatus = followStatus.requestStatus
                    isFollowing = followStatus.isFollowing
                }
                
                // フォロー状態変更を親ビューに通知
                NotificationCenter.default.post(
                    name: .followStatusChanged, 
                    object: nil,
                    userInfo: ["userId": user.id, "isFollowing": isFollowing]
                )
            } catch {
                print("Error toggling follow: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - ViewModel

@MainActor
class FollowListViewModel: ObservableObject {
    @Published var users: [UserProfile] = []
    @Published var pendingRequests: [FollowRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadUsers(userId: String, listType: FollowListType) async {
        print("🔄 FollowListViewModel - Loading \(listType.title) for user: \(userId)")
        isLoading = true
        errorMessage = nil
        
        do {
            switch listType {
            case .followers:
                users = try await FollowService.shared.fetchFollowers(userId: userId)
                print("✅ FollowListViewModel - Loaded \(users.count) followers")
                
                // Load pending follow requests for current user viewing their own followers
                if userId == AuthManager.shared.currentUser?.id {
                    await loadPendingRequests(for: userId)
                }
                
            case .following:
                users = try await FollowService.shared.fetchFollowing(userId: userId)
                print("✅ FollowListViewModel - Loaded \(users.count) following")
            }
        } catch {
            errorMessage = "Failed to load \(listType.title.lowercased())"
            print("❌ FollowListViewModel - Error loading \(listType.title): \(error)")
            print("❌ FollowListViewModel - Error details: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    private func loadPendingRequests(for userId: String) async {
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
        }
    }
    
    func acceptFollowRequest(_ request: FollowRequest) async {
        do {
            // Update follow status to accepted
            try await SupabaseManager.shared.client
                .from("follows")
                .update(["status": "accepted"])
                .eq("id", value: request.id)
                .execute()
            
            // Add to users list
            if let profile = request.followerProfile {
                users.insert(profile, at: 0) // Add to top of list
            }
            
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
        }
    }
}

#Preview {
    FollowListView(userId: "test-user-id", listType: .followers)
        .environmentObject(AuthManager.shared)
}