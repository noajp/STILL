//======================================================================
// MARK: - UserRepository.swift
// Purpose: User data repository with profile management, search functionality, and Supabase integration for user operations (プロフィール管理、検索機能、ユーザー操作のSupabase統合を持つユーザーデータリポジトリ)
// Path: still/Core/Repositories/UserRepository.swift
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
        
        // Fetch directly without task cancellation to avoid -999 errors
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
    
    /// Fetches all posts for a user
    func fetchUserPosts(userId: String) async throws -> [Post] {
        do {
            // First, fetch posts without the relationship
            let posts: [Post] = try await supabaseClient
                .from("posts")
                .select("""
                    id,
                    user_id,
                    media_url,
                    media_type,
                    thumbnail_url,
                    media_width,
                    media_height,
                    caption,
                    location_name,
                    latitude,
                    longitude,
                    is_public,
                    like_count,
                    comment_count,
                    created_at,
                    updated_at
                """)
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
    
    /// Fetches followers count (only accepted follows)
    func fetchFollowersCount(userId: String) async throws -> Int {
        do {
            let response = try await supabaseClient
                .from("follows")
                .select("*", head: true, count: .exact)
                .eq("following_id", value: userId)
                .eq("status", value: "accepted")
                .execute()
            
            return response.count ?? 0
        } catch {
            Logger.shared.error("Failed to fetch followers count: \(error)")
            return 0
        }
    }
    
    /// Fetches following count (only accepted follows)
    func fetchFollowingCount(userId: String) async throws -> Int {
        do {
            let response = try await supabaseClient
                .from("follows")
                .select("*", head: true, count: .exact)
                .eq("follower_id", value: userId)
                .eq("status", value: "accepted")
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
            print("🔍 UserRepository - Starting search for: '\(query)'")
            
            // First try with is_private column
            do {
                let response = try await supabaseClient
                    .from("profiles")
                    .select("id, username, display_name, avatar_url, bio, is_private, followers_count, following_count, created_at, public_key")
                    .ilike("username", pattern: "%\(query)%")
                    .limit(20)
                    .execute()
                
                print("🔍 Raw response status: \(response.status)")
                let responseString = String(data: response.data, encoding: .utf8) ?? "Unable to decode"
                print("🔍 Raw response data: \(responseString)")
                
                // Use custom decoder for date formatting
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                decoder.dateDecodingStrategy = .formatted(formatter)
                
                let profiles: [UserProfile] = try decoder.decode([UserProfile].self, from: response.data)
                
                print("🔍 Search returned \(profiles.count) profiles:")
                for profile in profiles {
                    print("  - \(profile.username) (isPrivate: \(profile.isPrivate ?? false))")
                }
                
                return profiles
            } catch {
                print("⚠️ Search with is_private failed, trying fallback: \(error)")
                
                // Fallback without is_private column
                let response = try await supabaseClient
                    .from("profiles")
                    .select("id, username, display_name, avatar_url, bio, followers_count, following_count, created_at, public_key")
                    .ilike("username", pattern: "%\(query)%")
                    .limit(20)
                    .execute()
                
                print("🔍 Fallback response status: \(response.status)")
                let responseString = String(data: response.data, encoding: .utf8) ?? "Unable to decode"
                print("🔍 Fallback response data: \(responseString)")
                
                // Use custom decoder for date formatting
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                decoder.dateDecodingStrategy = .formatted(formatter)
                
                let profiles: [UserProfile] = try decoder.decode([UserProfile].self, from: response.data)
                
                print("🔍 Fallback search returned \(profiles.count) profiles:")
                for profile in profiles {
                    print("  - \(profile.username) (isPrivate: nil - column missing)")
                }
                
                return profiles
            }
        } catch {
            print("❌ Search error details: \(error)")
            Logger.shared.error("Failed to search users: \(error)")
            throw ViewModelError.network("Failed to search users: \(error.localizedDescription)")
        }
    }
    
    /// DEBUG: Get all profiles for debugging
    func debugGetAllProfiles() async throws -> [UserProfile] {
        do {
            print("🔍 DEBUG - Getting all profiles...")
            
            let response = try await supabaseClient
                .from("profiles")
                .select("id, username, display_name, avatar_url, bio, is_private, followers_count, following_count, created_at, public_key")
                .limit(100)
                .execute()
            
            print("🔍 DEBUG - All profiles response status: \(response.status)")
            let responseString = String(data: response.data, encoding: .utf8) ?? "Unable to decode"
            print("🔍 DEBUG - All profiles data: \(responseString)")
            
            // Use custom decoder for date formatting
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            decoder.dateDecodingStrategy = .formatted(formatter)
            
            let profiles: [UserProfile] = try decoder.decode([UserProfile].self, from: response.data)
            
            print("🔍 DEBUG - Found \(profiles.count) total profiles:")
            for profile in profiles {
                print("  - \(profile.username) (isPrivate: \(profile.isPrivate ?? false))")
            }
            
            return profiles
        } catch {
            print("❌ DEBUG - Get all profiles error: \(error)")
            throw error
        }
    }
}

// Singleton access
extension UserRepository {
    static let shared = UserRepository()
}