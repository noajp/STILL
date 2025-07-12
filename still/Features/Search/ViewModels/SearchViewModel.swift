//======================================================================
// MARK: - SearchViewModel.swift（写真共有アプリ版）
// Path: foodai/Features/Search/ViewModels/SearchViewModel.swift
//======================================================================
import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchResults: [Post] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var popularPosts: [Post] = []
    
    private let postService = PostService()
    private var hasLoadedInitially = false
    
    init() {
        loadPopularPostsIfNeeded()
    }
    
    func search(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let allPosts = try await postService.fetchFeedPosts()
                self.searchResults = allPosts.filter { post in
                    // キャプション、ユーザー名、位置情報で検索
                    post.caption?.localizedCaseInsensitiveContains(query) ?? false ||
                    post.user?.username.localizedCaseInsensitiveContains(query) ?? false ||
                    post.user?.displayName?.localizedCaseInsensitiveContains(query) ?? false ||
                    post.locationName?.localizedCaseInsensitiveContains(query) ?? false
                }
                self.isLoading = false
            } catch {
                self.errorMessage = "検索に失敗しました"
                self.isLoading = false
            }
        }
    }
    
    private func loadPopularPostsIfNeeded() {
        guard !hasLoadedInitially else { return }
        loadPopularPosts()
    }
    
    func refreshPopularPosts() {
        hasLoadedInitially = false // Reset flag to force reload
        loadPopularPosts()
    }
    
    private func loadPopularPosts() {
        Task {
            do {
                let allPosts = try await postService.fetchFeedPosts()
                // いいね数で人気投稿をソート
                self.popularPosts = allPosts.sorted { $0.likeCount > $1.likeCount }
                self.hasLoadedInitially = true
            } catch {
                print("人気投稿の取得に失敗: \(error)")
            }
        }
    }
    
    func showFilters() {
        // フィルター画面を表示
    }
}

