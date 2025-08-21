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
    @State private var selectedCategory: PresetCategory = .light
    @State private var selectedTab: EditorTab = .wb
    @State private var filterIntensity: Float = 1.0
    @State private var currentFilterSettings = FilterSettings()
    @State private var currentToneCurve = ToneCurve()
    
    // State for UnifiedAdjustmentView to preserve across tab switches
    @State private var expandedParameter: AdjustmentParameter? = .brightness  // Default to brightness
    @State private var showToneCurve = false
    
    // State for post composition navigation
    @State private var showingPostComposition = false
    
    // Animation state removed - NavigationStack handles transitions
    
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
        print("🟡 ModernPhotoEditorView init (RAW) starting...")
        print("🟡 editorData: asset=\(editorData.asset), previewImage=\(editorData.previewImage != nil)")
        
        self.originalImage = editorData.previewImage ?? UIImage()
        self.onComplete = onComplete
        self.onCancel = onCancel
        self.onPost = onPost
        self.postViewModel = postViewModel
        
        print("🟡 PhotoEditorViewModel初期化中...")
        self._viewModel = StateObject(wrappedValue: PhotoEditorViewModel(
            asset: editorData.asset,
            rawInfo: editorData.rawInfo,
            previewImage: editorData.previewImage
        ))
        print("🟡 ModernPhotoEditorView init完了")
    }
    
    // MARK: - Computed Properties
    private var buttonText: Text {
        let isLoading = postViewModel?.isLoading == true
        let hasOnPost = onPost != nil
        
        if hasOnPost {
            return Text(isLoading ? "Posting..." : "Post")
        } else {
            return Text("NEXT")
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
            .fullScreenCover(isPresented: $showingPostComposition) {
                if let editedImage = viewModel.currentImage {
                    PostCompositionView(
                        editedImage: editedImage,
                        onPostCreated: {
                            showingPostComposition = false
                            onComplete(editedImage)
                        },
                        onCancel: {
                            showingPostComposition = false
                        }
                    )
                }
            }
    }
    
    private var mainContent: some View {
        ZStack(alignment: .top) {
            backgroundView
            contentView
            headerButtons
        }
    }
    
    private var backgroundView: some View {
        Color(hex: "121212").ignoresSafeArea()
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
                Button(action: onCancel) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .foregroundColor(.white)
                
                Spacer()
                
                Text("Edit Photo")
                    .font(MinimalDesign.Typography.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // RAW/DNG export button (only for RAW images)
                if viewModel.isProcessingRAW {
                    Button(action: {
                        Task {
                            do {
                                let dngURL = try await viewModel.exportAsDNG()
                                print("✅ DNG exported to: \(dngURL)")
                                // Could show success message or share sheet
                            } catch {
                                print("❌ DNG export failed: \(error)")
                            }
                        }
                    }) {
                        Text("DNG")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }
                
                Button(action: {
                    print("🟢 NEXT Button tapped!")
                    print("🟢 onPost is nil: \(onPost == nil)")
                    
                    if let editedImage = viewModel.currentImage {
                        print("🟢 editedImage is available")
                        if let onPost = onPost {
                            print("🟢 Calling onPost callback")
                            onPost(editedImage)
                        } else {
                            print("🟢 Showing PostCompositionView directly")
                            showingPostComposition = true
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
            ZStack {
                // Black background to maintain consistent size
                Color.black
                
                if viewModel.ciImage != nil {
                    MetalPreviewView(
                        currentImage: $viewModel.ciImage,
                        filterType: .constant(.none),
                        filterIntensity: $filterIntensity
                    )
                    .aspectRatio(contentMode: .fit)
                } else if let image = viewModel.currentImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if originalImage != UIImage() {
                    // Show original image while loading
                    Image(uiImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        )
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    

    
    // MARK: - Advanced Editing Section
    private var advancedEditingSection: some View {
        UnifiedAdjustmentView(
            filterSettings: $currentFilterSettings,
            toneCurve: $currentToneCurve,
            expandedParameter: $expandedParameter,
            showToneCurve: $showToneCurve,
            onSettingsChanged: applyFilterSettings,
            onToneCurveChanged: applyToneCurve,
            onAutoWB: applyAutoWhiteBalance
        )
    }
    // MARK: - Tab Selector
    private var tabSelectorView: some View {
        HStack(spacing: 0) {
            ForEach(EditorTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                        // When Edit tab is selected, default to Brightness expanded
                        if tab == .edit {
                            expandedParameter = .brightness
                            showToneCurve = false
                        }
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))
                        
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? MinimalDesign.Colors.accentRed : Color(white: 0.56))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(hex: "121212"))
        .overlay(
            // Selected tab indicator
            HStack {
                ForEach(EditorTab.allCases.indices, id: \.self) { index in
                    Rectangle()
                        .fill(selectedTab == EditorTab.allCases[index] ? MinimalDesign.Colors.accentRed : Color.clear)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 0)
            , alignment: .bottom
        )
    }
    private var editMenuView: some View {
        VStack(spacing: 0) {
            // Tab selector
            tabSelectorView
            
            // Content based on selected tab
            switch selectedTab {
            case .wb:
                WhiteBalanceView(
                    filterSettings: $currentFilterSettings,
                    onSettingsChanged: applyFilterSettings,
                    onAutoWB: applyAutoWhiteBalance
                )
            case .preset:
                BasicEditingView(
                    selectedPreset: $selectedPreset,
                    selectedCategory: $selectedCategory,
                    filterSettings: $currentFilterSettings,
                    originalImage: originalImage,
                    onPresetSelected: applyPreset,
                    onCustomPresetSelected: applyCustomPreset,
                    onSettingsChanged: applyFilterSettings
                )
            case .edit:
                advancedEditingSection
            case .angle:
                AngleAdjustmentView { rotation, straighten, flipH, flipV in
                    applyAngleAdjustments(rotation: rotation, straighten: straighten, flipHorizontal: flipH, flipVertical: flipV)
                }
            }
        }
        .background(Color(red: 28/255, green: 28/255, blue: 30/255))
    }
    
    // MARK: - Methods
    
    private func applyPreset(_ preset: PresetType) {
        let settings = preset.filterSettings
        currentFilterSettings = settings
        viewModel.applyFilterSettings(settings, toneCurve: currentToneCurve)
    }
    
    private func applyCustomPreset(_ customPreset: CustomPreset) {
        guard let ciImage = CIImage(image: originalImage),
              let filteredImage = CustomPresetManager.shared.applyPreset(customPreset, to: ciImage) else {
            return
        }
        
        // Convert back to UIImage and update the view model
        let context = CIContext()
        guard let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else {
            return
        }
        
        let resultImage = UIImage(cgImage: cgImage)
        viewModel.updateProcessedImage(resultImage)
    }
    
    private func applyFilterSettings(_ settings: FilterSettings) {
        currentFilterSettings = settings
        viewModel.applyFilterSettings(settings, toneCurve: currentToneCurve)
    }
    
    private func applyAutoWhiteBalance() {
        // Get auto WB values from view model
        let (temperature, tint) = viewModel.analyzeAutoWhiteBalance()
        
        // Update current settings
        currentFilterSettings.temperature = temperature
        currentFilterSettings.tint = tint
        
        // Apply the new settings
        viewModel.applyFilterSettings(currentFilterSettings, toneCurve: currentToneCurve)
    }
    
    private func applyToneCurve(_ curve: ToneCurve) {
        currentToneCurve = curve
        viewModel.applyFilterSettings(currentFilterSettings, toneCurve: curve)
    }
    
    private func applyAngleAdjustments(rotation: Double, straighten: Double, flipHorizontal: Bool, flipVertical: Bool) {
        // Apply angle adjustments to the image
        viewModel.applyAngleAdjustments(
            rotation: rotation,
            straighten: straighten,
            flipHorizontal: flipHorizontal,
            flipVertical: flipVertical
        )
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