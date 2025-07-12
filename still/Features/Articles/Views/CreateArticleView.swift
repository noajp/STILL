//======================================================================
// MARK: - CreateArticleView.swift
// Purpose: Note-like article creation with photo and text
// Path: still/Features/Articles/Views/CreateArticleView.swift
//======================================================================

import SwiftUI
import PhotosUI

struct CreateArticleView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = CreateArticleViewModel()
    
    @State private var title = ""
    @State private var content = ""
    @State private var coverImageItem: PhotosPickerItem?
    @State private var coverImageUrl: String?
    @State private var isPublishing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text("新しい記事")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: publishArticle) {
                            if isPublishing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("投稿")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor((title.isEmpty || content.isEmpty || coverImageUrl == nil) ? .gray : Color(red: 0.949, green: 0.098, blue: 0.020))
                            }
                        }
                        .disabled(title.isEmpty || content.isEmpty || coverImageUrl == nil || isPublishing)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // Photo Section
                    photoSection
                    
                    Divider()
                    
                    // Article Content
                    VStack(alignment: .leading, spacing: 20) {
                        // Title Input
                        TextField("タイトル", text: $title, axis: .vertical)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1...3)
                        
                        // Content Input
                        TextField("本文を入力...", text: $content, axis: .vertical)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .lineLimit(10...100)
                            .frame(minHeight: 300)
                    }
                    .padding()
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .onChange(of: coverImageItem) { _, newItem in
            Task { @MainActor in
                coverImageUrl = await viewModel.uploadCoverImage(item: newItem)
            }
        }
    }
    
    // MARK: - Photo Section
    
    private var photoSection: some View {
        VStack(spacing: 0) {
            if let imageUrl = coverImageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 250)
                        .overlay(
                            ProgressView()
                        )
                }
                .overlay(alignment: .topTrailing) {
                    Button(action: { 
                        coverImageUrl = nil
                        coverImageItem = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(8)
                }
            } else {
                PhotosPicker(selection: $coverImageItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("写真を選択")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("タップして写真を追加")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color(.tertiarySystemBackground))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Actions
    
    private func publishArticle() {
        isPublishing = true
        
        Task {
            await viewModel.createArticle(
                title: title,
                content: content,
                summary: nil,
                category: "article",
                tags: [],
                isPremium: false,
                coverImageUrl: coverImageUrl,
                status: .published,
                articleType: .magazine
            )
            
            await MainActor.run {
                isPublishing = false
                dismiss()
            }
        }
    }
}

#Preview {
    CreateArticleView()
}