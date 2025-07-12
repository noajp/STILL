//======================================================================
// MARK: - DependencyContainer
// Purpose: Simple dependency injection container
// Usage: DependencyContainer.shared.register(...) and resolve(...)
//======================================================================
import Foundation

/// Simple dependency injection container for managing app dependencies
final class DependencyContainer: @unchecked Sendable {
    static let shared = DependencyContainer()
    
    private var dependencies: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.tete.di", attributes: .concurrent)
    
    private init() {
        registerDefaults()
    }
    
    /// Register a dependency
    func register<T>(_ type: T.Type, factory: @escaping @Sendable () -> T) {
        queue.async(flags: .barrier) { [weak self] in
            let key = String(describing: type)
            self?.dependencies[key] = factory
        }
    }
    
    /// Register a singleton dependency
    func registerSingleton<T: Sendable>(_ type: T.Type, instance: T) {
        queue.async(flags: .barrier) { [weak self] in
            let key = String(describing: type)
            self?.dependencies[key] = instance
        }
    }
    
    /// Resolve a dependency
    func resolve<T>(_ type: T.Type) -> T? {
        return queue.sync {
            let key = String(describing: type)
            
            if let instance = dependencies[key] as? T {
                return instance
            }
            
            if let factory = dependencies[key] as? @Sendable () -> T {
                return factory()
            }
            
            return nil
        }
    }
    
    /// Resolve a dependency (force unwrapped)
    func resolve<T>(_ type: T.Type) -> T {
        guard let dependency = resolve(type) as T? else {
            fatalError("Dependency \(T.self) not registered")
        }
        return dependency
    }
    
    /// Register default dependencies
    private func registerDefaults() {
        // Repositories
        register(UserRepositoryProtocol.self) {
            UserRepository()
        }
        
        // Skip AuthManager registration for now - will be registered when needed
        // register((any AuthManagerProtocol).self) {
        //     AuthManager.shared as any AuthManagerProtocol
        // }
        register(SupabaseManager.self) {
            SupabaseManager.shared
        }
        
        // Add more default registrations as needed
    }
    
    /// Register test dependencies for testing
    /// This method should be called from test code with actual mock instances
    /// Note: AuthManager registration is handled separately due to @MainActor requirements
    func registerTestDependencies(
        userRepository: UserRepositoryProtocol? = nil
    ) {
        // Register test repositories if provided
        if let userRepository = userRepository {
            register(UserRepositoryProtocol.self) {
                userRepository
            }
        }
        
        // Note: AuthManager test registration should be done directly in test setup
        // due to @MainActor and Sendable constraints in Swift 6
    }
    
    /// Clear all dependencies (useful for testing)
    func clear() {
        queue.async(flags: .barrier) {
            self.dependencies.removeAll()
        }
    }
}

// MARK: - Property Wrapper for Dependency Injection

/// Property wrapper for injecting dependencies
@propertyWrapper
struct Injected<T> {
    private let dependency: T
    
    init() {
        guard let resolved = DependencyContainer.shared.resolve(T.self) as T? else {
            fatalError("Dependency \(T.self) not registered")
        }
        self.dependency = resolved
    }
    
    var wrappedValue: T {
        dependency
    }
}