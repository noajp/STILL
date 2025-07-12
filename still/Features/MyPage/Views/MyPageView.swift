//======================================================================
// MARK: - MyPageView.swift
// Purpose: User profile page with photo grid, edit capabilities, and drag-and-drop reordering (ユーザープロフィールページ：写真グリッド、編集機能、ドラッグ＆ドロップ並び替え)
// Path: still/Features/MyPage/Views/MyPageView.swift
//======================================================================
import SwiftUI
import PhotosUI

@MainActor
struct MyPageView: View {
    @StateObject private var viewModel = MyPageViewModel()
    @EnvironmentObject var authManager: AuthManager
    @Binding var isInProfileSingleView: Bool
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPost: Post?
    @State private var navigateToSingleView: Bool = false
    
    var body: some View {
        ScrollableHeaderView(
            title: "Profile",
            rightButton: HeaderButton(
                icon: "gearshape",
                action: { showSettings = true }
            )
        ) {
            LazyVStack(spacing: MinimalDesign.Spacing.xl) {
                // Profile Section
                ModernProfileSection(
                    profile: viewModel.userProfile,
                    isLoading: viewModel.isLoading,
                    postsCount: viewModel.postsCount,
                    followersCount: viewModel.followersCount,
                    hasNewFollowers: viewModel.hasNewFollowers,
                    onEditProfile: { showEditProfile = true },
                    onFollowersTapped: { viewModel.markNewFollowersAsSeen() },
                    selectedPhotoItem: $selectedPhotoItem
                )
                
                
                // Posts Tab Section
                ModernPostsTabSection(
                    posts: viewModel.userPosts,
                    selectedPost: $selectedPost,
                    navigateToSingleView: $navigateToSingleView,
                    onDeletePost: { post in
                        Task {
                            await viewModel.deletePost(post)
                        }
                    },
                    onReorderPosts: { reorderedPosts in
                        Task {
                            await viewModel.reorderPosts(reorderedPosts)
                        }
                    }
                )
            }
            .padding(.vertical, MinimalDesign.Spacing.md)
            .padding(.bottom, 100) // タブバー分のスペース
        }
        .background(MinimalDesign.Colors.background)
        .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authManager)
            }
            .task {
                await viewModel.loadUserDataIfNeeded()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await viewModel.updateProfilePhoto(item: newItem)
                }
            }
            .navigationDestination(isPresented: $navigateToSingleView) {
                if let selectedPost = selectedPost {
                    ProfileSinglePostView(
                        initialPost: selectedPost,
                        allPosts: viewModel.userPosts
                    )
                    .onAppear {
                        isInProfileSingleView = true
                    }
                    .onDisappear {
                        isInProfileSingleView = false
                    }
                }
            }
            .onChange(of: isInProfileSingleView) { _, newValue in
                if !newValue && navigateToSingleView {
                    // プロフィールボタンが押されたら戻る
                    navigateToSingleView = false
                    selectedPost = nil
                }
            }
    }
}

// MARK: - Modern Profile Components

struct ModernProfileHeader: View {
    let onSettings: () -> Void
    
    var body: some View {
        HStack {
            Text("Profile")
                .font(MinimalDesign.Typography.title)
                .fontWeight(.light)
                .foregroundColor(MinimalDesign.Colors.primary)
            
            Spacer()
            
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(MinimalDesign.Colors.secondary)
            }
        }
        .padding(.horizontal, MinimalDesign.Spacing.md)
        .padding(.vertical, MinimalDesign.Spacing.sm)
    }
}

@MainActor
struct ModernProfileSection: View {
    let profile: UserProfile?
    let isLoading: Bool
    let postsCount: Int
    let followersCount: Int
    let hasNewFollowers: Bool
    let onEditProfile: () -> Void
    let onFollowersTapped: () -> Void
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @State private var showGridMode = false
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top, spacing: 16) {
                // Profile Image - Rounded Square (Left aligned)
                ProfileImagePicker(
                    profile: profile,
                    selectedPhotoItem: $selectedPhotoItem
                )
                .buttonStyle(PlainButtonStyle())
                
                // Profile Info
                VStack(alignment: .leading, spacing: 8) {
                    // Display Name (優先表示)
                    if let displayName = profile?.displayName, !displayName.isEmpty {
                        Text(displayName)
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .lineLimit(1)
                    } else if let username = profile?.username {
                        // Display Nameがない場合はユーザー名を表示
                        Text(username)
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .lineLimit(1)
                    }
                    
                    // Username (グレー表示)
                    if let username = profile?.username {
                        Text("@\(username)")
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundColor(MinimalDesign.Colors.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Edit Profile Button
                    Button(action: onEditProfile) {
                        Text("Edit Profile")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            
            // Stats Section (Posts, Followers, Following)
            HStack(spacing: 32) {
                StatItem(value: postsCount, label: "Posts")
                
                // Followers with notification dot
                Button(action: onFollowersTapped) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text("\(followersCount)")
                                .font(.system(size: 18, weight: .semibold, design: .default))
                                .foregroundColor(MinimalDesign.Colors.primary)
                            
                            if hasNewFollowers {
                                Circle()
                                    .fill(Color(red: 0.949, green: 0.098, blue: 0.020))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        
                        Text("Followers")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(MinimalDesign.Colors.tertiary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                StatItem(value: profile?.followingCount ?? 0, label: "Following")
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            
            // Bio Section
            if let bio = profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, MinimalDesign.Spacing.sm)
            }
            
        }
        .padding(.vertical, MinimalDesign.Spacing.lg)
        .background(MinimalDesign.Colors.background)
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(MinimalDesign.Colors.primary)
            
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundColor(MinimalDesign.Colors.tertiary)
        }
    }
}

struct ModernPostsTabSection: View {
    let posts: [Post]
    @Binding var selectedPost: Post?
    @Binding var navigateToSingleView: Bool
    let onDeletePost: ((Post) -> Void)?
    let onReorderPosts: (([Post]) -> Void)?
    @State private var selectedTab = 0
    @State private var showGridMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                ProfileTabButton(
                    selectedIcon: "square.grid.3x3.fill",
                    unselectedIcon: "square.grid.3x3",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                ProfileTabButton(
                    selectedIcon: "book.fill",
                    unselectedIcon: "book",
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            .padding(.vertical, 8)
            
            // Content
            Group {
                switch selectedTab {
                case 0:
                    if posts.isEmpty {
                        EmptyStateView(
                            icon: "camera",
                            title: "No Posts Yet",
                            message: "Share your first photo to get started"
                        )
                        .frame(height: 300)
                    } else {
                        if showGridMode {
                            GridView(posts: posts, onPostTapped: { post in
                                selectedPost = post
                                navigateToSingleView = true
                            }, onDeletePost: onDeletePost, onReorderPosts: onReorderPosts)
                                .transition(.opacity)
                        } else {
                            SingleCardGridView(posts: posts, onPostTapped: { post in
                                selectedPost = post
                                navigateToSingleView = true
                            }, onDeletePost: onDeletePost, onReorderPosts: onReorderPosts)
                                .transition(.opacity)
                        }
                    }
                case 1:
                    EmptyStateView(
                        icon: "book",
                        title: "No Articles",
                        message: "Your written articles will appear here"
                    )
                    .frame(height: 300)
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            
        }
    }
}

struct ProfileTabButton: View {
    let selectedIcon: String
    let unselectedIcon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isSelected ? selectedIcon : unselectedIcon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(isSelected ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.primary)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(MinimalDesign.Colors.tertiary)
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(MinimalDesign.Colors.primary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(MinimalDesign.Colors.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

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
                        // 長押しでドラッグ開始の準備
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
                        // 空のビューを返してドラッグプレビューを無効化
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
                // 高性能なOptimizedAsyncImageを使用
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

// Classic Grid View
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
                        // 長押しでドラッグ開始の準備
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
                        // 空のビューを返してドラッグプレビューを無効化
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
                // 高性能なOptimizedAsyncImageを使用
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

// Magazine-style Feed View
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

// MARK: - Profile Image Picker
@MainActor
struct ProfileImagePicker: View {
    let profile: UserProfile?
    @Binding var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            if let avatarUrl = profile?.avatarUrl {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}