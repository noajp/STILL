//======================================================================
// MARK: - Notification.swift
// Purpose: Notification data model for app notifications (アプリ通知のための通知データモデル)
// Path: still/Core/DataModels/Notification.swift
//======================================================================

import Foundation

/// Data model representing an in-app notification
/// Supports various notification types with related user and post references
struct AppNotification: Identifiable, Codable {
    /// Unique identifier for the notification
    let id: String
    
    /// ID of the user who will receive this notification
    let userId: String
    
    /// Type of notification (like, follow, comment, etc.)
    let type: NotificationType
    
    /// Title text displayed in the notification
    let title: String
    
    /// Main message content of the notification
    let message: String
    
    /// Whether the user has read this notification
    var isRead: Bool
    
    /// ID of the user who triggered this notification (optional)
    let relatedUserId: String?
    
    /// ID of the post related to this notification (optional)
    let relatedPostId: String?
    
    /// Additional metadata for the notification (optional)
    let metadata: NotificationMetadata?
    
    /// CodingKeys to map between Swift property names and database column names
    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case message
        case isRead = "is_read"
        case relatedUserId = "related_user_id"
        case relatedPostId = "related_post_id"
        case metadata
    }
    
    /// Enum defining different types of notifications supported by the app
    enum NotificationType: String, Codable, CaseIterable {
        /// Someone liked a post
        case like = "like"
        /// Someone followed the user
        case follow = "follow"
        /// Someone sent a follow request (for private accounts)
        case followRequest = "follow_request"
        /// A follow request was approved
        case followRequestApproved = "follow_request_approved"
        /// Someone commented on a post
        case comment = "comment"
        /// Someone sent a direct message
        case message = "message"
        
        /// SF Symbol icon name for each notification type
        var icon: String {
            switch self {
            case .like: return "heart.fill"
            case .follow: return "person.badge.plus"
            case .followRequest: return "person.crop.circle.badge.clock"
            case .followRequestApproved: return "checkmark.circle.fill"
            case .comment: return "message"
            case .message: return "bubble.left"
            }
        }
        
        /// Color name for each notification type for UI theming
        var color: String {
            switch self {
            case .like: return "red"
            case .follow: return "blue"
            case .followRequest: return "orange"
            case .followRequestApproved: return "green"
            case .comment: return "green"
            case .message: return "blue"
            }
        }
    }
    
    /// Additional metadata for notifications containing related user and post information
    struct NotificationMetadata: Codable {
        /// URL of the post image if notification is related to a post
        let postImageUrl: String?
        
        /// Avatar URL of the user who triggered the notification
        let senderAvatarUrl: String?
        
        /// Display name of the user who triggered the notification
        let senderDisplayName: String?
        
        /// Username of the user who triggered the notification
        let senderUsername: String?
    }
}

// MARK: - Display Helpers

/// Extension providing computed properties for consistent notification display
extension AppNotification {
    /// Formatted title for display in notification UI
    var displayTitle: String {
        return title
    }
    
    /// Formatted message for display in notification UI
    var displayMessage: String {
        return message
    }
}