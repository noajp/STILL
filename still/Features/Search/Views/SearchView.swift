//======================================================================
// MARK: - 6. SearchView.swift の修正（検索結果の表示）
// Path: foodai/Features/Search/Views/SearchView.swift
//======================================================================
import SwiftUI

@MainActor
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Unified Header
                UnifiedHeader(title: "Search")
                
                // 検索バー
                SearchBarView(searchText: $viewModel.searchText, onSearch: viewModel.search)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
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
                    // 検索結果を表示
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 16) {
                            ForEach(viewModel.searchResults) { post in
                                PinCardView(post: post, onLikeTapped: { _ in
                                    // TODO: Add like functionality to search
                                })
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
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
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

