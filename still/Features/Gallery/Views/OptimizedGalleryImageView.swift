//======================================================================
// MARK: - OptimizedGalleryImageView.swift
// Purpose: Optimized image view for Gallery grid with immediate display
// Path: still/Features/Gallery/Views/OptimizedGalleryImageView.swift
//======================================================================

import SwiftUI

struct OptimizedGalleryImageView: View {
    let imageURL: String
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                Rectangle()
                    .fill(Color(hex: "1A1A1A"))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.6)
                            .opacity(0.5)
                    )
            } else {
                Rectangle()
                    .fill(Color(hex: "1A1A1A"))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    )
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        isLoading = true
        
        // Load full image directly for immediate display
        if let loadedImage = await ImageCacheManager.shared.loadImage(from: imageURL) {
            withAnimation(.none) { // No animation for immediate display
                self.image = loadedImage
            }
        }
        
        isLoading = false
    }
}