//======================================================================
// MARK: - MainTabViewModel.swift
// Purpose: Centralized state management for MainTabView navigation and UI state
// Path: still/Features/MainTab/ViewModels/MainTabViewModel.swift
//======================================================================

import SwiftUI
import Combine
import Photos

/**
 * MainTabViewModel manages all state for the main tab navigation system.
 * 
 * This ViewModel centralizes state management to reduce complexity in the view layer
 * and provides a single source of truth for navigation state, presentation state,
 * and UI configuration across the app's main tab structure.
 *
 * Key Responsibilities:
 * - Tab navigation state management
 * - Modal presentation coordination
 * - View mode configuration (grid/list, search modes)
 * - UI animation state (tab bar visibility, scroll tracking)
 * - Post creation flow orchestration
 */
@MainActor
class MainTabViewModel: BaseViewModelClass {
    
    // MARK: - Dependencies
    
    /// Dependency container providing access to all services
    private let dependencies: DependencyContainerProtocol
    
    // MARK: - Published Properties
    
    /// Currently selected tab index (0: Home, 1: Messages, 2: Profile)
    @Published var selectedTab: Int = 0
    
    /// Navigation-related state grouped for better organization
    @Published var navigationState = NavigationState()
    
    /// Presentation-related state for modals and overlays
    @Published var presentationState = PresentationState()
    
    /// UI configuration state for view modes and display options
    @Published var uiState = UIState()
    
    /// Animation and scroll tracking state
    @Published var animationState = AnimationState()
    
    // MARK: - Nested State Types
    
    /**
     * Groups navigation-related boolean flags for better organization
     * and easier state management in complex navigation flows.
     */
    struct NavigationState {
        /// Controls display of post creation modal
        var showingCreatePost = false
        
        /// Controls display of photo editor modal
        var showingPhotoEditor = false
        
        /// Controls display of camera view
        var showingCamera = false
        
        /// Controls display of settings view
        var showingSettings = false
        
        /// Controls display of article creation modal

        
        /// Controls display of post type selection popup
        var showingPostTypeSelection = false
        
        /// Controls display of post composition screen
        var showingPostComposition = false
        
        // pageSelection removed - camera is now accessed via story mode
    }
    
    /**
     * Groups presentation-related state for managing modal data
     * and selected content across different views.
     */
    struct PresentationState {
        /// Data passed to photo editor containing image and metadata
        var editorData: PhotoEditorData?
        
        /// Currently selected image for editing or display
        var selectedImage: UIImage?
        
        /// Edited image ready for post composition
        var editedImage: UIImage?
        
        /// Unread message count for badge display
        var unreadMessageCount: Int = 0
    }
    
    /**
     * Groups UI configuration state for managing different view modes
     * and display options throughout the app.
     */
    struct UIState {
        /// Controls grid vs list display mode in home feed
        var showGridMode = false
        
        /// Indicates if single post view is active in home feed
        var isInSingleView = false
        
        /// Indicates if single post view is active in profile
        var isInProfileSingleView = false
        
        
    }
    
    /**
     * Groups animation and scroll-related state for managing
     * UI animations and scroll-based visibility changes.
     */
    struct AnimationState {
        /// Vertical offset for tab bar hide/show animation
        var tabBarOffset: CGFloat = 0
        
        /// Vertical offset for header animation
        var headerOffset: CGFloat = 0
        
        /// Last recorded scroll position for delta calculations
        var lastScrollOffset: CGFloat = 0
        
        /// Controls tab change animation
        var animateTabChange = false
    }
    
    // MARK: - Initialization
    
    /**
     * Initialize with dependency injection support.
     * - Parameter dependencies: The dependency container, defaults to shared instance
     */
    init(dependencies: DependencyContainerProtocol = DependencyContainer.shared) {
        self.dependencies = dependencies
        super.init()
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    /**
     * Sets up reactive bindings and observers for state changes.
     * This method configures any necessary Combine pipelines for
     * coordinating state updates across different parts of the app.
     */
    private func setupBindings() {
        // Monitor tab changes for analytics or special handling
        $selectedTab
            .sink { [weak self] newTab in
                self?.handleTabChange(to: newTab)
            }
            .store(in: &cancellables)
        
        // Monitor navigation state changes
        $navigationState
            .sink { [weak self] state in
                self?.handleNavigationStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    /**
     * Handles tab change events for analytics and state updates.
     * - Parameter tab: The newly selected tab index
     */
    private func handleTabChange(to tab: Int) {
        // Reset certain states when changing tabs
        if tab != 0 { // Not home tab
            uiState.isInSingleView = false
        }
        if tab != 3 { // Not profile tab
            uiState.isInProfileSingleView = false
        }
        
        // Log tab change for analytics
        dependencies.logger.info("Tab changed to: \(tab)", file: #file, function: #function, line: #line)
    }
    
    /**
     * Handles navigation state changes for coordinating complex flows.
     * - Parameter state: The new navigation state
     */
    private func handleNavigationStateChange(_ state: NavigationState) {
        // Handle photo editor flow
        if !state.showingCreatePost && presentationState.editorData != nil {
            navigationState.showingPhotoEditor = true
        }
        
        // Reset editor data when photo editor closes
        if !state.showingPhotoEditor {
            presentationState.editorData = nil
        }
    }
    
    // MARK: - Public Methods
    
    /**
     * Updates UI elements based on scroll position for smooth animations.
     * - Parameter scrollOffset: Current vertical scroll offset
     */
    func updateUIForScroll(scrollOffset: CGFloat) {
        let deltaY = animationState.lastScrollOffset - scrollOffset
        animationState.lastScrollOffset = scrollOffset
        
        let tabBarHeight: CGFloat = 120
        
        // Show tab bar on upward scroll
        if deltaY < -0.5 {
            if animationState.tabBarOffset != 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animationState.tabBarOffset = 0
                }
            }
        }
        // Hide tab bar on significant downward scroll
        else if deltaY > 3 {
            if animationState.tabBarOffset != tabBarHeight {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animationState.tabBarOffset = tabBarHeight
                }
            }
        }
        // Always show tab bar near top
        else if scrollOffset > -50 {
            if animationState.tabBarOffset != 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animationState.tabBarOffset = 0
                }
            }
        }
    }
    
    /**
     * Handles the create post action by showing post type selection.
     */
    func handleCreatePost() {
        // 直接写真選択画面を開く
        navigationState.showingCreatePost = true
    }
    
    /**
     * Handles picture selection from post type popup.
     */
    func handlePictureSelected() {
        navigationState.showingPostTypeSelection = false
        navigationState.showingCreatePost = true
    }
    
    /**
     * Handles article selection from post type popup.
     */

    
    /**
     * Handles returning from single view to grid view.
     */
    func handleBackToGrid() {
        if uiState.isInSingleView {
            uiState.isInSingleView = false
            uiState.showGridMode = true
        }
    }
    
    /**
     * Handles returning from profile single view.
     */
    func handleBackFromProfileSingleView() {
        if uiState.isInProfileSingleView {
            uiState.isInProfileSingleView = false
        }
    }

    
    /**
     * Resets navigation to initial state for the current tab.
     * This ensures that tapping a tab button returns to the root view of that tab.
     */
    func resetTabNavigation(resetPaths: @escaping () -> Void) {
        // Call the path reset closure first
        resetPaths()
        // Reset UI states to initial values
        uiState.isInSingleView = false
        uiState.isInProfileSingleView = false
        uiState.showGridMode = false
        
        // Close any open modals
        navigationState.showingCreatePost = false
        navigationState.showingPhotoEditor = false
        navigationState.showingCamera = false
        navigationState.showingSettings = false
        navigationState.showingPostTypeSelection = false
        
        // Clear presentation data
        presentationState.editorData = nil
        presentationState.selectedImage = nil
        
        // Send notifications to reset individual views
        NotificationCenter.default.post(name: .resetGalleryNavigation, object: nil)
        NotificationCenter.default.post(name: .resetMessagesNavigation, object: nil)
        NotificationCenter.default.post(name: .resetProfileNavigation, object: nil)
        NotificationCenter.default.post(name: .resetHomeNavigation, object: nil)
        
        dependencies.logger.info("Tab navigation reset to initial state", file: #file, function: #function, line: #line)
    }
    
    
    
    /**
     * Handles image selection from photo picker.
     * - Parameter editorData: Photo editor data containing selected image
     */
    func handleImageSelected(_ editorData: PhotoEditorData) {
        print("🎯 handleImageSelected called with editorData")
        
        // Store the editor data first
        self.presentationState.editorData = editorData
        
        // Set photo editor to show
        self.navigationState.showingPhotoEditor = true
        
        // Then close the photo picker after a small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.navigationState.showingCreatePost = false
        }
        
        print("✅ showingPhotoEditor set to true, editorData stored")
    }
    
    /**
     * Handles photo editing completion.
     * - Parameter editedImage: The edited image from photo editor
     */
    func handlePhotoEditingComplete(_ editedImage: UIImage) {
        print("🔥 handlePhotoEditingComplete called with edited image")
        dependencies.logger.info("Photo editing completed", file: #file, function: #function, line: #line)
        
        // Store the edited image for post composition
        presentationState.editedImage = editedImage
        print("📝 Edited image stored for post composition")
        
        // Clear editor data
        presentationState.editorData = nil
        print("🧹 Editor data cleared")
        
        // Close photo editor and show post composition screen
        navigationState.showingPhotoEditor = false
        navigationState.showingPostComposition = true
        
        print("📝 Transitioning to post composition screen")
        print("📝 showingPhotoEditor: \(navigationState.showingPhotoEditor)")
        print("📝 showingPostComposition: \(navigationState.showingPostComposition)")
    }
    
    /**
     * Handles photo editing cancellation.
     */
    func handlePhotoEditingCancelled() {
        dependencies.logger.info("Photo editing cancelled - returning to photo picker", file: #file, function: #function, line: #line)
        
        // Clear editor data first to prevent retain cycles
        presentationState.editorData = nil
        
        // Use DispatchQueue to safely update UI state and return to photo picker
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Close photo editor and return to photo picker
            self.navigationState.showingPhotoEditor = false
            self.navigationState.showingCreatePost = true
        }
    }
    
    /**
     * Handles completion of post composition.
     */
    func handlePostCompositionComplete() {
        dependencies.logger.info("Post composition completed successfully", file: #file, function: #function, line: #line)
        navigationState.showingPostComposition = false
        presentationState.editedImage = nil
        
        // Navigate to home feed to show the new post
        selectedTab = 0
    }
    
    /**
     * Handles cancellation of post composition.
     */
    func handlePostCompositionCancelled() {
        dependencies.logger.info("Post composition cancelled", file: #file, function: #function, line: #line)
        
        // Return to photo editor
        navigationState.showingPostComposition = false
        navigationState.showingPhotoEditor = true
    }
}