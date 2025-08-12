//======================================================================
// MARK: - RemoteImageView.swift (名前変更版)
// Path: foodai/Features/SharedViews/RemoteImageView.swift
//======================================================================
import SwiftUI

struct RemoteImageView: View {
    let imageURL: String
    let thumbnailSize: String
    
    @State private var thumbnailImage: UIImage?
    @State private var fullImage: UIImage?
    @State private var isLoading = true
    
    init(imageURL: String, thumbnailSize: String = "medium") {
        self.imageURL = imageURL
        self.thumbnailSize = thumbnailSize
    }
    
    var body: some View {
        Group {
            if imageURL.starts(with: "http") {
                // サムネイル優先読み込み
                if let fullImage = fullImage {
                    Image(uiImage: fullImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let thumbnailImage = thumbnailImage {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 0.5)
                } else if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: "1A1A1A"))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: "1A1A1A"))
                }
            } else if let uiImage = UIImage(named: imageURL) {
                // ローカル画像
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // 画像が見つからない場合
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                            Text("Image not found")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    )
            }
        }
        .task {
            await loadImages()
        }
    }
    
    private func loadImages() async {
        isLoading = true
        
        // 1. サムネイルを先に読み込み
        thumbnailImage = await ImageCacheManager.shared.loadThumbnail(from: imageURL, size: thumbnailSize)
        
        // 2. フルサイズを背景で読み込み
        fullImage = await ImageCacheManager.shared.loadImage(from: imageURL)
        
        isLoading = false
    }
}

