//======================================================================
// MARK: - Comment.swift
// Purpose: Comment data model for post comments with user relationships
// Path: still/Core/DataModels/Comment.swift
//======================================================================

import Foundation

/**
 * Comment model representing user comments on posts.
 * 
 * This model handles comment data with proper relationships to users and posts,
 * including support for nested comments and moderation features.
 */
struct Comment: Identifiable, Codable, Equatable, Hashable {
    /// Unique identifier for the comment
    let id: String
    
    /// ID of the post this comment belongs to
    let postId: String
    
    /// ID of the user who created this comment
    let userId: String
    
    /// The comment content/text
    let content: String
    
    /// Timestamp when the comment was created
    let createdAt: Date
    
    /// Timestamp when the comment was last updated
    let updatedAt: Date?
    
    /// User profile information (loaded via relationship)
    var user: UserProfile?
    
    /// Post information (loaded via relationship)
    var post: Post?
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
        case post
    }
    
    // MARK: - Computed Properties
    
    /// Formatted relative time string for display
    var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale.current
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    /// Whether this comment was edited (updated after creation)
    var isEdited: Bool {
        guard let updatedAt = updatedAt else { return false }
        let timeDifference = updatedAt.timeIntervalSince(createdAt)
        return timeDifference > 5.0 // Consider edited if updated more than 5 seconds after creation
    }
    
    /// Display name for the comment author
    var authorDisplayName: String {
        return user?.displayName ?? user?.username ?? "Unknown User"
    }
    
    /// Username for the comment author
    var authorUsername: String {
        return user?.username ?? "unknown"
    }
    
    /// Avatar URL for the comment author
    var authorAvatarUrl: String? {
        return user?.avatarUrl
    }
    
    // MARK: - Hashable & Equatable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Comment Extensions

extension Comment {
    
    /// Creates a preview comment for testing/preview purposes
    static var preview: Comment {
        Comment(
            id: UUID().uuidString,
            postId: UUID().uuidString,
            userId: UUID().uuidString,
            content: "This is a sample comment for preview purposes. It shows how comments will look in the UI.",
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            updatedAt: nil,
            user: nil
        )
    }
    
    /// Creates multiple preview comments
    static var previews: [Comment] {
        return [
            Comment(
                id: "1",
                postId: "post1",
                userId: "user1",
                content: "Great photo! 📸",
                createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
                updatedAt: nil,
                user: UserProfile(
                    id: "user1",
                    username: "photographer",
                    displayName: "John Photographer",
                    avatarUrl: nil,
                    bio: "Love taking photos",
                    followersCount: nil,
                    followingCount: nil,
                    isPrivate: nil,
                    createdAt: nil
                )
            ),
            Comment(
                id: "2",
                postId: "post1",
                userId: "user2",
                content: "Amazing composition and lighting! What camera did you use for this shot?",
                createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
                updatedAt: nil,
                user: UserProfile(
                    id: "user2",
                    username: "artlover",
                    displayName: "Sarah Chen",
                    avatarUrl: nil,
                    bio: "Art enthusiast",
                    followersCount: nil,
                    followingCount: nil,
                    isPrivate: nil,
                    createdAt: nil
                )
            ),
            Comment(
                id: "3",
                postId: "post1",
                userId: "user3",
                content: "❤️",
                createdAt: Date().addingTimeInterval(-1800), // 30 minutes ago
                updatedAt: nil,
                user: UserProfile(
                    id: "user3",
                    username: "minimalist",
                    displayName: "Alex",
                    avatarUrl: nil,
                    bio: "Less is more",
                    followersCount: nil,
                    followingCount: nil,
                    isPrivate: nil,
                    createdAt: nil
                )
            )
        ]
    }
}

// MARK: - Comment Request/Response Models

/// Model for creating new comments
struct CreateCommentRequest: Codable {
    let postId: String
    let userId: String
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
        case content
    }
    
    /// Validates the comment content
    var isValid: Bool {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedContent.isEmpty && trimmedContent.count <= 1000
    }
}

/// Model for updating existing comments
struct UpdateCommentRequest: Codable {
    let content: String
    
    /// Validates the comment content
    var isValid: Bool {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedContent.isEmpty && trimmedContent.count <= 1000
    }
}