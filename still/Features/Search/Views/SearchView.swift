//======================================================================
// MARK: - SearchView.swift
// Purpose: Main search interface with tabbed search for posts and users
// Path: still/Features/Search/Views/SearchView.swift
//======================================================================
import SwiftUI

/**
 * SearchView provides the main search interface for the STILL app.
 * 
 * This view supports dual-mode searching with tabbed interface:
 * - Posts search: Find posts by content, hashtags, or captions
 * - Users search: Find users by username, display name, or bio
 * 
 * Features:
 * - Real-time search with debouncing for performance
 * - Animated tab switching with visual indicators
 * - Empty state handling for no results
 * - Popular posts and trending content discovery
 * - Pull-to-refresh functionality
 * - Responsive layout adaptation
 */
@MainActor
struct SearchView: View {
    // MARK: - Properties
    
    /// View model managing search operations and results
    @StateObject private var viewModel = SearchViewModel()
    
    /// Currently selected search tab (posts or users)
    @State private var selectedTab: SearchTab = .posts
    
    // MARK: - Search Tab Definition
    
    /// Available search categories with localized display names
    enum SearchTab: String, CaseIterable {
        case posts = "Posts"
        case users = "Users"
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                // Unified Header
                UnifiedHeader(title: "SEARCH")
                
                // Search input bar with real-time search functionality
                SearchBarView(searchText: $viewModel.searchText) { searchQuery in
                    switch selectedTab {
                    case .posts:
                        viewModel.searchPosts(searchQuery)
                    case .users:
                        viewModel.searchUsers(searchQuery)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Tab switcher with animated selection indicator
                HStack(spacing: 0) {
                    ForEach(SearchTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                            // Execute search when switching tabs if query exists
                            if !viewModel.searchText.isEmpty {
                                switch tab {
                                case .posts:
                                    viewModel.searchPosts(viewModel.searchText)
                                case .users:
                                    viewModel.searchUsers(viewModel.searchText)
                                }
                            }
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 16, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                }
                .background(MinimalDesign.Colors.background)
                .overlay(
                    // Animated selection indicator that slides between tabs
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 2)
                        .offset(x: selectedTab == .posts ? -geometry.size.width/4 : geometry.size.width/4)
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    , alignment: .bottom
                )
                .padding(.horizontal)
                
                // Search results display based on selected tab
                if selectedTab == .posts {
                    if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                        // Empty state for posts search
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding()
                            Text("No posts found for '\(viewModel.searchText)'")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !viewModel.searchResults.isEmpty {
                        // Display post search results
                        ScrollView {
                            // TODO: Implement post search results display
                            Text("Post search coming soon")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .padding(.horizontal)
                    } else {
                        // Default discovery content when no search is active
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                PopularSearchSection()
                                SearchTrendsSection()
                            }
                            .padding()
                        }
                        .refreshable {
                            viewModel.refreshPopularPosts()
                        }
                    }
                } else {
                    // User search results display
                    if viewModel.userSearchResults.isEmpty && !viewModel.searchText.isEmpty {
                        // Empty state for user search
                        VStack {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding()
                            Text("No users found for '\(viewModel.searchText)'")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !viewModel.userSearchResults.isEmpty {
                        // Display user search results in scrollable list
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.userSearchResults) { user in
                                    UserSearchResultView(user: user)
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // Default state encouraging user search
                        VStack {
                            Image(systemName: "person.2.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding()
                            Text("Search for users to connect")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                }
                .background(MinimalDesign.Colors.background)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

