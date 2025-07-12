//======================================================================
// MARK: - HomeFeedViewModel
// Purpose: Manages the main feed display and user interactions
// Dependencies: PostService, AuthManager
//======================================================================
import SwiftUI
import Combine

@MainActor
final class HomeFeedViewModel: BaseViewModelClass {
    // MARK: - Published Properties
    
    /// Current posts in the feed
    @Published var posts: [Post] = []
    
    // MARK: - Dependencies
    
    private let postService: PostServiceProtocol
    private let authManager: any AuthManagerProtocol
    
    // MARK: - Private Properties
    
    private var hasLoadedInitially = false
    private var loadingTask: Task<Void, Never>?
    private var currentUserId: String? {
        authManager.currentUser?.id
    }
    
    // MARK: - Initialization
    
    init(
        postService: PostServiceProtocol? = nil,
        authManager: (any AuthManagerProtocol)? = nil
    ) {
        self.postService = postService ?? PostService()
        self.authManager = authManager ?? (DependencyContainer.shared.resolve((any AuthManagerProtocol).self) ?? AuthManager.shared)
        super.init()
        
        Task {
            await loadPostsIfNeeded()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads posts only if not already loaded
    func loadPostsIfNeeded() async {
        guard !hasLoadedInitially else { return }
        await loadPosts()
    }
    
    /// Loads posts for the main feed
    func loadPosts() async {
        // Cancel previous loading task
        loadingTask?.cancel()
        
        loadingTask = Task {
            await performLoadPosts()
        }
        
        await loadingTask?.value
    }
    
    private func performLoadPosts() async {
        showLoading()
        
        do {
            // Check if task was cancelled before making network request
            try Task.checkCancellation()
            
            let fetchedPosts = try await postService.fetchFeedPosts(currentUserId: currentUserId)
            
            // Check if task was cancelled before updating UI
            try Task.checkCancellation()
            
            posts = fetchedPosts
            hasLoadedInitially = true
            hideLoading()
            Logger.shared.info("Loaded \(fetchedPosts.count) posts")
        } catch is CancellationError {
            print("🔄 Post loading was cancelled")
            hideLoading()
        } catch {
            handleError(error)
        }
    }
    
    /// Force refresh posts (bypasses cache if any)
    func forceRefreshPosts() async {
        print("🔄 HomeFeedViewModel: Force refreshing posts...")
        hasLoadedInitially = false // Reset to force reload
        await loadPosts()
    }
    
    // MARK: - Like Operations
    
    /// Toggles like status for a post with optimistic UI updates
    func toggleLike(for post: Post) async {
        guard let userId = currentUserId else {
            handleError(ViewModelError.unauthorized)
            return
        }
        
        // Optimistic UI update
        let originalLikeStatus = post.isLikedByMe
        let newLikeStatus = !originalLikeStatus
        updatePostLikeStatus(postId: post.id, isLiked: newLikeStatus)
        
        do {
            let isNowLiked = try await postService.toggleLike(
                postId: post.id,
                userId: userId
            )
            
            // Verify optimistic update was correct
            if isNowLiked != newLikeStatus {
                updatePostLikeStatusOnly(postId: post.id, isLiked: isNowLiked)
            }
            
            Logger.shared.info("Toggled like for post \(post.id): \(isNowLiked)")
            
        } catch {
            // Revert optimistic update on error
            updatePostLikeStatus(postId: post.id, isLiked: originalLikeStatus)
            handleError(error)
        }
    }
    
    private func updatePostLikeStatus(postId: String, isLiked: Bool) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isLikedByMe = isLiked
            
            // Update like count
            if isLiked {
                posts[index].likeCount += 1
            } else {
                posts[index].likeCount = max(0, posts[index].likeCount - 1)
            }
        }
    }
    
    // Like状態のみ更新（カウントは更新しない）
    private func updatePostLikeStatusOnly(postId: String, isLiked: Bool) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isLikedByMe = isLiked
        }
    }
    
    // MARK: - Refresh
    
    /// Refreshes the feed
    func refreshPosts() async {
        await loadPosts()
    }
}

