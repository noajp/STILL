//======================================================================
// MARK: - UserRepositoryIntegrationTests
// Purpose: Integration tests for UserRepository with Supabase
//======================================================================
import XCTest
@testable import tete

/// Integration tests for UserRepository
/// These tests use mock Supabase client to test repository integration
final class UserRepositoryIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    private var repository: UserRepository!
    private var mockSupabaseClient: MockSupabaseClient!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockSupabaseClient = MockSupabaseClient()
        repository = UserRepository(supabaseClient: mockSupabaseClient)
    }
    
    override func tearDown() {
        repository = nil
        mockSupabaseClient = nil
        super.tearDown()
    }
    
    // MARK: - Fetch User Profile Tests
    
    func testFetchUserProfileSuccess() async throws {
        // Given
        let expectedProfile = TestUtilities.createTestUserProfile(id: "user-123")
        mockSupabaseClient.setupUserProfile(expectedProfile)
        
        // When
        let profile = try await repository.fetchUserProfile(userId: "user-123")
        
        // Then
        XCTAssertEqual(profile.id, expectedProfile.id)
        XCTAssertEqual(profile.username, expectedProfile.username)
        XCTAssertEqual(profile.displayName, expectedProfile.displayName)
        XCTAssertEqual(profile.bio, expectedProfile.bio)
        
        // Verify Supabase call
        XCTAssertEqual(mockSupabaseClient.selectCalls.count, 1)
        XCTAssertEqual(mockSupabaseClient.selectCalls.first?.table, "user_profiles")
        XCTAssertEqual(mockSupabaseClient.selectCalls.first?.query, "*")
    }
    
    func testFetchUserProfileNotFound() async {
        // Given
        mockSupabaseClient.shouldThrowError = true
        mockSupabaseClient.errorToThrow = NSError(domain: "Supabase", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
        
        // When/Then
        do {
            let _ = try await repository.fetchUserProfile(userId: "nonexistent-user")
            XCTFail("Expected error to be thrown")
        } catch let error as ViewModelError {
            XCTAssertEqual(error.userFriendlyMessage, "Unable to connect. Please check your internet connection.")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchUserProfileNetworkError() async {
        // Given
        mockSupabaseClient.shouldThrowError = true
        mockSupabaseClient.errorToThrow = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        
        // When/Then
        do {
            let _ = try await repository.fetchUserProfile(userId: "user-123")
            XCTFail("Expected error to be thrown")
        } catch let error as ViewModelError {
            XCTAssertEqual(error.userFriendlyMessage, "Unable to connect. Please check your internet connection.")
        }
    }
    
    // MARK: - Fetch User Posts Tests
    
    func testFetchUserPostsSuccess() async throws {
        // Given
        let userProfile = TestUtilities.createTestUserProfile(id: "user-123")
        let expectedPosts = TestUtilities.createTestPosts(count: 3)
        
        mockSupabaseClient.setupUserProfile(userProfile)
        mockSupabaseClient.setupUserPosts("user-123", posts: expectedPosts)
        
        // When
        let posts = try await repository.fetchUserPosts(userId: "user-123")
        
        // Then
        XCTAssertEqual(posts.count, 3)
        
        // Verify each post has user profile attached
        for post in posts {
            XCTAssertNotNil(post.user)
            XCTAssertEqual(post.user?.id, userProfile.id)
            XCTAssertEqual(post.user?.username, userProfile.username)
        }
        
        // Verify Supabase calls
        XCTAssertGreaterThanOrEqual(mockSupabaseClient.selectCalls.count, 2) // Posts + User profile
    }
    
    func testFetchUserPostsEmptyResult() async throws {
        // Given
        let userProfile = TestUtilities.createTestUserProfile(id: "user-123")
        mockSupabaseClient.setupUserProfile(userProfile)
        mockSupabaseClient.setupUserPosts("user-123", posts: [])
        
        // When
        let posts = try await repository.fetchUserPosts(userId: "user-123")
        
        // Then
        XCTAssertTrue(posts.isEmpty)
    }
    
    func testFetchUserPostsWithNetworkError() async {
        // Given
        mockSupabaseClient.shouldThrowError = true
        mockSupabaseClient.errorToThrow = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        
        // When/Then
        do {
            let _ = try await repository.fetchUserPosts(userId: "user-123")
            XCTFail("Expected error to be thrown")
        } catch let error as ViewModelError {
            XCTAssertEqual(error.userFriendlyMessage, "Unable to connect. Please check your internet connection.")
        }
    }
    
    // MARK: - Update User Profile Tests
    
    func testUpdateUserProfileSuccess() async throws {
        // Given
        var profile = TestUtilities.createTestUserProfile()
        profile.username = "updated_username"
        profile.displayName = "Updated Name"
        profile.bio = "Updated bio"
        
        // When
        try await repository.updateUserProfile(profile)
        
        // Then
        XCTAssertEqual(mockSupabaseClient.updateCalls.count, 1)
        XCTAssertEqual(mockSupabaseClient.updateCalls.first?.table, "user_profiles")
        
        // Verify the profile data was passed correctly
        let updateCall = mockSupabaseClient.updateCalls.first!
        XCTAssertEqual(updateCall.data["username"] as? String, "updated_username")
        XCTAssertEqual(updateCall.data["display_name"] as? String, "Updated Name")
        XCTAssertEqual(updateCall.data["bio"] as? String, "Updated bio")
    }
    
    func testUpdateUserProfileWithError() async {
        // Given
        let profile = TestUtilities.createTestUserProfile()
        mockSupabaseClient.shouldThrowError = true
        mockSupabaseClient.errorToThrow = NSError(domain: "Supabase", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        
        // When/Then
        do {
            try await repository.updateUserProfile(profile)
            XCTFail("Expected error to be thrown")
        } catch let error as ViewModelError {
            XCTAssertEqual(error.userFriendlyMessage, "Something went wrong. Please try again later.")
        }
    }
    
    // MARK: - Update Profile Photo Tests
    
    func testUpdateProfilePhotoSuccess() async throws {
        // Given
        let userId = "user-123"
        let imageData = Data([0x01, 0x02, 0x03, 0x04])
        let expectedUrl = "https://example.com/storage/avatars/user-123/avatar_test.jpg"
        
        mockSupabaseClient.setupStorageUploadSuccess(publicUrl: expectedUrl)
        
        // When
        let resultUrl = try await repository.updateProfilePhoto(userId: userId, imageData: imageData)
        
        // Then
        XCTAssertEqual(resultUrl, expectedUrl)
        
        // Verify storage upload was called
        XCTAssertEqual(mockSupabaseClient.uploadCalls.count, 1)
        XCTAssertEqual(mockSupabaseClient.uploadCalls.first?.bucket, "avatars")
        XCTAssertEqual(mockSupabaseClient.uploadCalls.first?.data, imageData)
        
        // Verify profile update was called
        XCTAssertEqual(mockSupabaseClient.updateCalls.count, 1)
        XCTAssertEqual(mockSupabaseClient.updateCalls.first?.table, "user_profiles")
    }
    
    func testUpdateProfilePhotoUploadError() async {
        // Given
        let userId = "user-123"
        let imageData = Data([0x01, 0x02, 0x03, 0x04])
        
        mockSupabaseClient.shouldThrowError = true
        mockSupabaseClient.errorToThrow = NSError(domain: "Storage", code: 413, userInfo: [NSLocalizedDescriptionKey: "File too large"])
        
        // When/Then
        do {
            let _ = try await repository.updateProfilePhoto(userId: userId, imageData: imageData)
            XCTFail("Expected error to be thrown")
        } catch let error as ViewModelError {
            XCTAssertEqual(error.userFriendlyMessage, "Unable to access files. Please try again.")
        }
    }
    
    // MARK: - Fetch Followers Count Tests
    
    func testFetchFollowersCountSuccess() async throws {
        // Given
        let userId = "user-123"
        let expectedCount = 42
        mockSupabaseClient.setupFollowersCount(userId: userId, count: expectedCount)
        
        // When
        let count = try await repository.fetchFollowersCount(userId: userId)
        
        // Then
        XCTAssertEqual(count, expectedCount)
        
        // Verify Supabase call
        XCTAssertEqual(mockSupabaseClient.selectCalls.count, 1)
        XCTAssertEqual(mockSupabaseClient.selectCalls.first?.table, "follows")
    }
    
    func testFetchFollowersCountWithError() async throws {
        // Given - Even if there's an error, the method should return 0
        let userId = "user-123"
        mockSupabaseClient.shouldThrowError = true
        mockSupabaseClient.errorToThrow = NSError(domain: "Network", code: 500)
        
        // When
        let count = try await repository.fetchFollowersCount(userId: userId)
        
        // Then
        XCTAssertEqual(count, 0) // Should return 0 on error
    }
    
    // MARK: - Fetch Following Count Tests
    
    func testFetchFollowingCountSuccess() async throws {
        // Given
        let userId = "user-123"
        let expectedCount = 28
        mockSupabaseClient.setupFollowingCount(userId: userId, count: expectedCount)
        
        // When
        let count = try await repository.fetchFollowingCount(userId: userId)
        
        // Then
        XCTAssertEqual(count, expectedCount)
        
        // Verify Supabase call
        XCTAssertEqual(mockSupabaseClient.selectCalls.count, 1)
        XCTAssertEqual(mockSupabaseClient.selectCalls.first?.table, "follows")
    }
    
    func testFetchFollowingCountWithError() async throws {
        // Given
        let userId = "user-123"
        mockSupabaseClient.shouldThrowError = true
        mockSupabaseClient.errorToThrow = NSError(domain: "Network", code: 500)
        
        // When
        let count = try await repository.fetchFollowingCount(userId: userId)
        
        // Then
        XCTAssertEqual(count, 0) // Should return 0 on error
    }
    
    // MARK: - Integration Workflow Tests
    
    func testCompleteUserProfileWorkflow() async throws {
        // Given
        let userId = "user-123"
        let originalProfile = TestUtilities.createTestUserProfile(id: userId)
        mockSupabaseClient.setupUserProfile(originalProfile)
        
        // When - Fetch original profile
        let fetchedProfile = try await repository.fetchUserProfile(userId: userId)
        
        // Then - Verify fetch
        XCTAssertEqual(fetchedProfile.id, originalProfile.id)
        
        // When - Update profile
        var updatedProfile = fetchedProfile
        updatedProfile.username = "new_username"
        updatedProfile.displayName = "New Display Name"
        
        try await repository.updateUserProfile(updatedProfile)
        
        // Then - Verify update
        XCTAssertEqual(mockSupabaseClient.updateCalls.count, 1)
        
        // When - Update profile photo
        let imageData = Data(repeating: 0xFF, count: 1024)
        let newAvatarUrl = "https://example.com/new-avatar.jpg"
        mockSupabaseClient.setupStorageUploadSuccess(publicUrl: newAvatarUrl)
        
        let resultUrl = try await repository.updateProfilePhoto(userId: userId, imageData: imageData)
        
        // Then - Verify photo update
        XCTAssertEqual(resultUrl, newAvatarUrl)
        XCTAssertEqual(mockSupabaseClient.uploadCalls.count, 1)
        XCTAssertEqual(mockSupabaseClient.updateCalls.count, 2) // Profile update + avatar URL update
    }
    
    // MARK: - Performance Tests
    
    func testFetchMultipleUserProfilesPerformance() async throws {
        // Given
        let userIds = (1...100).map { "user-\($0)" }
        for userId in userIds {
            let profile = TestUtilities.createTestUserProfile(id: userId)
            mockSupabaseClient.setupUserProfile(profile)
        }
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for userId in userIds {
            let _ = try await repository.fetchUserProfile(userId: userId)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertLessThan(timeElapsed, 5.0) // Should complete within 5 seconds
        XCTAssertEqual(mockSupabaseClient.selectCalls.count, 100)
    }
    
    func testConcurrentProfileFetches() async throws {
        // Given
        let userIds = (1...10).map { "user-\($0)" }
        for userId in userIds {
            let profile = TestUtilities.createTestUserProfile(id: userId)
            mockSupabaseClient.setupUserProfile(profile)
        }
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            for userId in userIds {
                group.addTask {
                    do {
                        let _ = try await self.repository.fetchUserProfile(userId: userId)
                    } catch {
                        XCTFail("Failed to fetch profile for \(userId): \(error)")
                    }
                }
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertLessThan(timeElapsed, 2.0) // Concurrent calls should be faster
        XCTAssertEqual(mockSupabaseClient.selectCalls.count, 10)
    }
}