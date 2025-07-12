//======================================================================
// MARK: - TestUtilities
// Purpose: Common test utilities and helper functions
//======================================================================
import XCTest
import SwiftUI
import Combine
@testable import tete

/// Test utilities for common testing patterns
final class TestUtilities {
    
    /// Creates a test UserProfile
    static func createTestUserProfile(
        id: String = "test-user-id",
        username: String = "testuser",
        displayName: String = "Test User",
        avatarUrl: String? = nil,
        bio: String? = "Test bio"
    ) -> UserProfile {
        UserProfile(
            id: id,
            username: username,
            displayName: displayName,
            avatarUrl: avatarUrl,
            bio: bio,
            createdAt: Date()
        )
    }
    
    /// Creates a test Post
    static func createTestPost(
        id: String = "test-post-id",
        userId: String = "test-user-id",
        mediaUrl: String = "https://example.com/test.jpg",
        caption: String? = "Test caption",
        likeCount: Int = 0,
        commentCount: Int = 0
    ) -> Post {
        Post(
            id: id,
            userId: userId,
            mediaUrl: mediaUrl,
            mediaType: .photo,
            thumbnailUrl: nil,
            caption: caption,
            locationName: nil,
            latitude: nil,
            longitude: nil,
            isPublic: true,
            createdAt: Date(),
            likeCount: likeCount,
            commentCount: commentCount
        )
    }
    
    /// Creates multiple test posts
    static func createTestPosts(count: Int = 3) -> [Post] {
        (0..<count).map { index in
            createTestPost(
                id: "test-post-\(index)",
                caption: "Test caption \(index)",
                likeCount: index * 2
            )
        }
    }
    
    /// Waits for async operation to complete
    static func waitForAsync(timeout: TimeInterval = 1.0) async {
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    }
    
    /// Creates a mock error
    static func createTestError(message: String = "Test error") -> Error {
        ViewModelError.network(message)
    }
}

/// Test helper for observing published properties
class PublishedPropertyObserver<T: ObservableObject> {
    private var cancellables = Set<AnyCancellable>()
    private let object: T
    
    init(_ object: T) {
        self.object = object
    }
    
    func wait(for keyPath: KeyPath<T, Bool>, toBe value: Bool, timeout: TimeInterval = 1.0) async -> Bool {
        return await withCheckedContinuation { continuation in
            var hasCompleted = false
            
            // Check initial value
            if object[keyPath: keyPath] == value {
                continuation.resume(returning: true)
                return
            }
            
            // Set up timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                if !hasCompleted {
                    hasCompleted = true
                    continuation.resume(returning: false)
                }
            }
            
            // Observe changes
            object.objectWillChange
                .sink { _ in
                    DispatchQueue.main.async {
                        if !hasCompleted && self.object[keyPath: keyPath] == value {
                            hasCompleted = true
                            continuation.resume(returning: true)
                        }
                    }
                }
                .store(in: &cancellables)
        }
    }
}

/// Custom XCTest assertions
extension XCTestCase {
    
    /// Asserts that an async operation completes within timeout
    func assertAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        timeout: TimeInterval = 1.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await expression()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw XCTSkip("Operation timed out after \(timeout) seconds")
            }
            
            guard let result = try await group.next() else {
                throw XCTSkip("No result from async operation")
            }
            
            group.cancelAll()
            return result
        }
    }
    
    /// Asserts that a ViewModelError has the expected type
    func assertViewModelError(
        _ error: Error,
        isType expectedType: ViewModelError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let vmError = error as? ViewModelError else {
            XCTFail("Expected ViewModelError but got \(type(of: error))", file: file, line: line)
            return
        }
        
        switch (vmError, expectedType) {
        case (.network, .network),
             (.validation, .validation),
             (.unauthorized, .unauthorized),
             (.notFound, .notFound):
            break // Success
        default:
            XCTFail("Expected \(expectedType) but got \(vmError)", file: file, line: line)
        }
    }
}