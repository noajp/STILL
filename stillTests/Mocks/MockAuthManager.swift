//======================================================================
// MARK: - MockAuthManager
// Purpose: Mock implementation for testing AuthManager functionality
//======================================================================
import Foundation
import Combine
@testable import tete

/// Mock implementation of AuthManager for testing
@MainActor
final class MockAuthManager: ObservableObject, AuthManagerProtocol {
    typealias User = MockUser
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUser: MockUser?
    @Published var isLoading = false
    
    // MARK: - Call Tracking
    var signInCalls: [(email: String, password: String)] = []
    var signUpCalls: [(email: String, password: String, username: String)] = []
    var signOutCalls: Int = 0
    
    // MARK: - Error Simulation
    var shouldThrowError = false
    var errorToThrow: Error = ViewModelError.unauthorized
    
    // MARK: - Mock User (compatible with AppUser)
    struct MockUser: AuthUser {
        let id: String
        let email: String?
        let createdAt: String?
        
        init(id: String = "test-user-id", email: String = "test@example.com", createdAt: String? = nil) {
            self.id = id
            self.email = email
            self.createdAt = createdAt ?? "2024-01-01T00:00:00Z"
        }
    }
    
    // MARK: - Public Methods
    
    func signIn(email: String, password: String) async throws {
        signInCalls.append((email: email, password: password))
        isLoading = true
        
        defer { isLoading = false }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        currentUser = MockUser(email: email)
        isAuthenticated = true
    }
    
    func signUp(email: String, password: String, username: String) async throws {
        signUpCalls.append((email: email, password: password, username: username))
        isLoading = true
        
        defer { isLoading = false }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        currentUser = MockUser(email: email)
        isAuthenticated = true
    }
    
    func signOut() async throws {
        signOutCalls += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        isAuthenticated = false
        currentUser = nil
        isLoading = false
        
        signInCalls.removeAll()
        signUpCalls.removeAll()
        signOutCalls = 0
        
        shouldThrowError = false
        errorToThrow = ViewModelError.unauthorized
    }
    
    func simulateSignedInUser(
        id: String = "test-user-id",
        email: String = "test@example.com"
    ) {
        currentUser = MockUser(id: id, email: email)
        isAuthenticated = true
    }
    
    func simulateSignedOutUser() {
        currentUser = nil
        isAuthenticated = false
    }
}