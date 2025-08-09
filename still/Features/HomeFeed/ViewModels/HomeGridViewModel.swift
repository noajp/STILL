//======================================================================
// MARK: - HomeGridViewModel.swift
// Purpose: Manages grid-specific state and operations for the home grid display
// Path: still/Features/HomeFeed/ViewModels/HomeGridViewModel.swift
//======================================================================

import SwiftUI
import Combine

/**
 * HomeGridViewModel manages the state and operations specific to the grid display mode.
 * 
 * Features:
 * - Grid layout state management
 * - Post filtering and sorting
 * - Image preloading optimization
 * - Navigation state tracking
 * - Upload status coordination
 */
@MainActor
final class HomeGridViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current posts displayed in the grid
    @Published var posts: [Post] = []
    
    /// Loading state for the grid
    @Published var isLoading = false
    
    /// Selected post for navigation
    @Published var selectedPost: Post?
    
    /// Navigation trigger for single post view
    @Published var navigateToSingleView = false
    
    /// Current filter applied to the grid
    @Published var currentFilter: GridFilter = .all
    
    /// Current sort order
    @Published var currentSort: GridSort = .newest
    
    /// Search text for filtering posts
    @Published var searchText = ""
    
    /// Tracks if user is currently in single view
    @Published var isInSingleView = false
    
    // MARK: - Private Properties
    
    private let homeFeedViewModel: HomeFeedViewModel
    private var cancellables = Set<AnyCancellable>()
    private var preloadedImages: Set<String> = []
    
    // MARK: - Initialization
    
    init(homeFeedViewModel: HomeFeedViewModel? = nil) {
        self.homeFeedViewModel = homeFeedViewModel ?? HomeFeedViewModel()
        setupBindings()
    }
    
    // MARK: - Setup Methods
    
    private func setupBindings() {
        // Subscribe to posts from HomeFeedViewModel
        homeFeedViewModel.$posts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] posts in
                self?.updateFilteredPosts(from: posts)
            }
            .store(in: &cancellables)
        
        // Subscribe to loading state
        homeFeedViewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        // Listen for filter changes
        Publishers.CombineLatest3($currentFilter, $currentSort, $searchText)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.updateFilteredPosts(from: self?.homeFeedViewModel.posts ?? [])
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Loads posts if needed
    func loadPostsIfNeeded() async {
        await homeFeedViewModel.loadPostsIfNeeded()
    }
    
    /// Forces refresh of posts
    func forceRefreshPosts() async {
        await homeFeedViewModel.forceRefreshPosts()
    }
    
    /// Preloads grid data for performance
    func preloadGridData() async {
        await homeFeedViewModel.preloadGridData()
    }
    
    /// Handles post selection for navigation
    func selectPost(_ post: Post) {
        print("🔍 GridViewModel - Post selected: \(post.id)")
        selectedPost = post
        navigateToSingleView = true
    }
    
    /// Clears navigation state
    func clearNavigation() {
        selectedPost = nil
        navigateToSingleView = false
        isInSingleView = false
    }
    
    /// Handles like action for a post
    func toggleLike(for post: Post) async {
        await homeFeedViewModel.toggleLike(for: post)
    }
    
    /// Preloads images for grid display
    func preloadGridImages() async {
        let urls = posts.map { $0.mediaUrl }
        await preloadImages(urls)
    }
    
    // MARK: - Filter and Sort Methods
    
    /// Updates the current filter
    func updateFilter(_ filter: GridFilter) {
        currentFilter = filter
    }
    
    /// Updates the current sort order
    func updateSort(_ sort: GridSort) {
        currentSort = sort
    }
    
    /// Clears all filters and search
    func clearFilters() {
        currentFilter = .all
        searchText = ""
    }
    
    // MARK: - Private Methods
    
    private func updateFilteredPosts(from allPosts: [Post]) {
        var filteredPosts = allPosts
        
        // Apply search filter
        if !searchText.isEmpty {
            filteredPosts = filteredPosts.filter { post in
                post.caption?.localizedCaseInsensitiveContains(searchText) == true ||
                post.user?.username.localizedCaseInsensitiveContains(searchText) == true ||
                post.locationName?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply category filter
        switch currentFilter {
        case .all:
            break // No additional filtering
        case .photos:
            // Assume all posts are photos for now
            break
        case .videos:
            // Filter for videos when media type is available
            filteredPosts = filteredPosts.filter { _ in false } // Placeholder
        case .following:
            // Filter for posts from followed users
            filteredPosts = filteredPosts.filter { post in
                // This would need to be implemented based on follow relationships
                true // Placeholder
            }
        case .recent:
            // Filter for recent posts (last 7 days)
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            filteredPosts = filteredPosts.filter { $0.createdAt >= weekAgo }
        case .popular:
            // Filter for popular posts (high like count)
            filteredPosts = filteredPosts.filter { $0.likeCount >= 10 }
        }
        
        // Apply sort order
        switch currentSort {
        case .newest:
            filteredPosts.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            filteredPosts.sort { $0.createdAt < $1.createdAt }
        case .popular:
            filteredPosts.sort { $0.likeCount > $1.likeCount }
        case .trending:
            // Sort by a combination of likes and recency
            filteredPosts.sort { post1, post2 in
                let score1 = calculateTrendingScore(for: post1)
                let score2 = calculateTrendingScore(for: post2)
                return score1 > score2
            }
        }
        
        posts = filteredPosts
    }
    
    private func calculateTrendingScore(for post: Post) -> Double {
        let hoursSincePosted = Date().timeIntervalSince(post.createdAt) / 3600
        let likeScore = Double(post.likeCount)
        let commentScore = Double(post.commentCount) * 2 // Comments worth more
        
        // Decay factor - newer posts get higher scores
        let decayFactor = max(0.1, 1.0 / (1.0 + hoursSincePosted / 24.0))
        
        return (likeScore + commentScore) * decayFactor
    }
    
    private func preloadImages(_ urls: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for (index, url) in urls.enumerated() {
                // Skip if already preloaded
                guard !preloadedImages.contains(url) else { continue }
                
                // Load first 20 images with high priority
                let priority: TaskPriority = index < 20 ? .high : .medium
                
                group.addTask(priority: priority) {
                    // Use ImageCacheManager directly to avoid ambiguous references
                    let _ = await ImageCacheManager.shared.loadImage(from: url)
                    await MainActor.run {
                        self.preloadedImages.insert(url)
                    }
                }
            }
        }
    }
}

// MARK: - Grid Layout Helpers

extension HomeGridViewModel {
    /// Creates optimal grid layout from posts
    func createOptimalGrid() -> [[Post]] {
        var result: [[Post]] = []
        var currentIndex = 0
        var rowIndex = 0
        
        while currentIndex < posts.count {
            let isOddRow = rowIndex % 2 == 0
            
            if isOddRow {
                // Odd row: Try to get 1 landscape/large + 1 square
                let rowSize = min(2, posts.count - currentIndex)
                let rowPosts = Array(posts[currentIndex..<currentIndex + rowSize])
                result.append(rowPosts)
                currentIndex += rowSize
            } else {
                // Even row: Try to get 6 square images
                let rowSize = min(6, posts.count - currentIndex)
                let rowPosts = Array(posts[currentIndex..<currentIndex + rowSize])
                result.append(rowPosts)
                currentIndex += rowSize
            }
            
            rowIndex += 1
        }
        
        return result
    }
}

// MARK: - Navigation Helpers

extension HomeGridViewModel {
    /// Handles navigation back from single view
    func handleNavigationBack() {
        isInSingleView = false
        clearNavigation()
    }
    
    /// Prepares for navigation to single view
    func prepareForSingleView() {
        isInSingleView = true
    }
}