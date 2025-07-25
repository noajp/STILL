//======================================================================
// MARK: - MainTabView.swift
// Purpose: Main tab navigation controller with custom tab bar, tab switching, and root view management (カスタムタブバー、タブ切り替え、ルートビュー管理を持つメインタブナビゲーションコントローラー)
// Path: still/Features/SharedViews/MainTabView.swift
//======================================================================
import SwiftUI
import PhotosUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingCreatePost = false
    @State private var showingPhotoEditor = false
    @State private var editorData: PhotoEditorData?
    @State private var showGridMode = true
    @State private var pageSelection = 1  // 0: Camera, 1: Feed
    @State private var isInSingleView = false
    @State private var isInProfileSingleView = false
    @State private var tabBarOffset: CGFloat = 0
    @State private var headerOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var isUserSearchMode = false
    @State private var isGroupChatMode = false
    
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
                    HomeGridView(
                        showGridMode: $showGridMode, 
                        showingCreatePost: $showingCreatePost,
                        isInSingleView: $isInSingleView
                    )
                    .tag(0)
                    
                    // アーティクル (1)
                    NavigationStack {
                        ArticleListView()
                    }
                    .tag(1)
                    
                    // メッセージ (2) - タブの順序用に2に変更
                    NavigationStack {
                        MessagesView(isGroupChatMode: $isGroupChatMode)
                    }
                    .tag(2)
                    
                    // プロフィール (3) - タブの順序用に3に変更
                    MyPageView(
                        isInProfileSingleView: $isInProfileSingleView,
                        isUserSearchMode: $isUserSearchMode
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Color(.systemBackground))
                .ignoresSafeArea(.all)
                .tag(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Status bar moved to HomeGridView
            
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
                        },
                        onProfileDoubleTap: {
                            // プロフィールボタンのタップでユーザー検索モードを切り替え
                            isUserSearchMode.toggle()
                        },
                        isUserSearchMode: $isUserSearchMode,
                        onMessageDoubleTap: {
                            // メッセージボタンのタップでグループチャットモードを切り替え
                            isGroupChatMode.toggle()
                        },
                        isGroupChatMode: $isGroupChatMode
                    )
                }
                .offset(y: tabBarOffset)
                .animation(.easeInOut(duration: 0.5), value: tabBarOffset)
                .clipped() // 背景も含めて完全に隠すためにクリッピング
            }
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.all)
        .accentColor(MinimalDesign.Colors.accentRed)
        .fullScreenCover(isPresented: $showingCreatePost) {
            NavigationStack {
                PhotoPickerView { editorData in
                    print("🟢 MainTabViewで画像受信")
                    self.editorData = editorData
                    self.showingCreatePost = false
                    self.showingPhotoEditor = true
                }
            }
            .transition(.move(edge: .bottom))
        }
        .fullScreenCover(isPresented: $showingPhotoEditor) {
            if let editorData = editorData {
                NavigationStack {
                    ModernPhotoEditorView(
                        editorData: editorData,
                        onComplete: { editedImage in
                            print("🟢 編集完了")
                            showingPhotoEditor = false
                            self.editorData = nil
                        },
                        onCancel: {
                            print("🟢 編集キャンセル")
                            showingPhotoEditor = false
                            self.editorData = nil
                        }
                    )
                }
            }
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
