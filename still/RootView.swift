//======================================================================
// MARK: - RootView.swift（認証状態によって画面を切り替え）
// Path: foodai/RootView.swift
//======================================================================
import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                SignInView()
                    .environmentObject(authManager)
            }
        }
    }
}

