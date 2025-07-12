//======================================================================
// MARK: - StillApp.swift
// Path: still/StillApp.swift
//======================================================================
import SwiftUI

@main
struct StillApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    print("🔵 App received URL: \(url)")
                    Task {
                        do {
                            try await AuthManager.shared.handleAuthCallback(url: url)
                        } catch {
                            print("❌ Error handling auth callback: \(error)")
                        }
                    }
                }
        }
    }
}

