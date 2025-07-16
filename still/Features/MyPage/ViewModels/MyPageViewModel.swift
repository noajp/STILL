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
    
    // MARK: - Private Properties
    
    private var hasLoadedInitially = false
    private var currentUserId: String? {
        authManager.currentUser?.id
    }
    
    // MARK: - Initialization
    
    init(
        userRepository: UserRepositoryProtocol? = nil,
        authManager: (any AuthManagerProtocol)? = nil
    ) {
        self.userRepository = userRepository ?? UserRepository()
        self.authManager = authManager ?? (DependencyContainer.shared.resolve((any AuthManagerProtocol).self) ?? AuthManager.shared)
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
            handleError(ViewModelError.unauthorized)
            return
        }
        
        showLoading()
        
        do {
            // Load profile
            userProfile = try await userRepository.fetchUserProfile(userId: userId)
            
            // Load posts
            userPosts = try await userRepository.fetchUserPosts(userId: userId)
            print("🟢 MyPageViewModel: Loaded \(userPosts.count) posts for user \(userId)")
            
            // Check for new followers
            hasNewFollowers = try await FollowService.shared.checkNewFollowers()
            
            // Update statistics
            postsCount = userPosts.count
            followersCount = userProfile?.followersCount ?? 0
            followingCount = userProfile?.followingCount ?? 0
            
            hasLoadedInitially = true
            hideLoading()
            Logger.shared.info("User data loaded successfully")
            
        } catch {
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
    
    // MARK: - Private Methods
    
    @objc private func handlePostCreated() {
        print("🔄 MyPageViewModel: Post created notification received - refreshing user data")
        Task {
            // Force reload by resetting the flag
            hasLoadedInitially = false
            await loadUserData()
        }
    }
    
    // MARK: - Follow Methods
    
    /// Marks new followers as seen
    func markNewFollowersAsSeen() {
        hasNewFollowers = false
        FollowService.shared.markFollowersAsChecked()
    }
}
