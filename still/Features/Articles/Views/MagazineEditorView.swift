//======================================================================
// MARK: - MagazineEditorView.swift
// Purpose: SwiftUI view component (MagazineEditorViewビューコンポーネント)
// Path: still/Features/Articles/Views/MagazineEditorView.swift
//======================================================================
//
//  MagazineEditorView.swift
//  tete
//
//  雑誌記事風エディター（スタイリッシュ・横書き）
//

import SwiftUI
import PhotosUI

struct MagazineEditorView: View {
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
                // 雑誌風のグラデーション背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.05),
                        Color.purple.opacity(0.1),
                        Color.pink.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 雑誌風ヘッダー
                        magazineHeaderSection
                        
                        // メインコンテンツ
                        VStack(spacing: 24) {
                            // タイトル（雑誌風）
                            magazineTitleSection
                            
                            // タグ
                            tagsOnlySection
                            
                            // 本文（雑誌風レイアウト）
                            magazineContentSection
                            
                            // サマリー
                            magazineSummarySection
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationTitle("雑誌記事")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("公開") {
                        showingPublishOptions = true
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
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
                        articleType: .magazine
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
    
    // MARK: - Magazine Header Section
    
    @MainActor
    private var magazineHeaderSection: some View {
        let imageUrl = coverImageUrl // ローカルコピーでmain actor isolationを回避
        
        return PhotosPicker(selection: $coverImageItem, matching: .images) {
            if let imageUrl = imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(ProgressView().tint(.white))
                }
                .frame(height: 250)
                .clipped()
                .overlay(
                    // スタイリッシュなオーバーレイ
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    VStack {
                        Color.clear
                        HStack {
                            Color.clear.frame(maxWidth: .infinity)
                            Text("画像を変更")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.9))
                                .foregroundColor(.black)
                                .cornerRadius(20)
                                .padding()
                        }
                    }
                )
                .cornerRadius(16)
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.2), Color.pink.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 250)
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "photo.artframe")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.8))
                            Text("スタイリッシュなカバー画像を選択")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                    )
                    .cornerRadius(16)
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Magazine Title Section
    
    private var magazineTitleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("特集タイトル")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(1)
            
            TextField("魅力的なタイトルを入力...", text: $title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.leading)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.primary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Tags Only Section
    
    private var tagsOnlySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TAGS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(1.5)
            
            HStack {
                TextField("スタイリッシュなタグを追加", text: $newTag)
                    .font(.system(size: 16, design: .rounded))
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .onSubmit {
                        addTag()
                    }
                
                Button("ADD") {
                    addTag()
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(10)
                .disabled(newTag.isEmpty)
            }
            
            if !tags.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100))
                ], spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 6) {
                            Text("#\(tag)")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Button(action: { removeTag(tag) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(colors: [.purple.opacity(0.8), .pink.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Magazine Content Section
    
    private var magazineContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ARTICLE CONTENT")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(1.5)
            
            TextField("あなたのストーリーを書いてください...", text: $content, axis: .vertical)
                .font(.system(size: 18, design: .rounded))
                .lineSpacing(8)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(colors: [.purple.opacity(0.3), .pink.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 2
                                )
                        )
                )
                .lineLimit(10...40)
            
            // スタイリッシュなプレビュー
            if !content.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PREVIEW")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.5)
                    
                    Text(content)
                        .font(.system(size: 16, design: .rounded))
                        .lineSpacing(6)
                        .multilineTextAlignment(.leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.9), Color.gray.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Magazine Summary Section
    
    private var magazineSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUMMARY")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(1.5)
            
            TextField("魅力的な要約を書いてください...", text: $summary, axis: .vertical)
                .font(.system(size: 16, design: .rounded))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .lineLimit(3...8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Methods
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            withAnimation(.spring(response: 0.3)) {
                tags.append(trimmedTag)
                newTag = ""
            }
        }
    }
    
    private func removeTag(_ tag: String) {
        withAnimation(.spring(response: 0.3)) {
            tags.removeAll { $0 == tag }
        }
    }
}

#Preview {
    MagazineEditorView()
}