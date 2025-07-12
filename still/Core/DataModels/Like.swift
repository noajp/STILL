//======================================================================
// MARK: - Like.swift（いいね機能用モデル）
// Path: foodai/Core/DataModels/Like.swift
//======================================================================
import Foundation

struct Like: Identifiable, Codable {
    let id: String
    let userId: String
    let postId: String
    let createdAt: Date
    
    // リレーション（オプショナル）
    var user: UserProfile?
    var post: Post?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
        case createdAt = "created_at"
    }
}
