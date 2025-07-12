//======================================================================
// MARK: - FollowService.swift
// Purpose: Service for managing follow relationships
// Path: still/Core/Services/FollowService.swift
//======================================================================
import Foundation
import Supabase

@MainActor
class FollowService: ObservableObject {
    static let shared = FollowService()
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    // MARK: - Follow/Unfollow
    
    func followUser(userId: String) async throws {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            throw NSError(domain: "FollowService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let follow = [
            "follower_id": currentUserId,
            "following_id": userId
        ]
        
        try await supabase
            .from("follows")
            .insert(follow)
            .execute()
    }
    
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
    }
    
    // MARK: - Check Follow Status
    
    func checkFollowStatus(userId: String) async throws -> FollowStatus {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            return FollowStatus(isFollowing: false, isFollowedBy: false)
        }
        
        // Check if current user follows the target user
        let isFollowing: Bool
        do {
            _ = try await supabase
                .from("follows")
                .select()
                .eq("follower_id", value: currentUserId)
                .eq("following_id", value: userId)
                .single()
                .execute()
            isFollowing = true
        } catch {
            isFollowing = false
        }
        
        // Check if target user follows current user
        let isFollowedBy: Bool
        do {
            _ = try await supabase
                .from("follows")
                .select()
                .eq("follower_id", value: userId)
                .eq("following_id", value: currentUserId)
                .single()
                .execute()
            isFollowedBy = true
        } catch {
            isFollowedBy = false
        }
        
        return FollowStatus(isFollowing: isFollowing, isFollowedBy: isFollowedBy)
    }
    
    // MARK: - Followers/Following Lists
    
    func fetchFollowers(userId: String) async throws -> [UserProfile] {
        let response = try await supabase
            .from("follows")
            .select("follower:profiles!follower_id(*)")
            .eq("following_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
        
        let follows = try JSONDecoder().decode([Follow].self, from: response.data)
        return follows.compactMap { $0.follower }
    }
    
    func fetchFollowing(userId: String) async throws -> [UserProfile] {
        let response = try await supabase
            .from("follows")
            .select("following:profiles!following_id(*)")
            .eq("follower_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
        
        let follows = try JSONDecoder().decode([Follow].self, from: response.data)
        return follows.compactMap { $0.following }
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
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return }
        
        let lastCheckedKey = "lastFollowerCheck_\(currentUserId)"
        UserDefaults.standard.set(Date(), forKey: lastCheckedKey)
    }
}