//======================================================================
// MARK: - 6. SearchView.swift の修正（検索結果の表示）
// Path: foodai/Features/Search/Views/SearchView.swift
//======================================================================
import SwiftUI

@MainActor
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var selectedTab: SearchTab = .posts
    
    enum SearchTab: String, CaseIterable {
        case posts = "Posts"
        case users = "Users"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Unified Header
                UnifiedHeader(title: "Search")
                
                // 検索バー
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
                
                // タブスイッチャー
                HStack(spacing: 0) {
                    ForEach(SearchTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                            // タブ切り替え時に検索を実行
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
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 2)
                        .offset(x: selectedTab == .posts ? -UIScreen.main.bounds.width/4 : UIScreen.main.bounds.width/4)
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    , alignment: .bottom
                )
                .padding(.horizontal)
                
                // 検索結果表示
                if selectedTab == .posts {
                    if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                        // 検索結果なし
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding()
                            Text("「\(viewModel.searchText)」の検索結果はありません")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !viewModel.searchResults.isEmpty {
                        // 投稿検索結果を表示
                        ScrollView {
                            // TODO: Implement post search results display
                            Text("Post search coming soon")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .padding(.horizontal)
                    } else {
                        // デフォルト表示
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
                    // ユーザー検索結果
                    if viewModel.userSearchResults.isEmpty && !viewModel.searchText.isEmpty {
                        // ユーザー検索結果なし
                        VStack {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding()
                            Text("「\(viewModel.searchText)」のユーザーが見つかりません")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !viewModel.userSearchResults.isEmpty {
                        // ユーザー検索結果を表示
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.userSearchResults) { user in
                                    UserSearchResultView(user: user)
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // ユーザー検索デフォルト表示
                        VStack {
                            Image(systemName: "person.2.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding()
                            Text("ユーザーを検索してみましょう")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

