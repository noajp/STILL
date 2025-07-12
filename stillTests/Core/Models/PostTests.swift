//======================================================================
// MARK: - PostTests
// Purpose: Tests for Post model and its business logic
//======================================================================
import XCTest
@testable import tete

final class PostTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testPostInitialization() {
        // Given
        let id = "post-123"
        let userId = "user-456"
        let mediaUrl = "https://example.com/image.jpg"
        let mediaType = Post.MediaType.photo
        let thumbnailUrl = "https://example.com/thumb.jpg"
        let caption = "Test caption"
        let locationName = "Tokyo, Japan"
        let latitude = 35.6762
        let longitude = 139.6503
        let isPublic = true
        let createdAt = Date()
        let likeCount = 42
        let commentCount = 10
        
        // When
        let post = Post(
            id: id,
            userId: userId,
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            thumbnailUrl: thumbnailUrl,
            caption: caption,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            isPublic: isPublic,
            createdAt: createdAt,
            likeCount: likeCount,
            commentCount: commentCount
        )
        
        // Then
        XCTAssertEqual(post.id, id)
        XCTAssertEqual(post.userId, userId)
        XCTAssertEqual(post.mediaUrl, mediaUrl)
        XCTAssertEqual(post.mediaType, mediaType)
        XCTAssertEqual(post.thumbnailUrl, thumbnailUrl)
        XCTAssertEqual(post.caption, caption)
        XCTAssertEqual(post.locationName, locationName)
        XCTAssertEqual(post.latitude, latitude)
        XCTAssertEqual(post.longitude, longitude)
        XCTAssertEqual(post.isPublic, isPublic)
        XCTAssertEqual(post.createdAt, createdAt)
        XCTAssertEqual(post.likeCount, likeCount)
        XCTAssertEqual(post.commentCount, commentCount)
        XCTAssertNil(post.user)
        XCTAssertFalse(post.isLikedByMe)
        XCTAssertFalse(post.isSavedByMe)
    }
    
    func testPostWithOptionalFields() {
        // Given
        let id = "post-123"
        let userId = "user-456"
        let mediaUrl = "https://example.com/image.jpg"
        let mediaType = Post.MediaType.video
        let isPublic = false
        let createdAt = Date()
        let likeCount = 0
        let commentCount = 0
        
        // When
        let post = Post(
            id: id,
            userId: userId,
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            thumbnailUrl: nil,
            caption: nil,
            locationName: nil,
            latitude: nil,
            longitude: nil,
            isPublic: isPublic,
            createdAt: createdAt,
            likeCount: likeCount,
            commentCount: commentCount
        )
        
        // Then
        XCTAssertEqual(post.id, id)
        XCTAssertEqual(post.userId, userId)
        XCTAssertEqual(post.mediaUrl, mediaUrl)
        XCTAssertEqual(post.mediaType, mediaType)
        XCTAssertNil(post.thumbnailUrl)
        XCTAssertNil(post.caption)
        XCTAssertNil(post.locationName)
        XCTAssertNil(post.latitude)
        XCTAssertNil(post.longitude)
        XCTAssertFalse(post.isPublic)
        XCTAssertEqual(post.likeCount, 0)
        XCTAssertEqual(post.commentCount, 0)
    }
    
    // MARK: - MediaType Tests
    
    func testMediaTypeEnum() {
        // Test all media types
        XCTAssertEqual(Post.MediaType.photo.rawValue, "photo")
        XCTAssertEqual(Post.MediaType.video.rawValue, "video")
        
        // Test creation from raw value
        XCTAssertEqual(Post.MediaType(rawValue: "photo"), .photo)
        XCTAssertEqual(Post.MediaType(rawValue: "video"), .video)
        XCTAssertNil(Post.MediaType(rawValue: "invalid"))
    }
    
    // MARK: - Codable Tests
    
    func testPostEncoding() throws {
        // Given
        let post = Post(
            id: "post-123",
            userId: "user-456",
            mediaUrl: "https://example.com/image.jpg",
            mediaType: .photo,
            thumbnailUrl: "https://example.com/thumb.jpg",
            caption: "Test caption",
            locationName: "Tokyo",
            latitude: 35.6762,
            longitude: 139.6503,
            isPublic: true,
            createdAt: Date(timeIntervalSince1970: 1640995200),
            likeCount: 42,
            commentCount: 10
        )
        
        // When
        let data = try JSONEncoder().encode(post)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Then
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["id"] as? String, "post-123")
        XCTAssertEqual(json?["user_id"] as? String, "user-456")
        XCTAssertEqual(json?["media_url"] as? String, "https://example.com/image.jpg")
        XCTAssertEqual(json?["media_type"] as? String, "photo")
        XCTAssertEqual(json?["thumbnail_url"] as? String, "https://example.com/thumb.jpg")
        XCTAssertEqual(json?["caption"] as? String, "Test caption")
        XCTAssertEqual(json?["location_name"] as? String, "Tokyo")
        XCTAssertEqual(json?["latitude"] as? Double, 35.6762)
        XCTAssertEqual(json?["longitude"] as? Double, 139.6503)
        XCTAssertEqual(json?["is_public"] as? Bool, true)
        XCTAssertEqual(json?["like_count"] as? Int, 42)
        XCTAssertEqual(json?["comment_count"] as? Int, 10)
        XCTAssertNotNil(json?["created_at"])
    }
    
    func testPostDecoding() throws {
        // Given
        let json = """
        {
            "id": "post-123",
            "user_id": "user-456",
            "media_url": "https://example.com/image.jpg",
            "media_type": "video",
            "thumbnail_url": "https://example.com/thumb.jpg",
            "caption": "Test caption",
            "location_name": "Tokyo",
            "latitude": 35.6762,
            "longitude": 139.6503,
            "is_public": true,
            "like_count": 42,
            "comment_count": 10,
            "created_at": "2022-01-01T00:00:00Z"
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let post = try decoder.decode(Post.self, from: data)
        
        // Then
        XCTAssertEqual(post.id, "post-123")
        XCTAssertEqual(post.userId, "user-456")
        XCTAssertEqual(post.mediaUrl, "https://example.com/image.jpg")
        XCTAssertEqual(post.mediaType, .video)
        XCTAssertEqual(post.thumbnailUrl, "https://example.com/thumb.jpg")
        XCTAssertEqual(post.caption, "Test caption")
        XCTAssertEqual(post.locationName, "Tokyo")
        XCTAssertEqual(post.latitude, 35.6762)
        XCTAssertEqual(post.longitude, 139.6503)
        XCTAssertTrue(post.isPublic)
        XCTAssertEqual(post.likeCount, 42)
        XCTAssertEqual(post.commentCount, 10)
        XCTAssertNotNil(post.createdAt)
    }
    
    func testPostDecodingWithMissingOptionalFields() throws {
        // Given
        let json = """
        {
            "id": "post-123",
            "user_id": "user-456",
            "media_url": "https://example.com/image.jpg",
            "media_type": "photo",
            "is_public": true,
            "like_count": 0,
            "comment_count": 0,
            "created_at": "2022-01-01T00:00:00Z"
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let post = try decoder.decode(Post.self, from: data)
        
        // Then
        XCTAssertEqual(post.id, "post-123")
        XCTAssertEqual(post.userId, "user-456")
        XCTAssertEqual(post.mediaType, .photo)
        XCTAssertNil(post.thumbnailUrl)
        XCTAssertNil(post.caption)
        XCTAssertNil(post.locationName)
        XCTAssertNil(post.latitude)
        XCTAssertNil(post.longitude)
    }
    
    func testPostDecodingWithInvalidMediaType() {
        // Given
        let json = """
        {
            "id": "post-123",
            "user_id": "user-456",
            "media_url": "https://example.com/image.jpg",
            "media_type": "invalid_type",
            "is_public": true,
            "like_count": 0,
            "comment_count": 0,
            "created_at": "2022-01-01T00:00:00Z"
        }
        """
        
        // When/Then
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        XCTAssertThrowsError(try decoder.decode(Post.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - Identifiable Tests
    
    func testPostIdentifiable() {
        // Given
        let post1 = TestUtilities.createTestPost(id: "post-1")
        let post2 = TestUtilities.createTestPost(id: "post-2")
        let post3 = TestUtilities.createTestPost(id: "post-1")
        
        // Then
        XCTAssertEqual(post1.id, "post-1")
        XCTAssertEqual(post2.id, "post-2")
        XCTAssertEqual(post3.id, "post-1")
        
        // Same ID should be equal for Identifiable protocol
        XCTAssertEqual(post1.id, post3.id)
        XCTAssertNotEqual(post1.id, post2.id)
    }
    
    // MARK: - Business Logic Tests
    
    func testLikeCountManipulation() {
        // Given
        var post = TestUtilities.createTestPost(likeCount: 10)
        
        // When - Simulate like operations
        post.likeCount += 1
        XCTAssertEqual(post.likeCount, 11)
        
        post.likeCount -= 1
        XCTAssertEqual(post.likeCount, 10)
        
        // Test boundary condition
        post.likeCount = 0
        post.likeCount = max(0, post.likeCount - 1)
        XCTAssertEqual(post.likeCount, 0) // Should not go below 0
    }
    
    func testLikeStatusManagement() {
        // Given
        var post = TestUtilities.createTestPost()
        XCTAssertFalse(post.isLikedByMe)
        
        // When
        post.isLikedByMe = true
        XCTAssertTrue(post.isLikedByMe)
        
        post.isLikedByMe = false
        XCTAssertFalse(post.isLikedByMe)
    }
    
    func testSaveStatusManagement() {
        // Given
        var post = TestUtilities.createTestPost()
        XCTAssertFalse(post.isSavedByMe)
        
        // When
        post.isSavedByMe = true
        XCTAssertTrue(post.isSavedByMe)
        
        post.isSavedByMe = false
        XCTAssertFalse(post.isSavedByMe)
    }
    
    func testLocationHandling() {
        // Test post with location
        let postWithLocation = Post(
            id: "post-1",
            userId: "user-1",
            mediaUrl: "https://example.com/image.jpg",
            mediaType: .photo,
            thumbnailUrl: nil,
            caption: nil,
            locationName: "Tokyo Tower",
            latitude: 35.6586,
            longitude: 139.7454,
            isPublic: true,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0
        )
        
        XCTAssertEqual(postWithLocation.locationName, "Tokyo Tower")
        XCTAssertEqual(postWithLocation.latitude, 35.6586)
        XCTAssertEqual(postWithLocation.longitude, 139.7454)
        
        // Test post without location
        let postWithoutLocation = Post(
            id: "post-2",
            userId: "user-1",
            mediaUrl: "https://example.com/image.jpg",
            mediaType: .photo,
            thumbnailUrl: nil,
            caption: nil,
            locationName: nil,
            latitude: nil,
            longitude: nil,
            isPublic: true,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0
        )
        
        XCTAssertNil(postWithoutLocation.locationName)
        XCTAssertNil(postWithoutLocation.latitude)
        XCTAssertNil(postWithoutLocation.longitude)
    }
    
    func testPrivacySettings() {
        // Test public post
        let publicPost = TestUtilities.createTestPost()
        XCTAssertTrue(publicPost.isPublic)
        
        // Test private post
        let privatePost = Post(
            id: "post-1",
            userId: "user-1",
            mediaUrl: "https://example.com/image.jpg",
            mediaType: .photo,
            thumbnailUrl: nil,
            caption: nil,
            locationName: nil,
            latitude: nil,
            longitude: nil,
            isPublic: false,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0
        )
        
        XCTAssertFalse(privatePost.isPublic)
    }
    
    func testCaptionHandling() {
        // Test post with caption
        let postWithCaption = TestUtilities.createTestPost(caption: "Beautiful sunset! 🌅")
        XCTAssertEqual(postWithCaption.caption, "Beautiful sunset! 🌅")
        
        // Test post without caption
        let postWithoutCaption = TestUtilities.createTestPost(caption: nil)
        XCTAssertNil(postWithoutCaption.caption)
        
        // Test post with empty caption
        let postWithEmptyCaption = TestUtilities.createTestPost(caption: "")
        XCTAssertEqual(postWithEmptyCaption.caption, "")
        
        // Test post with long caption
        let longCaption = String(repeating: "This is a long caption. ", count: 100)
        let postWithLongCaption = TestUtilities.createTestPost(caption: longCaption)
        XCTAssertEqual(postWithLongCaption.caption, longCaption)
    }
    
    func testUserRelationship() {
        // Given
        var post = TestUtilities.createTestPost()
        let user = TestUtilities.createTestUserProfile()
        
        // When
        post.user = user
        
        // Then
        XCTAssertNotNil(post.user)
        XCTAssertEqual(post.user?.id, user.id)
        XCTAssertEqual(post.user?.username, user.username)
    }
    
    // MARK: - Edge Cases Tests
    
    func testNegativeCounts() {
        // Test that counts don't go negative in real usage
        var post = TestUtilities.createTestPost(likeCount: 0, commentCount: 0)
        
        // Simulate defensive programming
        post.likeCount = max(0, post.likeCount - 1)
        XCTAssertEqual(post.likeCount, 0)
        
        // Note: commentCount is let, so can't be modified after initialization
        XCTAssertEqual(post.commentCount, 0)
    }
    
    func testExtremeValues() {
        // Test with extreme values
        let extremePost = Post(
            id: "post-extreme",
            userId: "user-extreme",
            mediaUrl: "https://example.com/image.jpg",
            mediaType: .photo,
            thumbnailUrl: nil,
            caption: nil,
            locationName: nil,
            latitude: 90.0,  // Max latitude
            longitude: 180.0, // Max longitude
            isPublic: true,
            createdAt: Date(),
            likeCount: Int.max,
            commentCount: Int.max
        )
        
        XCTAssertEqual(extremePost.latitude, 90.0)
        XCTAssertEqual(extremePost.longitude, 180.0)
        XCTAssertEqual(extremePost.likeCount, Int.max)
        XCTAssertEqual(extremePost.commentCount, Int.max)
    }
    
    // MARK: - Performance Tests
    
    func testPostCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let _ = TestUtilities.createTestPost(
                    id: "post-\(i)",
                    caption: "Caption \(i)",
                    likeCount: i,
                    commentCount: i % 10
                )
            }
        }
    }
    
    func testPostEncodingPerformance() throws {
        // Given
        let posts = (0..<100).map { i in
            TestUtilities.createTestPost(
                id: "post-\(i)",
                caption: "Caption \(i)",
                likeCount: i,
                commentCount: i % 10
            )
        }
        
        // When/Then
        measure {
            let encoder = JSONEncoder()
            for post in posts {
                do {
                    let _ = try encoder.encode(post)
                } catch {
                    XCTFail("Encoding failed: \(error)")
                }
            }
        }
    }
}