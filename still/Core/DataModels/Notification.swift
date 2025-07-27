//======================================================================
// MARK: - Notification.swift
// Purpose: Notification data model for app notifications (アプリ通知のための通知データモデル)
// Path: still/Core/DataModels/Notification.swift
//======================================================================

import Foundation

struct AppNotification: Identifiable, Codable {
    let id: String
    let userId: String
    let type: NotificationType
    let title: String
    let message: String
    let isRead: Bool
    let relatedUserId: String?
    let relatedPostId: String?
    let metadata: NotificationMetadata?
    
    // CodingKeys to map between Swift property names and database column names
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
    
    enum NotificationType: String, Codable, CaseIterable {
        case like = "like"
        case follow = "follow"
        case followRequest = "follow_request"
        case comment = "comment"
        case message = "message"
        
        var icon: String {
            switch self {
            case .like: return "heart.fill"
            case .follow: return "person.badge.plus"
            case .followRequest: return "person.crop.circle.badge.clock"
            case .comment: return "message"
            case .message: return "bubble.left"
            }
        }
        
        var color: String {
            switch self {
            case .like: return "red"
            case .follow: return "blue"
            case .followRequest: return "orange"
            case .comment: return "green"
            case .message: return "blue"
            }
        }
    }
    
    struct NotificationMetadata: Codable {
        let postImageUrl: String?
        let senderAvatarUrl: String?
        let senderDisplayName: String?
        let senderUsername: String?
    }
}

extension AppNotification {
    var displayTitle: String {
        return title
    }
    
    var displayMessage: String {
        return message
    }
}