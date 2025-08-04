//======================================================================
// MARK: - CommentService.swift
// Purpose: Service for managing comment operations (CRUD, relationships)
// Path: still/Core/Services/CommentService.swift
//======================================================================

import Foundation
import Supabase
import Auth

/**
 * CommentService handles all comment-related operations.
 * 
 * This service provides functionality for creating, reading, updating, and deleting comments,
 * as well as managing comment relationships with posts and users.
 */
@MainActor
class CommentService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = CommentService()
    
    // MARK: - Properties
    
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Comment CRUD Operations
    
    /**
     * Fetches comments for a specific post
     * - Parameter postId: The ID of the post to fetch comments for
     * - Returns: Array of comments with user information
     */
    func fetchComments(for postId: String) async throws -> [Comment] {
        print("🔄 CommentService: Fetching comments for post: \(postId)")
        
        let query = supabase
            .from("comments")
            .select("""
                id,
                post_id,
                user_id,
                content,
                created_at,
                user:profiles!comments_user_id_fkey(*)
            """)
            .eq("post_id", value: postId)
            .order("created_at", ascending: true) // Oldest first for chronological order
        
        let response: [Comment] = try await query.execute().value
        
        print("✅ CommentService: Fetched \(response.count) comments")
        return response
    }
    
    /**
     * Creates a new comment on a post
     * - Parameters:
     *   - postId: The ID of the post to comment on
     *   - content: The comment content
     * - Returns: The created comment with user information
     */
    func createComment(postId: String, content: String) async throws -> Comment {
        print("🔄 CommentService: Creating comment for post: \(postId)")
        
        // Validate content
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty && trimmedContent.count <= 1000 else {
            throw CommentError.invalidContent
        }
        
        // Get current user
        let session = try await supabase.auth.session
        let currentUser = session.user
        
        print("🔄 CommentService: Current user ID: \(currentUser.id.uuidString)")
        print("🔄 CommentService: Post ID: \(postId)")
        print("🔄 CommentService: Content: \(trimmedContent)")
        
        // Create minimal comment data structure
        struct MinimalCommentRequest: Codable {
            let post_id: String
            let user_id: String
            let content: String
        }
        
        let commentData = MinimalCommentRequest(
            post_id: postId,
            user_id: currentUser.id.uuidString,
            content: trimmedContent
        )
        
        print("🔄 CommentService: Inserting comment data: \(commentData)")
        
        // Insert comment
        let insertResponse: [Comment] = try await supabase
            .from("comments")
            .insert(commentData)
            .select("""
                id,
                post_id,
                user_id,
                content,
                created_at,
                user:profiles!comments_user_id_fkey(*)
            """)
            .execute()
            .value
        
        guard let newComment = insertResponse.first else {
            throw CommentError.creationFailed
        }
        
        print("✅ CommentService: Created comment with ID: \(newComment.id)")
        
        // Create notification for post owner (if not commenting on own post)
        Task {
            await createCommentNotification(for: newComment, postId: postId, currentUser: currentUser)
        }
        
        return newComment
    }
    
    /**
     * Updates an existing comment
     * - Parameters:
     *   - commentId: The ID of the comment to update
     *   - content: The new comment content
     * - Returns: The updated comment
     */
    func updateComment(commentId: String, content: String) async throws -> Comment {
        print("🔄 CommentService: Updating comment: \(commentId)")
        
        // Validate content
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty && trimmedContent.count <= 1000 else {
            throw CommentError.invalidContent
        }
        
        // Get current user
        let session = try await supabase.auth.session
        let currentUser = session.user
        
        // Update comment request
        let updateRequest = UpdateCommentRequest(content: trimmedContent)
        
        // Update comment (RLS ensures user can only update their own comments)
        let updateResponse: [Comment] = try await supabase
            .from("comments")
            .update(updateRequest)
            .eq("id", value: commentId)
            .eq("user_id", value: currentUser.id.uuidString)
            .select("""
                id,
                post_id,
                user_id,
                content,
                created_at,
                user:profiles!comments_user_id_fkey(*)
            """)
            .execute()
            .value
        
        guard let updatedComment = updateResponse.first else {
            throw CommentError.updateFailed
        }
        
        print("✅ CommentService: Updated comment: \(commentId)")
        return updatedComment
    }
    
    /**
     * Deletes a comment
     * - Parameter commentId: The ID of the comment to delete
     */
    func deleteComment(commentId: String) async throws {
        print("🔄 CommentService: Deleting comment: \(commentId)")
        
        // Get current user
        let session = try await supabase.auth.session
        let currentUser = session.user
        
        // Delete comment (RLS ensures user can only delete their own comments)
        try await supabase
            .from("comments")
            .delete()
            .eq("id", value: commentId)
            .eq("user_id", value: currentUser.id.uuidString)
            .execute()
        
        print("✅ CommentService: Deleted comment: \(commentId)")
    }
    
    /**
     * Gets the comment count for a specific post
     * - Parameter postId: The ID of the post
     * - Returns: The number of comments on the post
     */
    func getCommentCount(for postId: String) async throws -> Int {
        let response = try await supabase
            .from("comments")
            .select("id", count: .exact)
            .eq("post_id", value: postId)
            .execute()
        
        return response.count ?? 0
    }
    
    // MARK: - Helper Methods
    
    /**
     * Creates a notification for comment on post
     * - Parameters:
     *   - comment: The comment that was created
     *   - postId: The ID of the post that was commented on
     *   - currentUser: The user who created the comment
     */
    private func createCommentNotification(for comment: Comment, postId: String, currentUser: User) async {
        do {
            // Get post owner information
            let postResponse: [Post] = try await supabase
                .from("posts")
                .select("user_id")
                .eq("id", value: postId)
                .execute()
                .value
            
            guard let post = postResponse.first,
                  post.userId != comment.userId else {
                // Don't notify if user is commenting on their own post
                return
            }
            
            // Get current user's profile for notification
            let profileResponse: [UserProfile] = try await supabase
                .from("profiles")
                .select("*")
                .eq("id", value: currentUser.id.uuidString)
                .execute()
                .value
            
            guard let userProfile = profileResponse.first else {
                print("❌ CommentService: Could not find user profile for notification")
                return
            }
            
            // Create notification using NotificationService
            await NotificationService.shared.createCommentNotification(
                fromUserId: currentUser.id.uuidString,
                toUserId: post.userId,
                postId: postId,
                senderProfile: userProfile
            )
            
            print("✅ CommentService: Created comment notification")
            
        } catch {
            print("❌ CommentService: Failed to create comment notification: \(error)")
        }
    }
}

// MARK: - Comment Errors

enum CommentError: LocalizedError {
    case userNotAuthenticated
    case invalidContent
    case creationFailed
    case updateFailed
    case deletionFailed
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .invalidContent:
            return "Comment content is invalid"
        case .creationFailed:
            return "Failed to create comment"
        case .updateFailed:
            return "Failed to update comment"
        case .deletionFailed:
            return "Failed to delete comment"
        case .notFound:
            return "Comment not found"
        }
    }
}