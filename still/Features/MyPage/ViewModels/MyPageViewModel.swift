//======================================================================
// MARK: - MyPageViewModel.swift
// Purpose: Manages the user's profile page state and operations (ユーザープロフィールページの状態と操作を管理)
// Path: still/Features/MyPage/ViewModels/MyPageViewModel.swift
//======================================================================
import SwiftUI
import Combine
import PhotosUI

/// ViewModel for the user's profile page
/// Handles profile data loading, updates, and post management
@MainActor
final class MyPageViewModel: BaseViewModelClass {
    // MARK: - Published Properties
    
    /// Current user's profile
    @Published var userProfile: UserProfile?
    
    /// Posts saved by the user
    @Published var savedPosts: [Post] = []
    
    /// Posts created by the user
    @Published var userPosts: [Post] = []
    
    /// Statistics (for algorithm use)
    @Published var postsCount: Int = 0
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    
    /// New follower notification
    @Published var hasNewFollowers: Bool = false
    
    
    // MARK: - Dependencies
    
    private let userRepository: UserRepositoryProtocol
    private let authManager: any AuthManagerProtocol
    private let postService: PostServiceProtocol
    
    // MARK: - Private Properties
    
    private var hasLoadedInitially = false
    private var currentUserId: String? {
        authManager.currentUser?.id
    }
    
    // MARK: - Initialization
    
    init(
        userRepository: UserRepositoryProtocol? = nil,
        authManager: (any AuthManagerProtocol)? = nil,
        postService: PostServiceProtocol? = nil
    ) {
        self.userRepository = userRepository ?? UserRepository()
        self.authManager = authManager ?? DependencyContainer.shared.authManager
        self.postService = postService ?? PostService()
        super.init()
        
        Task {
            await loadUserDataIfNeeded()
        }
        
        // Listen for post creation notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostCreated),
            name: NSNotification.Name("PostCreated"),
            object: nil
        )
        
        // Listen for follow status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFollowStatusChanged),
            name: NSNotification.Name("followStatusChanged"),
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// Loads user data only if not already loaded
    func loadUserDataIfNeeded() async {
        guard !hasLoadedInitially else { return }
        await loadUserData()
    }
    
    /// Loads all user data including profile, posts, and statistics
    func loadUserData() async {
        guard let userId = currentUserId else {
            print("❌ MyPageViewModel: No current user ID")
            handleError(ViewModelError.unauthorized)
            return
        }
        
        print("🔵 MyPageViewModel: Starting to load data for user: \(userId)")
        showLoading()
        
        do {
            // Load profile
            print("🔵 MyPageViewModel: Loading profile...")
            userProfile = try await userRepository.fetchUserProfile(userId: userId)
            print("✅ MyPageViewModel: Profile loaded for \(userProfile?.username ?? "unknown")")
            
            // Load user's own posts (both public and private)
            print("🔵 MyPageViewModel: Loading posts for user \(userId)...")
            userPosts = try await postService.fetchUserPosts(userId: userId)
            print("🔵 MyPageViewModel: Received \(userPosts.count) posts from PostService")
            
            // Debug: Print post details
            for (index, post) in userPosts.enumerated() {
                print("📋 Post \(index + 1): ID=\(post.id), userId=\(post.userId), mediaUrl=\(post.mediaUrl)")
            }
            
            // Set like status for each post
            for i in 0..<userPosts.count {
                do {
                    userPosts[i].isLikedByMe = try await LikeService().checkUserLikeStatus(
                        postId: userPosts[i].id,
                        userId: userId
                    )
                } catch {
                    print("⚠️ MyPageViewModel: Failed to get like status for post \(userPosts[i].id): \(error)")
                    userPosts[i].isLikedByMe = false
                }
            }
            print("✅ MyPageViewModel: Loaded \(userPosts.count) posts for user \(userId)")
            
            // Check for new followers
            hasNewFollowers = try await FollowService.shared.checkNewFollowers()
            
            // Update statistics with real-time counts
            postsCount = userPosts.count
            followersCount = try await userRepository.fetchFollowersCount(userId: userId)
            followingCount = try await userRepository.fetchFollowingCount(userId: userId)
            
            print("📊 MyPageViewModel: Stats - Posts: \(postsCount), Followers: \(followersCount), Following: \(followingCount)")
            
            hasLoadedInitially = true
            hideLoading()
            Logger.shared.info("User data loaded successfully")
            
        } catch {
            print("❌ MyPageViewModel: Error loading user data: \(error)")
            handleError(error)
        }
    }
    
    /// Updates user profile information
    func updateProfile(username: String, displayName: String, bio: String) async {
        guard var profile = userProfile else {
            handleError(ViewModelError.notFound("Profile"))
            return
        }
        
        showLoading()
        
        do {
            // Update local model
            profile.username = username
            profile.displayName = displayName
            profile.bio = bio
            
            // Update remote
            try await userRepository.updateUserProfile(profile)
            
            // Reload data to ensure consistency
            await loadUserData()
            
            Logger.shared.info("Profile updated successfully")
            
        } catch {
            handleError(error)
        }
    }
    
    /// Updates user profile photo
    func updateProfilePhoto(item: PhotosPickerItem?) async {
        guard let item = item,
              let userId = currentUserId else {
            return
        }
        
        showLoading()
        
        do {
            // Load image data
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw ViewModelError.fileSystem("Failed to load image data")
            }
            
            // Upload and update
            let newAvatarUrl = try await userRepository.updateProfilePhoto(
                userId: userId,
                imageData: data
            )
            
            // Update local profile
            userProfile?.avatarUrl = newAvatarUrl
            
            hideLoading()
            Logger.shared.info("Profile photo updated successfully")
            
        } catch {
            handleError(error)
        }
    }
    
    /// Updates profile photo with UIImage
    func updateProfilePhoto(_ image: UIImage) async -> Bool {
        guard let userId = currentUserId else {
            print("❌ MyPageViewModel: No current user ID")
            return false
        }
        
        showLoading()
        
        do {
            // Convert UIImage to Data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                hideLoading()
                return false
            }
            
            // Upload and update
            let newAvatarUrl = try await userRepository.updateProfilePhoto(
                userId: userId,
                imageData: imageData
            )
            
            // Update local profile
            userProfile?.avatarUrl = newAvatarUrl
            
            hideLoading()
            Logger.shared.info("Profile photo updated successfully")
            return true
            
        } catch {
            handleError(error)
            return false
        }
    }
    
    // MARK: - Navigation Methods
    func navigateToSavedPosts() {
        // TODO: 保存済み投稿画面への遷移
    }
    
    func navigateToFollowers() {
        // TODO: フォロワー一覧画面への遷移
    }
    
    func navigateToFollowing() {
        // TODO: フォロー中一覧画面への遷移
    }
    
    func navigateToHelp() {
        // TODO: ヘルプ画面への遷移
    }
    
    // MARK: - Delete Operations
    
    /// Deletes a post
    func deletePost(_ post: Post) async {
        guard let userId = currentUserId else {
            print("❌ MyPageViewModel: No current user ID")
            return
        }
        
        isLoading = true
        
        do {
            let success = try await PostService().deletePost(postId: post.id, userId: userId)
            if success {
                // Remove from local arrays
                userPosts.removeAll { $0.id == post.id }
                savedPosts.removeAll { $0.id == post.id }
                
                print("✅ MyPageViewModel: Post deleted successfully")
            }
        } catch {
            print("❌ MyPageViewModel: Failed to delete post: \(error)")
            errorMessage = "Failed to delete post"
        }
        
        isLoading = false
    }
    
    // MARK: - Reorder Operations
    
    /// Reorders posts
    func reorderPosts(_ reorderedPosts: [Post]) async {
        // Update local state immediately for responsive UI
        userPosts = reorderedPosts
        
        // TODO: Here you would typically send the new order to your backend
        // For now, we'll just update locally
        print("✅ MyPageViewModel: Posts reordered - \(reorderedPosts.map { $0.id })")
        
        // In a real implementation, you might want to:
        // 1. Send the new order to your backend API
        // 2. Update a 'display_order' field for each post
        // 3. Handle any errors and revert changes if needed
    }
    
    // MARK: - Refresh
    
    /// Refreshes all user data
    func refresh() async {
        await loadUserData()
    }
    
    /// Forces a complete reload of user data (ignores cache)
    func forceReload() async {
        hasLoadedInitially = false
        await loadUserData()
    }
    
    // MARK: - Private Methods
    
    @objc private func handlePostCreated() {
        print("🔄 MyPageViewModel: Post created notification received - refreshing user data")
        Task {
            // Force reload by resetting the flag
            hasLoadedInitially = false
            await loadUserData()
        }
    }
    
    @objc private func handleFollowStatusChanged() {
        print("🔄 MyPageViewModel: Follow status changed - updating counts")
        Task {
            await updateFollowCounts()
        }
    }
    
    /// Updates only the follow counts without full reload
    private func updateFollowCounts() async {
        guard let userId = currentUserId else { return }
        
        do {
            let newFollowersCount = try await userRepository.fetchFollowersCount(userId: userId)
            let newFollowingCount = try await userRepository.fetchFollowingCount(userId: userId)
            
            // スムーズなアニメーションでカウントを更新
            withAnimation(.easeInOut(duration: 0.3)) {
                followersCount = newFollowersCount
                followingCount = newFollowingCount
            }
            
            print("✅ MyPageViewModel: Updated counts - followers: \(followersCount), following: \(followingCount)")
        } catch {
            print("❌ MyPageViewModel: Failed to update follow counts: \(error)")
        }
    }
    
    // MARK: - Follow Methods
    
    /// Marks new followers as seen
    func markNewFollowersAsSeen() {
        hasNewFollowers = false
        FollowService.shared.markFollowersAsChecked()
    }
    
    // MARK: - Like Operations
    
    /// Toggles like status for a post with optimistic UI updates
    func toggleLike(for post: Post) async {
        print("🔄 MyPageViewModel: toggleLike called for post \(post.id)")
        guard let userId = currentUserId else {
            print("❌ MyPageViewModel: No current user ID")
            handleError(ViewModelError.unauthorized)
            return
        }
        
        print("🔍 MyPageViewModel: Current user ID: \(userId)")
        print("🔍 MyPageViewModel: Post like status before: \(post.isLikedByMe), count: \(post.likeCount)")
        
        // Optimistic UI update
        let originalLikeStatus = post.isLikedByMe
        let newLikeStatus = !originalLikeStatus
        updatePostLikeStatus(postId: post.id, isLiked: newLikeStatus)
        
        print("🔄 MyPageViewModel: Optimistic update - new status: \(newLikeStatus)")
        
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
        print("🔄 MyPageViewModel: updatePostLikeStatus called - postId: \(postId), isLiked: \(isLiked)")
        if let index = userPosts.firstIndex(where: { $0.id == postId }) {
            print("🔍 MyPageViewModel: Found post at index \(index)")
            print("🔍 MyPageViewModel: Before update - isLiked: \(userPosts[index].isLikedByMe), count: \(userPosts[index].likeCount)")
            
            userPosts[index].isLikedByMe = isLiked
            
            // Update like count
            if isLiked {
                userPosts[index].likeCount += 1
            } else {
                userPosts[index].likeCount = max(0, userPosts[index].likeCount - 1)
            }
            
            print("✅ MyPageViewModel: After update - isLiked: \(userPosts[index].isLikedByMe), count: \(userPosts[index].likeCount)")
        } else {
            print("❌ MyPageViewModel: Post not found in userPosts array")
        }
    }
    
    // Like状態のみ更新（カウントは更新しない）
    private func updatePostLikeStatusOnly(postId: String, isLiked: Bool) {
        if let index = userPosts.firstIndex(where: { $0.id == postId }) {
            userPosts[index].isLikedByMe = isLiked
        }
    }
}
