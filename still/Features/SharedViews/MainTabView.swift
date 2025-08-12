//======================================================================
// MARK: - MainTabView.swift
// Purpose: Main tab navigation controller with custom tab bar, tab switching, and root view management
// Path: still/Features/SharedViews/MainTabView.swift
//======================================================================

import SwiftUI
import PhotosUI

/**
 * MainTabView provides the primary navigation structure for the STILL app.
 * 
 * This view manages the main tab-based navigation with custom tab bar functionality,
 * handles transitions between different app sections, and coordinates the display
 * of camera, feed, articles, messages, and profile sections.
 *
 * Key Features:
 * - Dual-level TabView structure (camera/feed at top level, app sections at second level)
 * - Custom animated tab bar with hide/show functionality
 * - Modal presentation management for photo editing and article creation
 * - State management for different view modes (grid, single view, search modes)
 * - Post type selection and creation flow coordination
 */
struct MainTabView: View {
    // MARK: - View Model
    
    /// Centralized state management for the main tab view
    @StateObject private var viewModel = MainTabViewModel()
    
    // Navigation paths for each tab to enable programmatic navigation reset
    @State private var homePath = NavigationPath()
    @State private var galleryPath = NavigationPath()
    @State private var messagesPath = NavigationPath()
    @State private var profilePath = NavigationPath()
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main content area with horizontal swipe navigation
            // Navigation order: Home → Gallery → Messages → Profile
            TabView(selection: $viewModel.selectedTab) {
                // Home feed tab (0) - Main photo grid and feed view
                NavigationStack(path: $homePath) {
                    HomeGridView(
                        showGridMode: .constant(false),  // Always show feed mode
                        showingCreatePost: $viewModel.navigationState.showingCreatePost,
                        isInSingleView: $viewModel.uiState.isInSingleView
                    )
                }
                .tag(0)
                
                
                // Gallery tab (1) - Grid view of all posts
                NavigationStack(path: $galleryPath) {
                    GalleryView()
                }
                .tag(1)
                
                // Messages tab (2) - Chat and messaging interface
                NavigationStack(path: $messagesPath) {
                    MessagesView()
                }
                .tag(2)
                
                // Profile tab (3) - User profile and settings
                MyPageView(
                    isInProfileSingleView: $viewModel.uiState.isInProfileSingleView,
                    isUserSearchMode: .constant(false)
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color(hex: "121212"))
            .ignoresSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Note: Status bar handling moved to HomeGridView
            
            // Custom tab bar (footer navigation)
            VStack {
                Spacer()
                CustomTabBar(
                    selectedTab: $viewModel.selectedTab,

                    unreadMessageCount: viewModel.presentationState.unreadMessageCount,
                    onCreatePost: {
                        viewModel.handleCreatePost()
                    },
                    isInSingleView: viewModel.uiState.isInSingleView,
                    onBackToGrid: {
                        viewModel.handleBackToGrid()
                    },
                    onBackFromProfileSingleView: {
                        viewModel.handleBackFromProfileSingleView()
                    },
                    onProfileDoubleTap: {
                        // Profile double tap - no action needed
                    },
                    isUserSearchMode: .constant(false),
                    onMessageDoubleTap: {
                        // Unified messaging - no mode toggle needed
                    },
                    onTabReset: {
                        viewModel.resetTabNavigation {
                            homePath = NavigationPath()
                            galleryPath = NavigationPath()
                            messagesPath = NavigationPath()
                            profilePath = NavigationPath()
                        }
                    }
                )
            }
            .offset(y: viewModel.animationState.tabBarOffset)
            .animation(.easeInOut(duration: 0.5), value: viewModel.animationState.tabBarOffset)
            .clipped() // Clip to completely hide background when offset
        }
        .background(Color(hex: "121212"))
        .ignoresSafeArea(.all)
        .accentColor(MinimalDesign.Colors.accentRed)
        // MARK: - Modal Presentations
        
        // Photo picker modal for creating new posts
        .fullScreenCover(isPresented: $viewModel.navigationState.showingCreatePost) {
            NavigationStack {
                PhotoPickerView { editorData in
                    print("📸 Image received in MainTabView")
                    viewModel.handleImageSelected(editorData)
                }
            }
            .transition(.move(edge: .bottom))
        }
        
        // Photo editor modal for editing selected images
        .fullScreenCover(isPresented: $viewModel.navigationState.showingPhotoEditor) {
            if let editorData = viewModel.presentationState.editorData {
                NavigationStack {
                    ModernPhotoEditorView(
                        editorData: editorData,
                        onComplete: { editedImage in
                            viewModel.handlePhotoEditingComplete(editedImage)
                        },
                        onCancel: {
                            viewModel.handlePhotoEditingCancelled()
                        }
                    )
                }
            }
        }
        
        
    }
    
    // Note: updateUIForScroll method has been moved to MainTabViewModel
    
}
