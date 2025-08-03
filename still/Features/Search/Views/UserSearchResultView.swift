//======================================================================
// MARK: - UserSearchResultView.swift
// Path: still/Features/Search/Views/UserSearchResultView.swift
//======================================================================
import SwiftUI
import Supabase

struct UserSearchResultView: View {
    let user: UserProfile
    @State private var isFollowing = false
    @State private var requestStatus: FollowRequestStatus?
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
            
            // ユーザー情報 (タップでプロフィール表示)
            Button(action: {
                if !isCurrentUser {
                    showProfile = true
                }
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName ?? user.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("@\(user.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // フォローボタン (自分以外のユーザーのみ)
            if !isCurrentUser {
                Button(action: {
                    print("🔵 UserSearchResultView - Follow button clicked for user: \(user.username)")
                    print("🔵 UserSearchResultView - Current isFollowing state: \(isFollowing)")
                    toggleFollow()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: isFollowing ? MinimalDesign.Colors.primary : .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(requestStatus == .pending ? "Requested" : (isFollowing ? "Following" : "Follow"))
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(isFollowing ? MinimalDesign.Colors.primary : .white)
                    .frame(width: 90, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isFollowing ? Color.clear : MinimalDesign.Colors.accentRed)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isFollowing ? MinimalDesign.Colors.primary : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .disabled(isLoading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(MinimalDesign.Colors.background)
        .contentShape(Rectangle())
        .fullScreenCover(isPresented: $showProfile) {
            if isCurrentUser {
                // 自分のプロフィールの場合はMyPageViewを表示
                MyPageView(isInProfileSingleView: .constant(false), isUserSearchMode: .constant(false))
                    .environmentObject(AuthManager.shared)
            } else {
                // 他人のプロフィールの場合はOtherUserProfileViewを表示
                OtherUserProfileView(userId: user.id)
            }
        }
        .onAppear {
            print("🔵 UserSearchResultView - onAppear called for user: \(user.username)")
            print("🔵 UserSearchResultView - hasCheckedFollowStatus: \(hasCheckedFollowStatus)")
            
            // Reset state for current user to prevent any UI inconsistencies
            if isCurrentUser {
                isFollowing = false
                hasCheckedFollowStatus = true
                print("🔵 UserSearchResultView - Reset state for current user")
            } else if !hasCheckedFollowStatus {
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
        return user.id.lowercased() == currentUser.id.lowercased()
    }
    
    private func checkFollowStatus() {
        Task { @MainActor in
            do {
                print("🔵 UserSearch - Checking follow status for user: \(user.username) (ID: \(user.id))")
                
                let followStatus = try await FollowService.shared.checkFollowStatus(userId: user.id)
                isFollowing = followStatus.isFollowing
                requestStatus = followStatus.requestStatus
                hasCheckedFollowStatus = true
                
                print("🔵 UserSearch - Updated UI: isFollowing = \(isFollowing)")
                
            } catch {
                print("❌ UserSearch - Error checking follow status: \(error)")
                hasCheckedFollowStatus = true
            }
        }
    }
    
    private func toggleFollow() {
        // Extra safety check - never allow self-follow attempts
        guard !isCurrentUser else {
            print("⚠️ UserSearch - Attempted self-follow prevented")
            return
        }
        
        print("🔵 UserSearch - toggleFollow called, current isFollowing: \(isFollowing)")
        isLoading = true
        
        Task { @MainActor in
            do {
                if requestStatus == .accepted {
                    // Unfollow
                    try await FollowService.shared.unfollowUser(userId: user.id)
                    requestStatus = nil
                    isFollowing = false
                    print("✅ UserSearch - Successfully unfollowed user \(user.username)")
                } else if requestStatus == .pending {
                    // Cancel request
                    try await FollowService.shared.unfollowUser(userId: user.id)
                    requestStatus = nil
                    isFollowing = false
                    print("✅ UserSearch - Successfully cancelled follow request for \(user.username)")
                } else {
                    // Send follow request
                    try await FollowService.shared.followUser(userId: user.id)
                    // Refresh status to get correct state
                    let followStatus = try await FollowService.shared.checkFollowStatus(userId: user.id)
                    requestStatus = followStatus.requestStatus
                    isFollowing = followStatus.isFollowing
                    print("✅ UserSearch - Successfully sent follow request to \(user.username)")
                }
                
                isLoading = false
                
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