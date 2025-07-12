//======================================================================
// MARK: - MainTabView.swift（5タブ版 - 中央に投稿ボタン）
// Path: foodai/Features/SharedViews/MainTabView.swift
//======================================================================
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingCreatePost = false
    @State private var showGridMode = false
    @State private var pageSelection = 1  // 0: Camera, 1: Feed
    @State private var isInSingleView = false
    @State private var isInProfileSingleView = false
    @State private var tabBarOffset: CGFloat = 0
    @State private var headerOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // TabViewでカメラとフィードをスワイプで切り替え
            TabView(selection: $pageSelection) {
                // カメラビュー
                CameraView()
                    .tag(0)
                    .ignoresSafeArea()
                
                // メインコンテンツ - 横スワイプで画面遷移
                // ホーム → アーティクル → メッセージ → プロフィール
                TabView(selection: $selectedTab) {
                    // ホームフィード (0)
                    UnifiedNavigationView {
                        HomeFeedView(
                            showGridMode: $showGridMode, 
                            showingCreatePost: $showingCreatePost,
                            isInSingleView: $isInSingleView,
                            headerOffset: $headerOffset,
                            onBackToGrid: {
                                // シングルビューからグリッドビューに戻る
                                if isInSingleView {
                                    isInSingleView = false
                                    showGridMode = true
                                }
                            },
                            onScrollChanged: { scrollOffset in
                                updateUIForScroll(scrollOffset: scrollOffset)
                            }
                        )
                    }
                    .tag(0)
                    
                    // アーティクル (1)
                    UnifiedNavigationView {
                        ArticleListView()
                    }
                    .tag(1)
                    
                    // メッセージ (2) - タブの順序用に2に変更
                    UnifiedNavigationView {
                        MessagesView()
                    }
                    .tag(2)
                    
                    // プロフィール (3) - タブの順序用に3に変更
                    UnifiedNavigationView {
                        MyPageView(isInProfileSingleView: $isInProfileSingleView)
                    }
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Color.clear)
                .ignoresSafeArea(.all)
                .tag(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Status bar moved to HomeFeedView
            
            // カメラビューの時はタブバーを非表示
            if pageSelection == 1 {
                // カスタムタブバー（フッター）
                VStack {
                    Spacer()
                    CustomTabBar(
                        selectedTab: $selectedTab,
                        showGridMode: $showGridMode,
                        unreadMessageCount: 0,
                        onCreatePost: {
                            showingCreatePost = true
                        },
                        isInSingleView: isInSingleView,
                        onBackToGrid: {
                            // シングルビューからグリッドビューに戻る
                            if isInSingleView {
                                isInSingleView = false
                                showGridMode = true
                            }
                        },
                        onBackFromProfileSingleView: {
                            // プロフィールのシングルビューから戻る
                            if isInProfileSingleView {
                                isInProfileSingleView = false
                            }
                        }
                    )
                }
                .offset(y: tabBarOffset)
                .animation(.easeInOut(duration: 0.5), value: tabBarOffset)
                .clipped() // 背景も含めて完全に隠すためにクリッピング
            }
        }
        .background(Color.clear)
        .ignoresSafeArea(.all)
        .accentColor(MinimalDesign.Colors.accentRed)
        .fullScreenCover(isPresented: $showingCreatePost) {
            CreatePostNavigationView()
                .transition(.move(edge: .bottom))
        }
    }
    
    private func updateUIForScroll(scrollOffset: CGFloat) {
        let deltaY = lastScrollOffset - scrollOffset
        lastScrollOffset = scrollOffset
        
        // タブバーの実際の高さ（アイコン20pt + 縦パディング16pt + セーフエリア考慮）
        let tabBarHeight: CGFloat = 120 // 背景も含めて完全に隠すためにさらに大きく
        
        // 上にスクロールした場合（わずかでも上方向）
        if deltaY < -0.5 {
            // 上スクロール: タブバーを表示
            if tabBarOffset != 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    tabBarOffset = 0
                }
            }
        }
        // 下にスクロールした場合
        else if deltaY > 3 {
            // 下にスクロール: タブバーを隠す
            if tabBarOffset != tabBarHeight {
                withAnimation(.easeInOut(duration: 0.5)) {
                    tabBarOffset = tabBarHeight
                }
            }
        }
        // 上端付近にいる場合は常に表示
        else if scrollOffset > -50 {
            if tabBarOffset != 0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    tabBarOffset = 0
                }
            }
        }
    }
}
