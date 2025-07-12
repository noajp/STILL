//======================================================================
// MARK: - StoryStyleEditorView.swift
// Purpose: Instagram Stories-style article editor with paper interface
// Path: still/Features/Articles/Views/StoryStyleEditorView.swift
//======================================================================
import SwiftUI

struct StoryStyleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = StoryStyleEditorViewModel()
    let articleType: ArticleType = .magazine // 雑誌記事に固定
    
    @State private var showingTextEditor = false
    @State private var showingColorPicker = false
    @State private var showingPreview = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Instagram-style gradient background
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top toolbar
                    topToolbar
                    
                    Spacer()
                    
                    // Paper canvas (2/3 of screen)
                    paperCanvas(in: geometry)
                        .scaleEffect(isDragging ? 0.95 : 1.0)
                        .offset(dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    dragOffset = value.translation
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.4)) {
                                        isDragging = false
                                        dragOffset = .zero
                                    }
                                }
                        )
                    
                    Spacer()
                    
                    // Bottom toolbar
                    bottomToolbar
                }
                
                // Floating text editor
                if showingTextEditor {
                    textEditorOverlay
                }
                
                // Color picker overlay
                if showingColorPicker {
                    colorPickerOverlay
                }
                
                // Preview overlay
                if showingPreview {
                    previewOverlay
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            // メインの動的グラデーション
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.9),
                    Color.pink.opacity(0.85),
                    Color.orange.opacity(0.8),
                    Color.red.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // レイヤード効果
            RadialGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 400
            )
            
            // 雑誌的なパターンオーバーレイ
            ZStack {
                // 散らばった星のパターン
                ForEach(0..<8, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat.random(in: 15...30)))
                        .foregroundColor(.white.opacity(Double.random(in: 0.02...0.08)))
                        .position(
                            x: CGFloat.random(in: 50...350),
                            y: CGFloat.random(in: 100...700)
                        )
                }
                
                // グラデーションドット
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.1), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: CGFloat.random(in: 40...80))
                        .position(
                            x: CGFloat.random(in: 50...350),
                            y: CGFloat.random(in: 150...600)
                        )
                }
            }
        }
    }
    
    // MARK: - Top Toolbar
    
    private var topToolbar: some View {
        HStack {
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(width: 44, height: 44)
                    .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Magazine indicator with stylish design
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                Text("MAGAZINE")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            
            Spacer()
            
            // Stylish publish button
            Button(action: {
                Task {
                    await viewModel.publishArticle(type: articleType)
                    dismiss()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14))
                    Text("公開")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Paper Canvas
    
    private func paperCanvas(in geometry: GeometryProxy) -> some View {
        let paperHeight = geometry.size.height * 0.67 // 2/3 of screen height
        let paperWidth = min(geometry.size.width * 0.85, paperHeight * 0.7)
        
        return ZStack {
            // 雑誌風ペーパー背景
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: paperWidth, height: paperHeight)
                .overlay(
                    // 雑誌風のサブトルテクスチャ
                    ZStack {
                        // ソフトグラデーションエフェクト
                        LinearGradient(
                            colors: [Color.clear, Color.purple.opacity(0.03), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        
                        // エレガントなコーナーアクセント
                        VStack {
                            HStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.05))
                                    .frame(width: 40, height: 40)
                                Spacer()
                                Circle()
                                    .fill(Color.pink.opacity(0.05))
                                    .frame(width: 30, height: 30)
                            }
                            Spacer()
                            HStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.05))
                                    .frame(width: 35, height: 35)
                                Spacer()
                                Circle()
                                    .fill(Color.red.opacity(0.05))
                                    .frame(width: 25, height: 25)
                            }
                        }
                        .padding(30)
                    }
                )
                .shadow(color: .black.opacity(0.15), radius: 30, y: 15)
                .shadow(color: .purple.opacity(0.1), radius: 50, y: 25)
            
            // Paper content
            VStack(alignment: .leading, spacing: 16) {
                // タイトルエリア（雑誌風）
                VStack(alignment: .leading, spacing: 12) {
                    // カテゴリータグ
                    if !viewModel.category.isEmpty {
                        Text(viewModel.category.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .tracking(1.5)
                    }
                    
                    // メインタイトル
                    if viewModel.title.isEmpty {
                        Text("素敵なタイトルを入力してください")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.gray.opacity(0.4))
                            .onTapGesture {
                                viewModel.editingField = .title
                                showingTextEditor = true
                            }
                    } else {
                        Text(viewModel.title)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                            .onTapGesture {
                                viewModel.editingField = .title
                                showingTextEditor = true
                            }
                    }
                }
                
                // エレガントな区切り線
                if !viewModel.title.isEmpty {
                    HStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.clear, Color.purple.opacity(0.3), Color.pink.opacity(0.3), Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                    }
                }
                
                // コンテンツエリア（雑誌風）
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if viewModel.content.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("あなたのストーリーを")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(.gray.opacity(0.6))
                                Text("美しく綴ってください...")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.gray.opacity(0.4))
                            }
                            .onTapGesture {
                                viewModel.editingField = .content
                                showingTextEditor = true
                            }
                        } else {
                            Text(viewModel.content)
                                .font(.system(size: 17, weight: .regular, design: .rounded))
                                .foregroundColor(.black.opacity(0.85))
                                .lineSpacing(8)
                                .onTapGesture {
                                    viewModel.editingField = .content
                                    showingTextEditor = true
                                }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .frame(width: paperWidth, height: paperHeight)
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            // Text editing tool
            MagazineToolButton(
                icon: "textformat",
                label: "テキスト",
                isActive: false,
                gradient: [Color.blue, Color.purple]
            ) {
                viewModel.editingField = .content
                showingTextEditor = true
            }
            
            // Image tool
            MagazineToolButton(
                icon: "photo.on.rectangle",
                label: "画像",
                isActive: false,
                gradient: [Color.green, Color.blue]
            ) {
                // TODO: Implement image picker
            }
            
            // Style/Color picker
            MagazineToolButton(
                icon: "paintpalette.fill",
                label: "スタイル",
                isActive: showingColorPicker,
                gradient: [Color.pink, Color.orange]
            ) {
                showingColorPicker.toggle()
            }
            
            // Category/tags
            MagazineToolButton(
                icon: "tag.fill",
                label: "タグ",
                isActive: false,
                gradient: [Color.orange, Color.red]
            ) {
                viewModel.editingField = .category
                showingTextEditor = true
            }
            
            Spacer()
            
            // Preview button
            Button(action: {
                showingPreview = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 16))
                    Text("プレビュー")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: colorScheme == .dark ? [Color.black.opacity(0.3), Color.black.opacity(0.4)] : [Color.white.opacity(0.8), Color.white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Text Editor Overlay
    
    private var textEditorOverlay: some View {
        ZStack {
            (colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.95))
                .ignoresSafeArea()
                .onTapGesture {
                    showingTextEditor = false
                }
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button("キャンセル") {
                        showingTextEditor = false
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(viewModel.editingField?.title ?? "")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("完了") {
                        showingTextEditor = false
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                
                // Text editor
                VStack(alignment: .leading) {
                    switch viewModel.editingField {
                    case .title:
                        TextField("タイトル", text: $viewModel.title)
                            .font(.system(size: 24, weight: .bold))
                            .textFieldStyle(PlainTextFieldStyle())
                    case .content:
                        TextField("記事の内容", text: $viewModel.content, axis: .vertical)
                            .font(.system(size: 16))
                            .textFieldStyle(PlainTextFieldStyle())
                            .lineLimit(10...20)
                    case .category:
                        TextField("カテゴリー", text: $viewModel.category)
                            .font(.system(size: 16))
                            .textFieldStyle(PlainTextFieldStyle())
                    case .none:
                        EmptyView()
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 60)
        }
    }
    
    // MARK: - Color Picker Overlay
    
    private var colorPickerOverlay: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                ForEach(viewModel.availableColors, id: \.self) { color in
                    Button(action: {
                        viewModel.selectedColor = color
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: viewModel.selectedColor == color ? 3 : 0)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(colorScheme == .dark ? Color.black.opacity(0.5) : Color.white.opacity(0.9))
            .cornerRadius(25)
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
    }
    
    // MARK: - Preview Overlay
    
    private var previewOverlay: some View {
        ZStack {
            (colorScheme == .dark ? Color.black.opacity(0.95) : Color.white.opacity(0.98))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Preview header
                HStack {
                    Button("閉じる") {
                        showingPreview = false
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("プレビュー")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("投稿") {
                        Task {
                            await viewModel.publishArticle(type: articleType)
                            dismiss()
                        }
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Preview content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Magazine badge
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                Text("MAGAZINE")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .tracking(2)
                            }
                            .foregroundColor(.purple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            
                            Spacer()
                        }
                        
                        // Title
                        Text(viewModel.title.isEmpty ? "無題の記事" : viewModel.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineSpacing(4)
                        
                        // Category
                        if !viewModel.category.isEmpty {
                            Text(viewModel.category.uppercased())
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.pink)
                                .tracking(1.5)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        // Content
                        Text(viewModel.content.isEmpty ? "内容が入力されていません。" : viewModel.content)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(8)
                        
                        // Meta info
                        HStack {
                            Text("今すぐ")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("\(viewModel.content.split(separator: " ").count / 200 + 1) min read")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                    }
                    .padding(20)
                }
            }
        }
    }
}

// MARK: - Magazine Tool Button

struct MagazineToolButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        isActive 
                            ? LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(isActive ? 0.5 : 0.2), lineWidth: 1)
                    )
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class StoryStyleEditorViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var category: String = ""
    @Published var selectedColor: Color = .white
    @Published var editingField: EditingField?
    
    let availableColors: [Color] = [
        .white, .black, .red, .blue, .green, .yellow, .purple, .orange, .pink
    ]
    
    enum EditingField {
        case title, content, category
        
        var title: String {
            switch self {
            case .title: return "タイトル"
            case .content: return "本文"
            case .category: return "カテゴリー"
            }
        }
    }
    
    private let articleRepository = ArticleRepository.shared
    
    func publishArticle(type: ArticleType) async {
        guard !title.isEmpty, !content.isEmpty else { return }
        
        do {
            let request = CreateArticleRequest(
                userId: "current-user-id", // TODO: Get actual user ID from AuthManager
                title: title,
                content: content,
                summary: String(content.prefix(150)),
                category: category.isEmpty ? nil : category,
                tags: [],
                isPremium: false,
                coverImageUrl: nil,
                status: .published,
                articleType: type
            )
            
            let _ = try await articleRepository.createArticle(request)
            
            // Notify that article was created
            NotificationCenter.default.post(name: NSNotification.Name("ArticleCreated"), object: nil)
            
            print("✅ Successfully published \(type.rawValue) article: \(title)")
        } catch {
            print("❌ Failed to publish article: \(error)")
        }
    }
}

#Preview {
    StoryStyleEditorView()
}