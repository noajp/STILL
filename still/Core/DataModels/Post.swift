//======================================================================
// MARK: - Post.swift
// Purpose: Core data model for posts with media, location, user interaction states, and aspect ratio calculations (メディア、位置情報、ユーザーインタラクション状態、アスペクト比計算を持つ投稿のコアデータモデル)
// Path: still/Core/DataModels/Post.swift
//======================================================================
import Foundation
import CoreTransferable

/// Core data model representing a social media post with comprehensive metadata
/// Supports photos and videos with location data, user interactions, and relationship handling
/// Includes computed properties for UI display and aspect ratio calculations
struct Post: Identifiable, Codable, Hashable, Transferable {
    // MARK: - Core Properties
    
    /// Unique identifier for the post
    let id: String
    
    /// ID of the user who created this post
    let userId: String
    
    /// URL of the main media file (photo or video)
    let mediaUrl: String
    
    /// Type of media (photo or video)
    let mediaType: MediaType
    
    /// Optional URL for video thumbnail
    let thumbnailUrl: String?
    
    /// Original width of the media in pixels
    let mediaWidth: Double?
    
    /// Original height of the media in pixels
    let mediaHeight: Double?
    
    /// Optional caption text for the post
    let caption: String?
    
    /// Human-readable location name
    let locationName: String?
    
    /// GPS latitude coordinate
    let latitude: Double?
    
    /// GPS longitude coordinate
    let longitude: Double?
    
    /// Whether the post is publicly visible
    let isPublic: Bool
    
    /// Timestamp when the post was created
    let createdAt: Date
    
    /// Timestamp when the post was last updated (optional for backward compatibility)
    let updatedAt: Date?
    
    // MARK: - Statistics
    
    /// Number of likes this post has received (mutable for real-time updates)
    var likeCount: Int
    
    /// Number of comments on this post
    let commentCount: Int
    
    // MARK: - User Interaction State
    
    /// Associated user profile (populated when needed)
    var user: UserProfile?
    
    /// Whether the current user has liked this post
    var isLikedByMe: Bool = false
    
    /// Whether the current user has saved this post
    var isSavedByMe: Bool = false
    
    enum MediaType: String, Codable {
        case photo = "photo"
        case video = "video"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case thumbnailUrl = "thumbnail_url"
        case mediaWidth = "media_width"
        case mediaHeight = "media_height"
        case caption
        case locationName = "location_name"
        case latitude
        case longitude
        case isPublic = "is_public"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Initializers
    
    init(
        id: String,
        userId: String,
        mediaUrl: String,
        mediaType: MediaType,
        thumbnailUrl: String? = nil,
        mediaWidth: Double? = nil,
        mediaHeight: Double? = nil,
        caption: String? = nil,
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isPublic: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        likeCount: Int = 0,
        commentCount: Int = 0,
        user: UserProfile? = nil,
        isLikedByMe: Bool = false,
        isSavedByMe: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.mediaUrl = mediaUrl
        self.mediaType = mediaType
        self.thumbnailUrl = thumbnailUrl
        self.mediaWidth = mediaWidth
        self.mediaHeight = mediaHeight
        self.caption = caption
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.user = user
        self.isLikedByMe = isLikedByMe
        self.isSavedByMe = isSavedByMe
    }
    
    // MARK: - Custom Decodable Implementation
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        mediaUrl = try container.decode(String.self, forKey: .mediaUrl)
        mediaType = try container.decode(MediaType.self, forKey: .mediaType)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        mediaWidth = try container.decodeIfPresent(Double.self, forKey: .mediaWidth)
        mediaHeight = try container.decodeIfPresent(Double.self, forKey: .mediaHeight)
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        
        // Handle date parsing - Supabase returns ISO 8601 string
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: createdAtString) {
            createdAt = date
        } else {
            // Fallback without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: createdAtString) {
                createdAt = date
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .createdAt,
                    in: container,
                    debugDescription: "Cannot parse date string: \(createdAtString)"
                )
            }
        }
        
        // Handle optional updated_at parsing
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: updatedAtString) {
                updatedAt = date
            } else {
                // Fallback without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                updatedAt = formatter.date(from: updatedAtString)
            }
        } else {
            updatedAt = nil
        }
    }
    
    // MARK: - Hashable Implementation
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Aspect Ratio Utilities
    
    /// アスペクト比を計算（幅/高さ）
    var aspectRatio: Double? {
        guard let width = mediaWidth, let height = mediaHeight, height > 0 else {
            return nil
        }
        return width / height
    }
    
    /// 横長写真として表示すべきかを判定
    var shouldDisplayAsLandscape: Bool {
        guard let ratio = aspectRatio else {
            // アスペクト比が不明な場合は正方形表示
            return false
        }
        
        // アスペクト比が1.3以上（横:縦 = 1.3:1以上）を横長とする
        // 例: 1600x1200 = 1.33, 1920x1080 = 1.78
        let isLandscape = ratio >= 1.3
        return isLandscape
    }
    
    /// グリッド表示タイプを判定
    enum GridDisplayType {
        case landscape  // 横長表示
        case square     // 正方形表示
    }
    
    /// グリッド表示タイプを取得
    var gridDisplayType: GridDisplayType {
        return shouldDisplayAsLandscape ? .landscape : .square
    }
    
    // MARK: - Transferable Implementation
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

