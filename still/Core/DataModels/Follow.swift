//======================================================================
// MARK: - Follow.swift（フォロー関係）
// Path: still/Core/DataModels/Follow.swift
//======================================================================
import Foundation

struct Follow: Identifiable, Codable {
    let id: String
    let followerId: String      // フォローする人
    let followingId: String     // フォローされる人
    let createdAt: Date
    
    // Relationships
    var follower: UserProfile?
    var following: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
        case follower
        case following
    }
}

// MARK: - Follow Status
struct FollowStatus: Codable {
    let isFollowing: Bool
    let isFollowedBy: Bool
    
    enum CodingKeys: String, CodingKey {
        case isFollowing = "is_following"
        case isFollowedBy = "is_followed_by"
    }
}

// MARK: - New Follower Notification
struct NewFollowerNotification: Codable {
    let hasNewFollowers: Bool
    let lastCheckedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case hasNewFollowers = "has_new_followers"
        case lastCheckedAt = "last_checked_at"
    }
}