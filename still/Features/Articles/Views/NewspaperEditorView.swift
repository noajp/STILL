//======================================================================
// MARK: - NewspaperEditorView.swift
// Purpose: SwiftUI view component (NewspaperEditorViewビューコンポーネント)
// Path: still/Features/Articles/Views/NewspaperEditorView.swift
//======================================================================
//
//  NewspaperEditorView.swift
//  tete
//
//  新聞記事風エディター（縦書き・右から左）
//

import SwiftUI
import PhotosUI

struct NewspaperEditorView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateArticleViewModel()
    
    @State private var title = ""
    @State private var content = ""
    @State private var summary = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var coverImageItem: PhotosPickerItem?
    @State private var coverImageUrl: String?
    @State private var showingPublishOptions = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 新聞風の背景
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // ヘッダー画像選択
                        headerImageSection
                        
                        // 新聞風レイアウト
                        VStack(spacing: 24) {
                            // 見出し
                            headlineSection
                            
                            // タグ
                            tagsOnlySection
                            
                            // 本文（縦書き風）
                            newspaperContentSection
                            
                            // 要約
                            summarySection
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("新聞記事")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("発行") {
                        showingPublishOptions = true
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                    .foregroundColor(.primary)
                }
            }
        }
        .alert("記事を投稿しますか？", isPresented: $showingPublishOptions) {
            Button("投稿") {
                Task {
                    await viewModel.createArticle(
                        title: title,
                        content: content,
                        summary: summary.isEmpty ? nil : summary,
                        category: "other",
                        tags: tags,
                        isPremium: false,
                        coverImageUrl: coverImageUrl,
                        status: .published,
                        articleType: .newspaper
                    )
                    dismiss()
                }
            }
            Button("キャンセル", role: .cancel) { }
        }
        .onChange(of: coverImageItem) { _, newItem in
            Task {
                let uploadedUrl = await viewModel.uploadCoverImage(item: newItem)
                await MainActor.run {
                    coverImageUrl = uploadedUrl
                }
            }
        }
    }
    
    // MARK: - Header Image Section
    
    @MainActor
    private var headerImageSection: some View {
        let imageUrl = coverImageUrl // ローカルコピーでmain actor isolationを回避
        
        return PhotosPicker(selection: $coverImageItem, matching: .images) {
            if let imageUrl = imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(ProgressView())
                }
                .frame(height: 200)
                .clipped()
                .overlay(
                    VStack {
                        Color.clear
                        HStack {
                            Color.clear.frame(maxWidth: .infinity)
                            Text("写真を変更")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .padding()
                        }
                    }
                )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("ヘッダー写真を選択")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Headline Section
    
    private var headlineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("見出し")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.secondary)
            
            TextField("記事の見出しを入力", text: $title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.leading)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.vertical, 8)
        }
    }
    
    // MARK: - Tags Only Section
    
    private var tagsOnlySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("キーワード")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack {
                TextField("関連キーワードを追加", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }
                
                Button("追加") {
                    addTag()
                }
                .disabled(newTag.isEmpty)
            }
            
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.caption)
                                Button(action: { removeTag(tag) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }
    
    // MARK: - Newspaper Content Section
    
    private var newspaperContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("記事本文")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("縦書き風表示")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 新聞風のコンテンツエリア
            VStack(alignment: .leading, spacing: 0) {
                // 入力欄
                TextField("記事の内容を書いてください...", text: $content, axis: .vertical)
                    .font(.system(size: 16, design: .serif))
                    .lineSpacing(6)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .lineLimit(15...50)
                
                // プレビュー（新聞風スタイル）
                if !content.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("プレビュー")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 12)
                        
                        Text(content)
                            .font(.system(size: 16, design: .serif))
                            .lineSpacing(8)
                            .multilineTextAlignment(.leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("要約（任意）")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField("記事の要約を入力", text: $summary, axis: .vertical)
                .font(.system(size: 14))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Helper Methods
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

#Preview {
    NewspaperEditorView()
}