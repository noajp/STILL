//======================================================================
// MARK: - ContentView.swift
// Purpose: Main entry point for the STILL app providing root view navigation
// Path: still/ContentView.swift
//======================================================================

import SwiftUI

/**
 * ContentView serves as the main entry point for the STILL application.
 * 
 * This view acts as a simple wrapper that displays the RootView, which handles
 * the authentication flow and main app navigation. The ContentView is responsible
 * for initializing the app's core view hierarchy.
 *
 * Features:
 * - Provides the root view for the entire application
 * - Delegates authentication and navigation logic to RootView
 * - Maintains clean separation of concerns for app initialization
 */
struct ContentView: View {
    
    // MARK: - Body
    
    var body: some View {
        // Display the root view which handles authentication state and screen switching
        RootView()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

