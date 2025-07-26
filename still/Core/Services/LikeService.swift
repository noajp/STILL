//======================================================================
// MARK: - LikeService.swift
// Purpose: Like/unlike service managing post interactions, optimistic updates, and database synchronization (投稿インタラクション、楽観的更新、データベース同期を管理するいいね/いいね解除サービス)
// Path: still/Core/Services/LikeService.swift
//======================================================================
import Foundation
import Supabase

class LikeService: ObservableObject, @unchecked Sendable {
    private let client = SupabaseManager.shared.client
    
    // MARK: - Like Operations
    
    func toggleLike(postId: String, userId: String) async throws -> Bool {
        // Check if already liked
        let isLiked = try await checkIfLiked(postId: postId, userId: userId)
        
        if isLiked {
            try await unlikePost(postId: postId, userId: userId)
            return false
        } else {
            try await likePost(postId: postId, userId: userId)
            return true
        }
    }
    
    func likePost(postId: String, userId: String) async throws {
        // Insert like record
        let like = Like(
            id: UUID().uuidString,
            userId: userId,
            postId: postId,
            createdAt: Date()
        )
        
        try await client
            .from("likes")
            .insert(like)
            .execute()
        
        // Update post like count
        try await incrementLikeCount(postId: postId)
        
        // Create like notification
        await createLikeNotification(fromUserId: userId, postId: postId)
        
        print("✅ LikeService: Successfully liked post \(postId)")
    }
    
    private func createLikeNotification(fromUserId: String, postId: String) async {
        do {
            // Get post details to find the post owner
            let posts: [Post] = try await client
                .from("posts")
                .select("user_id")
                .eq("id", value: postId)
                .execute()
                .value
            
            guard let post = posts.first, post.userId != fromUserId else {
                // Don't create notification for own posts
                return
            }
            
            // Get sender's profile
            let senderProfile = try await UserRepository.shared.fetchUserProfile(userId: fromUserId)
            
            // Create notification using NotificationService
            await NotificationService.shared.createLikeNotification(
                fromUserId: fromUserId,
                toUserId: post.userId,
                postId: postId,
                senderProfile: senderProfile
            )
            
            print("✅ Like notification created for post \(postId)")
        } catch {
            print("❌ Failed to create like notification: \(error)")
        }
    }
    
    func unlikePost(postId: String, userId: String) async throws {
        // Delete like record
        try await client
            .from("likes")
            .delete()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()
        
        // Update post like count
        try await decrementLikeCount(postId: postId)
        
        print("✅ LikeService: Successfully unliked post \(postId)")
    }
    
    // MARK: - Helper Methods
    
    private func checkIfLiked(postId: String, userId: String) async throws -> Bool {
        let response: [Like] = try await client
            .from("likes")
            .select()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return !response.isEmpty
    }
    
    private func incrementLikeCount(postId: String) async throws {
        try await client
            .rpc("increment_like_count", params: ["post_id": postId])
            .execute()
    }
    
    private func decrementLikeCount(postId: String) async throws {
        try await client
            .rpc("decrement_like_count", params: ["post_id": postId])
            .execute()
    }
    
    // MARK: - Fetch Methods
    
    func getLikes(for postId: String) async throws -> [Like] {
        let response: [Like] = try await client
            .from("likes")
            .select("""
                *,
                user:users(id, username, display_name, avatar_url)
            """)
            .eq("post_id", value: postId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func getLikeCount(for postId: String) async throws -> Int {
        let response: [Post] = try await client
            .from("posts")
            .select("like_count")
            .eq("id", value: postId)
            .execute()
            .value
        
        return response.first?.likeCount ?? 0
    }
    
    func checkUserLikeStatus(postId: String, userId: String) async throws -> Bool {
        return try await checkIfLiked(postId: postId, userId: userId)
    }
}