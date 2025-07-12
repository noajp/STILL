//======================================================================
// MARK: - ArticlePublishSettingsView.swift
// Purpose: SwiftUI view component (ArticlePublishSettingsViewビューコンポーネント)
// Path: still/Features/Article/Views/ArticlePublishSettingsView.swift
//======================================================================
//
//  ArticlePublishSettingsView.swift
//  tete
//
//  Article publishing settings screen
//

import SwiftUI

struct ArticlePublishSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var article: Article
    @State private var selectedCategory = ""
    @State private var tagText = ""
    @State private var isPublishing = false
    
    let categories = ["Technology", "Lifestyle", "Art", "Photography", "Design", "Other"]
    
    init(article: Article) {
        _article = State(initialValue: article)
    }
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                customHeader
                
                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Hero section with article preview
                        heroSection
                        
                        // Settings cards
                        VStack(spacing: 20) {
                            categoryCard
                            tagsCard
                                }
                        
                        // Publish CTA
                        publishCTA
                        
                        Color.clear.frame(height: 50)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
        }
    }
    
    // MARK: - Custom Header
    
    private var customHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Publish")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Balance the layout
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.clear)
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            // Elegant title
            VStack(spacing: 8) {
                Text("Ready to Share")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Configure your article settings before publishing")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Article preview card
            articlePreviewCard
        }
    }
    
    private var articlePreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PREVIEW")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.2)
                    
                    if !article.title.isEmpty {
                        Text(article.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    } else {
                        Text("Untitled Article")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .italic()
                    }
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text("DRAFT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                        .tracking(0.5)
                }
            }
            
            // Content preview
            let textBlocks = article.blocks.filter { $0.type == .text && !$0.content.isEmpty }
            if let firstTextBlock = textBlocks.first {
                Text(firstTextBlock.content)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            } else {
                Text("No content available")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
                    .italic()
            }
            
            // Meta info
            HStack {
                Label("Now", systemImage: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                
                if !selectedCategory.isEmpty {
                    Label(selectedCategory, systemImage: "tag")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    
    // MARK: - Category Card
    
    private var categoryCard: some View {
        CategoryCardView(
            selectedCategory: $selectedCategory,
            categories: categories
        )
    }
}

struct CategoryCardView: View {
    @Binding var selectedCategory: String
    let categories: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            CategoryHeader()
            CategoryScrollView(
                selectedCategory: $selectedCategory,
                categories: categories
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct CategoryHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("CATEGORY")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.2)
                
                Text("Choose your article topic")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Image(systemName: "tag.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

struct CategoryScrollView: View {
    @Binding var selectedCategory: String
    let categories: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = selectedCategory == category ? "" : category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

struct CategoryButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                }
                
                Text(category)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .opacity(isSelected ? 0 : 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - ArticlePublishSettingsView Extension
extension ArticlePublishSettingsView {
    
    // MARK: - Tags Card
    
    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TAGS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.2)
                    
                    Text("Add relevant keywords")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "number")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            VStack(alignment: .leading, spacing: 16) {
                TextField("", text: $tagText, prompt: Text("photography, art, design...").foregroundColor(.white.opacity(0.4)))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                
                if !tagText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(tagText.components(separatedBy: ","), id: \.self) { tag in
                                HStack(spacing: 6) {
                                    Image(systemName: "number")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(tag.trimmingCharacters(in: .whitespaces))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    
    // MARK: - Publish CTA
    
    private var publishCTA: some View {
        VStack(spacing: 16) {
            // Final check info
            if canPublish {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                    
                    Text("Ready to publish")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // Publish button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    publishArticle()
                }
            }) {
                HStack(spacing: 12) {
                    if isPublishing {
                        ProgressView()
                            .scaleEffect(0.9)
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                    
                    Text(isPublishing ? "Publishing..." : "Publish Article")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: canPublish ? 
                            [Color.white, Color.white.opacity(0.9)] :
                            [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(canPublish ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .shadow(color: canPublish ? Color.white.opacity(0.2) : Color.clear, radius: 8, y: 4)
            }
            .disabled(!canPublish || isPublishing)
            .scaleEffect(isPublishing ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPublishing)
        }
    }
    
    private var canPublish: Bool {
        !article.title.isEmpty && !article.blocks.allSatisfy { $0.content.isEmpty }
    }
    
    private func publishArticle() {
        isPublishing = true
        
        // Update article
        article.category = selectedCategory
        article.tags = tagText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        article.isPublished = true
        
        Task {
            // Simulate publishing
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                isPublishing = false
                dismiss()
            }
        }
    }
}

#if DEBUG
struct ArticlePublishSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ArticlePublishSettingsView(article: Article())
    }
}
#endif