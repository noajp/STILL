//======================================================================
// MARK: - MagazineView.swift
// Purpose: SwiftUI view component (MagazineViewビューコンポーネント)
// Path: still/Features/Magazine/Views/MagazineView.swift
//======================================================================
import SwiftUI
import Foundation

struct MagazineFeedView: View {
    @StateObject private var viewModel = MagazineViewModel()
    @State private var showingCreatePost = false
    
    var body: some View {
        ScrollableHeaderView(
            title: "Article",
            rightButton: HeaderButton(icon: "plus", action: {
                showingCreatePost = true
            })
        ) {
            VStack(spacing: 0) {
                    // Magazine content - 奇数段は新聞記事、偶数段は雑誌記事
                    LazyVStack(spacing: 0) {
                        let allArticles = viewModel.articles
                        
                        // 記事タイプ別に分割
                        let newspaperArticles = allArticles.filter { $0.article.articleType == .newspaper }
                        let magazineArticles = allArticles.filter { $0.article.articleType == .magazine }
                        
                        // 交互に表示するためのロジック
                        let maxSections = max(newspaperArticles.count, magazineArticles.count)
                        
                        ForEach(0..<maxSections, id: \.self) { sectionIndex in
                            VStack(spacing: 40) {
                                // 奇数段（新聞記事スタイル）
                                if sectionIndex < newspaperArticles.count {
                                    let article = newspaperArticles[sectionIndex]
                                    VStack(spacing: 16) {
                                        // セクションヘッダー
                                        HStack {
                                            Text("NEWS")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.blue)
                                                .tracking(2)
                                            
                                            Rectangle()
                                                .fill(Color.blue)
                                                .frame(height: 1)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        
                                        // 新聞記事風表示
                                        NavigationLink(destination: ArticleDetailView(article: article.article)) {
                                            NewspaperStyleCard(article: article)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, 12)
                                    }
                                }
                                
                                // 偶数段（雑誌記事スタイル）
                                if sectionIndex < magazineArticles.count {
                                    let article = magazineArticles[sectionIndex]
                                    VStack(spacing: 16) {
                                        // セクションヘッダー
                                        HStack {
                                            Text("MAGAZINE")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.purple)
                                                .tracking(2)
                                            
                                            Rectangle()
                                                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                                                .frame(height: 1)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        
                                        // 雑誌記事風表示
                                        NavigationLink(destination: ArticleDetailView(article: article.article)) {
                                            MagazineStyleCard(article: article)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, 12)
                                    }
                                }
                            }
                            .padding(.bottom, 40)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 100) // タブバー分のスペース
                }
            }
        .onAppear {
            Task {
                await viewModel.loadArticles()
            }
        }
        .fullScreenCover(isPresented: $showingCreatePost) {
            StoryStyleEditorView()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ArticleCreated"))) { _ in
            Task {
                await viewModel.loadArticles()
            }
        }
    }
}


// Article format card (large horizontal photo with text below)
struct ArticleFormatCard: View {
    let article: MagazineArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Large horizontal image
            if let coverImageUrl = article.article.coverImageUrl {
                AsyncImage(url: URL(string: coverImageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                    case .failure(_):
                        Rectangle()
                            .fill(MinimalDesign.Colors.tertiary)
                            .frame(height: 220)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(MinimalDesign.Colors.secondary)
                            )
                    case .empty:
                        Rectangle()
                            .fill(MinimalDesign.Colors.tertiary)
                            .frame(height: 220)
                            .overlay(
                                ProgressView()
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Rectangle()
                    .fill(MinimalDesign.Colors.tertiary)
                    .frame(height: 220)
                    .overlay(
                        Image(systemName: "doc.text")
                            .foregroundColor(MinimalDesign.Colors.secondary)
                            .font(.system(size: 40))
                    )
            }
            
            // Article content below image
            VStack(alignment: .leading, spacing: 8) {
                // Category and date
                HStack {
                    if let category = article.article.category,
                       let categoryEnum = ArticleCategory(rawValue: category) {
                        Text(categoryEnum.displayName.uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.accentRed)
                    }
                    
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(MinimalDesign.Colors.secondary)
                    
                    if let publishedAt = article.article.publishedAt {
                        Text(publishedAt.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.system(size: 12))
                            .foregroundColor(MinimalDesign.Colors.secondary)
                    }
                    
                    Spacer()
                }
                
                // Title
                Text(article.article.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Summary or content preview
                if let summary = article.article.summary {
                    Text(summary)
                        .font(.system(size: 16))
                        .foregroundColor(MinimalDesign.Colors.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                } else {
                    Text(String(article.article.content.prefix(150)) + "...")
                        .font(.system(size: 16))
                        .foregroundColor(MinimalDesign.Colors.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // Author info
                HStack {
                    AsyncImage(url: URL(string: article.article.user?.avatarUrl ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                        default:
                            Circle()
                                .fill(MinimalDesign.Colors.tertiary)
                                .frame(width: 24, height: 24)
                        }
                    }
                    
                    Text("by \(article.article.user?.username ?? "Unknown")")
                        .font(.system(size: 14))
                        .foregroundColor(MinimalDesign.Colors.secondary)
                    
                    Spacer()
                    
                    Text("\(article.readTime) min read")
                        .font(.system(size: 14))
                        .foregroundColor(MinimalDesign.Colors.secondary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16) // Add horizontal padding to text content
        }
    }
}

// Magazine format card (small vertical layout)
struct MagazineFormatCard: View {
    let article: MagazineArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Small vertical magazine-style image
            if let coverImageUrl = article.article.coverImageUrl {
                AsyncImage(url: URL(string: coverImageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(3/4, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                            .clipped()
                    case .failure(_):
                        Rectangle()
                            .fill(MinimalDesign.Colors.tertiary)
                            .frame(height: 150)
                            .overlay(
                                Image(systemName: "doc.text")
                                    .foregroundColor(MinimalDesign.Colors.secondary)
                                    .font(.system(size: 20))
                            )
                    case .empty:
                        Rectangle()
                            .fill(MinimalDesign.Colors.tertiary)
                            .frame(height: 150)
                            .overlay(
                                ProgressView()
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Rectangle()
                    .fill(MinimalDesign.Colors.tertiary)
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "doc.text")
                            .foregroundColor(MinimalDesign.Colors.secondary)
                            .font(.system(size: 20))
                    )
            }
            
            // Simple text below
            VStack(alignment: .leading, spacing: 4) {
                if let category = article.article.category,
                   let categoryEnum = ArticleCategory(rawValue: category) {
                    Text(categoryEnum.displayName.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                }
                
                Text(article.article.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Magazine article model
struct MagazineArticle: Identifiable {
    let id: String
    let article: BlogArticle
    let readTime: Int
    
    init(from blogArticle: BlogArticle) {
        self.id = blogArticle.id
        self.article = blogArticle
        
        // Calculate read time based on content length
        let words = blogArticle.content.split(separator: " ").count
        self.readTime = max(1, words / 200) // Assuming 200 words per minute
    }
}

// View model
@MainActor
class MagazineViewModel: ObservableObject {
    @Published var articles: [MagazineArticle] = []
    
    private let articleRepository = ArticleRepository.shared
    
    func loadArticles() async {
        do {
            // Fetch published articles from ArticleRepository
            let blogArticles = try await articleRepository.getPublishedArticles(limit: 50)
            
            // Convert BlogArticles to MagazineArticles
            articles = blogArticles.map { blogArticle in
                MagazineArticle(from: blogArticle)
            }
            
            print("✅ Loaded \(articles.count) magazine articles")
        } catch {
            print("❌ Error loading magazine articles: \(error)")
        }
    }
}

// MARK: - Newspaper Style Card

struct NewspaperStyleCard: View {
    let article: MagazineArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 新聞風ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let category = article.article.category,
                       let categoryEnum = ArticleCategory(rawValue: category) {
                        Text(categoryEnum.displayName.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                            .tracking(1)
                    }
                    
                    if let publishedAt = article.article.publishedAt {
                        Text(publishedAt.formatted(.dateTime.year().month().day()))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(article.readTime)分で読める")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // タイトル（新聞風）
            Text(article.article.title)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // 画像と本文のレイアウト
            HStack(alignment: .top, spacing: 16) {
                // 本文プレビュー
                VStack(alignment: .leading, spacing: 8) {
                    if let summary = article.article.summary {
                        Text(summary)
                            .font(.system(size: 16, design: .serif))
                            .foregroundColor(.primary)
                            .lineLimit(4)
                    } else {
                        Text(String(article.article.content.prefix(200)) + "...")
                            .font(.system(size: 16, design: .serif))
                            .foregroundColor(.primary)
                            .lineLimit(4)
                    }
                    
                    // 著者情報
                    HStack {
                        if let user = article.article.user {
                            Text("by \(user.username)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart")
                                    .font(.caption)
                                Text("\(article.article.likeCount)")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "eye")
                                    .font(.caption)
                                Text("\(article.article.viewCount)")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 記事画像
                if let coverImageUrl = article.article.coverImageUrl {
                    AsyncImage(url: URL(string: coverImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(4/3, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 120, height: 90)
                    .clipped()
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Magazine Style Card

struct MagazineStyleCard: View {
    let article: MagazineArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 雑誌風画像
            if let coverImageUrl = article.article.coverImageUrl {
                AsyncImage(url: URL(string: coverImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/10, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                }
                .frame(height: 200)
                .clipped()
                .overlay(
                    // スタイリッシュなオーバーレイ
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if let category = article.article.category,
                                   let categoryEnum = ArticleCategory(rawValue: category) {
                                    Text(categoryEnum.displayName.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .tracking(1.5)
                                }
                                
                                Text(article.article.title)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                    }
                )
            }
            
            // 雑誌風コンテンツ
            VStack(alignment: .leading, spacing: 12) {
                // サマリー
                if let summary = article.article.summary {
                    Text(summary)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                } else {
                    Text(String(article.article.content.prefix(150)) + "...")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                
                // タグ
                if !article.article.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(article.article.tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        LinearGradient(colors: [.purple.opacity(0.2), .pink.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .foregroundColor(.purple)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                
                // 著者とメタ情報
                HStack {
                    if let user = article.article.user {
                        HStack(spacing: 8) {
                            AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                            }
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                            
                            Text(user.username)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(article.readTime) min read")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .purple.opacity(0.1), radius: 15, x: 0, y: 8)
        )
    }
}

// Helper extension to chunk arrays
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}