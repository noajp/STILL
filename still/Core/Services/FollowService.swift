//======================================================================
// MARK: - FollowService.swift
// Purpose: Service for managing follow relationships
// Path: still/Core/Services/FollowService.swift
//======================================================================
import Foundation
import Supabase

/// A comprehensive service for managing follow relationships between users
/// Handles both public and private account follow logic, follow requests, and follow status tracking
/// Supports instant follows for public accounts and request-based follows for private accounts
@MainActor
class FollowService: ObservableObject {
    // MARK: - Singleton
    
    /// Shared instance of the follow service
    static let shared = FollowService()
    
    /// Supabase client for database operations
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Follow/Unfollow Operations
    
    /// Initiates a follow action for the specified user
    /// Handles both public accounts (instant follow) and private accounts (follow request)
    /// - Parameter userId: The ID of the user to follow
    /// - Throws: NSError if user is not authenticated, trying to self-follow, or database operation fails
    func followUser(userId: String) async throws {
        // Ensure user is authenticated
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "FollowService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        print("🔵 FollowService.followUser called:")
        print("  - currentUserId: \(currentUserId)")
        print("  - targetUserId: \(userId)")
        
        // Prevent self-following - users cannot follow themselves
        if currentUserId == userId {
            print("⚠️ Cannot follow yourself, skipping")
            throw NSError(domain: "FollowService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cannot follow yourself"])
        }
        
        // Check if already following this user
        let existingFollow = try await supabase
            .from("follows")
            .select("*", head: true, count: .exact)
            .eq("follower_id", value: currentUserId)
            .eq("following_id", value: userId)
            .execute()
            .count ?? 0
        
        if existingFollow > 0 {
            print("⚠️ Already following user \(userId), skipping")
            return
        }
        
        // Check if target user has private account
        struct PrivacyResponse: Codable {
            let isPrivate: Bool?
            
            private enum CodingKeys: String, CodingKey {
                case isPrivate = "is_private"
            }
        }
        
        let privacyResponse: PrivacyResponse = try await supabase
            .from("profiles")
            .select("is_private")
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        let isPrivateAccount = privacyResponse.isPrivate == true
        
        if isPrivateAccount {
            // Private account: Create pending follow request
            let follow = [
                "follower_id": currentUserId,
                "following_id": userId,
                "status": "pending"
            ]
            
            try await supabase
                .from("follows")
                .insert(follow)
                .execute()
            
            print("✅ Follow request sent to private account")
            
            // Removed: Send follow request notification
            // await createFollowRequestNotification(fromUserId: currentUserId, toUserId: userId)
        } else {
            // Public account: Create immediate follow relationship
            let follow = [
                "follower_id": currentUserId,
                "following_id": userId,
                "status": "accepted"
            ]
            
            try await supabase
                .from("follows")
                .insert(follow)
                .execute()
            
            print("✅ Follow relationship created immediately (public account)")
            
            // Removed: Send follow notification
            // await createFollowNotification(fromUserId: currentUserId, toUserId: userId)
        }
        
        // Notify UI to update counts
        NotificationCenter.default.post(name: .followStatusChanged, object: nil)
    }
    
    // Removed: createFollowNotification method
    // Removed: createFollowRequestNotification method
    
    func unfollowUser(userId: String) async throws {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "FollowService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        try await supabase
            .from("follows")
            .delete()
            .eq("follower_id", value: currentUserId)
            .eq("following_id", value: userId)
            .execute()
        
        print("✅ Unfollowed user \(userId)")
        
        // Notify UI to update counts
        NotificationCenter.default.post(name: .followStatusChanged, object: nil)
    }
    
    // MARK: - Check Follow Status
    
    func checkFollowStatus(userId: String) async throws -> FollowStatus {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            return FollowStatus(isFollowing: false, isFollowedBy: false, requestStatus: nil)
        }
        
        // Check current user's follow request to target user
        var requestStatus: FollowRequestStatus?
        var isFollowing = false
        
        do {
            // Custom struct for decoding only the status field
            struct StatusResponse: Codable {
                let status: String
            }
            
            let followData: [StatusResponse] = try await supabase
                .from("follows")
                .select("status")
                .eq("follower_id", value: currentUserId)
                .eq("following_id", value: userId)
                .execute()
                .value
            
            if let statusResponse = followData.first,
               let status = FollowRequestStatus(rawValue: statusResponse.status) {
                requestStatus = status
                isFollowing = status == .accepted
            }
        } catch {
            // No follow relationship exists
            requestStatus = nil
            isFollowing = false
        }
        
        // Check if target user follows current user (only accepted status counts)
        let isFollowedBy: Bool
        do {
            let count = try await supabase
                .from("follows")
                .select("*", head: true, count: .exact)
                .eq("follower_id", value: userId)
                .eq("following_id", value: currentUserId)
                .eq("status", value: "accepted")
                .execute()
                .count ?? 0
            isFollowedBy = count > 0
        } catch {
            isFollowedBy = false
        }
        
        return FollowStatus(isFollowing: isFollowing, isFollowedBy: isFollowedBy, requestStatus: requestStatus)
    }
    
    // MARK: - Followers/Following Lists
    
    func fetchFollowers(userId: String) async throws -> [UserProfile] {
        // First, get all accepted follow relationships where this user is being followed
        let followResponse = try await supabase
            .from("follows")
            .select("follower_id")
            .eq("following_id", value: userId)
            .eq("status", value: "accepted")
            .order("created_at", ascending: false)
            .execute()
        
        // Parse follower IDs
        let followData = try JSONDecoder().decode([[String: String]].self, from: followResponse.data)
        let followerIds = followData.compactMap { $0["follower_id"] }
        
        print("🔍 fetchFollowers - Found \(followerIds.count) follower IDs for user \(userId)")
        
        // If no followers, return empty array
        guard !followerIds.isEmpty else {
            return []
        }
        
        // Then fetch user profiles for those IDs with proper date handling
        let profilesResponse = try await supabase
            .from("profiles")
            .select("id, username, display_name, avatar_url, bio, created_at")
            .in("id", values: followerIds)
            .execute()
        
        // Use a custom decoder for Supabase date format
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(formatter)
        
        let profiles = try decoder.decode([UserProfile].self, from: profilesResponse.data)
        print("🔍 fetchFollowers - Fetched \(profiles.count) follower profiles")
        
        return profiles
    }
    
    func fetchFollowing(userId: String) async throws -> [UserProfile] {
        // First, get all accepted follow relationships where this user is following others
        let followResponse = try await supabase
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: userId)
            .eq("status", value: "accepted")
            .order("created_at", ascending: false)
            .execute()
        
        // Parse following IDs
        let followData = try JSONDecoder().decode([[String: String]].self, from: followResponse.data)
        let followingIds = followData.compactMap { $0["following_id"] }
        
        print("🔍 fetchFollowing - Found \(followingIds.count) following IDs for user \(userId)")
        
        // If not following anyone, return empty array
        guard !followingIds.isEmpty else {
            return []
        }
        
        // Then fetch user profiles for those IDs with proper date handling
        let profilesResponse = try await supabase
            .from("profiles")
            .select("id, username, display_name, avatar_url, bio, created_at")
            .in("id", values: followingIds)
            .execute()
        
        // Use a custom decoder for Supabase date format
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(formatter)
        
        let profiles = try decoder.decode([UserProfile].self, from: profilesResponse.data)
        print("🔍 fetchFollowing - Fetched \(profiles.count) following profiles")
        
        return profiles
    }
    
    // MARK: - New Follower Notification
    
    func checkNewFollowers() async throws -> Bool {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            return false
        }
        
        // Get last checked time from UserDefaults
        let lastCheckedKey = "lastFollowerCheck_\(currentUserId)"
        let lastChecked = UserDefaults.standard.object(forKey: lastCheckedKey) as? Date ?? Date.distantPast
        
        // Check for new followers since last check
        let response = try await supabase
            .from("follows")
            .select("created_at")
            .eq("following_id", value: currentUserId)
            .gt("created_at", value: lastChecked.ISO8601Format())
            .execute()
        
        let newFollowerCount = try JSONDecoder().decode([[String: String]].self, from: response.data).count
        
        return newFollowerCount > 0
    }
    
    func markFollowersAsChecked() {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            return
        }
        
        let lastCheckedKey = "lastFollowerCheck_\(currentUserId)"
        UserDefaults.standard.set(Date(), forKey: lastCheckedKey)
    }
}