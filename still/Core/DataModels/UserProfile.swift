//======================================================================
// MARK: - UserProfile.swift（ユーザープロフィール）
// Path: foodai/Core/DataModels/UserProfile.swift
//======================================================================
import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String              // 内部UUID（データベース用）
    var username: String        // ユーザーID: 一意識別子、英小文字・数字・ハイフン・アンダーバーのみ
    var displayName: String?    // 表示名: プロフィール詳細でのみ表示
    var avatarUrl: String?
    var bio: String?
    var followersCount: Int?    // フォロワー数
    var followingCount: Int?    // フォロー数
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, username, bio
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case createdAt = "created_at"
    }
    
    // MARK: - 新仕様に基づく表示用ヘルパーメソッド
    
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

