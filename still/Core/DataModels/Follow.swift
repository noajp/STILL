//======================================================================
// MARK: - Follow.swift（フォロー関係）
// Path: still/Core/DataModels/Follow.swift
//======================================================================
import Foundation

struct Follow: Identifiable, Codable {
    let id: String
    let followerId: String      // フォローする人
    let followingId: String     // フォローされる人
    var status: FollowRequestStatus // フォローリクエストの状態
    let createdAt: Date
    
    // Relationships
    var follower: UserProfile?
    var following: UserProfile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
        case status
        case createdAt = "created_at"
        case follower
        case following
    }
}

// MARK: - Follow Request Status
enum FollowRequestStatus: String, Codable, CaseIterable {
    case pending = "pending"     // 承認待ち
    case accepted = "accepted"   // 承認済み
    case declined = "declined"   // 拒否済み
    
    var displayText: String {
        switch self {
        case .pending: return "承認待ち"
        case .accepted: return "フォロー中"
        case .declined: return "拒否済み"
        }
    }
}

// MARK: - Follow Status
struct FollowStatus: Codable {
    let isFollowing: Bool
    let isFollowedBy: Bool
    let requestStatus: FollowRequestStatus?
    
    enum CodingKeys: String, CodingKey {
        case isFollowing = "is_following"
        case isFollowedBy = "is_followed_by"
        case requestStatus = "request_status"
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