//======================================================================
// MARK: - ArticleDetailView.swift
// Purpose: SwiftUI view component (ArticleDetailViewビューコンポーネント)
// Path: still/Features/Articles/Views/ArticleDetailView.swift
//======================================================================
//
//  ArticleDetailView.swift
//  tete
//
//  記事詳細表示画面
//

import SwiftUI

struct ArticleDetailView: View {
    let article: BlogArticle
    @StateObject private var viewModel = ArticleDetailViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showMenu: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header with search
            UnifiedHeader(
                title: "記事",
                showBackButton: true,
                rightButton: HeaderButton(
                    icon: "ellipsis.circle",
                    action: {
                        showMenu = true
                    }
                ),
                onBack: {
                    dismiss()
                }
            )
            
            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cover Image
                if let coverImageUrl = article.coverImageUrl {
                    AsyncImage(url: URL(string: coverImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(ProgressView())
                    }
                    .frame(height: 250)
                    .clipped()
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Header Info
                    headerSection
                    
                    // Title
                    Text(article.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .lineLimit(nil)
                    
                    // Author and Date
                    authorSection
                    
                    // Tags
                    if !article.tags.isEmpty {
                        tagsSection
                    }
                    
                    // Summary
                    if let summary = article.summary {
                        summarySection(summary)
                    }
                    
                    Divider()
                    
                    // Content
                    contentSection
                    
                    // Actions
                    actionsSection
                }
                .padding(.horizontal, 16)
            }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadArticleDetail(articleId: article.id)
        }
        .sheet(isPresented: $showMenu) {
            VStack(alignment: .leading, spacing: 16) {
                Button(action: {
                    showMenu = false
                    // TODO: Share functionality
                }) {
                    Label("シェア", systemImage: "square.and.arrow.up")
                }
                
                Button(action: {
                    showMenu = false
                    // TODO: Bookmark functionality
                }) {
                    Label("ブックマーク", systemImage: "bookmark")
                }
                
                if article.user?.id == AuthManager.shared.currentUser?.id {
                    Button(action: {
                        showMenu = false
                        // TODO: Edit functionality
                    }) {
                        Label("編集", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        showMenu = false
                        // TODO: Delete functionality
                    }) {
                        Label("削除", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
            }
            .padding()
            .presentationDetents([.height(250)])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Category
            if let category = article.category,
               let categoryEnum = ArticleCategory(rawValue: category) {
                HStack(spacing: 4) {
                    Image(systemName: categoryEnum.icon)
                        .font(.caption)
                    Text(categoryEnum.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
            
            
            Spacer()
            
            // Stats
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.caption)
                    Text("\(viewModel.detailArticle?.likeCount ?? article.likeCount)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                        .font(.caption)
                    Text("\(viewModel.detailArticle?.viewCount ?? article.viewCount)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Author Section
    
    private var authorSection: some View {
        HStack(spacing: 12) {
            // Avatar
            if let user = article.user {
                AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(user.username.prefix(1).uppercased())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.username)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let publishedAt = article.publishedAt {
                        Text(timeAgoString(from: publishedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(article.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    // MARK: - Summary Section
    
    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("要約")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(summary)
                .font(.body)
                .padding(12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("記事内容")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(article.content)
                .font(.body)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            Divider()
            
            HStack(spacing: 24) {
                // Like Button
                Button(action: {
                    Task {
                        await viewModel.toggleLike()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: (viewModel.detailArticle?.isLikedByMe ?? article.isLikedByMe) ? "heart.fill" : "heart")
                            .font(.title3)
                        Text("\(viewModel.detailArticle?.likeCount ?? article.likeCount)")
                            .font(.subheadline)
                    }
                    .foregroundColor((viewModel.detailArticle?.isLikedByMe ?? article.isLikedByMe) ? .red : .primary)
                }
                
                Spacer()
                
                // Share Button
                Button("シェア") {
                    // TODO: Share functionality
                }
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(20)
                
                // Bookmark Button
                Button(action: {
                    // TODO: Bookmark functionality
                }) {
                    Image(systemName: "bookmark")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationView {
        ArticleDetailView(article: BlogArticle(
            id: UUID().uuidString,
            userId: UUID().uuidString,
            title: "Sample Article Title",
            content: "This is a sample article content...",
            summary: "This is a summary",
            category: "technology",
            tags: ["iOS", "SwiftUI", "Tech"],
            isPremium: false,
            coverImageUrl: nil,
            status: .published,
            articleType: .magazine,
            publishedAt: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            viewCount: 123,
            likeCount: 45
        ))
    }
}