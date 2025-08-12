//======================================================================
// MARK: - CustomTabBar.swift
// Purpose: Custom tab bar with dynamic icons and navigation (動的アイコンとナビゲーション機能付きカスタムタブバー)
// Path: still/Features/SharedViews/CustomTabBar.swift
//======================================================================
import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    let unreadMessageCount: Int
    let onCreatePost: () -> Void
    let isInSingleView: Bool
    let onBackToGrid: (() -> Void)?
    let onBackFromProfileSingleView: (() -> Void)?
    let onProfileDoubleTap: (() -> Void)?
    @Binding var isUserSearchMode: Bool
    let onMessageDoubleTap: (() -> Void)?
    let onTabReset: (() -> Void)?
    
    
    @Environment(\.colorScheme) var colorScheme
    
    // プロフィールアイコンの名前を計算
    private var profileIconName: String {
        return selectedTab == 3 ? "person.fill" : "person"
    }
    
    // メッセージアイコンの名前を計算
    private var messageIconName: String {
        return selectedTab == 2 ? "message.fill" : "message"
    }
    
    // ギャラリーアイコンの名前を計算
    private var galleryIconName: String {
        return selectedTab == 1 ? "square.grid.3x3.fill" : "square.grid.3x3"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // フィードボタン（正方形）
            VStack {
                Image(systemName: selectedTab == 0 ? "square.fill" : "square")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(selectedTab == 0 ? MinimalDesign.Colors.accentRed : .white)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                if isInSingleView {
                    onBackToGrid?()
                } else if selectedTab == 0 {
                    // Already on home tab - reset to initial state
                    onTabReset?()
                } else {
                    selectedTab = 0
                    onTabReset?()
                }
            }
            
            // ギャラリーボタン（グリッド）
            VStack {
                Image(systemName: galleryIconName)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(selectedTab == 1 ? MinimalDesign.Colors.accentRed : .white)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedTab == 1 {
                    // Already on gallery tab - reset to initial state
                    onTabReset?()
                } else {
                    selectedTab = 1
                    onTabReset?()
                }
            }
            

            
            // 投稿ボタン（中央）
            Button(action: onCreatePost) {
                ZStack {
                    Circle()
                        .fill(MinimalDesign.Colors.accentRed.opacity(0.8))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            
            // メッセージボタン
            VStack {
                ZStack(alignment: .topTrailing) {
                    // 固定フレームで位置を統一
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 24, height: 20)
                    
                    // 統合されたメッセージアイコン
                    Image(systemName: messageIconName)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(selectedTab == 2 ? MinimalDesign.Colors.accentRed : .white)
                        .frame(width: 20, height: 20, alignment: .center)
                    
                    // 未読メッセージバッジ
                    if unreadMessageCount > 0 {
                        Circle()
                            .fill(MinimalDesign.Colors.accentRed)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedTab == 2 {
                    // Already on messages tab - reset to initial state
                    onTabReset?()
                } else {
                    selectedTab = 2
                    onTabReset?()
                }
            }
            
            // アカウントボタン（シングルタップで検索モード切り替え）
            VStack {
                Image(systemName: profileIconName)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(selectedTab == 3 ? MinimalDesign.Colors.accentRed : .white)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedTab == 3 {
                    // Already on profile tab - reset to initial state
                    onTabReset?()
                } else {
                    selectedTab = 3
                    onTabReset?()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .padding(.bottom, 30) // タブバーを上に移動
        .background(MinimalDesign.Colors.background)
    }
}