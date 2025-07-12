//======================================================================
// MARK: - ArticleDetailViewModel.swift
// Purpose: View model for data and business logic (ArticleDetailViewModelのデータとビジネスロジック)
// Path: still/Features/Articles/ViewModels/ArticleDetailViewModel.swift
//======================================================================
//
//  ArticleDetailViewModel.swift
//  tete
//
//  記事詳細用ViewModel
//

import Foundation

@MainActor
class ArticleDetailViewModel: ObservableObject {
    @Published var detailArticle: BlogArticle?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let articleRepository = ArticleRepository.shared
    
    /// 記事詳細を読み込み
    func loadArticleDetail(articleId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            detailArticle = try await articleRepository.getArticle(id: articleId)
            print("✅ Article detail loaded: \(articleId)")
            
        } catch {
            print("❌ Failed to load article detail: \(error)")
            errorMessage = "記事の読み込みに失敗しました"
        }
        
        isLoading = false
    }
    
    /// 記事にいいね/いいね取り消し
    func toggleLike() async {
        guard let article = detailArticle else { return }
        
        do {
            let isLiked = try await articleRepository.toggleArticleLike(articleId: article.id)
            
            // ローカルの状態を更新
            var updatedArticle = article
            updatedArticle.isLikedByMe = isLiked
            updatedArticle.likeCount += isLiked ? 1 : -1
            detailArticle = updatedArticle
            
            print("✅ Article like toggled: \(article.id), liked: \(isLiked)")
            
        } catch {
            print("❌ Failed to toggle like: \(error)")
            errorMessage = "いいねの操作に失敗しました"
        }
    }
}