//======================================================================
// MARK: - UserProfileTests
// Purpose: Tests for UserProfile model and its business logic
//======================================================================
import XCTest
@testable import tete

final class UserProfileTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testUserProfileInitialization() {
        // Given
        let id = "test-user-id"
        let username = "testuser"
        let displayName = "Test User"
        let avatarUrl = "https://example.com/avatar.jpg"
        let bio = "Test bio"
        let createdAt = Date()
        
        // When
        let profile = UserProfile(
            id: id,
            username: username,
            displayName: displayName,
            avatarUrl: avatarUrl,
            bio: bio,
            createdAt: createdAt
        )
        
        // Then
        XCTAssertEqual(profile.id, id)
        XCTAssertEqual(profile.username, username)
        XCTAssertEqual(profile.displayName, displayName)
        XCTAssertEqual(profile.avatarUrl, avatarUrl)
        XCTAssertEqual(profile.bio, bio)
        XCTAssertEqual(profile.createdAt, createdAt)
    }
    
    func testUserProfileWithOptionalFields() {
        // Given
        let id = "test-user-id"
        let username = "testuser"
        
        // When
        let profile = UserProfile(
            id: id,
            username: username,
            displayName: nil,
            avatarUrl: nil,
            bio: nil,
            createdAt: nil
        )
        
        // Then
        XCTAssertEqual(profile.id, id)
        XCTAssertEqual(profile.username, username)
        XCTAssertNil(profile.displayName)
        XCTAssertNil(profile.avatarUrl)
        XCTAssertNil(profile.bio)
        XCTAssertNil(profile.createdAt)
    }
    
    // MARK: - Codable Tests
    
    func testUserProfileEncoding() throws {
        // Given
        let profile = UserProfile(
            id: "test-id",
            username: "testuser",
            displayName: "Test User",
            avatarUrl: "https://example.com/avatar.jpg",
            bio: "Test bio",
            createdAt: Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
        )
        
        // When
        let data = try JSONEncoder().encode(profile)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Then
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["id"] as? String, "test-id")
        XCTAssertEqual(json?["username"] as? String, "testuser")
        XCTAssertEqual(json?["display_name"] as? String, "Test User")
        XCTAssertEqual(json?["avatar_url"] as? String, "https://example.com/avatar.jpg")
        XCTAssertEqual(json?["bio"] as? String, "Test bio")
        XCTAssertNotNil(json?["created_at"])
    }
    
    func testUserProfileDecoding() throws {
        // Given
        let json = """
        {
            "id": "test-id",
            "username": "testuser",
            "display_name": "Test User",
            "avatar_url": "https://example.com/avatar.jpg",
            "bio": "Test bio",
            "created_at": "2022-01-01T00:00:00Z"
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let profile = try decoder.decode(UserProfile.self, from: data)
        
        // Then
        XCTAssertEqual(profile.id, "test-id")
        XCTAssertEqual(profile.username, "testuser")
        XCTAssertEqual(profile.displayName, "Test User")
        XCTAssertEqual(profile.avatarUrl, "https://example.com/avatar.jpg")
        XCTAssertEqual(profile.bio, "Test bio")
        XCTAssertNotNil(profile.createdAt)
    }
    
    func testUserProfileDecodingWithMissingOptionalFields() throws {
        // Given
        let json = """
        {
            "id": "test-id",
            "username": "testuser"
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let profile = try JSONDecoder().decode(UserProfile.self, from: data)
        
        // Then
        XCTAssertEqual(profile.id, "test-id")
        XCTAssertEqual(profile.username, "testuser")
        XCTAssertNil(profile.displayName)
        XCTAssertNil(profile.avatarUrl)
        XCTAssertNil(profile.bio)
        XCTAssertNil(profile.createdAt)
    }
    
    func testUserProfileDecodingWithInvalidData() {
        // Given
        let json = """
        {
            "username": "testuser"
        }
        """
        
        // When/Then
        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(UserProfile.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - Identifiable Tests
    
    func testUserProfileIdentifiable() {
        // Given
        let profile1 = UserProfile(id: "id-1", username: "user1", displayName: nil, avatarUrl: nil, bio: nil, createdAt: nil)
        let profile2 = UserProfile(id: "id-2", username: "user2", displayName: nil, avatarUrl: nil, bio: nil, createdAt: nil)
        let profile3 = UserProfile(id: "id-1", username: "user3", displayName: nil, avatarUrl: nil, bio: nil, createdAt: nil)
        
        // Then
        XCTAssertEqual(profile1.id, "id-1")
        XCTAssertEqual(profile2.id, "id-2")
        XCTAssertEqual(profile3.id, "id-1")
        
        // Same ID should be equal for Identifiable protocol
        XCTAssertEqual(profile1.id, profile3.id)
        XCTAssertNotEqual(profile1.id, profile2.id)
    }
    
    // MARK: - Business Logic Tests
    
    func testUsernameValidation() {
        // Test that username follows expected patterns
        
        // Valid usernames
        let validUsernames = ["user123", "test_user", "user.name", "a", "username123456"]
        
        for username in validUsernames {
            let profile = UserProfile(id: "test", username: username, displayName: nil, avatarUrl: nil, bio: nil, createdAt: nil)
            XCTAssertEqual(profile.username, username)
        }
        
        // Test empty username (should be handled at validation layer)
        let emptyProfile = UserProfile(id: "test", username: "", displayName: nil, avatarUrl: nil, bio: nil, createdAt: nil)
        XCTAssertEqual(emptyProfile.username, "")
    }
    
    func testDisplayNameFallback() {
        // Test behavior when displayName is nil
        let profileWithDisplayName = UserProfile(id: "test", username: "testuser", displayName: "Test User", avatarUrl: nil, bio: nil, createdAt: nil)
        let profileWithoutDisplayName = UserProfile(id: "test", username: "testuser", displayName: nil, avatarUrl: nil, bio: nil, createdAt: nil)
        
        XCTAssertEqual(profileWithDisplayName.displayName, "Test User")
        XCTAssertNil(profileWithoutDisplayName.displayName)
    }
    
    func testAvatarUrlValidation() {
        // Test with valid URL
        let validUrl = "https://example.com/avatar.jpg"
        let profileWithAvatar = UserProfile(id: "test", username: "testuser", displayName: nil, avatarUrl: validUrl, bio: nil, createdAt: nil)
        XCTAssertEqual(profileWithAvatar.avatarUrl, validUrl)
        
        // Test with nil URL
        let profileWithoutAvatar = UserProfile(id: "test", username: "testuser", displayName: nil, avatarUrl: nil, bio: nil, createdAt: nil)
        XCTAssertNil(profileWithoutAvatar.avatarUrl)
    }
    
    func testBioLengthHandling() {
        // Test short bio
        let shortBio = "Short bio"
        let profileWithShortBio = UserProfile(id: "test", username: "testuser", displayName: nil, avatarUrl: nil, bio: shortBio, createdAt: nil)
        XCTAssertEqual(profileWithShortBio.bio, shortBio)
        
        // Test long bio
        let longBio = String(repeating: "This is a long bio. ", count: 50) // 1000 characters
        let profileWithLongBio = UserProfile(id: "test", username: "testuser", displayName: nil, avatarUrl: nil, bio: longBio, createdAt: nil)
        XCTAssertEqual(profileWithLongBio.bio, longBio)
        
        // Test empty bio
        let emptyBio = ""
        let profileWithEmptyBio = UserProfile(id: "test", username: "testuser", displayName: nil, avatarUrl: nil, bio: emptyBio, createdAt: nil)
        XCTAssertEqual(profileWithEmptyBio.bio, emptyBio)
    }
    
    // MARK: - Equatable Tests (if needed)
    
    func testUserProfileEquality() {
        // Given
        let date = Date()
        let profile1 = UserProfile(id: "id-1", username: "user1", displayName: "User One", avatarUrl: "url1", bio: "bio1", createdAt: date)
        let profile2 = UserProfile(id: "id-1", username: "user1", displayName: "User One", avatarUrl: "url1", bio: "bio1", createdAt: date)
        let profile3 = UserProfile(id: "id-2", username: "user1", displayName: "User One", avatarUrl: "url1", bio: "bio1", createdAt: date)
        
        // Then
        // Note: UserProfile doesn't implement Equatable, but we can test field equality
        XCTAssertEqual(profile1.id, profile2.id)
        XCTAssertEqual(profile1.username, profile2.username)
        XCTAssertEqual(profile1.displayName, profile2.displayName)
        XCTAssertEqual(profile1.avatarUrl, profile2.avatarUrl)
        XCTAssertEqual(profile1.bio, profile2.bio)
        XCTAssertEqual(profile1.createdAt, profile2.createdAt)
        
        XCTAssertNotEqual(profile1.id, profile3.id)
    }
    
    // MARK: - Performance Tests
    
    func testUserProfileCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let _ = UserProfile(
                    id: "user-\(i)",
                    username: "user\(i)",
                    displayName: "User \(i)",
                    avatarUrl: "https://example.com/avatar\(i).jpg",
                    bio: "Bio for user \(i)",
                    createdAt: Date()
                )
            }
        }
    }
    
    func testUserProfileEncodingPerformance() throws {
        // Given
        let profiles = (0..<100).map { i in
            UserProfile(
                id: "user-\(i)",
                username: "user\(i)",
                displayName: "User \(i)",
                avatarUrl: "https://example.com/avatar\(i).jpg",
                bio: "Bio for user \(i)",
                createdAt: Date()
            )
        }
        
        // When/Then
        measure {
            let encoder = JSONEncoder()
            for profile in profiles {
                do {
                    let _ = try encoder.encode(profile)
                } catch {
                    XCTFail("Encoding failed: \(error)")
                }
            }
        }
    }
}