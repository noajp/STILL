//======================================================================
// MARK: - ServiceAdapters.swift
// Purpose: Adapter classes that wrap existing singleton services to conform to protocols
// Path: still/Core/DependencyInjection/ServiceAdapters.swift
//======================================================================

import Foundation
import Supabase
import CoreLocation
import UIKit

// MARK: - Auth Manager Adapter

@MainActor
final class AuthManagerAdapter: AuthManagerProtocol {
    var currentUser: AppUser? {
        return AuthManager.shared.currentUser
    }
    
    var isAuthenticated: Bool {
        return AuthManager.shared.isAuthenticated
    }
    
    func signIn(email: String, password: String) async throws -> AppUser {
        return try await AuthManager.shared.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String, username: String) async throws -> AppUser {
        return try await AuthManager.shared.signUp(email: email, password: password, username: username)
    }
    
    func signOut() async throws {
        try await AuthManager.shared.signOut()
    }
    
    func refreshSession() async throws {
        try await AuthManager.shared.refreshSession()
    }
}

// MARK: - Supabase Manager Adapter

@MainActor
final class SupabaseManagerAdapter: SupabaseManagerProtocol {
    var client: SupabaseClient {
        return SupabaseManager.shared.client
    }
    
    func configure() {
        // Call any configuration methods if they exist
    }
    
    func resetSession() async throws {
        // Implement session reset logic
        try await client.auth.signOut()
    }
}

// MARK: - Post Status Manager Adapter

@MainActor
final class PostStatusManagerAdapter: PostStatusManagerProtocol {
    private let manager = PostStatusManager.shared
    
    func markAsViewed(postId: String) async {
        // Stub implementation - PostStatusManager doesn't have this method
    }
    
    func markAsLiked(postId: String) async throws {
        // Implement like functionality
        // This might need to be added to the actual PostStatusManager
    }
    
    func removeLike(postId: String) async throws {
        // Implement unlike functionality
    }
    
    func getPostStatus(postId: String) -> PostStatus? {
        // Return post status information
        return nil // Placeholder
    }
    
    func syncWithServer() async throws {
        // Implement sync logic
    }
}

// MARK: - Image Cache Manager Adapter

@MainActor
final class ImageCacheManagerAdapter: ImageCacheManagerProtocol {
    private let manager = ImageCacheManager.shared
    
    func cache(image: UIImage, forKey key: String) {
        manager.cache.setObject(image, forKey: key as NSString)
    }
    
    func image(forKey key: String) -> UIImage? {
        return manager.cache.object(forKey: key as NSString)
    }
    
    func removeImage(forKey key: String) {
        manager.cache.removeObject(forKey: key as NSString)
    }
    
    func clearCache() {
        manager.clearCache()
    }
    
    func clearMemoryCache() {
        manager.cache.removeAllObjects()
    }
    
    func clearDiskCache() async {
        // Stub implementation - NSCache doesn't have disk cache
    }
}

// MARK: - Logger Adapter

final class LoggerAdapter: LoggerProtocol {
    private let logger = Logger.shared
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.debug(message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.info(message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.warning(message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.error(message, file: file, function: function, line: line)
    }
}

// MARK: - Notification Service Adapter

@MainActor
final class NotificationServiceAdapter: NotificationServiceProtocol {
    private let service = NotificationService.shared
    
    func requestAuthorization() async throws -> Bool {
        // Stub implementation - method doesn't exist
        return false
    }
    
    func registerForPushNotifications() async throws {
        // Stub implementation - method doesn't exist
    }
    
    func handleNotification(_ notification: [AnyHashable: Any]) async {
        // Stub implementation - method doesn't exist
    }
    
    func setBadgeCount(_ count: Int) async {
        // Stub implementation - method doesn't exist
    }
}

// MARK: - User Repository Adapter

@MainActor
final class UserRepositoryAdapter: UserRepositoryProtocol {
    private let repository = UserRepository.shared
    
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        return try await repository.fetchUserProfile(userId: userId)
    }
    
    func fetchUserPosts(userId: String) async throws -> [Post] {
        return try await repository.fetchUserPosts(userId: userId)
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        try await repository.updateUserProfile(profile)
    }
    
    func updateProfilePhoto(userId: String, imageData: Data) async throws -> String {
        return try await repository.updateProfilePhoto(userId: userId, imageData: imageData)
    }
    
    func fetchFollowersCount(userId: String) async throws -> Int {
        return try await repository.fetchFollowersCount(userId: userId)
    }
    
    func fetchFollowingCount(userId: String) async throws -> Int {
        return try await repository.fetchFollowingCount(userId: userId)
    }
    
    func searchUsersByUsername(_ query: String) async throws -> [UserProfile] {
        return try await repository.searchUsersByUsername(query)
    }
}


// MARK: - Comment Service Adapter

@MainActor
final class CommentServiceAdapter: CommentServiceProtocol {
    private let service = CommentService.shared
    
    func fetchComments(postId: String) async throws -> [Comment] {
        return try await service.fetchComments(for: postId)
    }
    
    func addComment(postId: String, content: String) async throws -> Comment {
        // Stub implementation - method doesn't exist
        throw NSError(domain: "CommentService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func deleteComment(id: String) async throws {
        try await service.deleteComment(commentId: id)
    }
    
    func likeComment(id: String) async throws {
        // Stub implementation - method doesn't exist
    }
    
    func unlikeComment(id: String) async throws {
        // Stub implementation - method doesn't exist
    }
}

// MARK: - Follow Service Adapter

@MainActor
final class FollowServiceAdapter: FollowServiceProtocol {
    private let service = FollowService.shared
    
    func follow(userId: String) async throws {
        try await service.followUser(userId: userId)
    }
    
    func unfollow(userId: String) async throws {
        try await service.unfollowUser(userId: userId)
    }
    
    func getFollowers(userId: String) async throws -> [AppUser] {
        // Stub implementation - method doesn't exist
        return []
    }
    
    func getFollowing(userId: String) async throws -> [AppUser] {
        // Stub implementation - method doesn't exist
        return []
    }
    
    func isFollowing(userId: String) async throws -> Bool {
        // Stub implementation - method doesn't exist
        return false
    }
    
    func getFollowRequests() async throws -> [FollowRequest] {
        // Convert from service's follow request type to protocol's type
        return []
    }
    
    func approveFollowRequest(requestId: String) async throws {
        // Stub implementation - method doesn't exist
    }
    
    func rejectFollowRequest(requestId: String) async throws {
        // Stub implementation - method doesn't exist
    }
}

// MARK: - Message Service Adapter

@MainActor
final class MessageServiceAdapter: MessageServiceProtocol {
    private let service = MessageServiceReplacement.shared
    
    func fetchConversations() async throws -> [Conversation] {
        return try await service.fetchConversations()
    }
    
    func fetchMessages(conversationId: String) async throws -> [Message] {
        return try await service.fetchMessages(for: conversationId)
    }
    
    func sendMessage(conversationId: String, content: String) async throws -> Message {
        return try await service.sendMessage(conversationId: conversationId, content: content)
    }
    
    func markAsRead(messageId: String) async throws {
        try await service.markAsRead(messageId: messageId)
    }
    
    func deleteMessage(messageId: String) async throws {
        try await service.deleteMessage(messageId)
    }
    
    func createConversation(with userIds: [String]) async throws -> Conversation {
        return try await service.createConversation(with: userIds)
    }
}

// MARK: - Image Processor Adapters

@MainActor
final class UnifiedImageProcessorAdapter: UnifiedImageProcessorProtocol {
    private let processor = UnifiedImageProcessor.shared
    
    func processImage(_ image: UIImage, with settings: ProcessingSettings) async throws -> UIImage {
        // Adapt the processing settings to the actual processor's format
        return image // Placeholder
    }
    
    func applyFilter(_ filter: ImageFilter, to image: UIImage) async throws -> UIImage {
        // Apply filter using the actual processor
        return image // Placeholder
    }
    
    func resizeImage(_ image: UIImage, to size: CGSize) async throws -> UIImage {
        // Resize using the actual processor
        return image // Placeholder
    }
    
    func generateThumbnail(from image: UIImage, size: CGSize) async throws -> UIImage {
        // Generate thumbnail using the actual processor
        return image // Placeholder
    }
}

@MainActor
final class CoreImageManagerAdapter: CoreImageManagerProtocol {
    private let manager = CoreImageManager.shared
    
    func applyFilter(named filterName: String, to image: CIImage, parameters: [String: Any]) -> CIImage? {
        // Stub implementation - method signature mismatch
        return nil
    }
    
    func availableFilters() -> [String] {
        // Stub implementation - method doesn't exist
        return []
    }
    
    func renderImage(_ ciImage: CIImage) -> UIImage? {
        // Stub implementation - method doesn't exist
        return nil
    }
}

@MainActor
final class RAWImageProcessorAdapter: RAWImageProcessorProtocol {
    private let processor = RAWImageProcessor.shared
    
    func processRAWImage(from data: Data) async throws -> UIImage {
        // Stub implementation - method doesn't exist
        throw NSError(domain: "RAWImageProcessor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func extractMetadata(from data: Data) async throws -> RAWImageInfo {
        // Extract metadata using the actual processor
        // This would need to be implemented in the actual RAWImageProcessor
        throw NSError(domain: "RAWImageProcessor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func supportsFormat(_ format: String) -> Bool {
        // Stub implementation - method doesn't exist
        return false
    }
}

// MARK: - Security Service Adapters

final class KeychainManagerAdapter: KeychainManagerProtocol {
    // Note: KeychainManager might need to be created if it doesn't exist
    
    func save(key: String, value: String) throws {
        // Implement keychain save
    }
    
    func retrieve(key: String) throws -> String? {
        // Implement keychain retrieve
        return nil
    }
    
    func delete(key: String) throws {
        // Implement keychain delete
    }
    
    func clear() throws {
        // Implement keychain clear
    }
}

final class CryptoManagerAdapter: CryptoManagerProtocol {
    // Note: CryptoManager might need to be created if it doesn't exist
    
    func encrypt(data: Data, withKey key: String) throws -> Data {
        // Implement encryption
        return data
    }
    
    func decrypt(data: Data, withKey key: String) throws -> Data {
        // Implement decryption
        return data
    }
    
    func generateKey() -> String {
        // Generate a cryptographic key
        return UUID().uuidString
    }
    
    func hash(data: Data) -> String {
        // Generate hash
        return data.base64EncodedString()
    }
}

// MARK: - Location Service Adapters

@MainActor
final class LocationManagerAdapter: LocationManagerProtocol {
    // Note: LocationManager might need to be created if it doesn't exist
    
    var currentLocation: CLLocation? {
        return nil // Placeholder
    }
    
    var authorizationStatus: CLAuthorizationStatus {
        return .notDetermined // Placeholder
    }
    
    func requestAuthorization() async {
        // Request location authorization
    }
    
    func startUpdatingLocation() {
        // Start location updates
    }
    
    func stopUpdatingLocation() {
        // Stop location updates
    }
    
    func reverseGeocode(location: CLLocation) async throws -> String? {
        // Perform reverse geocoding
        return nil
    }
}

@MainActor
final class RestaurantSearchServiceAdapter: RestaurantSearchServiceProtocol {
    private let service = RestaurantSearchService.shared
    
    func searchNearby(location: CLLocation, radius: Double) async throws -> [Restaurant] {
        // Adapt the service's restaurant type to the protocol's type
        return []
    }
    
    func search(query: String, near location: CLLocation) async throws -> [Restaurant] {
        // Adapt the service's search method
        return []
    }
    
    func getDetails(restaurantId: String) async throws -> Restaurant {
        // Get restaurant details
        throw NSError(domain: "RestaurantSearch", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
}

// MARK: - Real-time Service Adapters

@MainActor
final class RealtimeSubscriptionManagerAdapter: RealtimeSubscriptionManagerProtocol {
    // Note: This might need to be created or adapted from existing realtime services
    
    func subscribe(to channel: String, onMessage: @escaping (Any) -> Void) -> String {
        // Subscribe to channel
        return UUID().uuidString
    }
    
    func unsubscribe(subscriptionId: String) {
        // Unsubscribe from channel
    }
    
    func unsubscribeAll() {
        // Unsubscribe from all channels
    }
    
    func isConnected() -> Bool {
        // Check connection status
        return false
    }
}

@MainActor
final class ConversationManagerAdapter: ConversationManagerProtocol {
    private let manager = ConversationManagerReplacement.shared
    
    func loadConversation(id: String) async throws -> Conversation {
        return try await manager.loadConversation(id: id)
    }
    
    func createConversation(with userIds: [String]) async throws -> Conversation {
        return try await manager.createConversation(with: userIds)
    }
    
    func updateConversation(_ conversation: Conversation) async throws {
        try await manager.updateConversation(conversation)
    }
    
    func deleteConversation(id: String) async throws {
        try await manager.deleteConversation(id: id)
    }
    
    func markAsRead(conversationId: String) async throws {
        try await manager.markAsRead(conversationId: conversationId)
    }
}

@MainActor
final class MessageServiceCoordinatorAdapter: MessageServiceCoordinatorProtocol {
    // Use facade instead of the old coordinator
    private let facade = MessageSystemFacade.shared
    
    func startListening() {
        // Implement using new architecture
        // Real-time listening would be handled by RealtimeDataAccess
    }
    
    func stopListening() {
        // Implement using new architecture
    }
    
    func sendMessage(_ message: Message) async throws {
        // Use facade's message service
        guard let userId = await DependencyContainer.shared.authManager.currentUser?.id else {
            throw MessageError.unauthorized
        }
        _ = try await facade.messageService.sendMessage(
            conversationId: message.conversationId,
            content: message.content,
            senderId: userId
        )
    }
    
    func handleIncomingMessage(_ message: Message) async {
        // Handle incoming messages through new architecture
    }
    
    func syncMessages() async throws {
        // Sync messages using new architecture
    }
}
