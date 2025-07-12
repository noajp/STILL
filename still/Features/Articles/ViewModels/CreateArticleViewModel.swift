//======================================================================
// MARK: - CreateArticleViewModel.swift
// Purpose: View model for data and business logic (CreateArticleViewModelのデータとビジネスロジック)
// Path: still/Features/Articles/ViewModels/CreateArticleViewModel.swift
//======================================================================
//
//  CreateArticleViewModel.swift
//  tete
//
//  記事作成用ViewModel
//

import Foundation
import PhotosUI
import SwiftUI

@MainActor
class CreateArticleViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let articleRepository = ArticleRepository.shared
    // TODO: Implement storage service for cover image upload
    
    /// 記事を作成
    func createArticle(
        title: String,
        content: String,
        summary: String?,
        category: String,
        tags: [String],
        isPremium: Bool,
        coverImageUrl: String?,
        status: ArticleStatus,
        articleType: ArticleType = .magazine
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let currentUserId = AuthManager.shared.currentUser?.id else {
                errorMessage = "ユーザー認証が必要です"
                isLoading = false
                return
            }
            
            let request = CreateArticleRequest(
                userId: currentUserId,
                title: title,
                content: content,
                summary: summary,
                category: category,
                tags: tags,
                isPremium: isPremium,
                coverImageUrl: coverImageUrl,
                status: status,
                articleType: articleType
            )
            
            let article = try await articleRepository.createArticle(request)
            print("✅ Article created successfully: \(article.id)")
            
            // 投稿完了通知を送信
            NotificationCenter.default.post(
                name: NSNotification.Name("ArticleCreated"),
                object: article
            )
            
        } catch {
            print("❌ Failed to create article: \(error)")
            errorMessage = "記事の作成に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// カバー画像をアップロード
    func uploadCoverImage(item: PhotosPickerItem?) async -> String? {
        guard let item = item else { return nil }
        
        do {
            // 選択された画像データを取得
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                print("❌ Failed to load image data")
                return nil
            }
            
            // ファイル名を生成
            let fileName = "article_cover_\(UUID().uuidString).jpg"
            
            // Supabase Storageにアップロード
            let supabase = SupabaseManager.shared.client
            
            // 記事用のパスを作成（articles/フォルダに分けて管理）
            let filePath = "articles/\(fileName)"
            
            _ = try await supabase.storage
                .from("user-uploads")
                .upload(filePath, data: imageData)
            
            // 公開URLを構築（既存の投稿画像と同じパターン）
            let projectUrl = SecureConfig.shared.supabaseURL
            let publicUrl = "\(projectUrl)/storage/v1/object/public/user-uploads/\(filePath)"
            
            print("✅ Cover image uploaded: \(publicUrl)")
            return publicUrl
            
        } catch {
            print("❌ Failed to upload cover image: \(error)")
            errorMessage = "画像のアップロードに失敗しました: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// 記事の下書きを自動保存
    func autoSaveDraft(
        title: String,
        content: String,
        summary: String?,
        category: String,
        tags: [String],
        isPremium: Bool,
        coverImageUrl: String?,
        articleType: ArticleType = .magazine
    ) async {
        // 最低限のコンテンツがある場合のみ自動保存
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        do {
            guard let currentUserId = AuthManager.shared.currentUser?.id else {
                return // ユーザーが認証されていない場合は自動保存しない
            }
            
            let request = CreateArticleRequest(
                userId: currentUserId,
                title: title.isEmpty ? "無題の記事" : title,
                content: content,
                summary: summary,
                category: category,
                tags: tags,
                isPremium: isPremium,
                coverImageUrl: coverImageUrl,
                status: .draft,
                articleType: articleType
            )
            
            _ = try await articleRepository.createArticle(request)
            print("✅ Draft auto-saved")
            
        } catch {
            print("❌ Failed to auto-save draft: \(error)")
        }
    }
}