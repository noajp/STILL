//======================================================================
// MARK: - UserRepository
// Purpose: Handles all user-related data operations
// Usage: Inject into ViewModels for user data access
//======================================================================
import Foundation
import Supabase

/// Protocol defining user data operations
protocol UserRepositoryProtocol: Sendable {
    func fetchUserProfile(userId: String) async throws -> UserProfile
    func fetchUserPosts(userId: String) async throws -> [Post]
    func updateUserProfile(_ profile: UserProfile) async throws
    func updateProfilePhoto(userId: String, imageData: Data) async throws -> String
    func fetchFollowersCount(userId: String) async throws -> Int
    func fetchFollowingCount(userId: String) async throws -> Int
}

/// Implementation of UserRepository
final class UserRepository: UserRepositoryProtocol, Sendable {
    private let supabaseClient: SupabaseClient
    
    nonisolated init(supabaseClient: SupabaseClient = SupabaseManager.shared.client) {
        self.supabaseClient = supabaseClient
    }
    
    /// Fetches user profile by ID
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        do {
            let profile: UserProfile = try await supabaseClient
                .from("user_profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            return profile
        } catch {
            Logger.shared.error("Failed to fetch user profile: \(error)")
            throw ViewModelError.network("Failed to load profile")
        }
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
            _ = try await supabaseClient
                .from("user_profiles")
                .update(profile)
                .eq("id", value: profile.id)
                .execute()
        } catch {
            Logger.shared.error("Failed to update profile: \(error)")
            throw ViewModelError.serverError("Failed to update profile")
        }
    }
    
    /// Updates profile photo
    func updateProfilePhoto(userId: String, imageData: Data) async throws -> String {
        do {
            let fileName = "\(userId)/avatar_\(UUID().uuidString).jpg"
            
            // Upload to storage
            _ = try await supabaseClient.storage
                .from("avatars")
                .upload(fileName, data: imageData)
            
            // Get public URL
            let publicURL = try supabaseClient.storage
                .from("avatars")
                .getPublicURL(path: fileName)
            
            // Update profile with new URL
            _ = try await supabaseClient
                .from("user_profiles")
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
}