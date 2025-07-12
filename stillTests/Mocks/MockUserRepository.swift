//======================================================================
// MARK: - MockUserRepository
// Purpose: Mock implementation for testing UserRepository
//======================================================================
import Foundation
@testable import tete

/// Mock implementation of UserRepositoryProtocol for testing
final class MockUserRepository: UserRepositoryProtocol {
    
    // MARK: - Mock Data
    var userProfiles: [String: UserProfile] = [:]
    var userPosts: [String: [Post]] = [:]
    var followerCounts: [String: Int] = [:]
    var followingCounts: [String: Int] = [:]
    
    // MARK: - Call Tracking
    var fetchUserProfileCalls: [(userId: String)] = []
    var fetchUserPostsCalls: [(userId: String)] = []
    var updateUserProfileCalls: [UserProfile] = []
    var updateProfilePhotoCalls: [(userId: String, imageData: Data)] = []
    var fetchFollowersCountCalls: [(userId: String)] = []
    var fetchFollowingCountCalls: [(userId: String)] = []
    
    // MARK: - Error Simulation
    var shouldThrowError = false
    var errorToThrow: Error = ViewModelError.network("Mock error")
    
    // MARK: - UserRepositoryProtocol Implementation
    
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        fetchUserProfileCalls.append((userId: userId))
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let profile = userProfiles[userId] else {
            throw ViewModelError.notFound("User profile")
        }
        
        return profile
    }
    
    func fetchUserPosts(userId: String) async throws -> [Post] {
        fetchUserPostsCalls.append((userId: userId))
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return userPosts[userId] ?? []
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        updateUserProfileCalls.append(profile)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        userProfiles[profile.id] = profile
    }
    
    func updateProfilePhoto(userId: String, imageData: Data) async throws -> String {
        updateProfilePhotoCalls.append((userId: userId, imageData: imageData))
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        let newUrl = "https://example.com/avatar/\(userId).jpg"
        
        // Update the user profile if it exists
        if var profile = userProfiles[userId] {
            profile.avatarUrl = newUrl
            userProfiles[userId] = profile
        }
        
        return newUrl
    }
    
    func fetchFollowersCount(userId: String) async throws -> Int {
        fetchFollowersCountCalls.append((userId: userId))
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return followerCounts[userId] ?? 0
    }
    
    func fetchFollowingCount(userId: String) async throws -> Int {
        fetchFollowingCountCalls.append((userId: userId))
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return followingCounts[userId] ?? 0
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        userProfiles.removeAll()
        userPosts.removeAll()
        followerCounts.removeAll()
        followingCounts.removeAll()
        
        fetchUserProfileCalls.removeAll()
        fetchUserPostsCalls.removeAll()
        updateUserProfileCalls.removeAll()
        updateProfilePhotoCalls.removeAll()
        fetchFollowersCountCalls.removeAll()
        fetchFollowingCountCalls.removeAll()
        
        shouldThrowError = false
        errorToThrow = ViewModelError.network("Mock error")
    }
    
    func setupUser(
        _ profile: UserProfile,
        posts: [Post] = [],
        followersCount: Int = 0,
        followingCount: Int = 0
    ) {
        userProfiles[profile.id] = profile
        userPosts[profile.id] = posts
        followerCounts[profile.id] = followersCount
        followingCounts[profile.id] = followingCount
    }
}