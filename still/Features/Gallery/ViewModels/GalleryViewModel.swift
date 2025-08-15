//======================================================================
// MARK: - GalleryViewModel.swift
// Purpose: View model for gallery grid view functionality
// Path: still/Features/Gallery/ViewModels/GalleryViewModel.swift
//======================================================================

import Foundation
import SwiftUI

/**
 * GalleryViewModel manages the gallery grid view state and data.
 * 
 * Responsibilities:
 * - Loading and caching posts for grid display
 * - Pagination for infinite scroll
 * - Refresh functionality
 * - Error handling
 */
@MainActor
class GalleryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// All posts to display in the gallery
    @Published var posts: [Post] = []
    
    /// Loading state for initial load
    @Published var isLoading = false
    
    /// Error message to display
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let homeFeedViewModel = HomeFeedViewModel()
    
    /// Flag to prevent redundant initial loads
    private var hasLoadedInitially = false
    
    // MARK: - Initialization
    
    init() {
        setupNotificationListeners()
    }
    
    // MARK: - Setup
    
    /**
     * Sets up notification listeners for post updates.
     */
    private func setupNotificationListeners() {
        // Listen for new posts
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNewPost),
            name: NSNotification.Name("PostCreated"),
            object: nil
        )
        
        // Listen for post deletions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostDeleted),
            name: NSNotification.Name("PostDeleted"),
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /**
     * Loads posts only if they haven't been loaded initially.
     * 
     * This method prevents redundant API calls by checking the load status.
     */
    func loadPostsIfNeeded() async {
        // Skip if already loaded to avoid redundant API calls
        guard !hasLoadedInitially else { 
            return 
        }
        await loadPosts()
    }
    
    /**
     * Loads initial posts for the gallery.
     */
    func loadPosts() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Use HomeFeedViewModel to load posts
        await homeFeedViewModel.loadPostsIfNeeded()
        posts = homeFeedViewModel.posts
        
        print("✅ GalleryViewModel: Loaded \(posts.count) posts")
        hasLoadedInitially = true
        isLoading = false
    }
    
    /**
     * Loads more posts for pagination.
     */
    func loadMorePosts() async {
        // HomeFeedViewModel doesn't have pagination, so we'll skip this for now
        // In the future, this could be implemented by extending the post service
        print("📝 GalleryViewModel: Load more posts not implemented yet")
    }
    
    /**
     * Refreshes the gallery with latest posts.
     */
    func refreshPosts() async {
        await homeFeedViewModel.forceRefreshPosts()
        posts = homeFeedViewModel.posts
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleNewPost(_ notification: Notification) {
        Task {
            await refreshPosts()
        }
    }
    
    @objc private func handlePostDeleted(_ notification: Notification) {
        if let postId = notification.object as? String {
            posts.removeAll { $0.id == postId }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}