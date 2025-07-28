//======================================================================
// MARK: - RootView.swift
// Purpose: Root view controller that manages authentication state and navigation
// Displays either the main app interface or authentication screens based on user state
// Path: still/RootView.swift
//======================================================================
import SwiftUI

/// Root view that acts as the main navigation controller for the entire application
/// Automatically switches between authenticated and unauthenticated user interfaces
/// Provides the AuthManager instance to all child views via environment objects
struct RootView: View {
    // MARK: - Properties
    
    /// Shared authentication manager that tracks user login state
    @StateObject private var authManager = AuthManager.shared
    
    // MARK: - Body
    
    /// Main view body that conditionally renders UI based on authentication status
    var body: some View {
        Group {
            // Show different UI based on user authentication status
            if authManager.isAuthenticated {
                // User is logged in - show main app interface with tab navigation
                MainTabView()
                    .environmentObject(authManager)
            } else {
                // User is not logged in - show authentication interface
                SignInView()
                    .environmentObject(authManager)
            }
        }
    }
}

