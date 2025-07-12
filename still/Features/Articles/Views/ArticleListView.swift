//======================================================================
// MARK: - ArticleListView.swift
// Purpose: Article list with left photo and right text layout
// Path: still/Features/Articles/Views/ArticleListView.swift
//======================================================================

import SwiftUI

struct ArticleListView: View {
    @StateObject private var viewModel = ArticleListViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollableHeaderView(
                title: "Articles"
            ) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.articles) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        ArticleRowView(article: article)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                        .padding(.leading, 16)
                }
                }
                .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
            
            // カスタム投稿ボタン
            NavigationLink(destination: CreateArticleView()) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(width: 44, height: 44)
            }
            .padding(.top, 55)
            .padding(.trailing, 16)
        }
        .task {
            await viewModel.loadArticles()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ArticleCreated"))) { _ in
            Task {
                await viewModel.refreshArticles()
            }
        }
    }
}

// MARK: - Article Row View

struct ArticleRowView: View {
    let article: BlogArticle
    @Environment(\.colorScheme) var colorScheme
    
    // Feed画面の正方形写真の高さと同じサイズを計算
    private var squareSize: CGFloat {
        // 画面幅から余白を引いて3等分したサイズ（Feed画面のグリッドと同じ）
        (UIScreen.main.bounds.width - 4) / 3
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Left: Photo
            if let coverImageUrl = article.coverImageUrl {
                AsyncImage(url: URL(string: coverImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: squareSize, height: squareSize)
                        .clipped()
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: squareSize, height: squareSize)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                        )
                }
            } else {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: squareSize, height: squareSize)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    )
            }
            
            // Right: Text Content
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(article.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // User ID
                if let user = article.user {
                    Text("@\(user.username)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: squareSize)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    ArticleListView()
}
