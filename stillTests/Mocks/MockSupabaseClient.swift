//======================================================================
// MARK: - MockSupabaseClient
// Purpose: Mock implementation for testing Supabase client interactions
//======================================================================
import Foundation
@testable import tete

/// Mock implementation of Supabase client for testing
final class MockSupabaseClient {
    
    // MARK: - Mock Data Storage
    private var userProfiles: [String: UserProfile] = [:]
    private var userPosts: [String: [Post]] = [:]
    private var followersCount: [String: Int] = [:]
    private var followingCount: [String: Int] = [:]
    
    // MARK: - Call Tracking
    struct SelectCall {
        let table: String
        let query: String
        let filters: [String: Any]
    }
    
    struct UpdateCall {
        let table: String
        let data: [String: Any]
        let filters: [String: Any]
    }
    
    struct UploadCall {
        let bucket: String
        let fileName: String
        let data: Data
    }
    
    var selectCalls: [SelectCall] = []
    var updateCalls: [UpdateCall] = []
    var uploadCalls: [UploadCall] = []
    
    // MARK: - Error Simulation
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockSupabase", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    // MARK: - Storage Mock
    private var storageUploadSuccess = false
    private var storagePublicUrl = "https://example.com/storage/default.jpg"
    
    // MARK: - Test Setup Methods
    
    func setupUserProfile(_ profile: UserProfile) {
        userProfiles[profile.id] = profile
    }
    
    func setupUserPosts(_ userId: String, posts: [Post]) {
        userPosts[userId] = posts
    }
    
    func setupFollowersCount(userId: String, count: Int) {
        followersCount[userId] = count
    }
    
    func setupFollowingCount(userId: String, count: Int) {
        followingCount[userId] = count
    }
    
    func setupStorageUploadSuccess(publicUrl: String) {
        storageUploadSuccess = true
        storagePublicUrl = publicUrl
    }
    
    func reset() {
        userProfiles.removeAll()
        userPosts.removeAll()
        followersCount.removeAll()
        followingCount.removeAll()
        
        selectCalls.removeAll()
        updateCalls.removeAll()
        uploadCalls.removeAll()
        
        shouldThrowError = false
        storageUploadSuccess = false
        storagePublicUrl = "https://example.com/storage/default.jpg"
    }
}

// MARK: - Mock Query Builder

class MockQueryBuilder {
    private let client: MockSupabaseClient
    private let table: String
    private var query: String = "*"
    private var filters: [String: Any] = [:]
    private var isCountQuery = false
    
    init(client: MockSupabaseClient, table: String) {
        self.client = client
        self.table = table
    }
    
    func select(_ query: String = "*", head: Bool = false, count: CountType? = nil) -> MockQueryBuilder {
        self.query = query
        if count != nil {
            self.isCountQuery = true
        }
        return self
    }
    
    func eq(_ column: String, value: Any) -> MockQueryBuilder {
        filters[column] = value
        return self
    }
    
    func order(_ column: String, ascending: Bool = true) -> MockQueryBuilder {
        // Mock implementation - just return self
        return self
    }
    
    func single() -> MockQueryBuilder {
        // Mock implementation - just return self
        return self
    }
    
    func execute() async throws -> MockResponse {
        // Record the call
        client.selectCalls.append(SelectCall(table: table, query: query, filters: filters))
        
        if client.shouldThrowError {
            throw client.errorToThrow
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        if isCountQuery {
            let count = getCountForTable()
            return MockResponse(value: [], count: count)
        }
        
        return MockResponse(value: getDataForTable(), count: nil)
    }
    
    private func getDataForTable() -> Any {
        switch table {
        case "user_profiles":
            if let userId = filters["id"] as? String {
                guard let profile = client.userProfiles[userId] else {
                    // This would normally throw a not found error
                    return UserProfile(id: userId, username: "not_found", displayName: nil, avatarUrl: nil, bio: nil, createdAt: nil)
                }
                return profile
            }
            return Array(client.userProfiles.values)
            
        case "posts":
            if let userId = filters["user_id"] as? String {
                return client.userPosts[userId] ?? []
            }
            return client.userPosts.values.flatMap { $0 }
            
        case "follows":
            // Mock follows data
            return []
            
        default:
            return []
        }
    }
    
    private func getCountForTable() -> Int {
        switch table {
        case "follows":
            if let followingId = filters["following_id"] as? String {
                return client.followersCount[followingId] ?? 0
            }
            if let followerId = filters["follower_id"] as? String {
                return client.followingCount[followerId] ?? 0
            }
            return 0
        default:
            return 0
        }
    }
}

// MARK: - Mock Update Builder

class MockUpdateBuilder {
    private let client: MockSupabaseClient
    private let table: String
    private let data: [String: Any]
    private var filters: [String: Any] = [:]
    
    init(client: MockSupabaseClient, table: String, data: Any) {
        self.client = client
        self.table = table
        
        // Convert data to dictionary
        if let profile = data as? UserProfile {
            self.data = [
                "id": profile.id,
                "username": profile.username,
                "display_name": profile.displayName as Any,
                "avatar_url": profile.avatarUrl as Any,
                "bio": profile.bio as Any,
                "created_at": profile.createdAt as Any
            ]
        } else if let dict = data as? [String: Any] {
            self.data = dict
        } else {
            self.data = [:]
        }
    }
    
    func eq(_ column: String, value: Any) -> MockUpdateBuilder {
        filters[column] = value
        return self
    }
    
    func execute() async throws -> MockResponse {
        // Record the call
        client.updateCalls.append(UpdateCall(table: table, data: data, filters: filters))
        
        if client.shouldThrowError {
            throw client.errorToThrow
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        // Update the data in memory
        if table == "user_profiles", let userId = filters["id"] as? String {
            // Update user profile in memory
            if var existingProfile = client.userProfiles[userId] {
                if let username = data["username"] as? String {
                    existingProfile.username = username
                }
                if let displayName = data["display_name"] as? String {
                    existingProfile.displayName = displayName
                }
                if let bio = data["bio"] as? String {
                    existingProfile.bio = bio
                }
                if let avatarUrl = data["avatar_url"] as? String {
                    existingProfile.avatarUrl = avatarUrl
                }
                client.userProfiles[userId] = existingProfile
            }
        }
        
        return MockResponse(value: [], count: nil)
    }
}

// MARK: - Mock Storage

class MockStorage {
    private let client: MockSupabaseClient
    
    init(client: MockSupabaseClient) {
        self.client = client
    }
    
    func from(_ bucket: String) -> MockStorageBucket {
        return MockStorageBucket(client: client, bucket: bucket)
    }
}

class MockStorageBucket {
    private let client: MockSupabaseClient
    private let bucket: String
    
    init(client: MockSupabaseClient, bucket: String) {
        self.client = client
        self.bucket = bucket
    }
    
    func upload(_ fileName: String, data: Data) async throws -> MockUploadResponse {
        // Record the call
        client.uploadCalls.append(UploadCall(bucket: bucket, fileName: fileName, data: data))
        
        if client.shouldThrowError {
            throw client.errorToThrow
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        return MockUploadResponse(path: fileName)
    }
    
    func getPublicURL(path: String) throws -> URL {
        if client.shouldThrowError {
            throw client.errorToThrow
        }
        
        guard let url = URL(string: client.storagePublicUrl) else {
            throw NSError(domain: "MockStorage", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        return url
    }
}

// MARK: - Mock Response Types

struct MockResponse {
    let value: Any
    let count: Int?
}

struct MockUploadResponse {
    let path: String
}

enum CountType {
    case exact
    case planned
    case estimated
}

// MARK: - MockSupabaseClient Extensions

extension MockSupabaseClient {
    func from(_ table: String) -> MockQueryBuilder {
        return MockQueryBuilder(client: self, table: table)
    }
    
    var storage: MockStorage {
        return MockStorage(client: self)
    }
}

extension MockQueryBuilder {
    func update<T: Encodable>(_ data: T) -> MockUpdateBuilder {
        return MockUpdateBuilder(client: client, table: table, data: data)
    }
    
    func update(_ data: [String: Any]) -> MockUpdateBuilder {
        return MockUpdateBuilder(client: client, table: table, data: data)
    }
}