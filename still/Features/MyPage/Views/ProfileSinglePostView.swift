//======================================================================
// MARK: - ProfileSinglePostView.swift
// Purpose: Profile-specific single post view with scroll navigation (スクロールナビゲーション付きプロフィール専用シングル投稿ビュー)
// Path: still/Features/MyPage/Views/ProfileSinglePostView.swift
//======================================================================
import SwiftUI

@MainActor
struct ProfileSinglePostView: View {
    let initialPost: Post
    let allPosts: [Post]
    let viewModel: MyPageViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    
    private var reorderedPosts: [Post] {
        // Get latest user posts from MyPageViewModel (supports live updates)
        let currentPosts = viewModel.userPosts
        
        // Display selected post first, then show remaining posts in order
        guard let selectedIndex = currentPosts.firstIndex(where: { $0.id == initialPost.id }) else {
            return currentPosts
        }
        
        var posts = [Post]()
        
        // Add selected post first
        posts.append(currentPosts[selectedIndex])
        
        // Add posts after the selected post
        for i in (selectedIndex + 1)..<currentPosts.count {
            posts.append(currentPosts[i])
        }
        
        // Add posts before the selected post
        for i in 0..<selectedIndex {
            posts.append(currentPosts[i])
        }
        
        return posts
    }
    
    var body: some View {
        ScrollableHeaderView(
            title: "POST",
            showBackButton: true,
            onBack: { dismiss() }
        ) {
            VStack(spacing: 0) {
                // Display reordered posts with selected post first
                ForEach(Array(reorderedPosts.enumerated()), id: \.element.id) { index, post in
                    PostCardView(post: post) { post in
                        // Enable like functionality
                        print("🔄 ProfileSinglePostView: Like button tapped for post \(post.id)")
                        print("🔍 Current like status: \(post.isLikedByMe), like count: \(post.likeCount)")
                        Task {
                            await viewModel.toggleLike(for: post)
                        }
                    }
                    .onAppear {
                        currentIndex = index
                    }
                }
                
                // Padding for tab bar clearance
                Color.clear
                    .frame(height: 110)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            currentIndex = 0 // Selected post is displayed first, so index is 0
        }
    }
}