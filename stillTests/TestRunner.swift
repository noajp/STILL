//======================================================================
// MARK: - TestRunner
// Purpose: Test configuration and runner utilities
//======================================================================
import XCTest
@testable import tete

/// Test configuration for the app
final class TestRunner {
    
    /// Configures the app for testing
    static func configureForTesting() {
        // Enable mock data
        UserDefaults.standard.set(true, forKey: "IS_TESTING")
        
        // Clear any existing data
        clearTestData()
        
        // Set up test environment
        setupTestEnvironment()
    }
    
    /// Clears test data
    private static func clearTestData() {
        // Clear UserDefaults test keys
        let testKeys = [
            "test_user_profile",
            "test_posts",
            "test_auth_state"
        ]
        
        for key in testKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    /// Sets up test environment
    private static func setupTestEnvironment() {
        // Configure logging for tests
        Logger.shared.info("Test environment configured")
        
        // Set up dependency container for testing
        setupTestDependencies()
    }
    
    /// Sets up test dependencies
    private static func setupTestDependencies() {
        // Clear existing dependencies and register test ones
        DependencyContainer.shared.clear()
        
        // Register mock repositories and auth manager
        DependencyContainer.shared.registerTestDependencies(
            userRepository: MockUserRepository(),
            authManager: MockAuthManager()
        )
        
        // Register additional test-specific dependencies
        DependencyContainer.shared.register(PostServiceProtocol.self) {
            MockPostService()
        }
        
        Logger.shared.info("Test dependencies configured")
    }
    
    /// Creates test data for UI tests
    static func createTestData() {
        // Create mock user profile
        let testProfile = TestUtilities.createTestUserProfile()
        
        // Create mock posts
        let testPosts = TestUtilities.createTestPosts(count: 10)
        
        // Store in UserDefaults for UI tests to access
        if let profileData = try? JSONEncoder().encode(testProfile) {
            UserDefaults.standard.set(profileData, forKey: "test_user_profile")
        }
        
        if let postsData = try? JSONEncoder().encode(testPosts) {
            UserDefaults.standard.set(postsData, forKey: "test_posts")
        }
    }
}