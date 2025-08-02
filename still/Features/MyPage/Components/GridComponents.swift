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
        GridItem(.flexible(), spacing: 1.5),
        GridItem(.flexible(), spacing: 1.5),
        GridItem(.flexible(), spacing: 1.5)
    ]
    
    @State private var draggedItem: Post?
    @State private var isDragging: Bool = false
    
    init(posts: [Post], onPostTapped: ((Post) -> Void)? = nil, onDeletePost: ((Post) -> Void)? = nil, onReorderPosts: (([Post]) -> Void)? = nil) {
        self._posts = State(initialValue: posts)
        self.onPostTapped = onPostTapped
        self.onDeletePost = onDeletePost
        self.onReorderPosts = onReorderPosts
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 1.5) {
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
                    .onLongPressGesture(minimumDuration: 0.5) {
                        // Long press to initiate drag
                        withAnimation(.spring(response: 0.3)) {
                            isDragging = true
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if isDragging {
                                    draggedItem = post
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3)) {
                                    isDragging = false
                                    draggedItem = nil
                                }
                            }
                    )
                    .onDrag {
                        draggedItem = post
                        isDragging = true
                        let provider = NSItemProvider()
                        provider.suggestedName = post.id
                        return provider
                    }
                    .draggable(post) {
                        // Return empty view to disable drag preview
                        Color.clear
                            .frame(width: 1, height: 1)
                    }
                    .onDrop(of: [.text], delegate: LongPressDropDelegate(
                        item: post,
                        posts: $posts,
                        draggedItem: $draggedItem,
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
        GridItem(.flexible(), spacing: 1.5),
        GridItem(.flexible(), spacing: 1.5),
        GridItem(.flexible(), spacing: 1.5)
    ]
    
    @State private var draggedItem: Post?
    @State private var isDragging: Bool = false
    
    init(posts: [Post], onPostTapped: ((Post) -> Void)? = nil, onDeletePost: ((Post) -> Void)? = nil, onReorderPosts: (([Post]) -> Void)? = nil) {
        self._posts = State(initialValue: posts)
        self.onPostTapped = onPostTapped
        self.onDeletePost = onDeletePost
        self.onReorderPosts = onReorderPosts
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 1.5) {
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
                    .onLongPressGesture(minimumDuration: 0.5) {
                        // Long press to initiate drag
                        withAnimation(.spring(response: 0.3)) {
                            isDragging = true
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if isDragging {
                                    draggedItem = post
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3)) {
                                    isDragging = false
                                    draggedItem = nil
                                }
                            }
                    )
                    .onDrag {
                        draggedItem = post
                        isDragging = true
                        let provider = NSItemProvider()
                        provider.suggestedName = post.id
                        return provider
                    }
                    .draggable(post) {
                        // Return empty view to disable drag preview
                        Color.clear
                            .frame(width: 1, height: 1)
                    }
                    .onDrop(of: [.text], delegate: LongPressDropDelegate(
                        item: post,
                        posts: $posts,
                        draggedItem: $draggedItem,
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
    @Binding var draggedItem: Post?
    @Binding var isDragging: Bool
    let onReorderPosts: (([Post]) -> Void)?
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        withAnimation(.spring(response: 0.3)) {
            draggedItem = nil
            isDragging = false
        }
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem, isDragging else { return }
        
        if draggedItem.id != item.id {
            let fromIndex = posts.firstIndex(of: draggedItem) ?? 0
            let toIndex = posts.firstIndex(of: item) ?? 0
            
            if fromIndex != toIndex {
                withAnimation(.spring()) {
                    posts.move(fromOffsets: IndexSet([fromIndex]), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                    onReorderPosts?(posts)
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
        Button(action: {
            onTap?()
        }) {
            GeometryReader { geometry in
                // High-performance OptimizedAsyncImage
                OptimizedAsyncImage(urlString: post.mediaUrl) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(MinimalDesign.Colors.tertiaryBackground)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: MinimalDesign.Colors.secondary))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .clipped()
                    case .failure(_):
                        Rectangle()
                            .fill(MinimalDesign.Colors.tertiaryBackground)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(MinimalDesign.Colors.secondary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
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
        Button(action: {
            onTap?()
        }) {
            GeometryReader { geometry in
                // High-performance OptimizedAsyncImage
                OptimizedAsyncImage(urlString: post.mediaUrl) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(MinimalDesign.Colors.tertiaryBackground)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: MinimalDesign.Colors.secondary))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .clipped()
                    case .failure(_):
                        Rectangle()
                            .fill(MinimalDesign.Colors.tertiaryBackground)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(MinimalDesign.Colors.secondary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
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
                    .frame(height: 280)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(MinimalDesign.Colors.tertiaryBackground)
                    .frame(height: 280)
            }
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