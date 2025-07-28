//======================================================================
// MARK: - ProfileViewModel.swift
// Purpose: Profile data management and user profile operations
// Path: still/Features/Profile/ViewModels/ProfileViewModel.swift
//======================================================================
import SwiftUI

/**
 * ProfileViewModel manages user profile data and associated content.
 * 
 * This view model handles:
 * - User profile information loading and caching
 * - User's post collection management
 * - Profile data synchronization
 * - Loading state management
 * - Error handling for profile operations
 * 
 * The view model automatically loads user data on initialization
 * and provides methods for refreshing profile information.
 */
@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current user's profile information
    @Published var userProfile: UserProfile?
    
    /// Collection of posts created by the user
    @Published var posts: [Post] = []
    
    /// Loading state for profile operations
    @Published var isLoading = false
    
    // MARK: - Private Properties
    
    /// Service for handling post-related operations
    private let postService = PostService()
    
    /// Flag to prevent redundant initial loads
    private var hasLoadedInitially = false
    
    // MARK: - Initialization
    
    /**
     * Initializes the profile view model and triggers initial data load.
     */
    init() {
        loadUserDataIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /**
     * Loads user data only if it hasn't been loaded initially.
     * 
     * This method prevents redundant API calls by checking the load status.
     */
    func loadUserDataIfNeeded() {
        guard !hasLoadedInitially else { return }
        loadUserData()
    }
    
    /**
     * Loads complete user data including profile and posts.
     * 
     * This method fetches:
     * - User profile information (TODO: implement UserService)
     * - User's posts collection
     * 
     * The method handles loading states and error cases gracefully.
     */
    func loadUserData() {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        
        Task {
            isLoading = true
            
            // Load user profile information
            // TODO: Create UserService to fetch profile data
            
            // Load user's posts
            do {
                let userPosts = try await postService.fetchUserPosts(userId: userId)
                self.posts = userPosts
                self.hasLoadedInitially = true
            } catch {
                print("Error loading user posts: \(error)")
            }
            
            isLoading = false
        }
    }
}

