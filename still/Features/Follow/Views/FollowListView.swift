
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
            
            // User List
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.white)
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
                        .foregroundColor(.white)
                    Text(listType == .followers ? "When people follow this account, they\'ll appear here." : "When this account follows people, they\'ll appear here.")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Follow requests are now handled only in the notifications screen
                        // Removed follow request display from follower section to avoid duplication
                        
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
        .background(MinimalDesign.Colors.background)
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadUsers(userId: userId, listType: listType)
            }
        }
        .refreshable {
            await viewModel.loadUsers(userId: userId, listType: listType)
        }
        .onReceive(NotificationCenter.default.publisher(for: .followStatusChanged)) { _ in
            Task {
                await viewModel.loadUsers(userId: userId, listType: listType)
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
        case .declined, .none:
            return "Follow"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            Button(action: { if !isCurrentUser { showProfile = true } }) {
                if let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
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
                            Text(String(user.username.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // User Info
            Button(action: { if !isCurrentUser { showProfile = true } }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName ?? user.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("@\(user.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Follow Button (only for other users)
            if !isCurrentUser {
                Button(action: { toggleFollow() }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: isFollowing ? .white : .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(buttonText)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(isFollowing ? .white : .white)
                    .frame(width: 90, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isFollowing ? Color.clear : MinimalDesign.Colors.accentRed)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isFollowing ? Color.white : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .disabled(isLoading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(MinimalDesign.Colors.background)
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
        Task {
            let status = try? await FollowService.shared.checkFollowStatus(userId: user.id)
            self.isFollowing = status?.isFollowing == true
            self.requestStatus = status?.requestStatus
            self.hasCheckedFollowStatus = true
        }
    }
    
    private func toggleFollow() {
        isLoading = true
        Task {
            do {
                if requestStatus == .accepted {
                    try await FollowService.shared.unfollowUser(userId: user.id)
                } else if requestStatus == .pending {
                    try await FollowService.shared.unfollowUser(userId: user.id) // Cancels the request
                } else {
                    try await FollowService.shared.followUser(userId: user.id)
                }
                checkFollowStatus() // Re-check status after action
            } catch {
                print("❌ Error toggling follow: \(error)")
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
        isLoading = true
        errorMessage = nil
        
        do {
            switch listType {
            case .followers:
                users = try await FollowService.shared.fetchFollowers(userId: userId)
                // Follow requests are now handled only in the notifications screen
            case .following:
                users = try await FollowService.shared.fetchFollowing(userId: userId)
            }
        }
        catch {
            errorMessage = "Failed to load \(listType.title.lowercased())"
            print("❌ FollowListViewModel - Error loading \(listType.title): \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    FollowListView(userId: "test-user-id", listType: .followers)
        .environmentObject(AuthManager.shared)
}