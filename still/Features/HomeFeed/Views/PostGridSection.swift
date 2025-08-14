//======================================================================
// MARK: - PostGridSection.swift
// Purpose: Grid layout section with masonry-style post display and intelligent aspect ratio handling
// Path: still/Features/HomeFeed/Views/PostGridSection.swift
//======================================================================

import SwiftUI

/**
 * PostGridSection manages the masonry-style grid layout for posts.
 * 
 * Features:
 * - Alternating row patterns (1+1 landscape/square, then 3x2 grid)
 * - Intelligent image aspect ratio detection for optimal display
 * - Progressive loading with animation for smooth user experience
 * - Memory-efficient image loading and caching
 * - Post selection handling for navigation
 * 
 * Layout Pattern:
 * - Odd rows: 1 landscape/large image + 1 square image
 * - Even rows: 6 square images in 3x2 grid
 */
struct PostGridSection: View {
    // MARK: - Properties
    
    let posts: [Post]
    @Binding var selectedPost: Post?
    @Binding var navigateToSingleView: Bool
    
    @State private var loadedImages: Set<String> = []
    @State private var groupLoadStatus: [Int: Bool] = [:]
    
    // MARK: - Body
    
    var body: some View {
        LazyVStack(spacing: 7) {
            ForEach(0..<groupedPosts.count, id: \.self) { groupIndex in
                let group = groupedPosts[groupIndex]
                let isOddRow = groupIndex % 2 == 0
                let showGroup = true // groupLoadStatus[groupIndex] ?? false
                
                let _ = print("🎯 PostGridSection: Rendering group \(groupIndex), isOddRow: \(isOddRow), posts in group: \(group.count)")
                
                if isOddRow {
                    // Odd row: 1 landscape image + 1 square image
                    OddRowView(
                        posts: group,
                        availableWidth: UIScreen.main.bounds.width,
                        showContent: showGroup,
                        onImageLoaded: { postId in
                            loadedImages.insert(postId)
                            checkGroupLoadStatus(groupIndex: groupIndex, group: group)
                        }
                    ) { post in
                        handlePostSelection(post)
                    }
                } else {
                    // Even row: 6 square images in 3x2 grid
                    EvenRowView(
                        posts: group,
                        availableWidth: UIScreen.main.bounds.width,
                        showContent: showGroup,
                        onImageLoaded: { postId in
                            loadedImages.insert(postId)
                            checkGroupLoadStatus(groupIndex: groupIndex, group: group)
                        }
                    ) { post in
                        handlePostSelection(post)
                    }
                }
            }
        }
        .background(MinimalDesign.Colors.background)
    }
    
    // MARK: - Computed Properties
    
    private var groupedPosts: [[Post]] {
        print("🎯 PostGridSection: Total posts available: \(posts.count)")
        for (index, post) in posts.enumerated() {
            print("🎯 PostGridSection: Post \(index) - ID: \(post.id), URL: \(post.mediaUrl)")
        }
        return createOptimalGrid(from: posts)
    }
    
    // MARK: - Helper Methods
    
    private func handlePostSelection(_ post: Post) {
        print("🔍 Grid - Post tapped: \(post.id)")
        selectedPost = post
        print("🔍 Grid - selectedPost set to: \(selectedPost?.id ?? "nil")")
        navigateToSingleView = true
        print("🔍 Grid - navigateToSingleView set to: \(navigateToSingleView)")
    }
    
    private func checkGroupLoadStatus(groupIndex: Int, group: [Post]) {
        let allImagesInGroupLoaded = group.allSatisfy { post in
            loadedImages.contains(post.id)
        }
        
        if allImagesInGroupLoaded && groupLoadStatus[groupIndex] != true {
            withAnimation(.easeIn(duration: 0.3)) {
                groupLoadStatus[groupIndex] = true
            }
        }
    }
    
    /// Creates optimal grid layout based on new specifications
    private func createOptimalGrid(from posts: [Post]) -> [[Post]] {
        var result: [[Post]] = []
        var currentIndex = 0
        var rowIndex = 0
        
        while currentIndex < posts.count {
            let isOddRow = rowIndex % 2 == 0
            
            if isOddRow {
                // Odd row: Try to get 1 landscape/large + 1 square, fallback to available posts
                let rowSize = min(2, posts.count - currentIndex)
                let rowPosts = Array(posts[currentIndex..<currentIndex + rowSize])
                result.append(rowPosts)
                currentIndex += rowSize
            } else {
                // Even row: Try to get 6 square images, fallback to available posts
                let rowSize = min(6, posts.count - currentIndex)
                let rowPosts = Array(posts[currentIndex..<currentIndex + rowSize])
                result.append(rowPosts)
                currentIndex += rowSize
            }
            
            rowIndex += 1
        }
        
        return result
    }
}

// MARK: - Grid Row Views

/**
 * OddRowView displays the odd-numbered rows with 1+1 layout
 */
struct OddRowView: View {
    let posts: [Post]
    let availableWidth: CGFloat
    let showContent: Bool
    let onImageLoaded: (String) -> Void
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        HStack(spacing: 7) {
            if posts.count >= 1 {
                // First post - takes up 2/3 of width
                GridPostCell(
                    post: posts[0],
                    width: (availableWidth * 2/3) - 4.5,
                    height: calculateLargeImageHeight(availableWidth: availableWidth),
                    onImageLoaded: onImageLoaded,
                    onTapped: onPostTapped
                )
                .opacity(showContent ? 1 : 0)
                
                if posts.count >= 2 {
                    // Second post - takes up 1/3 of width
                    GridPostCell(
                        post: posts[1],
                        width: (availableWidth * 1/3) - 4.5,
                        height: calculateLargeImageHeight(availableWidth: availableWidth),
                        onImageLoaded: onImageLoaded,
                        onTapped: onPostTapped
                    )
                    .opacity(showContent ? 1 : 0)
                }
            }
        }
        .frame(height: calculateLargeImageHeight(availableWidth: availableWidth))
    }
    
    private func calculateLargeImageHeight(availableWidth: CGFloat) -> CGFloat {
        // Same height as square cells in even rows
        let cellWidth = (availableWidth - 2 * 7) / 3
        return cellWidth
    }
}

/**
 * EvenRowView displays the even-numbered rows with 3x2 grid layout
 */
struct EvenRowView: View {
    let posts: [Post]
    let availableWidth: CGFloat
    let showContent: Bool
    let onImageLoaded: (String) -> Void
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        let cellWidth = (availableWidth - 2 * 7) / 3 // 3 columns with spacing
        let cellHeight = cellWidth // Square cells
        
        VStack(spacing: 7) {
            // First row of 3
            HStack(spacing: 7) {
                ForEach(0..<min(3, posts.count), id: \.self) { index in
                    GridPostCell(
                        post: posts[index],
                        width: cellWidth,
                        height: cellHeight,
                        onImageLoaded: onImageLoaded,
                        onTapped: onPostTapped
                    )
                    .opacity(showContent ? 1 : 0)
                }
                
                // Fill empty spaces if needed
                if posts.count < 3 {
                    ForEach(posts.count..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: cellWidth, height: cellHeight)
                    }
                }
            }
            
            // Second row of 3 (if we have more than 3 posts)
            if posts.count > 3 {
                HStack(spacing: 7) {
                    ForEach(3..<min(6, posts.count), id: \.self) { index in
                        GridPostCell(
                            post: posts[index],
                            width: cellWidth,
                            height: cellHeight,
                            onImageLoaded: onImageLoaded,
                            onTapped: onPostTapped
                        )
                        .opacity(showContent ? 1 : 0)
                    }
                    
                    // Fill empty spaces if needed
                    if posts.count < 6 {
                        ForEach(posts.count..<6, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: cellWidth, height: cellHeight)
                        }
                    }
                }
            }
        }
    }
}

/**
 * GridPostCell represents an individual post cell in the grid
 */
struct GridPostCell: View {
    let post: Post
    let width: CGFloat
    let height: CGFloat
    let onImageLoaded: (String) -> Void
    let onTapped: (Post) -> Void
    
    var body: some View {
        Button(action: {
            onTapped(post)
        }) {
            GridOptimizedImageView(
                imageURL: post.mediaUrl,
                onImageLoaded: {
                    onImageLoaded(post.id)
                }
            )
            .frame(width: width, height: height)
            .clipped()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Grid Optimized Image View

/**
 * GridOptimizedImageView provides optimized image loading for grid display
 */
struct GridOptimizedImageView: View {
    let imageURL: String
    let onImageLoaded: () -> Void
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                        onImageLoaded()
                    }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    )
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // Add URL validation with logging
        guard !imageURL.isEmpty else {
            print("❌ GridOptimizedImageView: Empty image URL")
            isLoading = false
            return
        }
        
        // First check for cached compressed image
        let cacheKey = "\(imageURL)_compressed_grid" as NSString
        if let cachedImage = ImageCacheManager.shared.cache.object(forKey: cacheKey) {
            print("✅ GridOptimizedImageView: Using cached image: \(imageURL)")
            self.image = cachedImage
            isLoading = false
            return
        }
        
        // Load image directly
        print("🔄 GridOptimizedImageView: Loading image from: \(imageURL)")
        if let loadedImage = await ImageCacheManager.shared.loadImage(from: imageURL) {
            // Compress for grid
            let gridImage = await Self.compressForGrid(loadedImage)
            
            // Cache it
            ImageCacheManager.shared.cache.setObject(gridImage, forKey: cacheKey)
            
            self.image = gridImage
            print("✅ GridOptimizedImageView: Image loaded successfully: \(imageURL)")
        } else {
            print("❌ GridOptimizedImageView: Failed to load image: \(imageURL)")
        }
        isLoading = false
    }
    
    static func preloadImage(_ url: String) async -> UIImage? {
        let cacheKey = "\(url)_compressed_grid" as NSString
        
        // Skip if already cached
        if let cachedImage = ImageCacheManager.shared.cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Load and compress
        if let loadedImage = await ImageCacheManager.shared.loadImage(from: url) {
            let gridImage = await compressForGrid(loadedImage)
            ImageCacheManager.shared.cache.setObject(gridImage, forKey: cacheKey)
            return gridImage
        }
        
        return nil
    }
    
    private static func compressForGrid(_ image: UIImage) async -> UIImage {
        let maxSize: CGFloat = 400 // Grid cell size
        let size = image.size
        
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if aspectRatio > 1 {
            newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}