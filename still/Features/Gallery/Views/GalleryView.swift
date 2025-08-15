//======================================================================
// MARK: - GalleryView.swift
// Purpose: Gallery view with grid layout for browsing all posts
// Path: still/Features/Gallery/Views/GalleryView.swift
//======================================================================

import SwiftUI

extension Notification.Name {
    static let resetGalleryNavigation = Notification.Name("resetGalleryNavigation")
    static let resetMessagesNavigation = Notification.Name("resetMessagesNavigation")
    static let resetProfileNavigation = Notification.Name("resetProfileNavigation")
    static let resetHomeNavigation = Notification.Name("resetHomeNavigation")
}

/**
 * GalleryView displays all posts in a grid layout with unified header.
 * 
 * Features:
 * - Grid layout for post thumbnails
 * - Pull-to-refresh functionality
 * - Infinite scroll with pagination
 * - Navigation to post detail view
 * - Loading and error states
 */
struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()
    @StateObject private var feedViewModel = HomeFeedViewModel()
    @State private var selectedPost: Post?
    @State private var navigateToDetail = false
    @State private var showGridMode = false
    @State private var resetTrigger = 0
    
    var body: some View {
        ScrollableHeaderView(
            title: "GALLERY",
            rightButton: nil
        ) {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                // Initial loading state
                VStack {
                    ProgressView()
                    Text("Loading posts...")
                        .font(.caption)
                        .foregroundColor(Color(hex: "1A1A1A"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if viewModel.posts.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "1A1A1A").opacity(0.8))
                    Text("No posts yet")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Be the first to share something")
                        .font(.caption)
                        .foregroundColor(Color(hex: "1A1A1A"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else {
                // Alternating grid layout
                AlternatingGridLayout(
                    posts: viewModel.posts,
                    onPostTapped: { post in
                        selectedPost = post
                        navigateToDetail = true
                    }
                )
                .padding(.horizontal, 2)
            }
        }
        .task {
            // Only load if data is not already cached
            await viewModel.loadPostsIfNeeded()
        }
        .refreshable {
            // Allow manual refresh via pull-to-refresh
            await viewModel.refreshPosts()
        }
        .navigationDestination(isPresented: $navigateToDetail) {
            if let post = selectedPost {
                SinglePostView(
                    initialPost: post,
                    viewModel: feedViewModel,
                    showGridMode: $showGridMode
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetGalleryNavigation)) { _ in
            selectedPost = nil
            navigateToDetail = false
            showGridMode = false
        }
    }
}

// MARK: - Alternating Grid Layout
struct AlternatingGridLayout: View {
    let posts: [Post]
    let onPostTapped: (Post) -> Void
    
    // Process posts into rows based on 3-row cycle pattern
    private var rows: [GridRow] {
        var result: [GridRow] = []
        var currentIndex = 0
        var rowIndex = 0
        
        while currentIndex < posts.count {
            switch rowIndex % 3 {
            case 0:
                // Row 1: Landscape + Square
                let row = createLandscapeSquareRow(from: currentIndex)
                result.append(row)
                currentIndex += row.posts.count
            case 1:
                // Row 2: Slightly vertical photos
                let row = createVerticalRow(from: currentIndex)
                result.append(row)
                currentIndex += row.posts.count
            case 2:
                // Row 3: Square photos
                let row = createSquareRow(from: currentIndex, count: 3)
                result.append(row)
                currentIndex += row.posts.count
            default:
                break
            }
            rowIndex += 1
        }
        
        return result
    }
    
    private func createLandscapeSquareRow(from startIndex: Int) -> GridRow {
        var rowPosts: [Post] = []
        var remainingPosts = Array(posts[startIndex..<min(startIndex + 3, posts.count)])
        
        // Try to find a landscape photo
        if let landscapeIndex = remainingPosts.firstIndex(where: { $0.shouldDisplayAsLandscape }) {
            let landscapePost = remainingPosts.remove(at: landscapeIndex)
            rowPosts.append(landscapePost)
        }
        
        // Add remaining post as square (if any)
        if !remainingPosts.isEmpty {
            rowPosts.append(remainingPosts.first!)
        }
        
        return GridRow(posts: rowPosts, style: .landscapeSquare)
    }
    
    private func createVerticalRow(from startIndex: Int) -> GridRow {
        let endIndex = min(startIndex + 3, posts.count)
        let rowPosts = Array(posts[startIndex..<endIndex])
        return GridRow(posts: rowPosts, style: .vertical)
    }
    
    private func createSquareRow(from startIndex: Int, count: Int) -> GridRow {
        let endIndex = min(startIndex + count, posts.count)
        let rowPosts = Array(posts[startIndex..<endIndex])
        return GridRow(posts: rowPosts, style: .squares)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(rows) { row in
                    GridRowView(row: row, onPostTapped: onPostTapped)
                }
            }
        }
    }
}

// MARK: - Grid Row Model
struct GridRow: Identifiable {
    let id = UUID()
    let posts: [Post]
    let style: RowStyle
    
    enum RowStyle {
        case landscapeSquare  // Landscape (2 squares width) + 1 square
        case vertical        // 3 slightly vertical photos
        case squares         // 3 regular squares
    }
}

// MARK: - Grid Row View
struct GridRowView: View {
    let row: GridRow
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        switch row.style {
        case .landscapeSquare:
            LandscapeSquareRowView(posts: row.posts, onPostTapped: onPostTapped)
        case .vertical:
            VerticalRowView(posts: row.posts, onPostTapped: onPostTapped)
        case .squares:
            SquaresRowView(posts: row.posts, onPostTapped: onPostTapped)
        }
    }
}

// MARK: - Landscape + Square Row View
struct LandscapeSquareRowView: View {
    let posts: [Post]
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let spacing: CGFloat = 4
            let twoThirdsWidth = (totalWidth * 2 / 3) - spacing / 2
            let oneThirdWidth = (totalWidth / 3) - spacing / 2
            let height = oneThirdWidth // Square height based on 1/3 width
            
            HStack(spacing: spacing) {
                if posts.count > 0 {
                    // Landscape photo (2/3 width) - maintain aspect ratio
                    OptimizedGalleryImageView(imageURL: posts[0].mediaUrl)
                        .frame(width: twoThirdsWidth, height: height)
                        .clipped()
                        .onTapGesture {
                            onPostTapped(posts[0])
                        }
                }
                
                if posts.count > 1 {
                    // Square photo (1/3 width)
                    PostThumbnailView(post: posts[1], forceSquare: true)
                        .frame(width: oneThirdWidth, height: height)
                        .clipped()
                        .onTapGesture {
                            onPostTapped(posts[1])
                        }
                } else {
                    // Empty space if no second photo
                    Rectangle()
                        .fill(Color(hex: "1A1A1A"))
                        .frame(width: oneThirdWidth, height: height)
                }
            }
        }
        .frame(height: UIScreen.main.bounds.width / 3)
    }
}

// MARK: - Six Squares Row View
// MARK: - Vertical Row View (slightly vertical photos)
struct VerticalRowView: View {
    let posts: [Post]
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let spacing: CGFloat = 4
            let itemWidth = (totalWidth - spacing * 2) / 3
            let itemHeight = itemWidth * 1.3 // Slightly vertical (aspect ratio 1:1.3)
            
            HStack(spacing: spacing) {
                ForEach(0..<3) { index in
                    if index < posts.count {
                        OptimizedGalleryImageView(imageURL: posts[index].mediaUrl)
                            .frame(width: itemWidth, height: itemHeight)
                            .clipped()
                            .onTapGesture {
                                onPostTapped(posts[index])
                            }
                    } else {
                        Rectangle()
                            .fill(Color(hex: "1A1A1A"))
                            .frame(width: itemWidth, height: itemHeight)
                    }
                }
            }
        }
        .frame(height: (UIScreen.main.bounds.width / 3) * 1.3)
    }
}

struct SquaresRowView: View {
    let posts: [Post]
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let spacing: CGFloat = 4
            let itemWidth = (totalWidth - spacing * 2) / 3
            
            HStack(spacing: spacing) {
                ForEach(0..<3) { index in
                    if index < posts.count {
                        PostThumbnailView(post: posts[index], forceSquare: true)
                            .frame(width: itemWidth, height: itemWidth)
                            .clipped()
                            .onTapGesture {
                                onPostTapped(posts[index])
                            }
                    } else {
                        Rectangle()
                            .fill(Color(hex: "1A1A1A"))
                            .frame(width: itemWidth, height: itemWidth)
                    }
                }
            }
        }
        .frame(height: UIScreen.main.bounds.width / 3)
    }
}

// MARK: - Post Thumbnail View
struct PostThumbnailView: View {
    let post: Post
    let forceSquare: Bool
    
    init(post: Post, forceSquare: Bool = false) {
        self.post = post
        self.forceSquare = forceSquare
    }
    
    var body: some View {
        GeometryReader { geometry in
            OptimizedGalleryImageView(imageURL: post.mediaUrl)
                .frame(
                    width: geometry.size.width,
                    height: forceSquare ? geometry.size.width : geometry.size.height
                )
                .clipped()
        }
        .aspectRatio(forceSquare ? 1.0 : nil, contentMode: .fit)
    }
}

#Preview {
    NavigationStack {
        GalleryView()
    }
}