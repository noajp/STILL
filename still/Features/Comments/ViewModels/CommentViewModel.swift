//======================================================================
// MARK: - CommentViewModel.swift
// Purpose: ViewModel for managing comment operations and state
// Path: still/Features/Comments/ViewModels/CommentViewModel.swift
//======================================================================

import Foundation
import SwiftUI

/**
 * CommentViewModel manages the state and operations for comment functionality.
 * 
 * This ViewModel handles loading, creating, updating, and deleting comments
 * for a specific post, with proper error handling and optimistic updates.
 */
@MainActor
class CommentViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var hasError = false
    @Published var errorMessage = ""
    
    // MARK: - Properties
    
    private let postId: String
    private let commentService = CommentService.shared
    
    // MARK: - Initialization
    
    init(postId: String) {
        self.postId = postId
    }
    
    // MARK: - Comment Operations
    
    /**
     * Loads comments for the current post
     */
    func loadComments() async {
        isLoading = true
        hasError = false
        
        do {
            let fetchedComments = try await commentService.fetchComments(for: postId)
            comments = fetchedComments
            print("✅ CommentViewModel: Loaded \(fetchedComments.count) comments")
        } catch {
            print("❌ CommentViewModel: Failed to load comments: \(error)")
            hasError = true
            errorMessage = "Failed to load comments"
        }
        
        isLoading = false
    }
    
    /**
     * Creates a new comment
     * - Parameter content: The comment content
     */
    func createComment(content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isSubmitting = true
        hasError = false
        
        do {
            let newComment = try await commentService.createComment(postId: postId, content: content)
            
            // Add comment to local array
            comments.append(newComment)
            
            print("✅ CommentViewModel: Created comment: \(newComment.id)")
            
            // Post notification for comment creation
            NotificationCenter.default.post(
                name: NSNotification.Name("CommentCreated"),
                object: nil,
                userInfo: ["postId": postId, "comment": newComment]
            )
            
        } catch {
            print("❌ CommentViewModel: Failed to create comment: \(error)")
            hasError = true
            errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
    
    /**
     * Updates an existing comment
     * - Parameters:
     *   - commentId: The ID of the comment to update
     *   - content: The new comment content
     */
    func updateComment(_ commentId: String, content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Find comment index for optimistic update
        guard let commentIndex = comments.firstIndex(where: { $0.id == commentId }) else {
            return
        }
        
        // Store original comment for rollback
        let originalComment = comments[commentIndex]
        
        // Optimistic update
        let updatedComment = Comment(
            id: originalComment.id,
            postId: originalComment.postId,
            userId: originalComment.userId,
            content: content,
            createdAt: originalComment.createdAt,
            updatedAt: nil,
            user: originalComment.user,
            post: originalComment.post
        )
        
        comments[commentIndex] = updatedComment
        
        do {
            let serverUpdatedComment = try await commentService.updateComment(commentId: commentId, content: content)
            
            // Update with server response
            comments[commentIndex] = serverUpdatedComment
            
            print("✅ CommentViewModel: Updated comment: \(commentId)")
            
        } catch {
            // Rollback on error
            comments[commentIndex] = originalComment
            
            print("❌ CommentViewModel: Failed to update comment: \(error)")
            hasError = true
            errorMessage = error.localizedDescription
        }
    }
    
    /**
     * Deletes a comment
     * - Parameter commentId: The ID of the comment to delete
     */
    func deleteComment(_ commentId: String) async {
        // Find comment index for optimistic update
        guard let commentIndex = comments.firstIndex(where: { $0.id == commentId }) else {
            return
        }
        
        // Store comment for rollback
        let deletedComment = comments[commentIndex]
        
        // Optimistic removal
        comments.remove(at: commentIndex)
        
        do {
            try await commentService.deleteComment(commentId: commentId)
            
            print("✅ CommentViewModel: Deleted comment: \(commentId)")
            
            // Post notification for comment deletion
            NotificationCenter.default.post(
                name: NSNotification.Name("CommentDeleted"),
                object: nil,
                userInfo: ["postId": postId, "commentId": commentId]
            )
            
        } catch {
            // Rollback on error
            comments.insert(deletedComment, at: commentIndex)
            
            print("❌ CommentViewModel: Failed to delete comment: \(error)")
            hasError = true
            errorMessage = error.localizedDescription
        }
    }
    
    /**
     * Refreshes comments (useful for pull-to-refresh)
     */
    func refreshComments() async {
        await loadComments()
    }
    
    // MARK: - Helper Methods
    
    /**
     * Clears error state
     */
    func clearError() {
        hasError = false
        errorMessage = ""
    }
    
    /**
     * Gets comment count
     */
    var commentCount: Int {
        return comments.count
    }
}