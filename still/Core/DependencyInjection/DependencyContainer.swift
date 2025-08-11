//======================================================================
// MARK: - DependencyContainer.swift
// Purpose: Concrete implementation of the dependency injection container
// Path: still/Core/DependencyInjection/DependencyContainer.swift
//======================================================================

import Foundation

/**
 * DependencyContainer is the concrete implementation of DependencyContainerProtocol.
 * 
 * This class serves as the central registry for all application dependencies,
 * providing lazy initialization and singleton management for services.
 *
 * Key Features:
 * - Lazy initialization of dependencies
 * - Thread-safe singleton pattern
 * - Easy mocking support for testing
 * - Centralized dependency configuration
 *
 * Usage:
 * ```swift
 * class MyViewModel: BaseViewModel {
 *     private let dependencies: DependencyContainerProtocol
 *     
 *     init(dependencies: DependencyContainerProtocol = DependencyContainer.shared) {
 *         self.dependencies = dependencies
 *         super.init()
 *     }
 *     
 *     func loadData() async {
 *         let user = await dependencies.authManager.currentUser
 *         // Use other dependencies as needed
 *     }
 * }
 * ```
 */
@MainActor
final class DependencyContainer: DependencyContainerProtocol {
    
    // MARK: - Singleton Instance
    
    /// Shared instance of the dependency container
    static let shared = DependencyContainer()
    
    // MARK: - Private Properties (Lazy Initialization)
    
    private lazy var _authManager: any AuthManagerProtocol = AuthManager.shared
    private lazy var _supabaseManager: SupabaseManagerProtocol = SupabaseManagerAdapter()
    private lazy var _postStatusManager: PostStatusManagerProtocol = PostStatusManagerAdapter()
    private lazy var _imageCacheManager: ImageCacheManagerProtocol = ImageCacheManagerAdapter()
    private lazy var _logger: LoggerProtocol = LoggerAdapter()
    private lazy var _notificationService: NotificationServiceProtocol = NotificationServiceAdapter()
    
    private lazy var _userRepository: UserRepositoryProtocol = UserRepositoryAdapter()

    private lazy var _commentService: CommentServiceProtocol = CommentServiceAdapter()
    private lazy var _followService: FollowServiceProtocol = FollowServiceAdapter()
    private lazy var _messageService: MessageServiceProtocol = MessageServiceAdapter()
    
    private lazy var _imageProcessor: UnifiedImageProcessorProtocol = UnifiedImageProcessorAdapter()
    private lazy var _coreImageManager: CoreImageManagerProtocol = CoreImageManagerAdapter()
    private lazy var _rawImageProcessor: RAWImageProcessorProtocol = RAWImageProcessorAdapter()
    
    private lazy var _keychainManager: KeychainManagerProtocol = KeychainManagerAdapter()
    private lazy var _cryptoManager: CryptoManagerProtocol = CryptoManagerAdapter()
    
    private lazy var _locationManager: LocationManagerProtocol = LocationManagerAdapter()
    private lazy var _restaurantSearchService: RestaurantSearchServiceProtocol = RestaurantSearchServiceAdapter()
    
    private lazy var _realtimeSubscriptionManager: RealtimeSubscriptionManagerProtocol = RealtimeSubscriptionManagerAdapter()
    private lazy var _conversationManager: ConversationManagerProtocol = ConversationManagerAdapter()
    private lazy var _messageServiceCoordinator: MessageServiceCoordinatorProtocol = MessageServiceCoordinatorAdapter()
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Configure any initial setup if needed
    }
    
    // MARK: - DependencyContainerProtocol Implementation
    
    var authManager: any AuthManagerProtocol {
        return _authManager
    }
    
    var supabaseManager: SupabaseManagerProtocol {
        return _supabaseManager
    }
    
    var postStatusManager: PostStatusManagerProtocol {
        return _postStatusManager
    }
    
    var imageCacheManager: ImageCacheManagerProtocol {
        return _imageCacheManager
    }
    
    var logger: LoggerProtocol {
        return _logger
    }
    
    var notificationService: NotificationServiceProtocol {
        return _notificationService
    }
    
    var userRepository: UserRepositoryProtocol {
        return _userRepository
    }
    

    
    var commentService: CommentServiceProtocol {
        return _commentService
    }
    
    var followService: FollowServiceProtocol {
        return _followService
    }
    
    var messageService: MessageServiceProtocol {
        return _messageService
    }
    
    var imageProcessor: UnifiedImageProcessorProtocol {
        return _imageProcessor
    }
    
    var coreImageManager: CoreImageManagerProtocol {
        return _coreImageManager
    }
    
    var rawImageProcessor: RAWImageProcessorProtocol {
        return _rawImageProcessor
    }
    
    var keychainManager: KeychainManagerProtocol {
        return _keychainManager
    }
    
    var cryptoManager: CryptoManagerProtocol {
        return _cryptoManager
    }
    
    var locationManager: LocationManagerProtocol {
        return _locationManager
    }
    
    var restaurantSearchService: RestaurantSearchServiceProtocol {
        return _restaurantSearchService
    }
    
    var realtimeSubscriptionManager: RealtimeSubscriptionManagerProtocol {
        return _realtimeSubscriptionManager
    }
    
    var conversationManager: ConversationManagerProtocol {
        return _conversationManager
    }
    
    var messageServiceCoordinator: MessageServiceCoordinatorProtocol {
        return _messageServiceCoordinator
    }
}

// MARK: - Test Support

/**
 * MockableDependencyContainer for unit testing.
 * 
 * This class allows for easy mocking of dependencies in tests.
 * All properties are publicly settable to allow test customization.
 */
@MainActor
class MockableDependencyContainer: DependencyContainerProtocol {
    
    // All properties are var to allow test customization
    var authManager: any AuthManagerProtocol
    var supabaseManager: SupabaseManagerProtocol
    var postStatusManager: PostStatusManagerProtocol
    var imageCacheManager: ImageCacheManagerProtocol
    var logger: LoggerProtocol
    var notificationService: NotificationServiceProtocol
    var userRepository: UserRepositoryProtocol

    var commentService: CommentServiceProtocol
    var followService: FollowServiceProtocol
    var messageService: MessageServiceProtocol
    var imageProcessor: UnifiedImageProcessorProtocol
    var coreImageManager: CoreImageManagerProtocol
    var rawImageProcessor: RAWImageProcessorProtocol
    var keychainManager: KeychainManagerProtocol
    var cryptoManager: CryptoManagerProtocol
    var locationManager: LocationManagerProtocol
    var restaurantSearchService: RestaurantSearchServiceProtocol
    var realtimeSubscriptionManager: RealtimeSubscriptionManagerProtocol
    var conversationManager: ConversationManagerProtocol
    var messageServiceCoordinator: MessageServiceCoordinatorProtocol
    
    /**
     * Initialize with mock implementations.
     * 
     * In tests, you can create this container and replace specific
     * dependencies with mocks as needed.
     */
    init(
        authManager: (any AuthManagerProtocol)? = nil,
        supabaseManager: SupabaseManagerProtocol? = nil,
        postStatusManager: PostStatusManagerProtocol? = nil,
        imageCacheManager: ImageCacheManagerProtocol? = nil,
        logger: LoggerProtocol? = nil,
        notificationService: NotificationServiceProtocol? = nil,
        userRepository: UserRepositoryProtocol? = nil,

        commentService: CommentServiceProtocol? = nil,
        followService: FollowServiceProtocol? = nil,
        messageService: MessageServiceProtocol? = nil,
        imageProcessor: UnifiedImageProcessorProtocol? = nil,
        coreImageManager: CoreImageManagerProtocol? = nil,
        rawImageProcessor: RAWImageProcessorProtocol? = nil,
        keychainManager: KeychainManagerProtocol? = nil,
        cryptoManager: CryptoManagerProtocol? = nil,
        locationManager: LocationManagerProtocol? = nil,
        restaurantSearchService: RestaurantSearchServiceProtocol? = nil,
        realtimeSubscriptionManager: RealtimeSubscriptionManagerProtocol? = nil,
        conversationManager: ConversationManagerProtocol? = nil,
        messageServiceCoordinator: MessageServiceCoordinatorProtocol? = nil
    ) {
        self.authManager = authManager ?? AuthManagerAdapter()
        self.supabaseManager = supabaseManager ?? SupabaseManagerAdapter()
        self.postStatusManager = postStatusManager ?? PostStatusManagerAdapter()
        self.imageCacheManager = imageCacheManager ?? ImageCacheManagerAdapter()
        self.logger = logger ?? LoggerAdapter()
        self.notificationService = notificationService ?? NotificationServiceAdapter()
        self.userRepository = userRepository ?? UserRepositoryAdapter()

        self.commentService = commentService ?? CommentServiceAdapter()
        self.followService = followService ?? FollowServiceAdapter()
        self.messageService = messageService ?? MessageServiceAdapter()
        self.imageProcessor = imageProcessor ?? UnifiedImageProcessorAdapter()
        self.coreImageManager = coreImageManager ?? CoreImageManagerAdapter()
        self.rawImageProcessor = rawImageProcessor ?? RAWImageProcessorAdapter()
        self.keychainManager = keychainManager ?? KeychainManagerAdapter()
        self.cryptoManager = cryptoManager ?? CryptoManagerAdapter()
        self.locationManager = locationManager ?? LocationManagerAdapter()
        self.restaurantSearchService = restaurantSearchService ?? RestaurantSearchServiceAdapter()
        self.realtimeSubscriptionManager = realtimeSubscriptionManager ?? RealtimeSubscriptionManagerAdapter()
        self.conversationManager = conversationManager ?? ConversationManagerAdapter()
        self.messageServiceCoordinator = messageServiceCoordinator ?? MessageServiceCoordinatorAdapter()
    }
}