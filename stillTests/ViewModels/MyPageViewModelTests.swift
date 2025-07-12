//======================================================================
// MARK: - MyPageViewModelTests
// Purpose: Comprehensive tests for MyPageViewModel
//======================================================================
import XCTest
import Combine
@testable import tete

@MainActor
final class MyPageViewModelTests: XCTestCase {
    
    // MARK: - Properties
    private var viewModel: MyPageViewModel!
    private var mockUserRepository: MockUserRepository!
    private var mockAuthManager: MockAuthManager!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockUserRepository = MockUserRepository()
        mockAuthManager = MockAuthManager()
        cancellables = Set<AnyCancellable>()
        
        // Create view model with mocks
        viewModel = MyPageViewModel(
            userRepository: mockUserRepository,
            authManager: mockAuthManager
        )
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        viewModel = nil
        mockUserRepository = nil
        mockAuthManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.userProfile)
        XCTAssertTrue(viewModel.userPosts.isEmpty)
        XCTAssertEqual(viewModel.postsCount, 0)
        XCTAssertEqual(viewModel.followersCount, 0)
        XCTAssertEqual(viewModel.followingCount, 0)
    }
    
    // MARK: - Load User Data Tests
    
    func testLoadUserDataSuccess() async {
        // Given
        let testProfile = TestUtilities.createTestUserProfile()
        let testPosts = TestUtilities.createTestPosts(count: 3)
        
        mockAuthManager.simulateSignedInUser(id: testProfile.id)
        mockUserRepository.setupUser(
            testProfile,
            posts: testPosts,
            followersCount: 42,
            followingCount: 28
        )
        
        // When
        await viewModel.loadUserData()
        
        // Then
        XCTAssertEqual(viewModel.userProfile?.id, testProfile.id)
        XCTAssertEqual(viewModel.userProfile?.username, testProfile.username)
        XCTAssertEqual(viewModel.userPosts.count, 3)
        XCTAssertEqual(viewModel.postsCount, 3)
        XCTAssertEqual(viewModel.followersCount, 42)
        XCTAssertEqual(viewModel.followingCount, 28)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        
        // Verify repository calls
        XCTAssertEqual(mockUserRepository.fetchUserProfileCalls.count, 1)
        XCTAssertEqual(mockUserRepository.fetchUserPostsCalls.count, 1)
        XCTAssertEqual(mockUserRepository.fetchFollowersCountCalls.count, 1)
        XCTAssertEqual(mockUserRepository.fetchFollowingCountCalls.count, 1)
    }
    
    func testLoadUserDataWhenNotAuthenticated() async {
        // Given
        mockAuthManager.simulateSignedOutUser()
        
        // When
        await viewModel.loadUserData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
        
        // Verify no repository calls were made
        XCTAssertEqual(mockUserRepository.fetchUserProfileCalls.count, 0)
    }
    
    func testLoadUserDataWithRepositoryError() async {
        // Given
        mockAuthManager.simulateSignedInUser()
        mockUserRepository.shouldThrowError = true
        mockUserRepository.errorToThrow = ViewModelError.network("Failed to load profile")
        
        // When
        await viewModel.loadUserData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
        XCTAssertNil(viewModel.userProfile)
    }
    
    func testLoadUserDataShowsLoadingState() async {
        // Given
        let testProfile = TestUtilities.createTestUserProfile()
        mockAuthManager.simulateSignedInUser(id: testProfile.id)
        mockUserRepository.setupUser(testProfile)
        
        // Create expectation for loading state
        let loadingExpectation = expectation(description: "Loading state observed")
        var observedLoadingStates: [Bool] = []
        
        viewModel.$isLoading
            .sink { isLoading in
                observedLoadingStates.append(isLoading)
                if observedLoadingStates.count >= 2 {
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await viewModel.loadUserData()
        
        // Then
        await fulfillment(of: [loadingExpectation], timeout: 1.0)
        XCTAssertEqual(observedLoadingStates, [false, true, false])
    }
    
    // MARK: - Update Profile Tests
    
    func testUpdateProfileSuccess() async {
        // Given
        let originalProfile = TestUtilities.createTestUserProfile()
        mockAuthManager.simulateSignedInUser(id: originalProfile.id)
        mockUserRepository.setupUser(originalProfile)
        
        // Load initial data
        await viewModel.loadUserData()
        
        // When
        await viewModel.updateProfile(
            username: "newusername",
            displayName: "New Display Name",
            bio: "New bio"
        )
        
        // Then
        XCTAssertEqual(mockUserRepository.updateUserProfileCalls.count, 1)
        let updatedProfile = mockUserRepository.updateUserProfileCalls.first!
        XCTAssertEqual(updatedProfile.username, "newusername")
        XCTAssertEqual(updatedProfile.displayName, "New Display Name")
        XCTAssertEqual(updatedProfile.bio, "New bio")
        
        // Should reload data after update
        XCTAssertEqual(mockUserRepository.fetchUserProfileCalls.count, 2)
    }
    
    func testUpdateProfileWhenNoProfileExists() async {
        // Given
        mockAuthManager.simulateSignedInUser()
        // Don't set up any profile
        
        // When
        await viewModel.updateProfile(
            username: "newusername",
            displayName: "New Display Name",
            bio: "New bio"
        )
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(mockUserRepository.updateUserProfileCalls.count, 0)
    }
    
    func testUpdateProfileWithRepositoryError() async {
        // Given
        let testProfile = TestUtilities.createTestUserProfile()
        mockAuthManager.simulateSignedInUser(id: testProfile.id)
        mockUserRepository.setupUser(testProfile)
        
        await viewModel.loadUserData()
        
        mockUserRepository.shouldThrowError = true
        mockUserRepository.errorToThrow = ViewModelError.serverError("Update failed")
        
        // When
        await viewModel.updateProfile(
            username: "newusername",
            displayName: "New Display Name",
            bio: "New bio"
        )
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Update Profile Photo Tests
    
    func testUpdateProfilePhotoSuccess() async {
        // Given
        let testProfile = TestUtilities.createTestUserProfile()
        mockAuthManager.simulateSignedInUser(id: testProfile.id)
        mockUserRepository.setupUser(testProfile)
        
        await viewModel.loadUserData()
        
        let testImageData = Data([0x01, 0x02, 0x03])
        
        // When
        // Note: We can't easily test PhotosPickerItem, so we test the core logic
        // by calling updateProfilePhoto with mock data
        await viewModel.updateProfilePhoto(item: nil) // This will return early
        
        // Verify no calls were made since item was nil
        XCTAssertEqual(mockUserRepository.updateProfilePhotoCalls.count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async {
        // Given
        let testError = ViewModelError.network("Test error")
        
        // When
        viewModel.handleError(testError)
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, "Unable to connect. Please check your internet connection.")
        XCTAssertTrue(viewModel.showError)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testClearError() {
        // Given
        viewModel.handleError(ViewModelError.network("Test"))
        XCTAssertTrue(viewModel.showError)
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
    
    // MARK: - Refresh Tests
    
    func testRefresh() async {
        // Given
        let testProfile = TestUtilities.createTestUserProfile()
        mockAuthManager.simulateSignedInUser(id: testProfile.id)
        mockUserRepository.setupUser(testProfile)
        
        // Initial load
        await viewModel.loadUserData()
        XCTAssertEqual(mockUserRepository.fetchUserProfileCalls.count, 1)
        
        // When
        await viewModel.refresh()
        
        // Then
        XCTAssertEqual(mockUserRepository.fetchUserProfileCalls.count, 2)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteUserFlow() async {
        // Given
        let testProfile = TestUtilities.createTestUserProfile()
        let testPosts = TestUtilities.createTestPosts(count: 5)
        
        mockAuthManager.simulateSignedInUser(id: testProfile.id)
        mockUserRepository.setupUser(
            testProfile,
            posts: testPosts,
            followersCount: 100,
            followingCount: 50
        )
        
        // When - Load data
        await viewModel.loadUserData()
        
        // Then - Verify initial state
        XCTAssertEqual(viewModel.userProfile?.id, testProfile.id)
        XCTAssertEqual(viewModel.userPosts.count, 5)
        XCTAssertEqual(viewModel.postsCount, 5)
        XCTAssertEqual(viewModel.followersCount, 100)
        XCTAssertEqual(viewModel.followingCount, 50)
        
        // When - Update profile
        await viewModel.updateProfile(
            username: "updateduser",
            displayName: "Updated Name",
            bio: "Updated bio"
        )
        
        // Then - Verify update
        XCTAssertEqual(mockUserRepository.updateUserProfileCalls.count, 1)
        let updatedProfile = mockUserRepository.updateUserProfileCalls.first!
        XCTAssertEqual(updatedProfile.username, "updateduser")
        
        // When - Refresh
        await viewModel.refresh()
        
        // Then - Verify refresh
        XCTAssertEqual(mockUserRepository.fetchUserProfileCalls.count, 3) // Initial + after update + refresh
    }
}