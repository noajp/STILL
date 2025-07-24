//======================================================================
// MARK: - CreatePostView（Minimal Design）
// Path: still/Features/CreatePost/CreatePostView.swift
//======================================================================
import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

@MainActor
struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showingMediaPicker = true
    @State private var selectedItem: PhotosPickerItem?
    @State private var locationName: String = ""
    @State private var showingPhotoEditor = false
    @State private var imageToEdit: UIImage?
    @State private var showingCustomCamera = false
    @State private var selectedFilter: FilterType = .none
    @State private var showingFilterPreview = false
    @State private var filterIntensity: Float = 1.0
    @State private var showingPhotoPicker = true
    @State private var editorData: PhotoEditorData? = nil
    @State private var showSuccessAnimation = false
    
    var body: some View {
        Text("CreatePostView - Currently Disabled")
            .font(.title2)
            .foregroundColor(.secondary)
        
        /*
        if viewModel.selectedImage == nil {
            // 写真が選択されるまでは空のビューを表示
            Color.clear
                .onAppear {
                    // 初回表示時に自動的にPhotoPickerを開く
                    if !showingPhotoPicker {
                        showingPhotoPicker = true
                    }
                }
        } else {
            NavigationView {
                VStack(spacing: 0) {
                    // Header
                    UnifiedHeader(
                        title: "New Post",
                        showBackButton: true,
                        rightButton: viewModel.canPost ? HeaderButton(
                            icon: "checkmark",
                            action: {
                                // Start background upload
                                viewModel.createPostInBackground()
                                // Immediately dismiss and return to feed
                                dismiss()
                            }
                        ) : nil,
                        onBack: { dismiss() }
                    )
                    
                    // Content
                    ScrollView {
                        LazyVStack(spacing: MinimalDesign.Spacing.lg) {
                            // Quick Filter Selection
                            if viewModel.selectedImage != nil && viewModel.mediaType == .photo {
                            QuickFilterSection(
                                originalImage: viewModel.selectedImage,
                                selectedFilter: $selectedFilter,
                                filterIntensity: $filterIntensity,
                                onFilterSelected: { filter, intensity in
                                    applyQuickFilter(filter, intensity: intensity)
                                }
                            )
                        }
                        
                        // Form Fields
                        VStack(spacing: MinimalDesign.Spacing.md) {
                            MinimalCaptionField(caption: $viewModel.caption)
                            MinimalLocationField(locationName: $locationName)
                        }
                        .padding(.horizontal, MinimalDesign.Spacing.md)
                        
                        // Upload Progress
                        if viewModel.isLoading {
                            MinimalProgressView(progress: viewModel.uploadProgress)
                            }
                        }
                        .padding(.vertical, MinimalDesign.Spacing.md)
                    }
                }
                .background(MinimalDesign.Colors.background)
                .navigationBarHidden(true)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "Failed to create post")
            }
            .onChange(of: locationName) { _, newLocation in
                viewModel.locationName = newLocation
            }
            .sheet(isPresented: $showingPhotoEditor) {
            if let editorData = editorData {
                // RAW画像の編集
                ModernPhotoEditorView(
                    editorData: editorData,
                    onComplete: { editedImage in
                        viewModel.selectedImage = editedImage
                        showingPhotoEditor = false
                        self.editorData = nil
                    },
                    onCancel: {
                        showingPhotoEditor = false
                        self.editorData = nil
                    },
                    onPost: { editedImage in
                        print("🟢 onPost called in CreatePostView (RAW)")
                        viewModel.selectedImage = editedImage
                        Task {
                            // Start background upload
                            viewModel.createPostInBackground()
                            // Close editor and dismiss CreatePost view
                            showingPhotoEditor = false
                            self.editorData = nil
                            dismiss()
                        }
                    },
                    postViewModel: viewModel
                )
            } else if let imageToEdit = imageToEdit {
                // 通常の画像編集
                ModernPhotoEditorView(
                    image: imageToEdit,
                    onComplete: { editedImage in
                        viewModel.selectedImage = editedImage
                        showingPhotoEditor = false
                    },
                    onCancel: {
                        showingPhotoEditor = false
                    },
                    onPost: { editedImage in
                        print("🟢 onPost called in CreatePostView (normal)")
                        viewModel.selectedImage = editedImage
                        Task {
                            // Start background upload
                            viewModel.createPostInBackground()
                            // Close editor and dismiss CreatePost view
                            showingPhotoEditor = false
                            dismiss()
                        }
                    },
                    postViewModel: viewModel
                )
            }
        }
        .fullScreenCover(isPresented: $showingCustomCamera) {
            CustomCameraView { capturedImage in
                viewModel.selectedImage = capturedImage
                viewModel.mediaType = .photo
                viewModel.selectedVideoURL = nil
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView { editorData in
                print("🟢 PhotoPickerから画像受信")
                self.editorData = editorData
                self.imageToEdit = editorData.previewImage
                self.viewModel.selectedImage = editorData.previewImage
                self.viewModel.mediaType = .photo
                
                // PhotoPickerViewを閉じる
                self.showingPhotoPicker = false
            }
            .onAppear {
                print("🟡 DEBUG: PhotoPicker sheet onAppear")
            }
        }
        .onChange(of: showingPhotoPicker) { _, newValue in
            print("🟡 showingPhotoPicker changed: \(newValue)")
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            guard let item = newValue else { return }
            
            Task {
                do {
                    // iOS 16以降の推奨される方法
                    if let data = try await item.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            print("✅ 画像の読み込みに成功しました")
                            await MainActor.run {
                                viewModel.mediaType = .photo
                                imageToEdit = uiImage
                                showingPhotoEditor = true
                                selectedItem = nil  // リセット
                            }
                        } else {
                            print("❌ データからUIImageへの変換に失敗しました")
                        }
                    }
                } catch {
                    print("❌ 画像の読み込みエラー: \(error)")
                    
                    // コエラーコード (CocoaError) を確認
                    if let cocoaError = error as? CocoaError {
                        print("❌ CocoaError code: \(cocoaError.code.rawValue)")
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToEditor)) { notification in
            print("🟢 NotificationCenter受信: \(notification)")
            print("🟢 notification.object type: \(type(of: notification.object))")
            
            if let receivedEditorData = notification.object as? PhotoEditorData {
                print("🟢 PhotoEditorData受信")
                // RAW画像の処理
                self.editorData = receivedEditorData
                self.imageToEdit = receivedEditorData.previewImage
                self.showingPhotoEditor = true
                print("🟢 showingPhotoEditor = true設定完了")
            } else if let image = notification.object as? UIImage {
                print("🟢 UIImage受信")
                // 通常の画像処理
                self.editorData = nil
                self.imageToEdit = image
                self.showingPhotoEditor = true
                print("🟢 showingPhotoEditor = true設定完了")
            } else {
                print("🔴 未知のオブジェクト受信: \(String(describing: notification.object))")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func applyQuickFilter(_ filterType: FilterType, intensity: Float) {
        guard let originalImage = viewModel.selectedImage else { return }
        
        selectedFilter = filterType
        filterIntensity = intensity
        
        if filterType == .none {
            // オリジナルに戻す
            return
        }
        
        // フィルター適用
        CoreImageManager.shared.applyFilter(
            filterType,
            to: CoreImageManager.shared.createCIImage(from: originalImage) ?? CIImage(),
            intensity: intensity
        ) { result in
            switch result {
            case .success(let filteredImage):
                DispatchQueue.main.async {
                    self.viewModel.selectedImage = filteredImage
                }
            case .failure(let error):
                print("Filter application failed: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func loadImageFromPhotosPickerItem(_ item: PhotosPickerItem) async {
        // 画像の識別子を取得
        guard let itemIdentifier = item.itemIdentifier else {
            print("❌ PhotosPickerItemの識別子が取得できません")
            return
        }
        
        print("📷 画像識別子: \(itemIdentifier)")
        
        // 別の方法で画像を読み込む
        if let _ = try? await item.loadTransferable(type: Image.self) {
            // SwiftUI ImageをUIImageに変換する方法が必要
            print("⚠️ SwiftUI Imageとして読み込まれましたが、UIImageへの変換が必要です")
        }
        
        // データとして読み込んでみる
        let supportedContentTypes: [UTType] = [.jpeg, .png, .heif, .heic, .rawImage]
        
        for contentType in supportedContentTypes {
            if item.supportedContentTypes.contains(contentType) {
                print("📷 サポートされているタイプ: \(contentType)")
                
                // その型でデータを読み込んでみる
                if let data = try? await item.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        print("✅ \(contentType)として画像を読み込みました")
                        viewModel.mediaType = .photo
                        imageToEdit = uiImage
                        showingPhotoEditor = true
                        return
                    }
                }
            }
        }
        
        print("❌ すべての方法で画像の読み込みに失敗しました")
    }
    
    // MARK: - Minimal Components
    
    // Media Picker Component
    @MainActor
    struct MinimalMediaPickerSection: View {
        @Binding var selectedImage: UIImage?
        @Binding var selectedVideoURL: URL?
        @Binding var mediaType: Post.MediaType
        @Binding var showingMediaPicker: Bool
        @Binding var selectedItem: PhotosPickerItem?
        @Binding var showingPhotoEditor: Bool
        @Binding var imageToEdit: UIImage?
        @Binding var showingCustomCamera: Bool
        @Binding var selectedFilter: FilterType
        @Binding var showingFilterPreview: Bool
        @Binding var filterIntensity: Float
        @Binding var showingPhotoPicker: Bool
        
        var body: some View {
            // Capture main actor properties as local values
            let currentSelectedImage = selectedImage
            let currentMediaType = mediaType
            let currentSelectedFilter = selectedFilter
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .any(of: [.images, .videos])
            ) {
                MediaPickerContent(
                    selectedImage: currentSelectedImage,
                    mediaType: currentMediaType,
                    selectedFilter: currentSelectedFilter,
                    onEditImage: { @MainActor image in
                        imageToEdit = image
                        showingPhotoEditor = true
                    },
                    onToggleFilterPreview: { @MainActor in
                        showingFilterPreview.toggle()
                    },
                    onShowCustomCamera: { @MainActor in
                        showingCustomCamera = true
                    },
                    onShowPhotoPicker: { @MainActor in
                        showingPhotoPicker = true
                    }
                )
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
        }
    }
    
    struct MediaPickerContent: View {
        let selectedImage: UIImage?
        let mediaType: Post.MediaType
        let selectedFilter: FilterType
        let onEditImage: @MainActor (UIImage) -> Void
        let onToggleFilterPreview: @MainActor () -> Void
        let onShowCustomCamera: @MainActor () -> Void
        let onShowPhotoPicker: @MainActor () -> Void
        
        var body: some View {
            if let image = selectedImage {
                    ZStack {
                        // Image Display
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 280)
                            .clipped()
                        
                        // Overlay Controls
                        VStack {
                            HStack {
                                Spacer()
                                
                                VStack(spacing: MinimalDesign.Spacing.xs) {
                                    // Media Type Badge
                                    Text(mediaType == .video ? "Video" : "Photo")
                                        .font(MinimalDesign.Typography.small)
                                        .padding(.horizontal, MinimalDesign.Spacing.xs)
                                        .padding(.vertical, 2)
                                        .background(.black.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(MinimalDesign.Radius.sm)
                                    
                                    // Edit Button
                                    if mediaType == .photo {
                                        VStack(spacing: 4) {
                                            Button(action: {
                                                onEditImage(image)
                                            }) {
                                                Image(systemName: "wand.and.stars")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .padding(MinimalDesign.Spacing.xs)
                                                    .background(.black.opacity(0.7))
                                                    .cornerRadius(MinimalDesign.Radius.sm)
                                            }
                                            
                                            // Quick Filter Button
                                            Button(action: {
                                                onToggleFilterPreview()
                                            }) {
                                                Image(systemName: "camera.filters")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .padding(MinimalDesign.Spacing.xs)
                                                    .background(selectedFilter != .none ? Color.red.opacity(0.8) : .black.opacity(0.7))
                                                    .cornerRadius(MinimalDesign.Radius.sm)
                                            }
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(MinimalDesign.Spacing.sm)
                    }
                } else {
                    // Empty State
                    VStack(spacing: MinimalDesign.Spacing.lg) {
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(MinimalDesign.Colors.tertiary)
                        
                        VStack(spacing: MinimalDesign.Spacing.xs) {
                            Text("Add Photo or Video")
                                .font(MinimalDesign.Typography.body)
                                .foregroundColor(MinimalDesign.Colors.primary)
                            
                            Text("Tap to select from library")
                                .font(MinimalDesign.Typography.caption)
                                .foregroundColor(MinimalDesign.Colors.secondary)
                        }
                        
                        // Action Buttons
                        HStack(spacing: MinimalDesign.Spacing.sm) {
                            // Camera Button
                            Button(action: { onShowCustomCamera() }) {
                                HStack(spacing: MinimalDesign.Spacing.xs) {
                                    Image(systemName: "camera")
                                        .font(.caption)
                                    Text("Camera")
                                        .font(MinimalDesign.Typography.caption)
                                }
                                .minimalButton(style: .secondary)
                            }
                            
                            // Photo Picker Button
                            Button(action: { 
                                print("🟡 Browse ボタンが押されました")
                                onShowPhotoPicker()
                            }) {
                                HStack(spacing: MinimalDesign.Spacing.xs) {
                                    Image(systemName: "photo.stack")
                                        .font(.caption)
                                    Text("Browse")
                                        .font(MinimalDesign.Typography.caption)
                                }
                                .minimalButton(style: .secondary)
                            }
                        }
                    }
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
                    .background(MinimalDesign.Colors.tertiaryBackground)
                    .minimalCardBorder()
                }
        }
    }
    
    // Quick Filter Section Component  
    @MainActor
    struct QuickFilterSection: View {
        let originalImage: UIImage?
        @Binding var selectedFilter: FilterType
        @Binding var filterIntensity: Float
        let onFilterSelected: (FilterType, Float) -> Void
        
        // レトロ特化フィルターの選択肢
        private let retroFilters: [FilterType] = [
            .none, .vintage, .sepia, .kodakPortra, .fujiPro, 
            .cinestill, .polaroid, .ilfordHP5, .retro
        ]
        
        var body: some View {
            VStack(alignment: .leading, spacing: MinimalDesign.Spacing.sm) {
                HStack {
                    Text("Retro Filters")
                        .font(MinimalDesign.Typography.headline)
                        .foregroundColor(MinimalDesign.Colors.primary)
                    
                    Spacer()
                    
                    if selectedFilter != .none {
                        Button("Reset") {
                            selectedFilter = .none
                            onFilterSelected(.none, 0)
                        }
                        .font(MinimalDesign.Typography.caption)
                        .foregroundColor(MinimalDesign.Colors.accent)
                    }
                }
                .padding(.horizontal, MinimalDesign.Spacing.md)
                
                // フィルター選択
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MinimalDesign.Spacing.sm) {
                        ForEach(retroFilters, id: \.self) { filter in
                            FilterQuickPreview(
                                filter: filter,
                                originalImage: originalImage,
                                isSelected: selectedFilter == filter,
                                onTap: {
                                    let intensity = filter.defaultIntensity
                                    selectedFilter = filter
                                    filterIntensity = intensity
                                    onFilterSelected(filter, intensity)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, MinimalDesign.Spacing.md)
                }
                
                // 強度調整スライダー
                if selectedFilter != .none && selectedFilter.isAdjustable {
                    VStack(spacing: MinimalDesign.Spacing.xs) {
                        HStack {
                            Text("Intensity")
                                .font(MinimalDesign.Typography.caption)
                                .foregroundColor(MinimalDesign.Colors.secondary)
                            
                            Spacer()
                            
                            Text("\\(Int(filterIntensity * 100))%")
                                .font(MinimalDesign.Typography.caption)
                                .foregroundColor(MinimalDesign.Colors.secondary)
                        }
                        
                        Slider(value: $filterIntensity, in: 0...1) { _ in
                            onFilterSelected(selectedFilter, filterIntensity)
                        }
                        .accentColor(MinimalDesign.Colors.accent)
                    }
                    .padding(.horizontal, MinimalDesign.Spacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.vertical, MinimalDesign.Spacing.sm)
            .background(MinimalDesign.Colors.secondaryBackground)
            .cornerRadius(MinimalDesign.Radius.lg)
            .padding(.horizontal, MinimalDesign.Spacing.md)
        }
    }
    
    // Filter Quick Preview Component
    @MainActor
    struct FilterQuickPreview: View {
        let filter: FilterType
        let originalImage: UIImage?
        let isSelected: Bool
        let onTap: () -> Void
        
        @State private var previewImage: UIImage?
        
        var body: some View {
            VStack(spacing: MinimalDesign.Spacing.xs) {
                Button(action: onTap) {
                    ZStack {
                        // プレビュー画像
                        if let previewImage = previewImage {
                            Image(uiImage: previewImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: MinimalDesign.Radius.sm))
                        } else if let originalImage = originalImage {
                            Image(uiImage: originalImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: MinimalDesign.Radius.sm))
                                .overlay(
                                    RoundedRectangle(cornerRadius: MinimalDesign.Radius.sm)
                                        .fill(Color.black.opacity(0.3))
                                )
                        } else {
                            RoundedRectangle(cornerRadius: MinimalDesign.Radius.sm)
                                .fill(MinimalDesign.Colors.tertiaryBackground)
                                .frame(width: 60, height: 60)
                        }
                        
                        // 選択インジケーター
                        if isSelected {
                            RoundedRectangle(cornerRadius: MinimalDesign.Radius.sm)
                                .stroke(MinimalDesign.Colors.accent, lineWidth: 2)
                                .frame(width: 60, height: 60)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // フィルター名
                Text(filter.rawValue)
                    .font(MinimalDesign.Typography.caption)
                    .foregroundColor(isSelected ? MinimalDesign.Colors.accent : MinimalDesign.Colors.secondary)
                    .lineLimit(1)
                    .frame(width: 60)
            }
            .onAppear {
                generatePreview()
            }
        }
        
        private func generatePreview() {
            guard let originalImage = originalImage,
                  filter != .none else {
                previewImage = originalImage
                return
            }
            
            // サムネイル生成
            let thumbnailSize = CGSize(width: 120, height: 120)
            let thumbnail = originalImage.resized(to: thumbnailSize)
            
            guard let ciImage = CoreImageManager.shared.createCIImage(from: thumbnail) else {
                previewImage = thumbnail
                return
            }
            
            // フィルター適用
            if let filtered = CoreImageManager.shared.applyFilterSync(
                filter,
                to: ciImage,
                intensity: filter.previewIntensity
            ) {
                let context = CIContext()
                if let cgImage = context.createCGImage(filtered, from: filtered.extent) {
                    previewImage = UIImage(cgImage: cgImage)
                }
            }
        }
    }
    
    // Caption Field Component
    @MainActor
    struct MinimalCaptionField: View {
        @Binding var caption: String
        @FocusState private var isFocused: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: MinimalDesign.Spacing.xs) {
                Text("Caption")
                    .font(MinimalDesign.Typography.caption)
                    .foregroundColor(MinimalDesign.Colors.secondary)
                
                TextEditor(text: $caption)
                    .font(MinimalDesign.Typography.body)
                    .focused($isFocused)
                    .frame(minHeight: 80)
                    .padding(MinimalDesign.Spacing.sm)
                    .background(MinimalDesign.Colors.tertiaryBackground)
                    .cornerRadius(MinimalDesign.Radius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: MinimalDesign.Radius.md)
                            .stroke(
                                isFocused ? MinimalDesign.Colors.accent : MinimalDesign.Colors.border,
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
        }
    }
    
    // Location Field Component
    @MainActor
    struct MinimalLocationField: View {
        @Binding var locationName: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: MinimalDesign.Spacing.xs) {
                Text("Location (Optional)")
                    .font(MinimalDesign.Typography.caption)
                    .foregroundColor(MinimalDesign.Colors.secondary)
                
                HStack {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundColor(MinimalDesign.Colors.tertiary)
                    
                    TextField("Add location", text: $locationName)
                        .textFieldStyle(MinimalTextFieldStyle())
                }
            }
        }
    }
    
    // Progress View Component
    struct MinimalProgressView: View {
        let progress: Double
        
        var body: some View {
            VStack(spacing: MinimalDesign.Spacing.xs) {
                HStack {
                    Text("Uploading...")
                        .font(MinimalDesign.Typography.caption)
                        .foregroundColor(MinimalDesign.Colors.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(MinimalDesign.Typography.caption)
                        .foregroundColor(MinimalDesign.Colors.secondary)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: MinimalDesign.Colors.accent))
            }
            .padding(.horizontal, MinimalDesign.Spacing.md)
        }
        */
    }
}
