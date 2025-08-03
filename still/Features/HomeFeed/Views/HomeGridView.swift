//======================================================================
// MARK: - HomeGridView.swift
// Purpose: Home feed grid layout with masonry-style post display, landscape/square aspect handling, and infinite scroll
// Path: still/Features/HomeFeed/Views/HomeGridView.swift
//======================================================================
import SwiftUI
import Combine

/**
 * HomeGridView provides an intelligent masonry-style grid layout for displaying posts.
 * 
 * This view features:
 * - Adaptive grid layout with alternating row patterns (1+1 landscape/square, then 3x2 grid)
 * - Intelligent image aspect ratio detection for optimal display
 * - Progressive loading with animation for smooth user experience
 * - Post upload status tracking with visual progress indicators
 * - Navigation to single post view with state management
 * - Pull-to-refresh and infinite scroll capabilities
 * - Memory-efficient image loading and caching
 * 
 * Layout Pattern:
 * - Odd rows: 1 landscape/large image + 1 square image
 * - Even rows: 6 square images in 3x2 grid
 * 
 * The view automatically categorizes posts by aspect ratio and distributes them
 * optimally across the alternating layout pattern for visual balance.
 */
@MainActor
struct HomeGridView: View {
    // MARK: - Properties
    
    /// View model managing post data and feed operations
    @StateObject private var viewModel = HomeFeedViewModel()
    
    /// Singleton manager for tracking post upload status
    @StateObject private var postStatusManager = PostStatusManager.shared
    
    /// Controls whether to show grid mode vs following feed mode
    @Binding var showGridMode: Bool
    
    /// Controls display of create post interface
    @Binding var showingCreatePost: Bool
    
    /// Tracks if user is currently viewing a single post
    @Binding var isInSingleView: Bool
    
    /// Currently selected post for navigation
    @State private var selectedPost: Post?
    
    /// Controls navigation to single post view
    @State private var navigateToSingleView: Bool = false
    
    /// Environment dismiss handler
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollableHeaderView(
            title: "STILL"
        ) {
            VStack(spacing: 0) {
                // Post Upload Status Bar
                if PostStatusManager.shared.showStatus {
                    VStack(spacing: 0) {
                        // Status message
                        HStack {
                            Text(PostStatusManager.shared.statusMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("×") {
                                PostStatusManager.shared.hideStatus()
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                        
                        // Thin progress bar
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(white: 0.15))
                                .frame(height: 2)
                            
                            Rectangle()
                                .fill(PostStatusManager.shared.statusColor)
                                .frame(width: UIScreen.main.bounds.width * PostStatusManager.shared.progress, height: 2)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Content
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading...")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else if viewModel.posts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        Text("No posts yet")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Tap the + button\nto create your first post")
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    // Posts Display - Grid or List mode
                    if showGridMode {
                        // Custom Grid View with alternating layout
                        CustomGridView(posts: viewModel.posts, showGridMode: $showGridMode, selectedPost: $selectedPost, navigateToSingleView: $navigateToSingleView)
                    } else {
                        // Following Post View mode - Shows posts from followed users and own posts
                        FollowingPostView(viewModel: viewModel)
                    }
                }
                
                // Bottom padding for tab bar clearance
                Color.clear
                    .frame(height: 110)
            }
        }
        .navigationDestination(isPresented: $navigateToSingleView) {
            if let selectedPost = selectedPost {
                SinglePostView(
                    initialPost: selectedPost,
                    viewModel: viewModel,
                    showGridMode: $showGridMode
                )
                .onAppear {
                    isInSingleView = true
                }
                .onDisappear {
                    isInSingleView = false
                }
            }
        }
        .onAppear {
            Task {
                // Always load posts for following view first (primary)
                await viewModel.loadPostsIfNeeded()
                
                // If currently showing following view, also preload grid data in background
                if !showGridMode {
                    Task.detached(priority: .background) {
                        await viewModel.preloadGridData()
                    }
                } else {
                    // When in grid mode, preload grid-optimized images
                    let mediaUrls = viewModel.posts.map { $0.mediaUrl }
                    Task.detached(priority: .high) {
                        await preloadGridImages(mediaUrls)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostCreated"))) { _ in
            Task {
                await viewModel.forceRefreshPosts()
            }
        }
        .onChange(of: isInSingleView) { _, newValue in
            if !newValue && navigateToSingleView {
                // When returning from single view
                navigateToSingleView = false
                selectedPost = nil
            }
        }
        .onChange(of: showGridMode) { _, newValue in
            if newValue && isInSingleView {
                // When switching to grid mode, also exit single view
                navigateToSingleView = false
                selectedPost = nil
            }
            
            // Handle mode switching
            Task {
                if newValue {
                    // Switching to grid mode - ensure posts are loaded and preload thumbnails
                    print("🔄 Switching to grid mode")
                    await viewModel.loadPostsIfNeeded()
                    
                    // Preload grid-optimized images for instant display
                    let mediaUrls = viewModel.posts.map { $0.mediaUrl }
                    Task.detached(priority: .high) {
                        await preloadGridImages(mediaUrls)
                    }
                } else {
                    // Switching to following mode - start background preload for grid
                    print("🔄 Switching to following mode")
                    Task.detached(priority: .background) {
                        await viewModel.preloadGridData()
                    }
                }
            }
        }
    }
    
    // Grid image preloader
    private func preloadGridImages(_ urls: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for (index, url) in urls.enumerated() {
                // Load first 20 images with high priority
                if index < 20 {
                    group.addTask(priority: .high) {
                        let _ = await GridOptimizedImageView.preloadImage(url)
                    }
                } else {
                    // Load rest with lower priority
                    group.addTask(priority: .medium) {
                        let _ = await GridOptimizedImageView.preloadImage(url)
                    }
                }
            }
        }
    }
}

// MARK: - Post Card View
struct PostCardView: View {
    let post: Post
    let onLikeTapped: (Post) -> Void
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authManager: AuthManager
    @State private var showProfile = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Image with optimized loading
            OptimizedAsyncImage(urlString: post.mediaUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure(_):
                    Rectangle()
                        .fill(Color.gray)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                case .empty:
                    Rectangle()
                        .fill(Color.gray)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color.gray)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 400)
            .frame(width: UIScreen.main.bounds.width)
            .clipped()
            .background(MinimalDesign.Colors.background)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.black, lineWidth: 10)
            )
            
            // User Header (moved below image)
            HStack(spacing: 12) {
                // Avatar - タップ可能 (compressed for performance)
                Button(action: {
                    if post.user?.id != authManager.currentUser?.id {
                        showProfile = true
                    }
                }) {
                    if let avatarUrl = post.user?.avatarUrl {
                        CompressedAsyncImage(
                            urlString: avatarUrl,
                            quality: .low
                        ) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(white: 0.15))
                                .overlay(
                                    Text(post.user?.username.prefix(1).uppercased() ?? "?")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                )
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white, lineWidth: 2)
                        )
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(white: 0.15))
                            .overlay(
                                Text(post.user?.username.prefix(1).uppercased() ?? "?")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // User Info - タップ可能
                Button(action: {
                    if post.user?.id != authManager.currentUser?.id {
                        showProfile = true
                    }
                }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.user?.username ?? "unknown")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        if let location = post.locationName {
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Like Button
                Button(action: { onLikeTapped(post) }) {
                    Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(post.isLikedByMe ? .red : .white)
                }
                
                // Comment Button
                Button(action: {}) {
                    Image(systemName: "message")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.white)
                }
                
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Caption
            if let caption = post.caption, !caption.isEmpty {
                HStack {
                    Text(caption)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            
            // Divider line between posts
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.vertical, 50)
            
            // Large spacing between posts for single view
            Color.clear
                .frame(height: 50)
        }
        .background(Color.black)
        .fullScreenCover(isPresented: $showProfile) {
            if let userId = post.user?.id, userId != authManager.currentUser?.id {
                OtherUserProfileView(userId: userId)
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Custom Grid View

struct CustomGridView: View {
    let posts: [Post]
    @Binding var showGridMode: Bool
    @Binding var selectedPost: Post?
    @Binding var navigateToSingleView: Bool
    @State private var loadedImages: Set<String> = []
    @State private var groupLoadStatus: [Int: Bool] = [:]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 1.5) {
            ForEach(0..<groupedPosts.count, id: \.self) { groupIndex in
                let group = groupedPosts[groupIndex]
                let isOddRow = groupIndex % 2 == 0
                let showGroup = true // groupLoadStatus[groupIndex] ?? false
                
                if isOddRow {
                    // 奇数段: 横長写真1枚 + 正方形写真1枚
                    OddRowView(
                        posts: group,
                        showContent: showGroup,
                        onImageLoaded: { postId in
                            loadedImages.insert(postId)
                            checkGroupLoadStatus(groupIndex: groupIndex, group: group)
                        }
                    ) { post in
                        selectedPost = post
                        navigateToSingleView = true
                    }
                } else {
                    // 偶数段: 正方形写真6枚
                    EvenRowView(
                        posts: group,
                        showContent: showGroup,
                        onImageLoaded: { postId in
                            loadedImages.insert(postId)
                            checkGroupLoadStatus(groupIndex: groupIndex, group: group)
                        }
                    ) { post in
                        selectedPost = post
                        navigateToSingleView = true
                    }
                }
            }
            }
        }
        .background(MinimalDesign.Colors.background)
    }
    
    private var groupedPosts: [[Post]] {
        return createOptimalGrid(from: posts)
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
    
    /// 新しい仕様に基づいてグリッドレイアウトを生成
    private func createOptimalGrid(from posts: [Post]) -> [[Post]] {
        
        var groups: [[Post]] = []
        var blockNumber = 1 // ブロック番号（1から開始）
        
        // 投稿を横長と正方形に分類
        var landscapePosts: [(index: Int, post: Post)] = []
        var squarePosts: [(index: Int, post: Post)] = []
        
        for (index, post) in posts.enumerated() {
            if post.shouldDisplayAsLandscape {
                landscapePosts.append((index, post))
            } else {
                squarePosts.append((index, post))
            }
        }
        
        
        var landscapeIndex = 0
        var squareIndex = 0
        
        while landscapeIndex < landscapePosts.count || squareIndex < squarePosts.count {
            if blockNumber % 2 == 1 {
                // 奇数ブロック：横長1枚 + 正方形1枚
                var block: [Post] = []
                
                // 横長写真を1枚追加
                if landscapeIndex < landscapePosts.count {
                    block.append(landscapePosts[landscapeIndex].post)
                    landscapeIndex += 1
                } else if squareIndex < squarePosts.count {
                    // 横長写真がない場合は正方形を使用
                    block.append(squarePosts[squareIndex].post)
                    squareIndex += 1
                }
                
                // 正方形写真を1枚追加
                if squareIndex < squarePosts.count {
                    block.append(squarePosts[squareIndex].post)
                    squareIndex += 1
                } else if landscapeIndex < landscapePosts.count {
                    // 正方形写真がない場合は横長を使用
                    block.append(landscapePosts[landscapeIndex].post)
                    landscapeIndex += 1
                }
                
                if !block.isEmpty {
                    groups.append(block)
                }
            } else {
                // 偶数ブロック：正方形6枚
                var block: [Post] = []
                let neededSquares = 6
                
                // まず正方形写真を使用
                while block.count < neededSquares && squareIndex < squarePosts.count {
                    block.append(squarePosts[squareIndex].post)
                    squareIndex += 1
                }
                
                // 不足分は横長写真で補填
                while block.count < neededSquares && landscapeIndex < landscapePosts.count {
                    block.append(landscapePosts[landscapeIndex].post)
                    landscapeIndex += 1
                }
                
                if !block.isEmpty {
                    groups.append(block)
                }
            }
            
            blockNumber += 1
            
            // 全ての写真を使い切ったら終了
            if landscapeIndex >= landscapePosts.count && squareIndex >= squarePosts.count {
                break
            }
        }
        
        return groups
    }
}

// MARK: - Odd Row View (横長 + 正方形)

struct OddRowView: View {
    let posts: [Post]
    let showContent: Bool
    let onImageLoaded: (String) -> Void
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        HStack(spacing: 1.5) {
            // 最初の写真（アスペクト比に基づいて表示）
            if posts.count > 0 {
                let firstPost = posts[0]
                let isLandscape = firstPost.shouldDisplayAsLandscape
                
                if isLandscape {
                    // 横長写真は横長で表示 (幅は2/3)
                    GridImageView(
                        post: firstPost,
                        showContent: showContent,
                        onImageLoaded: { onImageLoaded(firstPost.id) }
                    ) {
                        onPostTapped(firstPost)
                    }
                    .frame(width: rectangleWidth, height: squareSize)
                    .clipped()
                } else {
                    // 横長でない写真は正方形で表示
                    GridImageView(
                        post: firstPost,
                        showContent: showContent,
                        onImageLoaded: { onImageLoaded(firstPost.id) }
                    ) {
                        onPostTapped(firstPost)
                    }
                    .frame(width: squareSize, height: squareSize)
                    .clipped()
                    .aspectRatio(1, contentMode: .fill)
                }
            }
            
            // 2枚目の写真（常に正方形）
            if posts.count > 1 {
                let secondaryWidth = posts[0].shouldDisplayAsLandscape ? squareSize : rectangleWidth
                
                GridImageView(
                    post: posts[1],
                    showContent: showContent,
                    onImageLoaded: { onImageLoaded(posts[1].id) }
                ) {
                    onPostTapped(posts[1])
                }
                .frame(width: secondaryWidth, height: squareSize)
                .clipped()
                .aspectRatio(1, contentMode: .fill)
            }
        }
        .frame(height: squareSize)
    }
    
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    private var spacing: CGFloat {
        1.5
    }
    
    private var availableWidth: CGFloat {
        screenWidth // 画面全体の幅を使用
    }
    
    private var squareSize: CGFloat {
        // 3列のグリッドで、間に2つのspacing（各1.5）があるため
        (availableWidth - (spacing * 2)) / 3
    }
    
    private var rectangleWidth: CGFloat {
        // 正方形2つ分 + 間の1つのspacing
        (squareSize * 2) + spacing
    }
}

// MARK: - Even Row View (正方形6枚)

struct EvenRowView: View {
    let posts: [Post]
    let showContent: Bool
    let onImageLoaded: (String) -> Void
    let onPostTapped: (Post) -> Void
    
    var body: some View {
        VStack(spacing: 1.5) {
            // 上段3枚
            HStack(spacing: 1.5) {
                ForEach(0..<3, id: \.self) { index in
                    if index < posts.count {
                        GridImageView(
                            post: posts[index],
                            showContent: showContent,
                            onImageLoaded: { onImageLoaded(posts[index].id) }
                        ) {
                            onPostTapped(posts[index])
                        }
                        .frame(width: squareSize, height: squareSize)
                        .clipped()
                        .aspectRatio(1, contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color(white: 0.15))
                            .frame(width: squareSize, height: squareSize)
                    }
                }
            }
            
            // 下段3枚
            HStack(spacing: 1.5) {
                ForEach(3..<6, id: \.self) { index in
                    if index < posts.count {
                        GridImageView(
                            post: posts[index],
                            showContent: showContent,
                            onImageLoaded: { onImageLoaded(posts[index].id) }
                        ) {
                            onPostTapped(posts[index])
                        }
                        .frame(width: squareSize, height: squareSize)
                        .clipped()
                        .aspectRatio(1, contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color(white: 0.15))
                            .frame(width: squareSize, height: squareSize)
                    }
                }
            }
        }
        .frame(height: totalHeight)
    }
    
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    private var spacing: CGFloat {
        1.5
    }
    
    private var availableWidth: CGFloat {
        screenWidth // 画面全体の幅を使用
    }
    
    private var squareSize: CGFloat {
        // 3列のグリッドで、間に2つのspacing（各1.5）があるため
        (availableWidth - (spacing * 2)) / 3
    }
    
    private var totalHeight: CGFloat {
        squareSize * 2 + spacing // 2段 + 中間のスペーシング
    }
}

// MARK: - Grid Image View

struct GridImageView: View {
    let post: Post
    let showContent: Bool
    let onImageLoaded: (() -> Void)?
    let onTap: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    @State private var imageLoaded = false
    
    init(post: Post, showContent: Bool = true, onImageLoaded: (() -> Void)? = nil, onTap: (() -> Void)? = nil) {
        self.post = post
        self.showContent = showContent
        self.onImageLoaded = onImageLoaded
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            // Compressed image loading for grid performance (medium quality)
            Group {
                if showContent {
                    GridOptimizedImageView(imageURL: post.mediaUrl)
                        .onAppear {
                            if !imageLoaded {
                                imageLoaded = true
                                onImageLoaded?()
                            }
                        }
                } else {
                    // Content not ready to show - display skeleton
                    Rectangle()
                        .fill(Color(white: 0.15))
                        .overlay(
                            Rectangle()
                                .fill(Color(white: 0.2))
                                .opacity(0.5)
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Grid Optimized Image View
struct GridOptimizedImageView: View {
    let imageURL: String
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(white: 0.15))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    )
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // First check for cached compressed image
        let cacheKey = "\(imageURL)_compressed_grid" as NSString
        if let cachedImage = ImageCacheManager.shared.cache.object(forKey: cacheKey) {
            self.image = cachedImage
            isLoading = false
            return
        }
        
        // Load image directly
        if let loadedImage = await ImageCacheManager.shared.loadImage(from: imageURL) {
            // Compress for grid
            let gridImage = await Self.compressForGrid(loadedImage)
            
            // Cache it
            ImageCacheManager.shared.cache.setObject(gridImage, forKey: cacheKey)
            
            self.image = gridImage
        }
        isLoading = false
    }
    
    static func preloadImage(_ url: String) async {
        let cacheKey = "\(url)_compressed_grid" as NSString
        
        // Skip if already cached
        if ImageCacheManager.shared.cache.object(forKey: cacheKey) != nil {
            return
        }
        
        // Load and compress
        if let loadedImage = await ImageCacheManager.shared.loadImage(from: url) {
            let gridImage = await compressForGrid(loadedImage)
            ImageCacheManager.shared.cache.setObject(gridImage, forKey: cacheKey)
        }
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

struct HomeGridView_Previews: PreviewProvider {
    static var previews: some View {
        HomeGridView(
            showGridMode: .constant(false), 
            showingCreatePost: .constant(false),
            isInSingleView: .constant(false)
        )
    }
}