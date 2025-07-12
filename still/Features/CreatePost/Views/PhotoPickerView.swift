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
    @State private var recentPhotos: [UIImage] = []
    @State private var recentAssets: [PHAsset] = []
    @State private var selectedIndex: Int? = nil
    @State private var selectedAsset: PHAsset? = nil
    @State private var isLoadingPhotos = true
    @State private var rawProcessor = RAWImageProcessor.shared
    @State private var showingCamera = false
    @State private var isSquareMode = true // デフォルトは正方形モード
    @State private var imageOffset: CGSize = .zero // 画像のドラッグオフセット
    @State private var currentImageOffset: CGSize = .zero // 現在の画像位置を保存

    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea()
            
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
                                .fill(colorScheme == .dark ? Color.black : Color.white)
                                .frame(height: 20)
                            
                            // 仕切り線（ヘッダーと同じ色）
                            Rectangle()
                                .fill(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.85))
                                .frame(height: 1)
                            
                            // Library タイトル
                            HStack {
                                Text("Library")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .padding(.leading, 16)
                                
                                Spacer()
                            }
                            .frame(height: 40)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            
                            // 下部スペース
                            Rectangle()
                                .fill(colorScheme == .dark ? Color.black : Color.white)
                                .frame(height: 12)
                        }
                        
                        // セクション3: カメラロール（残り領域）
                        ScrollView(showsIndicators: false) {
                            thumbnailGridView
                        }
                        .background(colorScheme == .dark ? Color.black : Color.white)
                    }
                }
            }
        }
        .onAppear {
            loadRecentPhotos()
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CustomCameraView { capturedImage in
                selectedImage = capturedImage
                selectedImages = [capturedImage]
                showingCamera = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetImagePosition() {
        imageOffset = .zero
        currentImageOffset = .zero
    }
    
    private func getPreviewHeight(geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        // ビューポート幅（画面幅の85%）
        let viewportWidth = screenWidth * 0.85
        // 4:3のアスペクト比で固定
        return viewportWidth * (3.0 / 4.0)
    }
    
    private func calculateImageSize(image: UIImage, in geometry: GeometryProxy) -> CGSize {
        let imageAspectRatio = image.size.width / image.size.height
        let viewWidth = geometry.size.width
        
        // ビューポートサイズ（4:3固定）
        let viewportWidth = viewWidth * 0.85
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
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            
            Spacer()
            
            Text("New Post")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Spacer()
            
            Button("次へ") {
                print("🔵 次へボタンが押されました")
                
                if let asset = selectedAsset {
                    print("🔵 Asset選択済み: \(asset)")
                    // RAW画像かどうかを判定してエディターに渡す
                    let rawInfo = rawProcessor.getRAWInfo(for: asset)
                    print("🔵 RAW情報: \(rawInfo)")
                    
                    // AssetとRAW情報をセットで渡す
                    let editorData = PhotoEditorData(asset: asset, rawInfo: rawInfo, previewImage: selectedImage)
                    print("🔵 Completion handler呼び出し")
                    print("🔵 onImageSelected is nil: \(onImageSelected == nil)")
                    
                    // completion handlerで直接渡す
                    if let handler = onImageSelected {
                        print("🔵 ハンドラー実行中...")
                        handler(editorData)
                        print("🔵 ハンドラー実行完了")
                    } else {
                        print("🔴 ハンドラーがnil!")
                    }
                } else if let image = selectedImage {
                    print("🔵 UIImage fallback")
                    // UIImageの場合、ダミーのassetでPhotoEditorDataを作成
                    if let asset = selectedAsset {
                        let rawInfo = RAWImageInfo(isRAW: false, format: nil, fileSize: 0, 
                                                 dimensions: image.size, asset: asset)
                        let editorData = PhotoEditorData(asset: asset, rawInfo: rawInfo, previewImage: image)
                        onImageSelected?(editorData)
                    }
                } else {
                    print("🔴 画像が選択されていません")
                }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(selectedImage != nil ? MinimalDesign.Colors.accentRed : .gray)
            .disabled(selectedImage == nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.85))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    
    private var selectedPhotoView: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景（ビューポートの範囲を示す）
                Rectangle()
                    .fill(colorScheme == .dark ? Color.black : Color.white)
                
                if let image = selectedImage {
                    // ビューポート（クリッピング領域）を画面中央に配置
                    ZStack {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: geometry.size.width * 0.85, height: getPreviewHeight(geometry: geometry))
                        
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit) // 全画面縮小表示
                            .frame(width: geometry.size.width * 0.85, height: getPreviewHeight(geometry: geometry))
                    }
                    .frame(width: geometry.size.width * 0.85, height: getPreviewHeight(geometry: geometry))
                    .clipped()
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                } else {
                    // プレースホルダー
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundColor(colorScheme == .dark ? .gray : .gray)
                        Text("写真を選択")
                            .foregroundColor(colorScheme == .dark ? .gray : .gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
            }
        }
    }
    
    
    
    private var thumbnailGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 4), spacing: 1) {
            ForEach(0..<recentPhotos.count, id: \.self) { index in
                Button(action: {
                    selectedIndex = index
                    selectedAsset = recentAssets[index]
                    // 高品質な画像を選択時に取得
                    loadHighQualityImage(for: recentAssets[index])
                    // オフセットをリセット
                    resetImagePosition()
                }) {
                    ZStack(alignment: .topLeading) {
                        Image(uiImage: recentPhotos[index])
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                        
                        // RAWバッジ
                        if index < recentAssets.count {
                            let rawInfo = rawProcessor.getRAWInfo(for: recentAssets[index])
                            if rawInfo.isRAW {
                                HStack {
                                    Spacer()
                                    VStack {
                                        Text(rawInfo.displayFormat)
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.white.opacity(0.9))
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
            if isLoadingPhotos {
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
    
    private func loadRecentPhotos() {
        Task {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 50
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var photos: [UIImage] = []
            var assetArray: [PHAsset] = []
            
            let imageManager = PHImageManager.default()
            let targetSize = CGSize(width: 800, height: 800) // 画質向上のためサイズ増加
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            
            assets.enumerateObjects { asset, _, _ in
                imageManager.requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFit,
                    options: options
                ) { image, _ in
                    if let image = image {
                        photos.append(image)
                        assetArray.append(asset)
                    }
                }
            }
            
            await MainActor.run {
                self.recentPhotos = photos
                self.recentAssets = assetArray
                self.isLoadingPhotos = false
                if !photos.isEmpty && !assetArray.isEmpty {
                    self.selectedAsset = assetArray[0]
                    self.selectedIndex = 0
                    // 最初の画像を高品質で取得
                    self.loadHighQualityImage(for: assetArray[0])
                }
            }
        }
    }
    
    private func loadHighQualityImage(for asset: PHAsset) {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .none // オリジナルサイズで取得
        
        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize, // 最大サイズで取得
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                if let image = image {
                    self.selectedImage = image
                    self.selectedImages = [image]
                    
                    // 画像のアスペクト比に基づいてモードを自動設定
                    let aspectRatio = image.size.width / image.size.height
                    // 横長の写真（16:9より横長）の場合は元画像モードに
                    if aspectRatio > 1.7 {
                        self.isSquareMode = false
                    } else {
                        // それ以外は正方形モード
                        self.isSquareMode = true
                    }
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