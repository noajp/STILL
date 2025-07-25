//======================================================================
// MARK: - ModernPhotoEditorView.swift
// Purpose: Advanced photo editor with RAW processing, filter presets, adjustment controls, and direct post creation integration (RAW処理、フィルタープリセット、調整コントロール、直接投稿作成統合を持つ高度な写真エディター)
// Path: still/Features/PhotoEditor/Views/ModernPhotoEditorView.swift
//======================================================================
//
//  ModernPhotoEditorView.swift
//  tete
//
//  モダンな写真編集画面（HTML参照）
//

import SwiftUI
import CoreImage

struct ModernPhotoEditorView: View {
    // MARK: - Properties
    let originalImage: UIImage
    let onComplete: (UIImage) -> Void
    let onCancel: () -> Void
    let onPost: ((UIImage) -> Void)?
    let postViewModel: CreatePostViewModel?
    
    @StateObject private var viewModel: PhotoEditorViewModel
    @State private var selectedPreset: PresetType = .none
    @State private var selectedCategory: PresetCategory = .basePresets
    @State private var selectedTab: EditorTab = .presets
    @State private var filterIntensity: Float = 1.0
    @State private var currentFilterSettings = FilterSettings()
    @State private var currentToneCurve = ToneCurve()
    
    // MARK: - Initialization
    init(image: UIImage,
         onComplete: @escaping (UIImage) -> Void,
         onCancel: @escaping () -> Void,
         onPost: ((UIImage) -> Void)? = nil,
         postViewModel: CreatePostViewModel? = nil) {
        print("🟡 ModernPhotoEditorView init - onPost is \(onPost != nil ? "provided" : "nil")")
        self.originalImage = image
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onPost = onPost
        self.postViewModel = postViewModel
        self._viewModel = StateObject(wrappedValue: PhotoEditorViewModel(image: image))
    }
    
    // RAW画像対応のイニシャライザ
    init(editorData: PhotoEditorData,
         onComplete: @escaping (UIImage) -> Void,
         onCancel: @escaping () -> Void,
         onPost: ((UIImage) -> Void)? = nil,
         postViewModel: CreatePostViewModel? = nil) {
        print("🟡 ModernPhotoEditorView init (RAW) - onPost is \(onPost != nil ? "provided" : "nil")")
        self.originalImage = editorData.previewImage ?? UIImage()
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onPost = onPost
        self.postViewModel = postViewModel
        self._viewModel = StateObject(wrappedValue: PhotoEditorViewModel(
            asset: editorData.asset,
            rawInfo: editorData.rawInfo,
            previewImage: editorData.previewImage
        ))
    }
    
    // MARK: - Computed Properties
    private var buttonText: Text {
        let isLoading = postViewModel?.isLoading == true
        let hasOnPost = onPost != nil
        
        if hasOnPost {
            return Text(isLoading ? "Posting..." : "Post")
        } else {
            return Text("Done")
        }
    }
    
    
    private func debugButtonState() {
        let hasOnPost = onPost != nil
        let isLoading = postViewModel?.isLoading == true
        let text = hasOnPost ? (isLoading ? "Posting..." : "Post") : "Done"
        print("🟡 Button text: onPost is \(hasOnPost ? "not nil" : "nil"), showing: \(text)")
    }
    
    // MARK: - Body
    var body: some View {
        mainContent
    }
    
    private var mainContent: some View {
        ZStack(alignment: .top) {
            backgroundView
            contentView
            headerButtons
        }
    }
    
    private var backgroundView: some View {
        Color.black.ignoresSafeArea()
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // メイン画像（全画面表示）
            mainImageView
            
            // 編集メニュー
            editMenuView
        }
    }
    
    private var headerButtons: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Edit Photo")
                    .font(MinimalDesign.Typography.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    print("🟢 Button tapped! onPost is nil: \(onPost == nil)")
                    if let editedImage = viewModel.currentImage {
                        if let onPost = onPost {
                            print("🟢 Calling onPost")
                            onPost(editedImage)
                        } else {
                            print("🟢 Calling onComplete")
                            onComplete(editedImage)
                        }
                    } else {
                        print("🔴 No editedImage available")
                    }
                }) {
                        if postViewModel?.isLoading == true {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            buttonText
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(postViewModel?.isLoading == true)
                }
                .padding(.horizontal, MinimalDesign.Spacing.md)
                .padding(.vertical, MinimalDesign.Spacing.sm)
                .padding(.top, 8) // Safe Area対応
                .background(Color.black.opacity(0.3))
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                Spacer() // ヘッダーを最上部に固定
            }
        .gesture(
            DragGesture()
                .onEnded { value in
                    // 右方向にスワイプで戻る
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        onCancel()
                    }
                }
        )
        .alert("Post Error", isPresented: .constant(postViewModel?.showError == true)) {
            Button("OK") {
                postViewModel?.showError = false
            }
        } message: {
            Text(postViewModel?.errorMessage ?? "Failed to post")
        }
    }
    
    // MARK: - Views
    
    
    private var mainImageView: some View {
        GeometryReader { geometry in
            if viewModel.ciImage != nil {
                MetalPreviewView(
                    currentImage: $viewModel.ciImage,
                    filterType: .constant(.none),
                    filterIntensity: $filterIntensity
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.black)
            } else if let image = viewModel.currentImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
    
    private var editMenuView: some View {
        VStack(spacing: 0) {
            // タブごとのコンテンツ
            switch selectedTab {
            case .presets:
                PresetSelectionView(
                    selectedPreset: $selectedPreset,
                    selectedCategory: $selectedCategory,
                    originalImage: originalImage,
                    onPresetSelected: applyPreset
                )
                .frame(height: 180)
                
            case .adjust:
                // 詳細調整ビュー
                AdjustmentView(
                    filterSettings: $currentFilterSettings,
                    toneCurve: $currentToneCurve,
                    onSettingsChanged: applyFilterSettings,
                    onToneCurveChanged: applyToneCurve
                )
            }
            
            // フッターボタン
            EditorFooterView(
                selectedTab: $selectedTab,
                onTabSelected: { tab in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            )
        }
        .background(Color(red: 28/255, green: 28/255, blue: 30/255))
    }
    
    // MARK: - Methods
    
    private func applyPreset(_ preset: PresetType) {
        let settings = preset.filterSettings
        currentFilterSettings = settings
        viewModel.applyFilterSettings(settings, toneCurve: currentToneCurve)
    }
    
    private func applyFilterSettings(_ settings: FilterSettings) {
        currentFilterSettings = settings
        viewModel.applyFilterSettings(settings, toneCurve: currentToneCurve)
    }
    
    private func applyToneCurve(_ curve: ToneCurve) {
        currentToneCurve = curve
        viewModel.applyFilterSettings(currentFilterSettings, toneCurve: curve)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    typealias UIViewControllerType = UIActivityViewController
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {}
}

// MARK: - Preview
#if DEBUG
struct ModernPhotoEditorView_Previews: PreviewProvider {
    static var previews: some View {
        ModernPhotoEditorView(
            image: UIImage(systemName: "photo")!,
            onComplete: { _ in },
            onCancel: { }
        )
    }
}
#endif