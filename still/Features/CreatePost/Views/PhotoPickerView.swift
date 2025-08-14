//======================================================================
// MARK: - PhotoPickerView.swift
// Purpose: SwiftUI view component (PhotoPickerViewビューコンポーネント)
// Path: still/Features/CreatePost/Views/PhotoPickerView.swift
//======================================================================
//
//  PhotoPickerView.swift
//  tete
//
//  写真選択画面
//

import SwiftUI
import PhotosUI
import Photos

extension Notification.Name {
    static let navigateToEditor = Notification.Name("navigateToEditor")
}


struct PhotoPickerView: View {
    @Environment(\.dismiss) var dismiss
    let onImageSelected: ((PhotoEditorData) -> Void)?
    
    init(onImageSelected: ((PhotoEditorData) -> Void)? = nil) {
        self.onImageSelected = onImageSelected
    }
    @State private var selectedImage: UIImage?
    @State private var selectedImages: [UIImage] = []
    @State private var selectedIndex: Int? = nil
    @State private var selectedAsset: PHAsset? = nil
    @State private var rawProcessor: RAWImageProcessor = RAWImageProcessor.shared
    @StateObject private var photoCacheManager: PhotoCacheManager = PhotoCacheManager.shared
    @State private var showingCamera = false
    @State private var isSquareMode = true // デフォルトは正方形モード
    @State private var imageOffset: CGSize = .zero // 画像のドラッグオフセット
    @State private var currentImageOffset: CGSize = .zero // 現在の画像位置を保存
    @State private var showingPhotoEditor = false

    // Color scheme now handled by MinimalDesign
    
    var body: some View {
        NavigationStack {
            ZStack {
                MinimalDesign.Colors.background.ignoresSafeArea()
                
                GeometryReader { geometry in
                VStack(spacing: 0) {
                    // ヘッダー (固定高さ: 56pt)
                    headerView
                        .frame(height: 56)
                    
                    // 残りの領域を2つのセクションで分割
                    VStack(spacing: 0) {
                        // セクション1: 選択写真表示画面（4:3固定）
                        selectedPhotoView
                            .frame(height: getPreviewHeight(geometry: geometry))
                        
                        // 分離セクション
                        VStack(spacing: 0) {
                            // 上部スペース
                            Rectangle()
                                .fill(MinimalDesign.Colors.background)
                                .frame(height: 12)
                            
                            
                            // Library タイトル
                            HStack {
                                Text("Library")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(MinimalDesign.Colors.primary)
                                    .padding(.leading, 16)
                                
                                Spacer()
                            }
                            .frame(height: 40)
                            .background(MinimalDesign.Colors.background)
                            
                            // 下部スペース
                            Rectangle()
                                .fill(MinimalDesign.Colors.background)
                                .frame(height: 10)
                        }
                        
                        // セクション3: カメラロール（残り領域）
                        ScrollView(showsIndicators: false) {
                            thumbnailGridView
                        }
                        .background(MinimalDesign.Colors.background)
                    }
                }
            }
        }
        } // NavigationStack
        .onAppear {
            Task {
                await photoCacheManager.loadPhotosIfNeeded()
                // 最初の画像を選択
                if !photoCacheManager.recentPhotos.isEmpty && !photoCacheManager.recentAssets.isEmpty {
                    selectedAsset = photoCacheManager.recentAssets[0]
                    selectedIndex = 0
                    loadHighQualityImage(for: photoCacheManager.recentAssets[0])
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CustomCameraView { capturedImage in
                selectedImage = capturedImage
                selectedImages = [capturedImage]
                showingCamera = false
            }
        }
        .navigationDestination(isPresented: $showingPhotoEditor) {
            Group {
                if let asset = selectedAsset, let image = selectedImage {
                    let rawInfo = rawProcessor.getRAWInfo(for: asset)
                    let editorData = PhotoEditorData(asset: asset, rawInfo: rawInfo, previewImage: image)
                    
                    ModernPhotoEditorView(
                        editorData: editorData,
                        onComplete: { editedImage in
                            showingPhotoEditor = false
                            if let handler = onImageSelected {
                                handler(editorData)
                            }
                            dismiss()
                        },
                        onCancel: {
                            showingPhotoEditor = false
                        }
                    )
                } else {
                    // Fallback to prevent white screen
                    Color.black.ignoresSafeArea()
                }
            }
            .navigationBarHidden(true)
            .background(Color.black.ignoresSafeArea())
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetImagePosition() {
        imageOffset = .zero
        currentImageOffset = .zero
    }
    
    private func getPreviewHeight(geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        // 画面高さの約55%を写真表示に使用
        return screenHeight * 0.55
    }
    
    private func calculateImageSize(image: UIImage, in geometry: GeometryProxy) -> CGSize {
        let imageAspectRatio = image.size.width / image.size.height
        let viewWidth = geometry.size.width
        
        // ビューポートサイズ（4:3固定）
        let viewportWidth = viewWidth * 0.98
        let viewportHeight = getPreviewHeight(geometry: geometry)
        let viewportAspectRatio = viewportWidth / viewportHeight // 4:3 = 1.333...
        
        if isSquareMode {
            // 正方形モード: ビューポートを完全にカバーする
            if imageAspectRatio > viewportAspectRatio {
                // 横長画像: 高さでビューポートをカバー
                return CGSize(width: viewportHeight * imageAspectRatio, height: viewportHeight)
            } else {
                // 縦長画像: 幅でビューポートをカバー
                return CGSize(width: viewportWidth, height: viewportWidth / imageAspectRatio)
            }
        } else {
            // 元画像モード: 横にははみ出さないよう幅でフィット、縦は可変
            return CGSize(width: viewportWidth, height: viewportWidth / imageAspectRatio)
        }
    }
    
    
    // MARK: - Views
    
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(MinimalDesign.Colors.primary)
            }
            
            Spacer()
            
            Text("New Post")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(MinimalDesign.Colors.primary)
            
            Spacer()
            
            // Edit button - Red circle with white text
            Button(action: {
                guard let _ = selectedImage else { return }
                showingPhotoEditor = true
            }) {
                Text("Edit")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(selectedImage != nil ? MinimalDesign.Colors.accentRed : Color.gray.opacity(0.5))
                    )
            }
            .disabled(selectedImage == nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    
    private var selectedPhotoView: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景（ビューポートの範囲を示す）
                Rectangle()
                    .fill(MinimalDesign.Colors.background)
                
                if let image = selectedImage {
                    // 写真を中央に配置
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .background(Color.black.opacity(0.02))
                } else {
                    // プレースホルダー
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundColor(MinimalDesign.Colors.tertiary)
                        Text("写真を選択")
                            .foregroundColor(MinimalDesign.Colors.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
            }
        }
    }
    
    
    
    private var thumbnailGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 4), spacing: 7) {
            ForEach(0..<photoCacheManager.recentPhotos.count, id: \.self) { index in
                Button(action: {
                    selectedIndex = index
                    selectedAsset = photoCacheManager.recentAssets[index]
                    // 高品質な画像を選択時に取得
                    loadHighQualityImage(for: photoCacheManager.recentAssets[index])
                    // オフセットをリセット
                    resetImagePosition()
                }) {
                    ZStack(alignment: .topLeading) {
                        Image(uiImage: photoCacheManager.recentPhotos[index])
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                        
                        // RAWバッジ
                        if index < photoCacheManager.recentAssets.count {
                            let rawInfo = rawProcessor.getRAWInfo(for: photoCacheManager.recentAssets[index])
                            if rawInfo.isRAW {
                                HStack {
                                    Spacer()
                                    VStack {
                                        Text(rawInfo.displayFormat)
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(MinimalDesign.Colors.accentRed.opacity(0.9))
                                            .cornerRadius(4)
                                        Spacer()
                                    }
                                }
                                .padding(4)
                            }
                        }
                        
                        // 選択中の画像にチェックマーク表示
                        if selectedIndex == index {
                            VStack {
                                HStack {
                                    ZStack {
                                        Rectangle()
                                            .fill(MinimalDesign.Colors.accentRed)
                                            .frame(width: 14, height: 14)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                Spacer()
                            }
                            .padding(6)
                        }
                    }
                }
            }
            
            // プレースホルダー
            if photoCacheManager.isLoading {
                ForEach(0..<12, id: \.self) { _ in
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .aspectRatio(1, contentMode: .fit)
                        .shimmer()
                }
            }
        }
    }
    
    
    // MARK: - Methods
    
    private func loadHighQualityImage(for asset: PHAsset) {
        Task {
            if let image = await photoCacheManager.getHighQualityImage(for: asset) {
                selectedImage = image
                selectedImages = [image]
                
                // 画像のアスペクト比に基づいてモードを自動設定
                let aspectRatio = image.size.width / image.size.height
                // 横長の写真（16:9より横長）の場合は元画像モードに
                if aspectRatio > 1.7 {
                    isSquareMode = false
                } else {
                    // それ以外は正方形モード
                    isSquareMode = true
                }
            }
        }
    }
}

// MARK: - Shimmer Effect
extension View {
    func shimmer() -> some View {
        self
            .redacted(reason: .placeholder)
            .shimmering()
    }
}

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200 - 100)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear { phase = 1 }
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(Shimmer())
    }
}

// MARK: - Preview
#if DEBUG
struct PhotoPickerView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoPickerView()
    }
}
#endif