//======================================================================
// MARK: - OtherUserProfileViewModel.swift
// Purpose: ViewModel for other user profile view with privacy restrictions and follow request functionality (プライバシー制限とフォローリクエスト機能を持つ他ユーザープロフィールビューのためのViewModel)
// Path: still/Features/Profile/ViewModels/OtherUserProfileViewModel.swift
//======================================================================

import Foundation
import Supabase

@MainActor
class OtherUserProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var userPosts: [Post] = []
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var followStatus: FollowRequestStatus?
    @Published var hasIncomingFollowRequest = false // Whether viewed user has sent a follow request to current user
    @Published var canViewContent = false // Whether user can see posts/articles
    @Published var showFollowersList = false
    @Published var showFollowingList = false
    
    private var justAcceptedRequest = false // Flag to prevent re-checking after acceptance
    
    // Computed properties for stats
    var postsCount: Int { userPosts.count }
    var followersCount: Int { userProfile?.followersCount ?? 0 }
    var followingCount: Int { userProfile?.followingCount ?? 0 }
    
    private let followService = FollowService.shared
    
    func loadUserData(userId: String) async {
        await loadProfile(userId: userId)
    }
    
    func loadProfile(userId: String) async {
        isLoading = true
        justAcceptedRequest = false // Reset flag when loading fresh
        
        do {
            // Load user profile
            let profile: UserProfile = try await SupabaseManager.shared.client
                .from("profiles")
                .select("*")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            userProfile = profile
            
            // Check follow status and determine content visibility
            await checkFollowStatus(targetUserId: userId)
            
            // Only check incoming requests if we haven't just accepted one
            if !justAcceptedRequest {
                await checkIncomingFollowRequest(fromUserId: userId)
            }
            
            await determineContentVisibility(for: profile)
            
            // Load content if user can view it
            if canViewContent {
                await loadPosts(userId: userId)
                await loadArticles(userId: userId)
            }
            
        } catch {
            print("❌ Error loading profile: \(error)")
            errorMessage = "Failed to load profile"
        }
        
        isLoading = false
    }
    
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
        
        // If account is public, content is visible
        if profile.isPrivate != true {
            canViewContent = true
            return
        }
        
        // If account is private, check if current user is following them OR
        // if the viewed user is following the current user (mutual access after accepting follow request)
        if followStatus == .accepted {
            canViewContent = true
            return
        }
        
        // Check if the viewed user is following the current user (they sent a follow request and it was accepted)
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
    
    private func loadPosts(userId: String) async {
        do {
            let loadedPosts: [Post] = try await SupabaseManager.shared.client
                .from("posts")
                .select("*")
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
    
    private func loadArticles(userId: String) async {
        do {
            let loadedArticles: [Article] = try await SupabaseManager.shared.client
                .from("articles")
                .select("*")
                .eq("user_id", value: userId)
                .eq("status", value: "published")
                .order("created_at", ascending: false)
                .limit(10)
                .execute()
                .value
            
            articles = loadedArticles
            
        } catch {
            print("❌ Error loading articles: \(error)")
        }
    }
    
    func followUser() async {
        guard let targetUser = userProfile else { return }
        
        print("🔵 followUser called - targetUserId: \(targetUser.id), currentFollowStatus: \(followStatus?.rawValue ?? "nil")")
        
        do {
            // Use FollowService to handle follow request
            try await followService.followUser(userId: targetUser.id)
            
            // Refresh follow status
            let status = try await followService.checkFollowStatus(userId: targetUser.id)
            followStatus = status.requestStatus
            
            print("🔵 Follow action - new status: \(status.requestStatus?.rawValue ?? "nil")")
            
            // Update content visibility
            await determineContentVisibility(for: targetUser)
            
            // Don't reload full profile to avoid resetting flags and causing issues
            // await loadProfile(userId: targetUser.id)
            
            print("✅ Follow action completed")
            
        } catch {
            print("❌ Error following user: \(error)")
            errorMessage = "Failed to follow user"
        }
    }
    
    func unfollowUser() async {
        guard let targetUser = userProfile else { return }
        
        do {
            // Use FollowService to handle unfollow
            try await followService.unfollowUser(userId: targetUser.id)
            
            followStatus = nil
            
            // Update content visibility
            await determineContentVisibility(for: targetUser)
            
            // Don't reload full profile to avoid issues
            // await loadProfile(userId: targetUser.id)
            
            print("✅ Unfollow action completed")
            
        } catch {
            print("❌ Error unfollowing user: \(error)")
            errorMessage = "Failed to unfollow user"
        }
    }
    
    func acceptFollowRequest() async {
        guard let viewedUser = userProfile,
              let currentUserId = AuthManager.shared.currentUser?.id else { return }
        
        do {
            print("🔔 Accepting follow request from \(viewedUser.id) to \(currentUserId)")
            
            // Update the follow status from pending to accepted
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