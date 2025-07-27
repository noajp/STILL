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
        
        // Check if already following (any status) to prevent duplicates
        let existingFollow = try await supabase
            .from("follows")
            .select("*", head: true, count: .exact)
            .eq("follower_id", value: currentUserId)
            .eq("following_id", value: userId)
            .execute()
            .count ?? 0
        
        if existingFollow > 0 {
            print("⚠️ Already have a follow relationship with user \(userId), skipping")
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
        
        // Determine status based on target user's privacy setting
        let status = privacyResponse.isPrivate == true ? "pending" : "accepted"
        
        let follow = [
            "follower_id": currentUserId,
            "following_id": userId,
            "status": status
        ]
        
        try await supabase
            .from("follows")
            .insert(follow)
            .execute()
        
        print("✅ Follow relationship created with status: \(status)")
        
        // Create appropriate notification based on status
        if status == "accepted" {
            print("🔔 Creating follow notification for public account...")
            await createFollowNotification(fromUserId: currentUserId, toUserId: userId)
        } else {
            print("🔔 Creating follow request notification for private account...")
            await createFollowRequestNotification(fromUserId: currentUserId, toUserId: userId)
        }
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
    
    private func createFollowRequestNotification(fromUserId: String, toUserId: String) async {
        print("🔔 createFollowRequestNotification called:")
        print("  - fromUserId: \(fromUserId)")
        print("  - toUserId: \(toUserId)")
        
        do {
            // Get sender's profile
            print("🔔 Fetching sender profile...")
            let senderProfile = try await UserRepository.shared.fetchUserProfile(userId: fromUserId)
            print("🔔 Sender profile fetched: \(senderProfile.username)")
            
            // Create follow request notification using NotificationService
            print("🔔 Calling NotificationService.createFollowRequestNotification...")
            await NotificationService.shared.createFollowRequestNotification(
                fromUserId: fromUserId,
                toUserId: toUserId,
                senderProfile: senderProfile
            )
            
            print("✅ Follow request notification created for user \(toUserId)")
        } catch {
            print("❌ Failed to create follow request notification: \(error)")
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
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return }
        
        let lastCheckedKey = "lastFollowerCheck_\(currentUserId)"
        UserDefaults.standard.set(Date(), forKey: lastCheckedKey)
    }
}