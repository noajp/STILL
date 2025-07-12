//======================================================================
// MARK: - UserRepositoryTests
// Purpose: Tests for UserRepository implementation
//======================================================================
import XCTest
@testable import tete

final class UserRepositoryTests: XCTestCase {
    
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
        let expectedProfile = TestUtilities.createTestUserProfile()
        mockSupabaseClient.mockUserProfile = expectedProfile
        
        // When
        let result = try await repository.fetchUserProfile(userId: expectedProfile.id)
        
        // Then
        XCTAssertEqual(result.id, expectedProfile.id)
        XCTAssertEqual(result.username, expectedProfile.username)
        XCTAssertEqual(result.displayName, expectedProfile.displayName)
        XCTAssertEqual(mockSupabaseClient.fetchUserProfileCalls.count, 1)
        XCTAssertEqual(mockSupabaseClient.fetchUserProfileCalls.first, expectedProfile.id)
    }
    
    func testFetchUserProfileFailure() async {
        // Given
        mockSupabaseClient.shouldThrowError = true
        mockSupabaseClient.errorToThrow = NSError(domain: "TestError", code: 404)
        
        // When & Then
        do {
            _ = try await repository.fetchUserProfile(userId: "invalid-id")
            XCTFail("Expected error to be thrown")
        } catch let error as ViewModelError {
            switch error {
            case .network:
                break // Expected
            default:
                XCTFail("Expected network error but got \(error)")
            }
        } catch {
            XCTFail("Expected ViewModelError but got \(error)")
        }
    }
    
    // MARK: - Fetch User Posts Tests
    
    func testFetchUserPostsSuccess() async throws {
        // Given
        let testPosts = TestUtilities.createTestPosts(count: 3)
        let testProfile = TestUtilities.createTestUserProfile()
        
        mockSupabaseClient.mockPosts = testPosts
        mockSupabaseClient.mockUserProfile = testProfile
        
        // When
        let result = try await repository.fetchUserPosts(userId: testProfile.id)
        
        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.first?.id, testPosts.first?.id)
        XCTAssertEqual(result.first?.user?.id, testProfile.id)
        XCTAssertEqual(mockSupabaseClient.fetchUserPostsCalls.count, 1)
        XCTAssertEqual(mockSupabaseClient.fetchUserProfileCalls.count, 1)
    }
    
    func testFetchUserPostsEmpty() async throws {
        // Given
        mockSupabaseClient.mockPosts = []
        
        // When
        let result = try await repository.fetchUserPosts(userId: "test-user-id")
        
        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(mockSupabaseClient.fetchUserPostsCalls.count, 1)
        XCTAssertEqual(mockSupabaseClient.fetchUserProfileCalls.count, 0) // Should not fetch profile for empty posts
    }
    
    func testFetchUserPostsFailure() async {
        // Given
        mockSupabaseClient.shouldThrowError = true
        mockSupabaseClient.errorToThrow = NSError(domain: "NetworkError", code: 500)
        
        // When & Then
        do {
            _ = try await repository.fetchUserPosts(userId: "test-user-id")
            XCTFail("Expected error to be thrown")
        } catch let error as ViewModelError {
            switch error {
            case .network:
                break // Expected
            default:
                XCTFail("Expected network error but got \(error)")
            }
        }
    }
    
    // MARK: - Update User Profile Tests
    
    func testUpdateUserProfileSuccess() async throws {
        // Given
        let profileToUpdate = TestUtilities.createTestUserProfile()
        
        // When
        try await repository.updateUserProfile(profileToUpdate)
        
        // Then
        XCTAssertEqual(mockSupabaseClient.updateUserProfileCalls.count, 1)
        XCTAssertEqual(mockSupabaseClient.updateUserProfileCalls.first?.id, profileToUpdate.id)
    }
    
    func testUpdateUserProfileFailure() async {
        // Given
        let profileToUpdate = TestUtilities.createTestUserProfile()
        mockSupabaseClient.shouldThrowError = true
        mockSupabaseClient.errorToThrow = NSError(domain: "ServerError", code: 500)
        
        // When & Then
        do {
            try await repository.updateUserProfile(profileToUpdate)
            XCTFail("Expected error to be thrown")
        } catch let error as ViewModelError {
            switch error {
            case .serverError:
                break // Expected
            default:
                XCTFail("Expected server error but got \(error)")
            }
        }
    }
    
    // MARK: - Follow Count Tests
    
    func testFetchFollowersCountSuccess() async throws {
        // Given
        mockSupabaseClient.mockFollowersCount = 42
        
        // When
        let result = try await repository.fetchFollowersCount(userId: "test-user-id")
        
        // Then
        XCTAssertEqual(result, 42)
        XCTAssertEqual(mockSupabaseClient.fetchFollowersCountCalls.count, 1)
    }
    
    func testFetchFollowingCountSuccess() async throws {
        // Given
        mockSupabaseClient.mockFollowingCount = 28
        
        // When
        let result = try await repository.fetchFollowingCount(userId: "test-user-id")
        
        // Then
        XCTAssertEqual(result, 28)
        XCTAssertEqual(mockSupabaseClient.fetchFollowingCountCalls.count, 1)
    }
    
    func testFetchFollowCountsWithErrors() async throws {
        // Given
        mockSupabaseClient.shouldThrowError = true
        
        // When
        let followersResult = try await repository.fetchFollowersCount(userId: "test-user-id")
        let followingResult = try await repository.fetchFollowingCount(userId: "test-user-id")
        
        // Then - Should return 0 on error, not throw
        XCTAssertEqual(followersResult, 0)
        XCTAssertEqual(followingResult, 0)
    }
}

// MARK: - Mock Supabase Client

private class MockSupabaseClient {
    
    // MARK: - Mock Data
    var mockUserProfile: UserProfile?
    var mockPosts: [Post] = []
    var mockFollowersCount: Int = 0
    var mockFollowingCount: Int = 0
    
    // MARK: - Call Tracking
    var fetchUserProfileCalls: [String] = []
    var fetchUserPostsCalls: [String] = []
    var updateUserProfileCalls: [UserProfile] = []
    var fetchFollowersCountCalls: [String] = []
    var fetchFollowingCountCalls: [String] = []
    
    // MARK: - Error Simulation
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockError", code: 500)
    
    // MARK: - Mock Methods
    
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        fetchUserProfileCalls.append(userId)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let profile = mockUserProfile else {
            throw NSError(domain: "NotFound", code: 404)
        }
        
        return profile
    }
    
    func fetchUserPosts(userId: String) async throws -> [Post] {
        fetchUserPostsCalls.append(userId)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockPosts
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        updateUserProfileCalls.append(profile)
        
        if shouldThrowError {
            throw errorToThrow
        }
    }
    
    func fetchFollowersCount(userId: String) async throws -> Int {
        fetchFollowersCountCalls.append(userId)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockFollowersCount
    }
    
    func fetchFollowingCount(userId: String) async throws -> Int {
        fetchFollowingCountCalls.append(userId)
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockFollowingCount
    }
}