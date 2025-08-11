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
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main content area with horizontal swipe navigation
            // Navigation order: Home → Messages → Profile
            TabView(selection: $viewModel.selectedTab) {
                    // Home feed tab (0) - Main photo grid and feed view
                    NavigationStack {
                        HomeGridView(
                            showGridMode: $viewModel.uiState.showGridMode, 
                            showingCreatePost: $viewModel.navigationState.showingCreatePost,
                            isInSingleView: $viewModel.uiState.isInSingleView
                        )
                    }
                    .tag(0)
                    

                    
                    // Messages tab (1) - Chat and messaging interface
                    NavigationStack {
                        MessagesView()
                    }
                    .tag(1)
                    
                    // Profile tab (2) - User profile and settings
                    MyPageView(
                        isInProfileSingleView: $viewModel.uiState.isInProfileSingleView,
                        isUserSearchMode: .constant(false)
                    )
                    .tag(2)
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
                        showGridMode: $viewModel.uiState.showGridMode,
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
                        }
                    )
            }
            .offset(y: viewModel.animationState.tabBarOffset)
            .animation(.easeInOut(duration: 0.5), value: viewModel.animationState.tabBarOffset)
            .clipped() // Clip to completely hide background when offset
            
            // Post type selection popup
            if viewModel.navigationState.showingPostTypeSelection {
                PostTypeSelectionPopup(
                    isPresented: $viewModel.navigationState.showingPostTypeSelection,
                    onPictureSelected: {
                        viewModel.handlePictureSelected()
                    },

                )
                .zIndex(999) // Display on top of all other views
            }
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
