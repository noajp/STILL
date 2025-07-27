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

struct FollowUserRow: View {
    let user: UserProfile
    @State private var isFollowing = false
    @State private var requestStatus: FollowRequestStatus?
    @State private var isLoading = false
    @State private var showProfile = false
    @State private var hasCheckedFollowStatus = false
    @EnvironmentObject var authManager: AuthManager
    
    private var isCurrentUser: Bool {
        user.id == authManager.currentUser?.id
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
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isFollowing ? Color.clear : MinimalDesign.Colors.accentRed)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
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
            OtherUserProfileView(userId: user.id)
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
                } else {
                    // Follow or cancel request
                    if requestStatus == .pending {
                        // Cancel request (unfollow)
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
}

#Preview {
    FollowListView(userId: "test-user-id", listType: .followers)
        .environmentObject(AuthManager.shared)
}