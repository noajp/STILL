//======================================================================
// MARK: - PostServiceProtocol
// Purpose: Protocol for post-related operations to enable dependency injection
//======================================================================
import Foundation

/// Protocol defining post service operations
protocol PostServiceProtocol: Sendable {
    func fetchFeedPosts(currentUserId: String?) async throws -> [Post]
    func fetchUserPosts(userId: String) async throws -> [Post]
    func toggleLike(postId: String, userId: String) async throws -> Bool
    func getLikes(for postId: String) async throws -> [Like]
    func getLikeCount(for postId: String) async throws -> Int
}

/// Implementation wrapper for existing PostService
extension PostService: PostServiceProtocol {}