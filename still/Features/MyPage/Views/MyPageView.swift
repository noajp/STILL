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
    @State private var showUserSearch = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Custom profile header with three buttons
                    profileHeader
                    
                    // Always show profile display mode
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
            .fullScreenCover(isPresented: $showUserSearch) {
                NavigationStack {
                    UserSearchView(isUserSearchMode: $showUserSearch)
                        .environmentObject(authManager)
                }
            }
        }
    }
    
    // MARK: - Custom Profile Header
    private var profileHeader: some View {
        HStack(spacing: 0) {
            // Title
            Text("PROFILE")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(MinimalDesign.Colors.primary)
                .padding(.leading, 8)
            
            Spacer()
            
            // Right buttons area
            HStack(spacing: 12) {
                // Search button
                Button(action: {
                    showUserSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(MinimalDesign.Colors.primary)
                }
                .frame(width: 36, height: 36)
                
                // Notification bell button
                Button(action: {
                    showNotifications = true
                }) {
                    Image(systemName: "bell")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(MinimalDesign.Colors.primary)
                }
                .frame(width: 36, height: 36)
                
                // Settings button (three lines)
                Button(action: {
                    navigateToSettings = true
                }) {
                    VStack(spacing: 5) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(MinimalDesign.Colors.primary)
                                .frame(width: 22, height: 1.5)
                        }
                    }
                }
                .frame(width: 36, height: 36)
            }
            .padding(.trailing, 8)
        }
        .padding(.horizontal, MinimalDesign.Spacing.sm)
        .padding(.vertical, MinimalDesign.Spacing.xs)
        .background(Color.clear)
    }
}