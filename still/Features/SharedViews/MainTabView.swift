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
    // MARK: - State Properties
    
    /// Currently selected tab in the main navigation (0: Home, 1: Articles, 2: Messages, 3: Profile)
    @State private var selectedTab = 0
    
    /// Controls the display of the photo creation modal
    @State private var showingCreatePost = false
    
    /// Controls the display of the photo editor modal
    @State private var showingPhotoEditor = false
    
    /// Data passed to the photo editor containing image and metadata
    @State private var editorData: PhotoEditorData?
    
    /// Controls whether the home feed displays in grid or list mode
    @State private var showGridMode = true
    
    /// Top-level page selection (0: Camera, 1: Main Feed)
    @State private var pageSelection = 1
    
    /// Indicates if a single post view is currently displayed
    @State private var isInSingleView = false
    
    /// Indicates if a single post view is displayed in the profile section
    @State private var isInProfileSingleView = false
    
    /// Vertical offset for tab bar animation (hide/show on scroll)
    @State private var tabBarOffset: CGFloat = 0
    
    /// Vertical offset for header animation
    @State private var headerOffset: CGFloat = 0
    
    /// Tracks the last scroll position for animation calculations
    @State private var lastScrollOffset: CGFloat = 0
    
    /// Indicates if user search mode is active in the profile section
    @State private var isUserSearchMode = false
    
    /// Indicates if group chat mode is active in the messages section
    @State private var isGroupChatMode = false
    
    /// Controls the display of the post type selection popup
    @State private var showingPostTypeSelection = false
    
    /// Controls the display of the article creation modal
    @State private var showingCreateArticle = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Top-level TabView for swipe navigation between camera and main feed
            TabView(selection: $pageSelection) {
                // Camera view for photo capture
                CameraView()
                    .tag(0)
                    .ignoresSafeArea()
                
                // Main content area with horizontal swipe navigation
                // Navigation order: Home → Articles → Messages → Profile
                TabView(selection: $selectedTab) {
                    // Home feed tab (0) - Main photo grid and feed view
                    HomeGridView(
                        showGridMode: $showGridMode, 
                        showingCreatePost: $showingCreatePost,
                        isInSingleView: $isInSingleView
                    )
                    .tag(0)
                    
                    // Articles tab (1) - Article browsing and reading
                    NavigationStack {
                        ArticleListView()
                    }
                    .tag(1)
                    
                    // Messages tab (2) - Chat and messaging interface
                    NavigationStack {
                        MessagesView(isGroupChatMode: $isGroupChatMode)
                    }
                    .tag(2)
                    
                    // Profile tab (3) - User profile and settings
                    MyPageView(
                        isInProfileSingleView: $isInProfileSingleView,
                        isUserSearchMode: $isUserSearchMode
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Color(.systemBackground))
                .ignoresSafeArea(.all)
                .tag(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Note: Status bar handling moved to HomeGridView
            
            // Hide tab bar when camera view is active
            if pageSelection == 1 {
                // Custom tab bar (footer navigation)
                VStack {
                    Spacer()
                    CustomTabBar(
                        selectedTab: $selectedTab,
                        showGridMode: $showGridMode,
                        unreadMessageCount: 0,
                        onCreatePost: {
                            showingPostTypeSelection = true
                        },
                        isInSingleView: isInSingleView,
                        onBackToGrid: {
                            // Return from single view to grid view
                            if isInSingleView {
                                isInSingleView = false
                                showGridMode = true
                            }
                        },
                        onBackFromProfileSingleView: {
                            // Return from profile single view
                            if isInProfileSingleView {
                                isInProfileSingleView = false
                            }
                        },
                        onProfileDoubleTap: {
                            // Toggle user search mode on profile button tap
                            isUserSearchMode.toggle()
                        },
                        isUserSearchMode: $isUserSearchMode,
                        onMessageDoubleTap: {
                            // Toggle group chat mode on message button tap
                            isGroupChatMode.toggle()
                        },
                        isGroupChatMode: $isGroupChatMode
                    )
                }
                .offset(y: tabBarOffset)
                .animation(.easeInOut(duration: 0.5), value: tabBarOffset)
                .clipped() // Clip to completely hide background when offset
            }
            
            // Post type selection popup
            if showingPostTypeSelection {
                PostTypeSelectionPopup(
                    isPresented: $showingPostTypeSelection,
                    onPictureSelected: {
                        showingCreatePost = true
                    },
                    onArticleSelected: {
                        showingCreateArticle = true
                    }
                )
                .zIndex(999) // Display on top of all other views
            }
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.all)
        .accentColor(MinimalDesign.Colors.accentRed)
        // MARK: - Modal Presentations
        
        // Photo picker modal for creating new posts
        .fullScreenCover(isPresented: $showingCreatePost) {
            NavigationStack {
                PhotoPickerView { editorData in
                    print("📸 Image received in MainTabView")
                    self.editorData = editorData
                    self.showingCreatePost = false
                    self.showingPhotoEditor = true
                }
            }
            .transition(.move(edge: .bottom))
        }
        
        // Photo editor modal for editing selected images
        .fullScreenCover(isPresented: $showingPhotoEditor) {
            if let editorData = editorData {
                NavigationStack {
                    ModernPhotoEditorView(
                        editorData: editorData,
                        onComplete: { editedImage in
                            print("✅ Photo editing completed")
                            showingPhotoEditor = false
                            self.editorData = nil
                        },
                        onCancel: {
                            print("❌ Photo editing cancelled")
                            showingPhotoEditor = false
                            self.editorData = nil
                        }
                    )
                }
            }
        }
        
        // Article editor modal for creating new articles
        .fullScreenCover(isPresented: $showingCreateArticle) {
            ArticleEditorView()
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Updates the UI elements based on scroll position to provide smooth animations.
     * 
     * This method handles the show/hide animation of the tab bar based on scroll direction
     * and position, creating a more immersive browsing experience.
     *
     * - Parameter scrollOffset: The current vertical scroll offset
     */
    private func updateUIForScroll(scrollOffset: CGFloat) {
        let deltaY = lastScrollOffset - scrollOffset
        lastScrollOffset = scrollOffset
        
        // Tab bar height including icon, padding, and safe area considerations
        let tabBarHeight: CGFloat = 120 // Extra height to completely hide background
        
        // Scrolling up (even slight upward movement)
        if deltaY < -0.5 {
            // Show tab bar on upward scroll
            if tabBarOffset != 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    tabBarOffset = 0
                }
            }
        }
        // Scrolling down significantly
        else if deltaY > 3 {
            // Hide tab bar on downward scroll
            if tabBarOffset != tabBarHeight {
                withAnimation(.easeInOut(duration: 0.5)) {
                    tabBarOffset = tabBarHeight
                }
            }
        }
        // Near the top of the content - always show tab bar
        else if scrollOffset > -50 {
            if tabBarOffset != 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    tabBarOffset = 0
                }
            }
        }
    }
}
