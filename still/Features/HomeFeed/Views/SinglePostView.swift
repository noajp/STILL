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
    
    init(initialPost: Post, viewModel: HomeFeedViewModel, showGridMode: Binding<Bool>) {
        self.initialPost = initialPost
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._showGridMode = showGridMode
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 選択された投稿を最初に表示
                    SingleCardView(post: initialPost) { post in
                        Task {
                            await viewModel.toggleLike(for: post)
                        }
                    }
                    .id(initialPost.id)
                    
                    // それ以外の投稿を下に表示
                    ForEach(viewModel.posts.filter { $0.id != initialPost.id }) { post in
                        SingleCardView(post: post) { post in
                            Task {
                                await viewModel.toggleLike(for: post)
                            }
                        }
                    }
                }
            }
            .onAppear {
                // シングルビューモードに切り替え
                showGridMode = false
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
        .navigationBarHidden(true)
    }
}