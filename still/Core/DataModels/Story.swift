//======================================================================
// MARK: - Story.swift
// Purpose: Data model for Stories feature - temporary posts that expire after 24 hours
// Path: still/Core/DataModels/Story.swift
//======================================================================

import Foundation

/**
 * Story represents a temporary post that expires after 24 hours.
 * Similar to Instagram/Snapchat stories.
 */
struct Story: Identifiable, Codable {
    // MARK: - Core Properties
    
    /// Unique identifier
    let id: String
    
    /// User who created the story
    let userId: String
    
    /// URL of the story image/video
    let mediaUrl: String
    
    /// Type of media (image or video)
    let mediaType: MediaType
    
    /// Optional caption
    var caption: String?
    
    /// Creation timestamp
    let createdAt: Date
    
    /// Expiration timestamp (24 hours from creation)
    let expiresAt: Date
    
    /// Number of views
    var viewCount: Int = 0
    
    /// List of user IDs who viewed the story
    var viewerIds: [String] = []
    
    // MARK: - Relationships
    
    /// User profile (populated when fetched)
    var user: UserProfile?
    
    // MARK: - Computed Properties
    
    /// Check if story is still active (not expired)
    var isActive: Bool {
        Date() < expiresAt
    }
    
    /// Time remaining until expiration
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }
    
    /// Formatted time remaining string
    var timeRemainingText: String {
        let hours = Int(timeRemaining / 3600)
        let minutes = Int((timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Just now"
        }
    }
    
    // MARK: - Media Type
    
    enum MediaType: String, Codable {
        case image = "image"
        case video = "video"
    }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case caption
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case viewCount = "view_count"
        case viewerIds = "viewer_ids"
        case user
    }
}

/**
 * StoryGroup represents a collection of stories from a single user
 */
struct StoryGroup: Identifiable {
    /// User ID (used as group ID)
    var id: String { user.id }
    
    /// User who owns these stories
    let user: UserProfile
    
    /// List of active stories from this user
    let stories: [Story]
    
    /// Whether the current user has viewed all stories in this group
    var hasUnviewedStories: Bool
    
    /// Most recent story timestamp
    var latestStoryTime: Date? {
        stories.map { $0.createdAt }.max()
    }
}