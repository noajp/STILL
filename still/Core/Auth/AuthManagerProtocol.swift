//======================================================================
// MARK: - AuthManagerProtocol
// Purpose: Protocol for authentication management to enable dependency injection
//======================================================================
import Foundation

/// User type that can be used by ViewModels
protocol AuthUser {
    var id: String { get }
    var email: String? { get }
}

/// Protocol for authentication management
@MainActor
protocol AuthManagerProtocol: ObservableObject {
    associatedtype User: AuthUser
    
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get }
    
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String, username: String) async throws
    func signOut() async throws
}

// MARK: - Extensions

extension AppUser: AuthUser {
    // AppUser already conforms to AuthUser requirements
}