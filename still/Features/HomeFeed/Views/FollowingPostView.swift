//======================================================================
// MARK: - FollowingPostView.swift
// Purpose: Feed view showing only following users and own posts
// Path: still/Features/HomeFeed/Views/FollowingPostView.swift
//======================================================================
import SwiftUI

@MainActor
struct FollowingPostView: View {
    // For single post mode (when used in ProfileSinglePostView)
    let post: Post?
    let onLikeTapped: ((Post) -> Void)?
    
    // For feed mode (when used in HomeGridView)
    let viewModel: HomeFeedViewModel?
    @State private var followingUserIds: Set<String> = []
    @State private var isLoadingFollowing = false
    @EnvironmentObject var authManager: AuthManager
    
    // Initializer for single post mode
    init(post: Post, onLikeTapped: @escaping (Post) -> Void) {
        self.post = post
        self.onLikeTapped = onLikeTapped
        self.viewModel = nil
    }
    
    // Initializer for feed mode
    init(viewModel: HomeFeedViewModel) {
        self.post = nil
        self.onLikeTapped = nil
        self.viewModel = viewModel
    }
    
    var body: some View {
        if let singlePost = post {
            // Single post mode (SingleView replacement)
            SinglePostCard(post: singlePost, onLikeTapped: onLikeTapped ?? { _ in })
        } else {
            // Feed mode
            LazyVStack(spacing: 0) {
                if filteredPosts.isEmpty && !isLoadingFollowing {
                    // フォローしている人がいないか、投稿がない場合
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("フォローしている人の投稿がありません")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("他のユーザーをフォローして\n投稿を見てみましょう")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 100)
                    .frame(maxWidth: .infinity)
                } else {
                    // フィルタリングされた投稿を表示
                    ForEach(filteredPosts) { post in
                        PostCardView(post: post) { post in
                            Task {
                                await viewModel?.toggleLike(for: post)
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await loadFollowingUsers()
                }
            }
        }
    }
    
    private var filteredPosts: [Post] {
        guard let viewModel = viewModel,
              let currentUserId = authManager.currentUser?.id else {
            return []
        }
        
        // フォローしている人と自分の投稿のみフィルタリング
        let filteredPosts = viewModel.posts.filter { post in
            // 自分の投稿
            if post.userId == currentUserId {
                return true
            }
            
            // フォローしている人の投稿
            if let userId = post.user?.id {
                return followingUserIds.contains(userId)
            }
            
            return false
        }
        
        // 時系列順（新しい順）でソート
        return filteredPosts.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func loadFollowingUsers() async {
        guard let currentUserId = authManager.currentUser?.id else { return }
        
        isLoadingFollowing = true
        do {
            let following = try await FollowService.shared.fetchFollowing(userId: currentUserId)
            followingUserIds = Set(following.map { $0.id })
            print("📱 FollowingPostView: Loaded \(followingUserIds.count) following users")
        } catch {
            print("❌ FollowingPostView: Failed to load following users: \(error)")
        }
        isLoadingFollowing = false
    }
}