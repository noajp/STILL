//======================================================================
// MARK: - HomeGridView.swift (Refactored)
// Purpose: Main container for home feed grid with modular components
// Path: still/Features/HomeFeed/Views/HomeGridView.swift
//======================================================================

import SwiftUI
import Combine

/**
 * HomeGridView provides the main container for the home feed grid display.
 * 
 * This refactored version uses modular components for better maintainability:
 * - GridHeaderView for upload status and controls
 * - PostGridSection for the grid layout
 * - PostCardView for individual post cards
 * - GridFilterView for filtering and sorting
 * - HomeGridViewModel for state management
 * 
 * Features:
 * - Dual mode switching (grid vs following feed)
 * - Post upload status tracking
 * - Navigation to single post view
 * - Pull-to-refresh and infinite scroll
 * - Image preloading optimization
 */
@MainActor
struct HomeGridView: View {
    // MARK: - Properties
    
    /// Grid-specific view model
    @StateObject private var gridViewModel = HomeGridViewModel()
    
    /// Legacy feed view model for compatibility
    @StateObject private var feedViewModel = HomeFeedViewModel()
    
    /// Controls whether to show grid mode vs following feed mode
    @Binding var showGridMode: Bool
    
    /// Controls display of create post interface
    @Binding var showingCreatePost: Bool
    
    /// Tracks if user is currently viewing a single post
    @Binding var isInSingleView: Bool
    
    /// Environment dismiss handler
    @Environment(\.dismiss) private var dismiss
    
    /// Navigation state for tab reset functionality
    @State private var navigationPath = NavigationPath()
    
    // MARK: - Filter State
    
    @State private var selectedFilter: GridFilter = .all
    @State private var selectedSort: GridSort = .newest
    @State private var searchText = ""
    @State private var showFilters = false
    
    // MARK: - Story State
    
    @State private var showingCamera = false
    @State private var storyGroups: [StoryGroup] = []
    
    // MARK: - Body
    
    var body: some View {
        ScrollableHeaderView(
            title: "STILL"
        ) {
            VStack(spacing: 0) {
                // Stories bar
                StoriesBarView(
                    storyGroups: storyGroups,
                    currentUserId: getCurrentUserId(),
                    onAddStory: {
                        showingCamera = true
                    },
                    onViewStory: { storyGroup in
                        // TODO: Navigate to story viewer
                        print("View story for: \(storyGroup.user.username)")
                    }
                )
                .padding(.vertical, 8)
                
                // Upload status header
                GridHeaderView()
                
                // Filter section (when in grid mode)
                if showGridMode && showFilters {
                    GridFilterView(
                        selectedFilter: $selectedFilter,
                        selectedSort: $selectedSort,
                        searchText: $searchText,
                        onFilterChanged: handleFilterChange
                    )
                }
                
                // Main content
                mainContentView
                
                // Bottom padding for tab bar clearance
                Color.clear
                    .frame(height: 110)
            }
        }
        .navigationDestination(isPresented: $gridViewModel.navigateToSingleView) {
            singlePostDestination
        }
        .onAppear {
            handleViewAppear()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostCreated"))) { _ in
            Task {
                await handlePostCreated()
            }
        }
        .onChange(of: showGridMode) { _, newValue in
            handleModeChange(newValue)
        }
        .onChange(of: isInSingleView) { _, newValue in
            handleSingleViewChange(newValue)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(isForStory: true)
                .ignoresSafeArea()
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetHomeNavigation)) { _ in
            // Reset navigation state
            navigationPath = NavigationPath()
            // Reset view model state
            gridViewModel.clearNavigation()
            // Reset local state
            selectedFilter = .all
            selectedSort = .newest
            searchText = ""
            showFilters = false
            showingCamera = false
        }
    }
    
    // MARK: - Main Content View
    
    @ViewBuilder
    private var mainContentView: some View {
        if gridViewModel.isLoading {
            LoadingStateHeaderView()
        } else if gridViewModel.posts.isEmpty {
            EmptyStateHeaderView()
        } else {
            contentBasedOnMode
        }
    }
    
    @ViewBuilder
    private var contentBasedOnMode: some View {
        if showGridMode {
            gridModeContent
        } else {
            followingModeContent
        }
    }
    
    @ViewBuilder
    private var gridModeContent: some View {
        let _ = print("🎯 HomeGridView: Passing \(gridViewModel.posts.count) posts to PostGridSection")
        PostGridSection(
            posts: gridViewModel.posts,
            selectedPost: $gridViewModel.selectedPost,
            navigateToSingleView: $gridViewModel.navigateToSingleView
        )
    }
    
    @ViewBuilder
    private var followingModeContent: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 20) {
                ForEach(gridViewModel.posts) { post in
                    PostCardView(
                        post: post,
                        onLikeTapped: { post in
                            Task {
                                await gridViewModel.toggleLike(for: post)
                            }
                        }
                    )
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await gridViewModel.forceRefreshPosts()
        }
    }
    
    @ViewBuilder
    private var singlePostDestination: some View {
        if let selectedPost = gridViewModel.selectedPost {
            SinglePostView(
                initialPost: selectedPost,
                viewModel: feedViewModel,
                showGridMode: $showGridMode
            )
            .onAppear {
                print("🔍 SinglePostView appeared for post: \(selectedPost.id)")
                isInSingleView = true
                gridViewModel.prepareForSingleView()
            }
            .onDisappear {
                print("🔍 SinglePostView disappeared")
                isInSingleView = false
                gridViewModel.handleNavigationBack()
            }
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleViewAppear() {
        Task {
            // Load posts if needed
            await gridViewModel.loadPostsIfNeeded()
            
            // Optimize based on current mode
            if showGridMode {
                // Preload grid-optimized images
                await gridViewModel.preloadGridImages()
            } else {
                // Preload grid data in background for quick switching
                Task.detached(priority: .background) {
                    await gridViewModel.preloadGridData()
                }
            }
        }
    }
    
    private func handlePostCreated() async {
        await gridViewModel.forceRefreshPosts()
    }
    
    private func handleModeChange(_ newValue: Bool) {
        if newValue && isInSingleView {
            // When switching to grid mode, exit single view
            gridViewModel.clearNavigation()
        }
        
        // Handle mode switching optimization
        Task {
            if newValue {
                // Switching to grid mode
                print("🔄 Switching to grid mode")
                await gridViewModel.loadPostsIfNeeded()
                await gridViewModel.preloadGridImages()
            } else {
                // Switching to following mode
                print("🔄 Switching to following mode")
                Task.detached(priority: .background) {
                    await gridViewModel.preloadGridData()
                }
            }
        }
    }
    
    private func handleSingleViewChange(_ newValue: Bool) {
        if !newValue && gridViewModel.navigateToSingleView {
            // When returning from single view
            gridViewModel.clearNavigation()
        }
    }
    
    private func handleFilterChange() {
        // Update view model with new filter settings
        gridViewModel.updateFilter(selectedFilter)
        gridViewModel.updateSort(selectedSort)
        gridViewModel.searchText = searchText
    }
    
    private func getCurrentUserId() -> String? {
        // TODO: Get from AuthManager when available
        // return AuthManager.shared.currentUser?.id
        return "current_user_id"
    }
}

// MARK: - Toolbar Extension

extension HomeGridView {
    /// Creates toolbar items for the grid view
    func toolbarItems() -> some View {
        HStack {
            // Filter toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showFilters.toggle()
                }
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(showFilters ? MinimalDesign.Colors.accentRed : .white)
            }
            
            // Mode toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showGridMode.toggle()
                }
            }) {
                Image(systemName: showGridMode ? "rectangle.grid.3x2.fill" : "list.bullet")
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Legacy Support
// FollowingPostView is now in its own file

// MARK: - Preview Provider

struct HomeGridView_Previews: PreviewProvider {
    static var previews: some View {
        HomeGridView(
            showGridMode: .constant(true),
            showingCreatePost: .constant(false),
            isInSingleView: .constant(false)
        )
        .background(MinimalDesign.Colors.background)
    }
}