//======================================================================
// MARK: - UserSearchResultView.swift
// Path: still/Features/Search/Views/UserSearchResultView.swift
//======================================================================
import SwiftUI
import Supabase

struct UserSearchResultView: View {
    let user: UserProfile
    @State private var isFollowing = false
    @State private var isLoading = false
    @State private var showProfile = false
    @State private var hasCheckedFollowStatus = false
    
    var body: some View {
        HStack(spacing: 12) {
            // プロフィール画像
            AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // ユーザー情報
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName ?? user.username)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("@\(user.username)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // フォロー/ビューボタン
            if !isCurrentUser {
                Button(action: {
                    print("🔵 UserSearchResultView - Button clicked for user: \(user.username)")
                    print("🔵 UserSearchResultView - Current isFollowing state: \(isFollowing)")
                    print("🔵 UserSearchResultView - hasCheckedFollowStatus: \(hasCheckedFollowStatus)")
                    if isFollowing {
                        print("🔵 UserSearchResultView - Navigating to profile")
                        navigateToProfile()
                    } else {
                        print("🔵 UserSearchResultView - Toggling follow")
                        toggleFollow()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: isFollowing ? MinimalDesign.Colors.primary : .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(isFollowing ? "Following" : "Follow")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(isFollowing ? MinimalDesign.Colors.primary : .white)
                    .frame(width: 90, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isFollowing ? Color.clear : MinimalDesign.Colors.accentRed)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isFollowing ? MinimalDesign.Colors.primary : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .disabled(isLoading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .fullScreenCover(isPresented: $showProfile) {
            OtherUserProfileView(userId: user.id)
        }
        .onAppear {
            print("🔵 UserSearchResultView - onAppear called for user: \(user.username)")
            print("🔵 UserSearchResultView - hasCheckedFollowStatus: \(hasCheckedFollowStatus)")
            if !hasCheckedFollowStatus {
                print("🔵 UserSearchResultView - Calling checkFollowStatus()")
                checkFollowStatus()
            } else {
                print("🔵 UserSearchResultView - Follow status already checked, isFollowing: \(isFollowing)")
            }
        }
    }
    
    private var isCurrentUser: Bool {
        guard let currentUser = AuthManager.shared.currentUser else {
            return false
        }
        return user.id == currentUser.id
    }
    
    private func checkFollowStatus() {
        Task { @MainActor in
            do {
                print("🔵 UserSearch - Checking follow status for user: \(user.username) (ID: \(user.id))")
                
                let followStatus = try await FollowService.shared.checkFollowStatus(userId: user.id)
                isFollowing = followStatus.isFollowing
                hasCheckedFollowStatus = true
                
                print("🔵 UserSearch - Updated UI: isFollowing = \(isFollowing)")
                
            } catch {
                print("❌ UserSearch - Error checking follow status: \(error)")
                hasCheckedFollowStatus = true
            }
        }
    }
    
    private func toggleFollow() {
        print("🔵 UserSearch - toggleFollow called, current isFollowing: \(isFollowing)")
        isLoading = true
        
        Task { @MainActor in
            do {
                print("🔵 UserSearch - About to \(isFollowing ? "unfollow" : "follow") user \(user.username)")
                
                if isFollowing {
                    try await FollowService.shared.unfollowUser(userId: user.id)
                    print("✅ UserSearch - Successfully unfollowed user \(user.username)")
                } else {
                    try await FollowService.shared.followUser(userId: user.id)
                    print("✅ UserSearch - Successfully followed user \(user.username)")
                }
                
                // Toggle the state and update UI
                isFollowing.toggle()
                isLoading = false
                print("🔵 UserSearch - UI updated, new isFollowing: \(isFollowing)")
                
            } catch {
                print("❌ UserSearch - Error toggling follow: \(error)")
                isLoading = false
            }
        }
    }
    
    private func navigateToProfile() {
        // プロフィール画面への遷移を実装
        showProfile = true
    }
}

#Preview {
    UserSearchResultView(user: UserProfile(
        id: "1",
        username: "johndoe",
        displayName: "John Doe",
        avatarUrl: nil,
        bio: "Hello world! This is my bio.",
        followersCount: 100,
        followingCount: 50,
        createdAt: Date()
    ))
}