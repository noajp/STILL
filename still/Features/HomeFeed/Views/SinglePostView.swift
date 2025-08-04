//======================================================================
// MARK: - SinglePostView.swift
// Purpose: Individual post display view with media rendering, user interactions, aspect ratio handling, and action button integration (メディアレンダリング、ユーザーインタラクション、アスペクト比処理、アクションボタン統合を持つ個別投稿表示ビュー)
// Path: still/Features/HomeFeed/Views/SinglePostView.swift
//======================================================================
import SwiftUI

@MainActor
struct SinglePostView: View {
    let initialPost: Post
    @StateObject private var viewModel: HomeFeedViewModel
    @Binding var showGridMode: Bool
    @State private var scrollToTop = false
    @Environment(\.dismiss) private var dismiss
    
    init(initialPost: Post, viewModel: HomeFeedViewModel, showGridMode: Binding<Bool>) {
        self.initialPost = initialPost
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._showGridMode = showGridMode
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // Header space
                        Color.clear
                            .frame(height: 105) // Same as HomeGridView header height
                            .frame(width: UIScreen.main.bounds.width)
                        
                        // 選択された投稿を最初に表示
                        PostCardView(post: initialPost) { post in
                            Task {
                                await viewModel.toggleLike(for: post)
                            }
                        }
                        .id(initialPost.id)
                        
                        // 全ユーザーの投稿を時系列順で表示（初期投稿以外）
                        ForEach(allPostsExceptInitial) { post in
                            PostCardView(post: post) { post in
                                Task {
                                    await viewModel.toggleLike(for: post)
                                }
                            }
                        }
                        
                        // Bottom space for tab bar
                        Color.clear
                            .frame(height: 110)
                    }
                }
                .onAppear {
                    // グリッドから遷移した場合でもグリッドモードのままにする
                    // showGridMode = false を削除
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
        .background(Color(hex: "121212"))
        .navigationBarHidden(true)
        .ignoresSafeArea(.all, edges: .top)
    }
    
    // MARK: - Computed Properties
    
    private var allPostsExceptInitial: [Post] {
        // 初期投稿以外の全ての投稿を時系列順（新しい順）で返す
        return viewModel.posts
            .filter { $0.id != initialPost.id }
            .sorted { $0.createdAt > $1.createdAt }
    }
}