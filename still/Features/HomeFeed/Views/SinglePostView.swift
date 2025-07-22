//======================================================================
// MARK: - SinglePostView.swift
// Purpose: SwiftUI view component (SinglePostViewビューコンポーネント)
// Path: still/Features/HomeFeed/Views/SinglePostView.swift
//======================================================================
import SwiftUI

@MainActor
struct SinglePostView: View {
    let initialPost: Post
    @StateObject private var viewModel: HomeFeedViewModel
    @Binding var showGridMode: Bool
    @State private var scrollToTop = false
    @State private var followingUserIds: Set<String> = []
    @State private var isLoadingFollowing = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    init(initialPost: Post, viewModel: HomeFeedViewModel, showGridMode: Binding<Bool>) {
        self.initialPost = initialPost
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._showGridMode = showGridMode
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Header space
                        Color.clear
                            .frame(height: 105) // Same as HomeFeedView header height
                            .frame(width: UIScreen.main.bounds.width)
                        
                        // 選択された投稿を最初に表示
                        PostCardView(post: initialPost) { post in
                            Task {
                                await viewModel.toggleLike(for: post)
                            }
                        }
                        .id(initialPost.id)
                        
                        // フォローしている人がいない場合のメッセージ
                        if followingUserIds.isEmpty && !isLoadingFollowing {
                            VStack(spacing: 20) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                
                                Text("まだ誰もフォローしていません")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("他のユーザーをフォローして\n投稿を見てみましょう")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 100)
                            .frame(maxWidth: .infinity)
                        } else if !isLoadingFollowing {
                            // フォローしている人の投稿のみを時系列順で表示
                            ForEach(filteredPosts) { post in
                                PostCardView(post: post) { post in
                                    Task {
                                        await viewModel.toggleLike(for: post)
                                    }
                                }
                            }
                        }
                        
                        // Bottom space for tab bar
                        Color.clear
                            .frame(height: 110)
                    }
                }
                .onAppear {
                    // シングルビューモードに切り替え
                    showGridMode = false
                    // フォローしているユーザーリストを取得
                    Task {
                        await loadFollowingUsers()
                    }
                }
                .onChange(of: scrollToTop) { _, newValue in
                    if newValue {
                        withAnimation {
                            proxy.scrollTo(initialPost.id, anchor: .top)
                        }
                        scrollToTop = false
                    }
                }
            }
            
            // Header without back button
            VStack(spacing: 0) {
                UnifiedHeader(
                    title: "STILL"
                )
            }
            .zIndex(1000)
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .ignoresSafeArea(.all, edges: .top)
    }
    
    // MARK: - Computed Properties
    
    private var filteredPosts: [Post] {
        let otherPosts = viewModel.posts.filter { $0.id != initialPost.id }
        
        // フォローしているユーザーの投稿のみフィルタリング
        let followingPosts = otherPosts.filter { post in
            guard let userId = post.user?.id else { return false }
            return followingUserIds.contains(userId)
        }
        
        // 時系列順（新しい順）でソート
        return followingPosts.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Private Methods
    
    private func loadFollowingUsers() async {
        guard let currentUserId = authManager.currentUser?.id else { return }
        
        isLoadingFollowing = true
        do {
            let following = try await FollowService.shared.fetchFollowing(userId: currentUserId)
            followingUserIds = Set(following.map { $0.id })
            print("📱 SinglePostView: Loaded \(followingUserIds.count) following users")
        } catch {
            print("❌ SinglePostView: Failed to load following users: \(error)")
        }
        isLoadingFollowing = false
    }
}