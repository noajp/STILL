//======================================================================
// MARK: - StillApp.swift
// Purpose: Main application entry point for the STILL social media app
// Handles app lifecycle, URL schemes, and authentication callbacks
// Path: still/StillApp.swift
//======================================================================
import SwiftUI

/// Main application structure that serves as the entry point for the STILL app
/// Configures the root view and handles incoming URL schemes for authentication
@main
struct StillApp: App {
    // MARK: - App Body
    
    /// Defines the main scene configuration for the application
    var body: some Scene {
        WindowGroup {
            // Root view that manages the entire app navigation and state
            RootView()
                // Handle incoming URLs (primarily for authentication callbacks)
                .onOpenURL { url in
                    print("🔵 App received URL: \(url)")
                    Task {
                        do {
                            // Process authentication callback URLs from Supabase
                            try await AuthManager.shared.handleAuthCallback(url: url)
                        } catch {
                            print("❌ Error handling auth callback: \(error)")
                        }
                    }
                }
        }
    }
}

