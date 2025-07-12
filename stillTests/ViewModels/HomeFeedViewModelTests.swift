//======================================================================
// MARK: - HomeFeedViewModelTests
// Purpose: Comprehensive tests for HomeFeedViewModel
//======================================================================
import XCTest
import Combine
@testable import tete

@MainActor
final class HomeFeedViewModelTests: XCTestCase {
    
    // MARK: - Properties
    private var viewModel: HomeFeedViewModel!
    private var mockPostService: MockPostService!
    private var mockAuthManager: MockAuthManager!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockPostService = MockPostService()
        mockAuthManager = MockAuthManager()
        cancellables = Set<AnyCancellable>()
        
        // Create view model with mocks
        viewModel = HomeFeedViewModel(
            postService: mockPostService,
            authManager: mockAuthManager
        )
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        viewModel = nil
        mockPostService = nil
        mockAuthManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
    
    func testInitialLoadPostsCall() async {
        // Given - setup posts and wait for initial load
        let testPosts = TestUtilities.createTestPosts(count: 3)
        mockPostService.setupFeedPosts(testPosts)
        mockAuthManager.simulateSignedInUser()
        
        // Wait for the async init to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(mockPostService.fetchFeedPostsCalls.count, 1)
    }
    
    // MARK: - Load Posts Tests
    
    func testLoadPostsSuccess() async {
        // Given
        let testPosts = TestUtilities.createTestPosts(count: 5)
        mockPostService.setupFeedPosts(testPosts)
        mockAuthManager.simulateSignedInUser(id: "test-user-1")
        
        // When
        await viewModel.loadPosts()
        
        // Then
        XCTAssertEqual(viewModel.posts.count, 5)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
        
        // Verify service call
        XCTAssertGreaterThanOrEqual(mockPostService.fetchFeedPostsCalls.count, 1)
        XCTAssertEqual(mockPostService.fetchFeedPostsCalls.last?.currentUserId, "test-user-1")
    }
    
    func testLoadPostsWhenNotAuthenticated() async {
        // Given
        let testPosts = TestUtilities.createTestPosts(count: 3)
        mockPostService.setupFeedPosts(testPosts)
        mockAuthManager.simulateSignedOutUser()
        
        // When
        await viewModel.loadPosts()
        
        // Then
        XCTAssertEqual(viewModel.posts.count, 3)
        XCTAssertFalse(viewModel.isLoading)
        
        // Should still load posts but without user ID
        XCTAssertGreaterThanOrEqual(mockPostService.fetchFeedPostsCalls.count, 1)
        XCTAssertNil(mockPostService.fetchFeedPostsCalls.last?.currentUserId)
    }
    
    func testLoadPostsWithNetworkError() async {
        // Given
        mockPostService.shouldThrowError = true
        mockPostService.errorToThrow = ViewModelError.network("Failed to load feed")
        
        // When
        await viewModel.loadPosts()
        
        // Then
        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "Unable to connect. Please check your internet connection.")
    }
    
    func testLoadPostsShowsLoadingState() async {
        // Given
        let testPosts = TestUtilities.createTestPosts(count: 2)
        mockPostService.setupFeedPosts(testPosts)
        mockAuthManager.simulateSignedInUser()
        
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
        await viewModel.loadPosts()
        
        // Then
        await fulfillment(of: [loadingExpectation], timeout: 1.0)
        XCTAssertEqual(observedLoadingStates, [false, true, false])
    }
    
    // MARK: - Like Operations Tests
    
    func testToggleLikeSuccess() async {
        // Given
        let testPost = TestUtilities.createTestPost(id: "post-1", likeCount: 5)
        mockPostService.setupFeedPosts([testPost])
        mockAuthManager.simulateSignedInUser(id: "user-1")
        
        await viewModel.loadPosts()
        
        // When - Like the post
        await viewModel.toggleLike(for: testPost)
        
        // Then
        XCTAssertEqual(mockPostService.toggleLikeCalls.count, 1)
        XCTAssertEqual(mockPostService.toggleLikeCalls.first?.postId, "post-1")
        XCTAssertEqual(mockPostService.toggleLikeCalls.first?.userId, "user-1")
        
        // Check optimistic update
        let updatedPost = viewModel.posts.first { $0.id == "post-1" }
        XCTAssertNotNil(updatedPost)
        XCTAssertTrue(updatedPost!.isLikedByMe)
        XCTAssertEqual(updatedPost!.likeCount, 6)
    }
    
    func testToggleLikeWhenNotAuthenticated() async {
        // Given
        let testPost = TestUtilities.createTestPost(id: "post-1")
        mockPostService.setupFeedPosts([testPost])
        mockAuthManager.simulateSignedOutUser()
        
        await viewModel.loadPosts()
        
        // When
        await viewModel.toggleLike(for: testPost)
        
        // Then
        XCTAssertEqual(mockPostService.toggleLikeCalls.count, 0)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "Please log in to continue")
    }
    
    func testToggleLikeWithNetworkError() async {
        // Given
        let testPost = TestUtilities.createTestPost(id: "post-1", likeCount: 5)
        var postWithLikeStatus = testPost
        postWithLikeStatus.isLikedByMe = false
        
        mockPostService.setupFeedPosts([postWithLikeStatus])
        mockAuthManager.simulateSignedInUser(id: "user-1")
        
        await viewModel.loadPosts()
        
        // Set up error after initial load
        mockPostService.shouldThrowError = true
        mockPostService.errorToThrow = ViewModelError.network("Like failed")
        
        // When
        await viewModel.toggleLike(for: postWithLikeStatus)
        
        // Then
        XCTAssertEqual(mockPostService.toggleLikeCalls.count, 1)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
        
        // Check that optimistic update was reverted
        let updatedPost = viewModel.posts.first { $0.id == "post-1" }
        XCTAssertNotNil(updatedPost)
        XCTAssertFalse(updatedPost!.isLikedByMe) // Should be reverted
        XCTAssertEqual(updatedPost!.likeCount, 5) // Should be reverted
    }
    
    func testToggleLikeOptimisticUpdate() async {
        // Given
        let testPost = TestUtilities.createTestPost(id: "post-1", likeCount: 10)
        var postWithLikeStatus = testPost
        postWithLikeStatus.isLikedByMe = false
        
        mockPostService.setupFeedPosts([postWithLikeStatus])
        mockAuthManager.simulateSignedInUser(id: "user-1")
        
        await viewModel.loadPosts()
        
        // When
        let toggleTask = Task {
            await viewModel.toggleLike(for: postWithLikeStatus)
        }
        
        // Check immediate optimistic update (before network call completes)
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        let immediatePost = viewModel.posts.first { $0.id == "post-1" }
        XCTAssertNotNil(immediatePost)
        XCTAssertTrue(immediatePost!.isLikedByMe) // Should be immediately updated
        XCTAssertEqual(immediatePost!.likeCount, 11) // Should be immediately incremented
        
        // Wait for toggle to complete
        await toggleTask.value
        
        // Verify final state
        let finalPost = viewModel.posts.first { $0.id == "post-1" }
        XCTAssertNotNil(finalPost)
        XCTAssertTrue(finalPost!.isLikedByMe)
        XCTAssertEqual(finalPost!.likeCount, 11)
    }
    
    func testToggleUnlike() async {
        // Given
        let testPost = TestUtilities.createTestPost(id: "post-1", likeCount: 10)
        var postWithLikeStatus = testPost
        postWithLikeStatus.isLikedByMe = true
        
        mockPostService.setupFeedPosts([postWithLikeStatus])
        mockAuthManager.simulateSignedInUser(id: "user-1")
        mockPostService.setupLikedPosts(userId: "user-1", postIds: ["post-1"])
        
        await viewModel.loadPosts()
        
        // When
        await viewModel.toggleLike(for: postWithLikeStatus)
        
        // Then
        let updatedPost = viewModel.posts.first { $0.id == "post-1" }
        XCTAssertNotNil(updatedPost)
        XCTAssertFalse(updatedPost!.isLikedByMe)
        XCTAssertEqual(updatedPost!.likeCount, 9)
    }
    
    // MARK: - Refresh Tests
    
    func testRefreshPosts() async {
        // Given
        let initialPosts = TestUtilities.createTestPosts(count: 2)
        mockPostService.setupFeedPosts(initialPosts)
        mockAuthManager.simulateSignedInUser()
        
        await viewModel.loadPosts()
        XCTAssertEqual(viewModel.posts.count, 2)
        
        // Update mock data
        let refreshedPosts = TestUtilities.createTestPosts(count: 5)
        mockPostService.setupFeedPosts(refreshedPosts)
        
        // When
        await viewModel.refreshPosts()
        
        // Then
        XCTAssertEqual(viewModel.posts.count, 5)
        XCTAssertGreaterThanOrEqual(mockPostService.fetchFeedPostsCalls.count, 2)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async {
        // Given
        let testError = ViewModelError.serverError("Server error")
        
        // When
        viewModel.handleError(testError)
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, "Something went wrong. Please try again later.")
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
    
    // MARK: - Integration Tests
    
    func testCompleteUserFlow() async {
        // Given
        let testPosts = TestUtilities.createTestPosts(count: 3)
        mockPostService.setupFeedPosts(testPosts)
        mockAuthManager.simulateSignedInUser(id: "user-1")
        
        // When - Load posts
        await viewModel.loadPosts()
        
        // Then - Verify initial state
        XCTAssertEqual(viewModel.posts.count, 3)
        XCTAssertFalse(viewModel.isLoading)
        
        // When - Like first post
        let firstPost = viewModel.posts[0]
        await viewModel.toggleLike(for: firstPost)
        
        // Then - Verify like
        let likedPost = viewModel.posts.first { $0.id == firstPost.id }
        XCTAssertNotNil(likedPost)
        XCTAssertTrue(likedPost!.isLikedByMe)
        
        // When - Unlike the post
        await viewModel.toggleLike(for: likedPost!)
        
        // Then - Verify unlike
        let unlikedPost = viewModel.posts.first { $0.id == firstPost.id }
        XCTAssertNotNil(unlikedPost)
        XCTAssertFalse(unlikedPost!.isLikedByMe)
        
        // When - Refresh
        await viewModel.refreshPosts()
        
        // Then - Verify refresh
        XCTAssertEqual(viewModel.posts.count, 3)
        XCTAssertGreaterThanOrEqual(mockPostService.fetchFeedPostsCalls.count, 3)
    }
    
    // MARK: - Performance Tests
    
    func testLargePostListPerformance() async {
        // Given
        let largePosts = TestUtilities.createTestPosts(count: 100)
        mockPostService.setupFeedPosts(largePosts)
        mockAuthManager.simulateSignedInUser()
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        await viewModel.loadPosts()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertEqual(viewModel.posts.count, 100)
        XCTAssertLessThan(timeElapsed, 1.0) // Should complete within 1 second
    }
    
    func testMultipleLikeTogglePerformance() async {
        // Given
        let testPosts = TestUtilities.createTestPosts(count: 10)
        mockPostService.setupFeedPosts(testPosts)
        mockAuthManager.simulateSignedInUser(id: "user-1")
        
        await viewModel.loadPosts()
        
        // When - Toggle likes on multiple posts rapidly
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            for post in viewModel.posts.prefix(5) {
                group.addTask {
                    await self.viewModel.toggleLike(for: post)
                }
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertLessThan(timeElapsed, 2.0) // Should complete within 2 seconds
        XCTAssertEqual(mockPostService.toggleLikeCalls.count, 5)
    }
}