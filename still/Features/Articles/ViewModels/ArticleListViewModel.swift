//======================================================================
// MARK: - ArticleListViewModel.swift
// Purpose: View model for data and business logic (ArticleListViewModelのデータとビジネスロジック)
// Path: still/Features/Articles/ViewModels/ArticleListViewModel.swift
//======================================================================
//
//  ArticleListViewModel.swift
//  tete
//
//  記事一覧用ViewModel
//

import Foundation

@MainActor
class ArticleListViewModel: ObservableObject {
    @Published var articles: [BlogArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let articleRepository = ArticleRepository.shared
    private var currentOffset = 0
    private let pageSize = 20
    
    /// 記事一覧を読み込み
    func loadArticles() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let newArticles = try await articleRepository.getPublishedArticles(
                limit: pageSize,
                offset: currentOffset
            )
            
            if currentOffset == 0 {
                articles = newArticles
            } else {
                articles.append(contentsOf: newArticles)
            }
            
            currentOffset += newArticles.count
            print("✅ Loaded \(newArticles.count) articles")
            
        } catch {
            print("❌ Failed to load articles: \(error)")
            errorMessage = "記事の読み込みに失敗しました"
        }
        
        isLoading = false
    }
    
    /// 記事一覧を更新（pull-to-refresh）
    func refreshArticles() async {
        currentOffset = 0
        await loadArticles()
    }
    
    /// 次のページを読み込み
    func loadMoreArticles() async {
        await loadArticles()
    }
    
    /// カテゴリ別記事を読み込み
    func loadArticlesByCategory(_ category: ArticleCategory) async {
        isLoading = true
        errorMessage = nil
        
        do {
            articles = try await articleRepository.getArticlesByCategory(
                category.rawValue,
                limit: pageSize
            )
            print("✅ Loaded \(articles.count) articles for category: \(category.displayName)")
            
        } catch {
            print("❌ Failed to load articles by category: \(error)")
            errorMessage = "記事の読み込みに失敗しました"
        }
        
        isLoading = false
    }
    
    /// 記事を検索
    func searchArticles(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await refreshArticles()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            articles = try await articleRepository.searchArticles(
                query: query,
                limit: pageSize
            )
            print("✅ Found \(articles.count) articles for query: \(query)")
            
        } catch {
            print("❌ Failed to search articles: \(error)")
            errorMessage = "記事の検索に失敗しました"
        }
        
        isLoading = false
    }
    
    /// 記事にいいね/いいね取り消し
    func toggleLike(for article: BlogArticle) async {
        do {
            let isLiked = try await articleRepository.toggleArticleLike(articleId: article.id)
            
            // ローカルの状態を更新
            if let index = articles.firstIndex(where: { $0.id == article.id }) {
                var updatedArticle = articles[index]
                updatedArticle.isLikedByMe = isLiked
                updatedArticle.likeCount += isLiked ? 1 : -1
                articles[index] = updatedArticle
            }
            
            print("✅ Article like toggled: \(article.id), liked: \(isLiked)")
            
        } catch {
            print("❌ Failed to toggle like: \(error)")
            errorMessage = "いいねの操作に失敗しました"
        }
    }
}