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
        
        print("🔵 FollowService.followUser called:")
        print("  - currentUserId: \(currentUserId)")
        print("  - targetUserId: \(userId)")
        
        // Check if already following to prevent duplicates
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
        
        let follow = [
            "follower_id": currentUserId,
            "following_id": userId
        ]
        
        try await supabase
            .from("follows")
            .insert(follow)
            .execute()
        
        print("✅ Follow relationship created successfully")
        
        // Create follow notification
        print("🔔 Creating follow notification...")
        await createFollowNotification(fromUserId: currentUserId, toUserId: userId)
    }
    
    private func createFollowNotification(fromUserId: String, toUserId: String) async {
        print("🔔 createFollowNotification called:")
        print("  - fromUserId: \(fromUserId)")
        print("  - toUserId: \(toUserId)")
        
        do {
            // Get sender's profile
            print("🔔 Fetching sender profile...")
            let senderProfile = try await UserRepository.shared.fetchUserProfile(userId: fromUserId)
            print("🔔 Sender profile fetched: \(senderProfile.username)")
            
            // Create notification using NotificationService
            print("🔔 Calling NotificationService.createFollowNotification...")
            await NotificationService.shared.createFollowNotification(
                fromUserId: fromUserId,
                toUserId: toUserId,
                senderProfile: senderProfile
            )
            
            print("✅ Follow notification created for user \(toUserId)")
        } catch {
            print("❌ Failed to create follow notification: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
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
        // First, get all follow relationships where this user is being followed
        let followResponse = try await supabase
            .from("follows")
            .select("follower_id")
            .eq("following_id", value: userId)
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
        // First, get all follow relationships where this user is following others
        let followResponse = try await supabase
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: userId)
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
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return }
        
        let lastCheckedKey = "lastFollowerCheck_\(currentUserId)"
        UserDefaults.standard.set(Date(), forKey: lastCheckedKey)
    }
}