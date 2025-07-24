//======================================================================
// MARK: - ModernArticleListView.swift
// Purpose: Modern blog-style article list view
// Path: still/Features/Articles/Views/ModernArticleListView.swift
//======================================================================

import SwiftUI
import PhotosUI

struct ModernArticleListView: View {
    @StateObject private var viewModel = ArticleListViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var showingArticleEditor = false
    @State private var selectedCategory = "For You"
    
    let categories = ["For You", "Following"]
    
    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 0) {
                    // Category tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    VStack(spacing: 4) {
                                        Text(category)
                                            .font(.system(size: 15, weight: selectedCategory == category ? .semibold : .regular))
                                            .foregroundColor(selectedCategory == category ? .primary : .secondary)
                                        
                                        // Underline for selected
                                        Rectangle()
                                            .fill(selectedCategory == category ? Color.primary : Color.clear)
                                            .frame(height: 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Article list
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.articles) { article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                ModernArticleCard(article: article)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.top, 105) // UnifiedHeaderの高さ分のスペース
            }
            
            // Fixed Header (same as STILL)
            VStack(spacing: 0) {
                UnifiedHeader(
                    title: "Articles",
                    rightButton: HeaderButton(
                        icon: "square.and.pencil",
                        action: { showingArticleEditor = true }
                    )
                )
                
                Spacer()
            }
        }
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $showingArticleEditor) {
            ModernArticleEditorView()
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

// MARK: - Modern Article Card
struct ModernArticleCard: View {
    let article: BlogArticle
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // Cover image (left side)
                if let coverImageUrl = article.coverImageUrl {
                    AsyncImage(url: URL(string: coverImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(8)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.tertiarySystemBackground))
                            .frame(width: 120, height: 120)
                            .overlay(
                                ProgressView()
                            )
                    }
                } else {
                    // Default placeholder if no cover image
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                }
                
                // Text content (right side)
                VStack(alignment: .leading, spacing: 8) {
                    // Author info
                    HStack(spacing: 8) {
                        // Author avatar
                        if let user = article.user, let avatarUrl = user.avatarUrl {
                            AsyncImage(url: URL(string: avatarUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 24, height: 24)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.tertiarySystemBackground))
                                    .frame(width: 24, height: 24)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.tertiarySystemBackground))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        if let user = article.user {
                            Text(user.displayName ?? user.username)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Text("·")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(article.createdAt))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    // Title
                    Text(article.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Excerpt/Preview
                    if let content = extractPlainText(from: article.content) {
                        Text(content)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Reading time and category
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text("\(calculateReadingTime(article.content)) min read")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                        
                        if let category = article.category {
                            Text(category)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(12)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            
            Divider()
                .padding(.leading, 20)
        }
        .background(Color(.systemBackground))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func extractPlainText(from content: String) -> String? {
        // Simple HTML tag removal (you might want to use a proper HTML parser)
        let plainText = content
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return plainText.isEmpty ? nil : plainText
    }
    
    private func calculateReadingTime(_ content: String) -> Int {
        let wordsPerMinute = 200
        let wordCount = content.split(separator: " ").count
        let readingTime = max(1, wordCount / wordsPerMinute)
        return readingTime
    }
}

#Preview {
    ModernArticleListView()
}