//======================================================================
// MARK: - OtherUserProfileViewModel.swift
// Purpose: ViewModel for other user profile view with privacy restrictions and follow request functionality (プライバシー制限とフォローリクエスト機能を持つ他ユーザープロフィールビューのためのViewModel)
// Path: still/Features/Profile/ViewModels/OtherUserProfileViewModel.swift
//======================================================================

import Foundation
import Supabase

/// Database article structure matching the articles table schema
/// Used for direct database communication with Supabase articles table


/// ViewModel for managing other user profile views with privacy restrictions and follow functionality
/// Handles profile loading, follow requests, content visibility based on privacy settings
@MainActor
class OtherUserProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The profile data of the user being viewed
    @Published var userProfile: UserProfile?
    
    /// Posts created by the viewed user
    @Published var userPosts: [Post] = []
    

    
    /// Loading state indicator
    @Published var isLoading = false
    
    /// Error message to display to user
    @Published var errorMessage: String?
    
    /// Current follow request status between current user and viewed user
    @Published var followStatus: FollowRequestStatus?
    
    /// Whether the viewed user has sent a follow request to the current user
    @Published var hasIncomingFollowRequest = false
    
    /// Whether the current user can see the viewed user's posts/articles based on privacy settings
    @Published var canViewContent = false
    
    /// Controls display of followers list modal
    @Published var showFollowersList = false
    
    /// Controls display of following list modal
    @Published var showFollowingList = false
    
    // MARK: - Private Properties
    
    /// Flag to prevent re-checking follow requests after acceptance to avoid UI flicker
    private var justAcceptedRequest = false
    
    // MARK: - Computed Properties
    
    /// Number of posts created by the viewed user
    var postsCount: Int { userPosts.count }
    
    /// Number of followers of the viewed user
    var followersCount: Int { userProfile?.followersCount ?? 0 }
    
    /// Number of users the viewed user is following
    var followingCount: Int { userProfile?.followingCount ?? 0 }
    
    /// Whether the current user is viewing their own profile
    var isCurrentUser: Bool {
        guard let currentUserId = AuthManager.shared.currentUser?.id,
              let profileUserId = userProfile?.id else { return false }
        return currentUserId.lowercased() == profileUserId.lowercased()
    }
    
    // MARK: - Dependencies
    
    /// Service for handling follow/unfollow operations
    private let followService = FollowService.shared
    
    // MARK: - Initialization
    
    /// Initializes the view model and sets up notification observers
    init() {
        // Listen for follow status changes from other parts of the app
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFollowStatusChanged),
            name: NSNotification.Name("followStatusChanged"),
            object: nil
        )
    }
    
    // MARK: - Notification Handlers
    
    /// Handles follow status change notifications and refreshes profile counts
    @objc private func handleFollowStatusChanged() {
        print("🔄 OtherUserProfileViewModel: Follow status changed - updating profile")
        Task {
            if let userId = userProfile?.id {
                await refreshProfileCounts(userId: userId)
            }
        }
    }
    
    /// Refreshes follower and following counts for the viewed user
    /// - Parameter userId: ID of the user whose counts should be refreshed
    private func refreshProfileCounts(userId: String) async {
        do {
            let updatedProfile = try await UserRepository.shared.fetchUserProfile(userId: userId)
            userProfile?.followersCount = updatedProfile.followersCount
            userProfile?.followingCount = updatedProfile.followingCount
            print("✅ OtherUserProfileViewModel: Updated counts - followers: \(updatedProfile.followersCount ?? 0), following: \(updatedProfile.followingCount ?? 0)")
        } catch {
            print("❌ OtherUserProfileViewModel: Failed to refresh profile counts: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads all user data for the specified user ID
    /// - Parameter userId: ID of the user whose data should be loaded
    func loadUserData(userId: String) async {
        await loadProfile(userId: userId)
    }
    
    /// Loads the complete profile data for a user including privacy checks and content
    /// - Parameter userId: ID of the user whose profile should be loaded
    func loadProfile(userId: String) async {
        isLoading = true
        justAcceptedRequest = false // Reset flag when loading fresh
        
        do {
            // Load user profile from database - force fresh data by bypassing cache
            let profile = try await UserRepository.shared.fetchUserProfile(userId: userId)
            
            userProfile = profile
            
            // Check follow status and determine content visibility
            await checkFollowStatus(targetUserId: userId)
            
            // Only check incoming requests if we haven't just accepted one
            if !justAcceptedRequest {
                await checkIncomingFollowRequest(fromUserId: userId)
            }
            
            await determineContentVisibility(for: profile)
            
            // Load content if user can view it based on privacy settings
            if canViewContent {
                await loadPosts(userId: userId)

            }
            
        } catch {
            print("❌ Error loading profile: \(error)")
            errorMessage = "Failed to load profile"
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    /// Checks the follow status between current user and target user
    /// - Parameter targetUserId: ID of the user being viewed
    private func checkFollowStatus(targetUserId: String) async {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return }
        
        do {
            // Use FollowService to check status
            let status = try await followService.checkFollowStatus(userId: targetUserId)
            followStatus = status.requestStatus
            
            print("🔍 Follow status check - currentUser: \(currentUserId), targetUser: \(targetUserId)")
            print("🔍 Follow status result - isFollowing: \(status.isFollowing), isFollowedBy: \(status.isFollowedBy), requestStatus: \(status.requestStatus?.rawValue ?? "nil")")
            
        } catch {
            print("❌ Error checking follow status: \(error)")
            followStatus = nil
        }
    }
    
    /// Checks if the viewed user has sent a pending follow request to the current user
    /// - Parameter fromUserId: ID of the user who might have sent a follow request
    private func checkIncomingFollowRequest(fromUserId: String) async {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { 
            hasIncomingFollowRequest = false
            return 
        }
        
        do {
            // Check if there's a pending request from the viewed user to current user
            let response = try await SupabaseManager.shared.client
                .from("follows")
                .select("status")
                .eq("follower_id", value: fromUserId)
                .eq("following_id", value: currentUserId)
                .eq("status", value: "pending")
                .limit(1)
                .execute()
            
            let followData = try JSONDecoder().decode([[String: String]].self, from: response.data)
            let hasPendingRequest = !followData.isEmpty
            
            // Only set hasIncomingFollowRequest to true if there's actually a pending request
            // and we haven't just processed an acceptance
            hasIncomingFollowRequest = hasPendingRequest
            
            print("🔍 Incoming follow request check - fromUserId: \(fromUserId), currentUserId: \(currentUserId), hasIncoming: \(hasIncomingFollowRequest), pendingCount: \(followData.count)")
            
        } catch {
            print("❌ Error checking incoming follow request: \(error)")
            hasIncomingFollowRequest = false
        }
    }
    
    /// Determines whether the current user can view the profile owner's content based on privacy settings
    /// - Parameter profile: The profile of the user being viewed
    private func determineContentVisibility(for profile: UserProfile) async {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            canViewContent = false
            return
        }
        
        // User can always view their own content
        if profile.id == currentUserId {
            canViewContent = true
            return
        }
        
        // If account is public, content is visible to all
        if profile.isPrivate != true {
            canViewContent = true
            return
        }
        
        // If account is private, check if current user is following them
        if followStatus == .accepted {
            canViewContent = true
            return
        }
        
        // Check if the viewed user is following the current user (mutual access after accepting follow request)
        do {
            let mutualFollowStatus = try await followService.checkFollowStatus(userId: currentUserId)
            if mutualFollowStatus.isFollowedBy {
                canViewContent = true
                print("🔍 Content access granted - viewed user is following current user")
                return
            }
        } catch {
            print("❌ Error checking mutual follow status: \(error)")
        }
        
        canViewContent = false
    }
    
    /// Loads posts created by the specified user
    /// - Parameter userId: ID of the user whose posts should be loaded
    private func loadPosts(userId: String) async {
        do {
            let loadedPosts: [Post] = try await SupabaseManager.shared.client
                .from("posts")
                .select("""
                    id,
                    user_id,
                    media_url,
                    media_type,
                    thumbnail_url,
                    media_width,
                    media_height,
                    caption,
                    location_name,
                    latitude,
                    longitude,
                    is_public,
                    like_count,
                    comment_count,
                    created_at,
                    updated_at
                """)
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value
            
            userPosts = loadedPosts
            
        } catch {
            print("❌ Error loading posts: \(error)")
        }
    }
    
    /// Loads published articles written by the specified user
    /// - Parameter userId: ID of the user whose articles should be loaded

    
    // MARK: - Follow Actions
    
    /// Initiates a follow request to the viewed user
    /// For public accounts, immediately follows; for private accounts, sends a follow request
    func followUser() async {
        guard let targetUser = userProfile else { return }
        
        print("🔵 followUser called - targetUserId: \(targetUser.id), currentFollowStatus: \(followStatus?.rawValue ?? "nil")")
        
        do {
            // Use FollowService to handle follow request
            try await followService.followUser(userId: targetUser.id)
            
            // Refresh follow status to get updated state
            let status = try await followService.checkFollowStatus(userId: targetUser.id)
            followStatus = status.requestStatus
            
            print("🔵 Follow action - new status: \(status.requestStatus?.rawValue ?? "nil")")
            
            // Update content visibility based on new follow status
            await determineContentVisibility(for: targetUser)
            
            print("✅ Follow action completed")
            
        } catch {
            print("❌ Error following user: \(error)")
            errorMessage = "Failed to follow user"
        }
    }
    
    /// Unfollows the viewed user and removes follow relationship
    func unfollowUser() async {
        guard let targetUser = userProfile else { return }
        
        do {
            // Use FollowService to handle unfollow
            try await followService.unfollowUser(userId: targetUser.id)
            
            // Clear follow status
            followStatus = nil
            
            // Update content visibility (likely will be restricted for private accounts)
            await determineContentVisibility(for: targetUser)
            
            print("✅ Unfollow action completed")
            
        } catch {
            print("❌ Error unfollowing user: \(error)")
            errorMessage = "Failed to unfollow user"
        }
    }
    
    /// Cancels a pending follow request sent to the viewed user
    func cancelFollowRequest() async {
        guard let targetUser = userProfile else { return }
        
        print("🔵 cancelFollowRequest called - targetUserId: \(targetUser.id)")
        
        do {
            // Use FollowService to cancel follow request (same as unfollow)
            try await followService.unfollowUser(userId: targetUser.id)
            
            // Clear follow status since request is cancelled
            followStatus = nil
            
            // Update content visibility (will be restricted for private accounts)
            await determineContentVisibility(for: targetUser)
            
            print("✅ Follow request cancelled")
            
        } catch {
            print("❌ Error cancelling follow request: \(error)")
            errorMessage = "Failed to cancel follow request"
        }
    }
    
    /// Accepts a follow request from the viewed user to the current user
    /// Updates the follow relationship status and creates notification
    func acceptFollowRequest() async {
        guard let viewedUser = userProfile,
              let currentUserId = AuthManager.shared.currentUser?.id else { return }
        
        do {
            print("🔔 Accepting follow request from \(viewedUser.id) to \(currentUserId)")
            
            // Update the follow status from pending to accepted in database
            let response = try await SupabaseManager.shared.client
                .from("follows")
                .update(["status": "accepted"])
                .eq("follower_id", value: viewedUser.id)
                .eq("following_id", value: currentUserId)
                .eq("status", value: "pending")
                .execute()
            
            print("✅ Database updated successfully - Response status: \(response.status)")
            
            // Update local state immediately to prevent UI flicker
            hasIncomingFollowRequest = false
            justAcceptedRequest = true
            
            // Small delay to ensure database consistency before any reloads
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            // Refresh the follow status properly after acceptance
            await checkFollowStatus(targetUserId: viewedUser.id)
            
            // Create a follow notification now that the request is accepted
            await createAcceptedFollowNotification(fromUserId: viewedUser.id, toUserId: currentUserId)
            
            print("✅ Follow request accepted - hasIncomingFollowRequest set to false")
            
        } catch {
            print("❌ Error accepting follow request: \(error)")
            errorMessage = "Failed to accept follow request"
        }
    }
    
    /// Creates a follow notification when a follow request is accepted
    /// - Parameters:
    ///   - fromUserId: ID of the user who originally sent the follow request
    ///   - toUserId: ID of the user who accepted the follow request
    private func createAcceptedFollowNotification(fromUserId: String, toUserId: String) async {
        do {
            let senderProfile = try await UserRepository.shared.fetchUserProfile(userId: toUserId)
            await NotificationService.shared.createFollowNotification(
                fromUserId: fromUserId,
                toUserId: toUserId,
                senderProfile: senderProfile
            )
        } catch {
            print("❌ Failed to create accepted follow notification: \(error)")
        }
    }
}