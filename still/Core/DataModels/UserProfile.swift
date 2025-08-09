//======================================================================
// MARK: - UserProfile.swift
// Purpose: User profile data model with username validation, display name handling, and follower/following count tracking (ユーザー名検証、表示名処理、フォロワー/フォロー数追跡を持つユーザープロフィールデータモデル)
// Path: still/Core/DataModels/UserProfile.swift
//======================================================================
import Foundation

/// Comprehensive user profile data model with validation and display helpers
/// Supports username validation, display name handling, follower/following tracking, and private account settings
/// Provides computed properties for consistent user identification across the app
struct UserProfile: Identifiable, Codable {
    // MARK: - Core Properties
    
    /// Unique user identifier (UUID from database)
    let id: String
    
    /// Unique username for user identification (lowercase letters, numbers, hyphens, underscores only)
    var username: String
    
    /// Optional display name shown in profile details (falls back to username if empty)
    var displayName: String?
    
    /// URL of the user's profile avatar image
    var avatarUrl: String?
    
    /// User's biography text
    var bio: String?
    
    /// Number of users following this user
    var followersCount: Int?
    
    /// Number of users this user is following
    var followingCount: Int?
    
    /// Whether this account is private (requires follow approval)
    var isPrivate: Bool?
    
    /// Account creation timestamp
    let createdAt: Date?
    
    /// User's public key for end-to-end encryption (Base64 encoded P256 public key)
    var publicKey: String?
    
    // MARK: - JSON Coding Keys
    
    /// Coding keys for JSON serialization/deserialization with database column names
    enum CodingKeys: String, CodingKey {
        case id, username, bio
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case isPrivate = "is_private"
        case createdAt = "created_at"
        case publicKey = "public_key"
    }
    
    // MARK: - Display Helper Methods
    
    /// メッセージ機能で表示するユーザーID
    var userIdForDisplay: String {
        return username
    }
    
    /// @付きのユーザーID表示
    var userIdWithAt: String {
        return "@\(username)"
    }
    
    /// プロフィール詳細で表示する表示名（フォールバック: ユーザーID）
    var profileDisplayName: String {
        return displayName?.isEmpty == false ? displayName! : username
    }
    
    /// プロフィール詳細での完全表示（表示名 + @ユーザーID）
    var fullProfileDisplay: String {
        if let displayName = displayName, !displayName.isEmpty {
            return "\(displayName) (@\(username))"
        } else {
            return "@\(username)"
        }
    }
    
    // MARK: - バリデーション
    
    /// ユーザーIDの形式が有効かチェック
    var isValidUserId: Bool {
        let pattern = "^[a-z0-9_-]{3,30}$"
        return username.range(of: pattern, options: .regularExpression) != nil
    }
}

