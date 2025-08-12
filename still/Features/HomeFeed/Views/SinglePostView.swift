//======================================================================
// MARK: - SinglePostView.swift
// Purpose: Individual post display view with media rendering, user interactions, aspect ratio handling, and action button integration
// Path: still/Features/HomeFeed/Views/SinglePostView.swift
//
// Features:
// - Displays a selected post at the top followed by other posts in chronological order
// - Handles like state updates by using the updated post from viewModel.posts
// - Provides smooth scrolling experience with proper spacing
// - Integrates with HomeFeedViewModel for real-time state management
//
// Recent fixes:
// - Fixed like button not updating UI by using viewModel.posts instead of static initialPost
//======================================================================
import SwiftUI

@MainActor
struct SinglePostView: View {
    let initialPost: Post
    @StateObject private var viewModel: HomeFeedViewModel
    @Binding var showGridMode: Bool
    @State private var scrollToTop = false
    @State private var visiblePostCount = 2 // Start by showing initial + 2 more posts
    @State private var isLoadingMore = false
    @Environment(\.dismiss) private var dismiss
    
    init(initialPost: Post, viewModel: HomeFeedViewModel, showGridMode: Binding<Bool>) {
        self.initialPost = initialPost
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._showGridMode = showGridMode
    }
    
    var body: some View {
        ScrollableHeaderView(
            title: "STILL"
        ) {
            VStack(spacing: 120) {
                // MARK: - Initial Post Display
                // Display the selected post first
                // Use the updated post from viewModel.posts to ensure UI reflects like state changes
                // This fixes the issue where likes weren't updating in SinglePostView
                if let updatedPost = viewModel.posts.first(where: { $0.id == initialPost.id }) {
                    PostCardView(post: updatedPost) { post in
                        Task {
                            await viewModel.toggleLike(for: post)
                        }
                    }
                    .id(updatedPost.id)
                } else {
                    // Fallback to initialPost if not found in viewModel.posts yet
                    PostCardView(post: initialPost) { post in
                        Task {
                            await viewModel.toggleLike(for: post)
                        }
                    }
                    .id(initialPost.id)
                }
                
                // Progressive loading: Show only visible posts (3 at a time)
                ForEach(visiblePosts) { post in
                    PostCardView(post: post) { post in
                        Task {
                            await viewModel.toggleLike(for: post)
                        }
                    }
                    .onAppear {
                        // When the last visible post appears, load more
                        if post.id == visiblePosts.last?.id {
                            loadMorePostsIfNeeded()
                        }
                    }
                }
                
                // Loading indicator for next batch
                if isLoadingMore && visiblePostCount < allPostsExceptInitial.count {
                    HStack {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "1A1A1A"))
                                .frame(width: 100, height: 100)
                                .shimmerEffect()
                        }
                    }
                    .padding(.vertical, 20)
                }
                
                // Bottom space for tab bar
                Color.clear
                    .frame(height: 110)
            }
        }
        .background(Color(hex: "121212"))
        .navigationBarHidden(true)
    }
    
    // MARK: - Computed Properties
    
    private var allPostsExceptInitial: [Post] {
        // 初期投稿以外の全ての投稿を時系列順（新しい順）で返す
        return viewModel.posts
            .filter { $0.id != initialPost.id }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    private var visiblePosts: [Post] {
        // Return only the posts that should be visible based on progressive loading
        let posts = allPostsExceptInitial
        let endIndex = min(visiblePostCount, posts.count)
        return Array(posts.prefix(endIndex))
    }
    
    // MARK: - Private Methods
    
    private func loadMorePostsIfNeeded() {
        guard !isLoadingMore else { return }
        guard visiblePostCount < allPostsExceptInitial.count else { return }
        
        isLoadingMore = true
        
        // Simulate loading delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                // Load next 3 posts
                visiblePostCount += 3
                isLoadingMore = false
            }
        }
    }
}