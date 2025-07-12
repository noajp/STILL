//======================================================================
// MARK: - RemoteImageView.swift (名前変更版)
// Path: foodai/Features/SharedViews/RemoteImageView.swift
//======================================================================
import SwiftUI

struct RemoteImageView: View {
    let imageURL: String
    
    var body: some View {
        Group {
            if imageURL.starts(with: "http") {
                // URLから画像を読み込む
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                    @unknown default:
                        EmptyView()
                    }
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
    }
}

