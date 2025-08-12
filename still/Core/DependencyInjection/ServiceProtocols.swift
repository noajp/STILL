//======================================================================
// MARK: - ServiceProtocols.swift
// Purpose: Protocol definitions for all injectable services
// Path: still/Core/DependencyInjection/ServiceProtocols.swift
//======================================================================

import Foundation
import Supabase
import CoreLocation
import UIKit

// MARK: - Core Service Protocols

/**
 * Protocol for authentication management
 */
@MainActor
protocol AuthManagerProtocol {
    var currentUser: AppUser? { get }
    var isAuthenticated: Bool { get }
    func signIn(email: String, password: String) async throws -> AppUser
    func signUp(email: String, password: String, username: String) async throws -> AppUser
    func signOut() async throws
    func refreshSession() async throws
}

/**
 * Protocol for Supabase client management
 */
@MainActor
protocol SupabaseManagerProtocol {
    var client: SupabaseClient { get }
    func configure()
    func resetSession() async throws
}

/**
 * Protocol for post status management
 */
@MainActor
protocol PostStatusManagerProtocol {
    func markAsViewed(postId: String) async
    func markAsLiked(postId: String) async throws
    func removeLike(postId: String) async throws
    func getPostStatus(postId: String) -> PostStatus?
    func syncWithServer() async throws
}

/**
 * Protocol for image cache management
 */
@MainActor
protocol ImageCacheManagerProtocol {
    func cache(image: UIImage, forKey key: String)
    func image(forKey key: String) -> UIImage?
    func removeImage(forKey key: String)
    func clearCache()
    func clearMemoryCache()
    func clearDiskCache() async
}

/**
 * Protocol for logging service
 */
protocol LoggerProtocol {
    func debug(_ message: String, file: String, function: String, line: Int)
    func info(_ message: String, file: String, function: String, line: Int)
    func warning(_ message: String, file: String, function: String, line: Int)
    func error(_ message: String, file: String, function: String, line: Int)
}

/**
 * Protocol for notification service
 */
@MainActor
protocol NotificationServiceProtocol {
    func requestAuthorization() async throws -> Bool
    func registerForPushNotifications() async throws
    func handleNotification(_ notification: [AnyHashable: Any]) async
    func setBadgeCount(_ count: Int) async
}

// MARK: - Data Service Protocols

// UserRepositoryProtocol is defined in Core/Repositories/UserRepository.swift

/**
 * Protocol for article repository
 */

/**
 * Protocol for comment service
 */
@MainActor
protocol CommentServiceProtocol {
    func fetchComments(postId: String) async throws -> [Comment]
    func addComment(postId: String, content: String) async throws -> Comment
    func deleteComment(id: String) async throws
    func likeComment(id: String) async throws
    func unlikeComment(id: String) async throws
}

/**
 * Protocol for follow service
 */
@MainActor
protocol FollowServiceProtocol {
    func follow(userId: String) async throws
    func unfollow(userId: String) async throws
    func getFollowers(userId: String) async throws -> [AppUser]
    func getFollowing(userId: String) async throws -> [AppUser]
    func isFollowing(userId: String) async throws -> Bool
    func getFollowRequests() async throws -> [FollowRequest]
    func approveFollowRequest(requestId: String) async throws
    func rejectFollowRequest(requestId: String) async throws
}

/**
 * Protocol for message service
 */
@MainActor
protocol MessageServiceProtocol {
    func fetchConversations() async throws -> [Conversation]
    func fetchMessages(conversationId: String) async throws -> [Message]
    func sendMessage(conversationId: String, content: String) async throws -> Message
    func markAsRead(messageId: String) async throws
    func deleteMessage(messageId: String) async throws
    func createConversation(with userIds: [String]) async throws -> Conversation
}

// MARK: - Image Processing Protocols

/**
 * Protocol for unified image processor
 */
@MainActor
protocol UnifiedImageProcessorProtocol {
    func processImage(_ image: UIImage, with settings: ProcessingSettings) async throws -> UIImage
    func applyFilter(_ filter: ImageFilter, to image: UIImage) async throws -> UIImage
    func resizeImage(_ image: UIImage, to size: CGSize) async throws -> UIImage
    func generateThumbnail(from image: UIImage, size: CGSize) async throws -> UIImage
}

/**
 * Protocol for Core Image manager
 */
@MainActor
protocol CoreImageManagerProtocol {
    func applyFilter(named filterName: String, to image: CIImage, parameters: [String: Any]) -> CIImage?
    func availableFilters() -> [String]
    func renderImage(_ ciImage: CIImage) -> UIImage?
}

/**
 * Protocol for RAW image processor
 */
@MainActor
protocol RAWImageProcessorProtocol {
    func processRAWImage(from data: Data) async throws -> UIImage
    func extractMetadata(from data: Data) async throws -> RAWImageInfo
    func supportsFormat(_ format: String) -> Bool
}

// MARK: - Security Service Protocols

/**
 * Protocol for keychain manager
 */
protocol KeychainManagerProtocol {
    func save(key: String, value: String) throws
    func retrieve(key: String) throws -> String?
    func delete(key: String) throws
    func clear() throws
}

/**
 * Protocol for cryptography manager
 */
protocol CryptoManagerProtocol {
    func encrypt(data: Data, withKey key: String) throws -> Data
    func decrypt(data: Data, withKey key: String) throws -> Data
    func generateKey() -> String
    func hash(data: Data) -> String
}

// MARK: - Location Service Protocols

/**
 * Protocol for location manager
 */
@MainActor
protocol LocationManagerProtocol {
    var currentLocation: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    
    func requestAuthorization() async
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func reverseGeocode(location: CLLocation) async throws -> String?
}

/**
 * Protocol for restaurant search service
 */
@MainActor
protocol RestaurantSearchServiceProtocol {
    func searchNearby(location: CLLocation, radius: Double) async throws -> [Restaurant]
    func search(query: String, near location: CLLocation) async throws -> [Restaurant]
    func getDetails(restaurantId: String) async throws -> Restaurant
}

// MARK: - Real-time Service Protocols

/**
 * Protocol for realtime subscription manager
 */
@MainActor
protocol RealtimeSubscriptionManagerProtocol {
    func subscribe(to channel: String, onMessage: @escaping (Any) -> Void) -> String
    func unsubscribe(subscriptionId: String)
    func unsubscribeAll()
    func isConnected() -> Bool
}

/**
 * Protocol for conversation manager
 */
@MainActor
protocol ConversationManagerProtocol {
    func loadConversation(id: String) async throws -> Conversation
    func createConversation(with userIds: [String]) async throws -> Conversation
    func updateConversation(_ conversation: Conversation) async throws
    func deleteConversation(id: String) async throws
    func markAsRead(conversationId: String) async throws
}

/**
 * Protocol for message service coordinator
 */
@MainActor
protocol MessageServiceCoordinatorProtocol {
    func startListening()
    func stopListening()
    func sendMessage(_ message: Message) async throws
    func handleIncomingMessage(_ message: Message) async
    func syncMessages() async throws
}

// MARK: - Supporting Types

/**
 * Post status information
 */
struct PostStatus {
    let postId: String
    let isViewed: Bool
    let isLiked: Bool
    let viewedAt: Date?
    let likedAt: Date?
}

/**
 * Image processing settings
 */
struct ProcessingSettings {
    let brightness: Float
    let contrast: Float
    let saturation: Float
    let filters: [ImageFilter]
}

/**
 * Image filter definition
 */
struct ImageFilter {
    let name: String
    let parameters: [String: Any]
}

/**
 * Restaurant model
 */
struct Restaurant {
    let id: String
    let name: String
    let location: CLLocation
    let address: String
    let rating: Double?
    let priceLevel: Int?
}

/**
 * Follow request model
 */
struct FollowRequest: Identifiable, Codable {
    let id: String
    let follower_id: String  // Changed from fromUserId
    let following_id: String  // Changed from toUserId
    let created_at: Date  // Changed from createdAt
    let status: String
    
    // Optional profile information
    var followerProfile: UserProfile?
    
    // Compatibility properties
    var fromUserId: String { follower_id }
    var toUserId: String { following_id }
    var createdAt: Date { created_at }
}