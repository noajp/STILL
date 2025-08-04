//======================================================================
// MARK: - ArticleListView.swift
// Purpose: Article list view with unified header, refresh capability, and navigation to article creation and detail views (統一ヘッダーとリフレッシュ機能、記事作成と詳細画面への遷移を持つ記事一覧ビュー)
// Path: still/Features/Articles/Views/ArticleListView.swift
//======================================================================

import SwiftUI
import PhotosUI

struct ArticleListView: View {
    @StateObject private var viewModel = ArticleListViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollableHeaderView(
            title: "ARTICLES"
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
                
                // タブバー用の下部余白
                Color.clear
                    .frame(height: 110)
            }
            .padding(.vertical, 8)
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
    private func squareSize(for geometry: GeometryProxy) -> CGFloat {
        // 画面幅から余白を引いて3等分したサイズ（Feed画面のグリッドと同じ）
        (geometry.size.width - 4) / 3
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 12) {
            // Left: Photo
            if let coverImageUrl = article.coverImageUrl {
                AsyncImage(url: URL(string: coverImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: squareSize(for: geometry), height: squareSize(for: geometry))
                        .clipped()
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: squareSize(for: geometry), height: squareSize(for: geometry))
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                        )
                }
            } else {
                Rectangle()
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: squareSize(for: geometry), height: squareSize(for: geometry))
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
            .frame(height: squareSize(for: geometry))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}


#Preview {
    ArticleListView()
}
