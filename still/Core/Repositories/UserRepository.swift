//======================================================================
// MARK: - UserRepository
// Purpose: Handles all user-related data operations
// Usage: Inject into ViewModels for user data access
//======================================================================
import Foundation
import Supabase

/// Actor for managing mutable state in UserRepository
actor UserRepositoryActor {
    private var currentProfileTask: Task<UserProfile, Error>?
    private var profileCache: [String: (profile: UserProfile, timestamp: Date)] = [:]
    private let cacheExpiry: TimeInterval = 300 // 5 minutes
    
    func getCachedProfile(userId: String) -> UserProfile? {
        if let cached = profileCache[userId],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiry {
            return cached.profile
        }
        return nil
    }
    
    func cacheProfile(_ profile: UserProfile, userId: String) {
        profileCache[userId] = (profile: profile, timestamp: Date())
    }
    
    func cancelCurrentTask() {
        currentProfileTask?.cancel()
    }
    
    func setCurrentTask(_ task: Task<UserProfile, Error>) {
        currentProfileTask = task
    }
}

/// Protocol defining user data operations
protocol UserRepositoryProtocol: Sendable {
    func fetchUserProfile(userId: String) async throws -> UserProfile
    func fetchUserPosts(userId: String) async throws -> [Post]
    func updateUserProfile(_ profile: UserProfile) async throws
    func updateProfilePhoto(userId: String, imageData: Data) async throws -> String
    func fetchFollowersCount(userId: String) async throws -> Int
    func fetchFollowingCount(userId: String) async throws -> Int
    func searchUsersByUsername(_ query: String) async throws -> [UserProfile]
}

/// Implementation of UserRepository
final class UserRepository: UserRepositoryProtocol, Sendable {
    private let supabaseClient: SupabaseClient
    private let actor = UserRepositoryActor()
    
    nonisolated init(supabaseClient: SupabaseClient = SupabaseManager.shared.client) {
        self.supabaseClient = supabaseClient
    }
    
    /// Fetches user profile by ID with caching and deduplication
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        // Check cache first
        if let cachedProfile = await actor.getCachedProfile(userId: userId) {
            return cachedProfile
        }
        
        // Cancel previous task if exists
        await actor.cancelCurrentTask()
        
        // Create new task
        let task = Task {
            do {
                let profile: UserProfile = try await supabaseClient
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                
                // Cache the result
                await actor.cacheProfile(profile, userId: userId)
                return profile
            } catch {
                Logger.shared.error("Failed to fetch user profile: \(error)")
                throw ViewModelError.network("Failed to load profile")
            }
        }
        
        await actor.setCurrentTask(task)
        return try await task.value
    }
    
    /// Fetches all posts for a user
    func fetchUserPosts(userId: String) async throws -> [Post] {
        do {
            // First, fetch posts without the relationship
            let posts: [Post] = try await supabaseClient
                .from("posts")
                .select("*")
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // Then fetch the user profile separately if needed
            if !posts.isEmpty {
                let userProfile = try await fetchUserProfile(userId: userId)
                
                // Manually attach user profile to posts
                return posts.map { post in
                    var updatedPost = post
                    updatedPost.user = userProfile
                    return updatedPost
                }
            }
            
            return posts
        } catch {
            Logger.shared.error("Failed to fetch user posts: \(error)")
            throw ViewModelError.network("Failed to load posts")
        }
    }
    
    /// Updates user profile
    func updateUserProfile(_ profile: UserProfile) async throws {
        do {
            let response = try await supabaseClient
                .from("profiles")
                .update(profile)
                .eq("id", value: profile.id)
                .execute()
            
            // Verify the update actually happened
            if response.count == 0 {
                Logger.shared.error("Profile update failed - no rows affected")
                throw ViewModelError.serverError("Profile update failed - no rows affected")
            }
            
            Logger.shared.info("Profile updated successfully for user: \(profile.id)")
        } catch {
            Logger.shared.error("Failed to update profile: \(error)")
            if let postgrestError = error as? PostgrestError {
                Logger.shared.error("Supabase error code: \(postgrestError.code ?? "unknown")")
                Logger.shared.error("Supabase error message: \(postgrestError.message)")
            }
            throw ViewModelError.serverError("Failed to update profile")
        }
    }
    
    /// Updates profile photo
    func updateProfilePhoto(userId: String, imageData: Data) async throws -> String {
        do {
            let fileName = "\(userId)/avatar_\(UUID().uuidString).jpg"
            
            // Upload to storage
            _ = try await supabaseClient.storage
                .from("user-uploads")
                .upload(fileName, data: imageData)
            
            // Get public URL
            let publicURL = try supabaseClient.storage
                .from("user-uploads")
                .getPublicURL(path: fileName)
            
            // Update profile with new URL
            _ = try await supabaseClient
                .from("profiles")
                .update(["avatar_url": publicURL.absoluteString])
                .eq("id", value: userId)
                .execute()
            
            return publicURL.absoluteString
        } catch {
            Logger.shared.error("Failed to update profile photo: \(error)")
            throw ViewModelError.fileSystem("Failed to upload photo")
        }
    }
    
    /// Fetches followers count
    func fetchFollowersCount(userId: String) async throws -> Int {
        do {
            let response = try await supabaseClient
                .from("follows")
                .select("*", head: true, count: .exact)
                .eq("following_id", value: userId)
                .execute()
            
            return response.count ?? 0
        } catch {
            Logger.shared.error("Failed to fetch followers count: \(error)")
            return 0
        }
    }
    
    /// Fetches following count
    func fetchFollowingCount(userId: String) async throws -> Int {
        do {
            let response = try await supabaseClient
                .from("follows")
                .select("*", head: true, count: .exact)
                .eq("follower_id", value: userId)
                .execute()
            
            return response.count ?? 0
        } catch {
            Logger.shared.error("Failed to fetch following count: \(error)")
            return 0
        }
    }
    
    /// Searches users by username
    func searchUsersByUsername(_ query: String) async throws -> [UserProfile] {
        do {
            let profiles: [UserProfile] = try await supabaseClient
                .from("profiles")
                .select()
                .ilike("username", pattern: "%\(query)%")
                .limit(20)
                .execute()
                .value
            
            return profiles
        } catch {
            Logger.shared.error("Failed to search users: \(error)")
            throw ViewModelError.network("Failed to search users")
        }
    }
}

// Singleton access
extension UserRepository {
    static let shared = UserRepository()
}