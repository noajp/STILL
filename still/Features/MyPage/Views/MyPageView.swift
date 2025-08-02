//======================================================================
// MARK: - MyPageView.swift
// Purpose: Container view for mode switching between user search and profile display
// Path: still/Features/MyPage/Views/MyPageView.swift
//======================================================================
import SwiftUI
import PhotosUI

/**
 * Main container view for My Page functionality
 * Switches between user search mode and profile display mode based on tab bar selection
 */
@MainActor
struct MyPageView: View {
    // MARK: - Properties
    @StateObject private var viewModel = MyPageViewModel()
    @EnvironmentObject var authManager: AuthManager
    @Binding var isInProfileSingleView: Bool
    @Binding var isUserSearchMode: Bool
    @State private var navigateToSettings = false
    @State private var showNotifications = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollableHeaderView(
                title: isUserSearchMode ? "USER SEARCH" : "PROFILE",
                rightButton: isUserSearchMode ? nil : HeaderButton(
                    icon: "custom.three.lines",
                    action: { 
                        navigateToSettings = true
                    }
                ),
                extraRightButton: isUserSearchMode ? nil : HeaderButton(
                    icon: "bell",
                    action: {
                        showNotifications = true
                    }
                )
            ) {
                if isUserSearchMode {
                    // User search mode
                    UserSearchView(isUserSearchMode: $isUserSearchMode)
                        .environmentObject(authManager)
                } else {
                    // Profile display mode
                    MyProfileView(viewModel: viewModel, isInProfileSingleView: $isInProfileSingleView)
                        .environmentObject(authManager)
                }
            }
            .background(MinimalDesign.Colors.background)
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
                    .environmentObject(authManager)
            }
            .fullScreenCover(isPresented: $showNotifications) {
                NotificationListView()
                    .environmentObject(authManager)
            }
        }
    }
}