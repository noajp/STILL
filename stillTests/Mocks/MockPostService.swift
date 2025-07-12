//======================================================================
// MARK: - MockPostService
// Purpose: Mock implementation for testing PostService functionality
//======================================================================
import Foundation
@testable import tete

/// Mock implementation of PostServiceProtocol for testing
final class MockPostService: PostServiceProtocol {
    
    // MARK: - Mock Data
    var feedPosts: [Post] = []
    var userPosts: [String: [Post]] = [:]
    var likedPosts: Set<String> = []
    var likes: [String: [Like]] = [:]
    
    // MARK: - Call Tracking
    var fetchFeedPostsCalls: [(currentUserId: String?)] = []
    var fetchUserPostsCalls: [(userId: String)] = []
    var toggleLikeCalls: [(postId: String, userId: String)] = []
    var getLikesCalls: [(postId: String)] = []
    var getLikeCountCalls: [(postId: String)] = []
    
    // MARK: - Error Simulation
    var shouldThrowError = false
    var errorToThrow: Error = ViewModelError.network("Mock error")
    
    // MARK: - PostServiceProtocol Implementation
    
    func fetchFeedPosts(currentUserId: String? = nil) async throws -> [Post] {
        fetchFeedPostsCalls.append((currentUserId: currentUserId))
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        var posts = feedPosts
        
        // Update like status for current user
        if let userId = currentUserId {
            for i in 0..<posts.count {
                posts[i].isLikedByMe = likedPosts.contains(posts[i].id)
            }
        }
        
        return posts
    }
    
    func fetchUserPosts(userId: String) async throws -> [Post] {
        fetchUserPostsCalls.append((userId: userId))
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        return userPosts[userId] ?? []
    }
    
    func toggleLike(postId: String, userId: String) async throws -> Bool {
        toggleLikeCalls.append((postId: postId, userId: userId))
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        let likeKey = "\(postId)-\(userId)"
        let isCurrentlyLiked = likedPosts.contains(likeKey)
        
        if isCurrentlyLiked {
            likedPosts.remove(likeKey)
            
            // Update like count in posts
            updatePostLikeCount(postId: postId, increment: false)
            
            // Remove from likes array
            if var postLikes = likes[postId] {
                postLikes.removeAll { $0.userId == userId }
                likes[postId] = postLikes
            }
            
            return false
        } else {
            likedPosts.insert(likeKey)
            
            // Update like count in posts
            updatePostLikeCount(postId: postId, increment: true)
            
            // Add to likes array
            let like = Like(
                id: UUID().uuidString,
                userId: userId,
                postId: postId,
                createdAt: Date()
            )
            
            if likes[postId] == nil {
                likes[postId] = []
            }
            likes[postId]?.append(like)
            
            return true
        }
    }
    
    func getLikes(for postId: String) async throws -> [Like] {
        getLikesCalls.append((postId: postId))
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return likes[postId] ?? []
    }
    
    func getLikeCount(for postId: String) async throws -> Int {
        getLikeCountCalls.append((postId: postId))
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return likes[postId]?.count ?? 0
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        feedPosts.removeAll()
        userPosts.removeAll()
        likedPosts.removeAll()
        likes.removeAll()
        
        fetchFeedPostsCalls.removeAll()
        fetchUserPostsCalls.removeAll()
        toggleLikeCalls.removeAll()
        getLikesCalls.removeAll()
        getLikeCountCalls.removeAll()
        
        shouldThrowError = false
        errorToThrow = ViewModelError.network("Mock error")
    }
    
    func setupFeedPosts(_ posts: [Post]) {
        feedPosts = posts
    }
    
    func setupUserPosts(userId: String, posts: [Post]) {
        userPosts[userId] = posts
    }
    
    func setupLikedPosts(userId: String, postIds: [String]) {
        for postId in postIds {
            let likeKey = "\(postId)-\(userId)"
            likedPosts.insert(likeKey)
        }
    }
    
    private func updatePostLikeCount(postId: String, increment: Bool) {
        // Update in feed posts
        if let index = feedPosts.firstIndex(where: { $0.id == postId }) {
            if increment {
                feedPosts[index].likeCount += 1
            } else {
                feedPosts[index].likeCount = max(0, feedPosts[index].likeCount - 1)
            }
        }
        
        // Update in user posts
        for (userId, posts) in userPosts {
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                if increment {
                    userPosts[userId]![index].likeCount += 1
                } else {
                    userPosts[userId]![index].likeCount = max(0, userPosts[userId]![index].likeCount - 1)
                }
            }
        }
    }
}