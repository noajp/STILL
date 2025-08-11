//======================================================================
// MARK: - DependencyContainerProtocol.swift
// Purpose: Protocol defining the dependency injection container interface
// Path: still/Core/DependencyInjection/DependencyContainerProtocol.swift
//======================================================================

import Foundation

/**
 * DependencyContainerProtocol defines the interface for accessing
 * all application dependencies through dependency injection.
 * 
 * This protocol enables:
 * - Loose coupling between components
 * - Easy mocking and testing
 * - Centralized dependency management
 * - Better separation of concerns
 *
 * Usage:
 * ViewModels and services should depend on this protocol
 * rather than accessing singleton instances directly.
 */
@MainActor
protocol DependencyContainerProtocol {
    
    // MARK: - Core Services
    
    /// Authentication management service
    var authManager: any AuthManagerProtocol { get }
    
    /// Supabase client management service
    var supabaseManager: SupabaseManagerProtocol { get }
    
    /// Post status and lifecycle management
    var postStatusManager: PostStatusManagerProtocol { get }
    
    /// Image caching and memory management
    var imageCacheManager: ImageCacheManagerProtocol { get }
    
    /// Logging and analytics service
    var logger: LoggerProtocol { get }
    
    /// Notification handling service
    var notificationService: NotificationServiceProtocol { get }
    
    // MARK: - Data Services
    
    /// User data repository
    var userRepository: UserRepositoryProtocol { get }
    

    
    /// Comment service for post interactions
    var commentService: CommentServiceProtocol { get }
    
    /// Follow relationship management
    var followService: FollowServiceProtocol { get }
    
    /// Messaging and chat service
    var messageService: MessageServiceProtocol { get }
    
    // MARK: - Image Processing
    
    /// Unified image processing pipeline
    var imageProcessor: UnifiedImageProcessorProtocol { get }
    
    /// Core Image filter management
    var coreImageManager: CoreImageManagerProtocol { get }
    
    /// RAW image format processor
    var rawImageProcessor: RAWImageProcessorProtocol { get }
    
    // MARK: - Security Services
    
    /// Keychain access management
    var keychainManager: KeychainManagerProtocol { get }
    
    /// Cryptographic operations service
    var cryptoManager: CryptoManagerProtocol { get }
    
    // MARK: - Location Services
    
    /// Location tracking and geolocation
    var locationManager: LocationManagerProtocol { get }
    
    /// Restaurant search and discovery
    var restaurantSearchService: RestaurantSearchServiceProtocol { get }
    
    // MARK: - Real-time Services
    
    /// WebSocket subscription management
    var realtimeSubscriptionManager: RealtimeSubscriptionManagerProtocol { get }
    
    /// Conversation state management
    var conversationManager: ConversationManagerProtocol { get }
    
    /// Message service coordination
    var messageServiceCoordinator: MessageServiceCoordinatorProtocol { get }
}

/**
 * Protocol for objects that can be injected with dependencies.
 * Classes conforming to this protocol can receive dependencies
 * through constructor injection.
 */
protocol DependencyInjectable {
    /// The type of dependency container this object requires
    associatedtype Container: DependencyContainerProtocol
    
    /// Initialize with a dependency container
    init(dependencies: Container)
}

/**
 * Extension providing a convenience initializer for dependency injectable objects
 * that uses the default container when no specific container is provided.
 */
@MainActor
extension DependencyInjectable where Container == DependencyContainer {
    /// Initialize with the default dependency container
    init() {
        self.init(dependencies: DependencyContainer.shared)
    }
}