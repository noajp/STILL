//======================================================================
// MARK: - ModernArticleEditorView.swift
// Purpose: Modern rich text article editor
// Path: still/Features/Articles/Views/ModernArticleEditorView.swift
//======================================================================

import SwiftUI
import PhotosUI

struct ModernArticleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var title = ""
    @State private var content = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var coverImage: UIImage?
    @State private var coverImageUrl: String?
    @State private var showingImagePicker = false
    @State private var currentTextStyle: TextStyle = .body
    @State private var showingPublishOptions = false
    @State private var isPublishing = false
    
    enum TextStyle {
        case title, subtitle, body, quote, code
        
        var font: Font {
            switch self {
            case .title: return .system(size: 28, weight: .bold)
            case .subtitle: return .system(size: 20, weight: .semibold)
            case .body: return .system(size: 16)
            case .quote: return .system(size: 16).italic()
            case .code: return .system(size: 14, design: .monospaced)
            }
        }
        
        var icon: String {
            switch self {
            case .title: return "textformat.size.larger"
            case .subtitle: return "textformat.size"
            case .body: return "text.alignleft"
            case .quote: return "quote.bubble"
            case .code: return "chevron.left.forwardslash.chevron.right"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Cover image section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cover Image")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if let coverImage = coverImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: coverImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                                
                                Button(action: { self.coverImage = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding(8)
                            }
                        } else {
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.tertiarySystemBackground))
                                    .frame(height: 120)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 28))
                                                .foregroundColor(.secondary)
                                            Text("Add cover image")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                    )
                            }
                        }
                    }
                    
                    // Title input
                    TextField("Article title...", text: $title, axis: .vertical)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(3...5)
                    
                    // Formatting toolbar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach([TextStyle.title, .subtitle, .body, .quote, .code], id: \.self) { style in
                                Button(action: { currentTextStyle = style }) {
                                    Image(systemName: style.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(currentTextStyle == style ? .white : .primary)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(currentTextStyle == style ? Color.primary : Color(.tertiarySystemBackground))
                                        )
                                }
                            }
                            
                            Divider()
                                .frame(height: 24)
                            
                            // Additional formatting
                            Button(action: {}) {
                                Image(systemName: "bold")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "italic")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "link")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                            }
                            
                            Button(action: { showingImagePicker = true }) {
                                Image(systemName: "photo")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    // Content editor
                    TextEditor(text: $content)
                        .font(currentTextStyle.font)
                        .foregroundColor(.primary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 400)
                        .placeholder(when: content.isEmpty) {
                            Text("Tell your story...")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                        }
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingPublishOptions = true }) {
                        if isPublishing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Text("Publish")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(20)
                        }
                    }
                    .disabled(title.isEmpty || content.isEmpty || isPublishing)
                }
            }
        }
        .onChange(of: selectedImage) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    coverImage = uiImage
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotosPicker(selection: $selectedImage, matching: .images) {
                Text("Select Image")
            }
        }
        .sheet(isPresented: $showingPublishOptions) {
            PublishOptionsView(
                title: title,
                content: content,
                coverImage: coverImage,
                onPublish: { category, tags in
                    Task {
                        await publishArticle(category: category, tags: tags)
                    }
                }
            )
        }
    }
    
    private func publishArticle(category: String?, tags: [String]) async {
        isPublishing = true
        
        do {
            // Upload cover image if exists
            if let coverImage = coverImage {
                let imageData = coverImage.jpegData(compressionQuality: 0.8) ?? Data()
                let fileName = "\(UUID().uuidString).jpg"
                
                // Upload to Supabase storage
                _ = try await SupabaseManager.shared.client.storage
                    .from("article-images")
                    .upload(
                        fileName,
                        data: imageData
                    )
                
                // Get public URL
                let publicUrl = try SupabaseManager.shared.client.storage
                    .from("article-images")
                    .getPublicURL(path: fileName)
                
                coverImageUrl = publicUrl.absoluteString
            }
            
            // Create article
            let formattedContent = formatContent(content)
            
            struct ArticleInsert: Encodable {
                let title: String
                let content: String
                let cover_image_url: String?
                let category: String?
                let tags: [String]
                let user_id: String
                let created_at: String
            }
            
            let article = ArticleInsert(
                title: title,
                content: formattedContent,
                cover_image_url: coverImageUrl,
                category: category,
                tags: tags,
                user_id: authManager.currentUser?.id ?? "",
                created_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await SupabaseManager.shared.client
                .from("blog_articles")
                .insert(article)
                .execute()
            
            // Notify that article was created
            NotificationCenter.default.post(name: NSNotification.Name("ArticleCreated"), object: nil)
            
            dismiss()
        } catch {
            print("Error publishing article: \(error)")
            isPublishing = false
        }
    }
    
    private func formatContent(_ text: String) -> String {
        // In a real app, you'd convert to proper HTML/Markdown based on formatting
        return "<p>\(text.replacingOccurrences(of: "\n", with: "</p><p>"))</p>"
    }
}

// MARK: - Publish Options View
struct PublishOptionsView: View {
    let title: String
    let content: String
    let coverImage: UIImage?
    let onPublish: (String?, [String]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String?
    @State private var tagInput = ""
    @State private var tags: [String] = []
    
    let categories = ["Technology", "Design", "Business", "Culture", "Health", "Science"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Story Preview")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            if let coverImage = coverImage {
                                Image(uiImage: coverImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 150)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                            
                            Text(title)
                                .font(.system(size: 20, weight: .bold))
                                .lineLimit(2)
                            
                            Text(content)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Category selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    Text(category)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedCategory == category ? .white : .primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedCategory == category ? Color.primary : Color(.tertiarySystemBackground))
                                        )
                                }
                            }
                        }
                    }
                    
                    // Tags
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("Add tags...", text: $tagInput)
                                .onSubmit {
                                    if !tagInput.isEmpty {
                                        tags.append(tagInput)
                                        tagInput = ""
                                    }
                                }
                            
                            Button("Add") {
                                if !tagInput.isEmpty {
                                    tags.append(tagInput)
                                    tagInput = ""
                                }
                            }
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                        
                        if !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.system(size: 12))
                                        
                                        Button(action: {
                                            tags.removeAll { $0 == tag }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 12))
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Publish Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Publish Now") {
                        onPublish(selectedCategory, tags)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
                }
            }
        }
    }
}

// MARK: - Helper Views
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .topLeading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: result.positions[index].x + bounds.minX,
                                     y: result.positions[index].y + bounds.minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                maxHeight = max(maxHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: y + maxHeight)
        }
    }
}

#Preview {
    ModernArticleEditorView()
}