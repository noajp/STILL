//======================================================================
// MARK: - GridComponents.swift
// Purpose: Grid view components for displaying posts in various layouts
// Path: still/Features/MyPage/Components/GridComponents.swift
//======================================================================
import SwiftUI

// MARK: - Single Card Grid View
/**
 * Grid view with single card layout for posts
 * Supports drag and drop reordering
 */
struct SingleCardGridView: View {
    @State var posts: [Post]
    let onPostTapped: ((Post) -> Void)?
    let onDeletePost: ((Post) -> Void)?
    let onReorderPosts: (([Post]) -> Void)?
    let columns = [
        GridItem(.flexible(), spacing: 7),
        GridItem(.flexible(), spacing: 7),
        GridItem(.flexible(), spacing: 7)
    ]
    
    @State private var draggedItemId: String?
    @State private var isDragging: Bool = false
    
    init(posts: [Post], onPostTapped: ((Post) -> Void)? = nil, onDeletePost: ((Post) -> Void)? = nil, onReorderPosts: (([Post]) -> Void)? = nil) {
        self._posts = State(initialValue: posts)
        self.onPostTapped = onPostTapped
        self.onDeletePost = onDeletePost
        self.onReorderPosts = onReorderPosts
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(posts, id: \.id) { post in
                    ProfileSingleCardView(post: post, onTap: {
                        if !isDragging {
                            onPostTapped?(post)
                        }
                    })
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            onDeletePost?(post)
                        }
                    }
                    .onDrag {
                        print("🟢 onDrag triggered for post: \(post.id)")
                        draggedItemId = post.id
                        isDragging = true
                        
                        // ハプティックフィードバック
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        let provider = NSItemProvider(object: post.id as NSString)
                        return provider
                    }
                    .onDrop(of: [.text], delegate: LongPressDropDelegate(
                        item: post,
                        posts: $posts,
                        draggedItemId: $draggedItemId,
                        isDragging: $isDragging,
                        onReorderPosts: onReorderPosts
                    ))
                }
            }
        }
    }
}

// MARK: - Classic Grid View
/**
 * Classic grid layout for posts
 * Supports drag and drop reordering
 */
struct GridView: View {
    @State var posts: [Post]
    let onPostTapped: ((Post) -> Void)?
    let onDeletePost: ((Post) -> Void)?
    let onReorderPosts: (([Post]) -> Void)?
    let columns = [
        GridItem(.flexible(), spacing: 7),
        GridItem(.flexible(), spacing: 7),
        GridItem(.flexible(), spacing: 7)
    ]
    
    @State private var draggedItemId: String?
    @State private var isDragging: Bool = false
    
    init(posts: [Post], onPostTapped: ((Post) -> Void)? = nil, onDeletePost: ((Post) -> Void)? = nil, onReorderPosts: (([Post]) -> Void)? = nil) {
        self._posts = State(initialValue: posts)
        self.onPostTapped = onPostTapped
        self.onDeletePost = onDeletePost
        self.onReorderPosts = onReorderPosts
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(posts, id: \.id) { post in
                    GridItemView(post: post, onTap: {
                        if !isDragging {
                            onPostTapped?(post)
                        }
                    })
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            onDeletePost?(post)
                        }
                    }
                    .opacity(isDragging && draggedItemId == post.id ? 0.8 : 1.0)
                    .onDrag {
                        print("🟢 onDrag triggered for post: \(post.id)")
                        draggedItemId = post.id
                        isDragging = true
                        
                        // ハプティックフィードバック
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        let provider = NSItemProvider(object: post.id as NSString)
                        return provider
                    }
                    .onDrop(of: [.text], delegate: LongPressDropDelegate(
                        item: post,
                        posts: $posts,
                        draggedItemId: $draggedItemId,
                        isDragging: $isDragging,
                        onReorderPosts: onReorderPosts
                    ))
                }
            }
        }
    }
}

// MARK: - Drop Delegate
/**
 * Handles drag and drop operations for post reordering
 */
struct LongPressDropDelegate: DropDelegate {
    let item: Post
    @Binding var posts: [Post]
    @Binding var draggedItemId: String?
    @Binding var isDragging: Bool
    let onReorderPosts: (([Post]) -> Void)?
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        print("🔚 performDrop: Completing drag operation")
        
        // Reset dragging state without vibration
        draggedItemId = nil
        isDragging = false
        
        print("✅ performDrop: Drag state reset - isDragging: \(isDragging), draggedItemId: \(draggedItemId ?? "nil")")
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItemId = draggedItemId, isDragging else { 
            print("❌ dropEntered: No dragged item or not dragging")
            return 
        }
        
        print("🔄 dropEntered: Dragged \(draggedItemId) onto \(item.id)")
        
        if draggedItemId != item.id {
            guard let draggedPost = posts.first(where: { $0.id == draggedItemId }) else { return }
            let fromIndex = posts.firstIndex(of: draggedPost) ?? 0
            let toIndex = posts.firstIndex(of: item) ?? 0
            
            print("📍 Moving from index \(fromIndex) to \(toIndex)")
            
            if fromIndex != toIndex {
                withAnimation(.spring()) {
                    posts.move(fromOffsets: IndexSet([fromIndex]), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                    onReorderPosts?(posts)
                    print("✅ Posts reordered successfully")
                }
            }
        }
    }
}

// MARK: - Profile Single Card View
/**
 * Individual card view for a single post in the profile grid
 */
struct ProfileSingleCardView: View {
    let post: Post
    let onTap: (() -> Void)?
    
    init(post: Post, onTap: (() -> Void)? = nil) {
        self.post = post
        self.onTap = onTap
    }
    
    var body: some View {
        GeometryReader { geometry in
            // High-performance CompressedAsyncImage for faster loading
            CompressedAsyncImage(
                urlString: post.mediaUrl,
                quality: .medium
            ) {
                Rectangle()
                    .fill(MinimalDesign.Colors.tertiaryBackground)
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: MinimalDesign.Colors.secondary))
                    )
            }
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.width)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Grid Item View
/**
 * Individual grid item for posts in classic grid layout
 */
struct GridItemView: View {
    let post: Post
    let onTap: (() -> Void)?
    
    init(post: Post, onTap: (() -> Void)? = nil) {
        self.post = post
        self.onTap = onTap
    }
    
    var body: some View {
        GeometryReader { geometry in
            // High-performance CompressedAsyncImage for faster loading
            CompressedAsyncImage(
                urlString: post.mediaUrl,
                quality: .medium
            ) {
                Rectangle()
                    .fill(MinimalDesign.Colors.tertiaryBackground)
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: MinimalDesign.Colors.secondary))
                    )
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: geometry.size.width, height: geometry.size.width)
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Magazine View
/**
 * Magazine-style feed view for posts
 */
struct MagazineView: View {
    let posts: [Post]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: MinimalDesign.Spacing.lg) {
                ForEach(posts) { post in
                    MagazinePostCard(post: post)
                }
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
        }
    }
}

// MARK: - Magazine Post Card
/**
 * Individual card for magazine-style post display
 */
struct MagazinePostCard: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: MinimalDesign.Spacing.sm) {
            // Image
            AsyncImage(url: URL(string: post.mediaUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(MinimalDesign.Colors.tertiaryBackground)
            }
            .frame(height: 280)
            .clipped()
            .cornerRadius(MinimalDesign.Radius.md)
            
            // Caption
            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .font(MinimalDesign.Typography.body)
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .lineLimit(2)
            }
        }
    }
}