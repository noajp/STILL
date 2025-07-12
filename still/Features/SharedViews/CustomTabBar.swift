//======================================================================
// MARK: - CustomTabBar.swift
// Purpose: Custom tab bar with dynamic icons and navigation (動的アイコンとナビゲーション機能付きカスタムタブバー)
// Path: still/Features/SharedViews/CustomTabBar.swift
//======================================================================
import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showGridMode: Bool
    let unreadMessageCount: Int
    let onCreatePost: () -> Void
    let isInSingleView: Bool
    let onBackToGrid: (() -> Void)?
    let onBackFromProfileSingleView: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            // フィードボタン（正方形）
            Button(action: {
                if isInSingleView {
                    // シングルビューからグリッドビューに戻る
                    onBackToGrid?()
                } else if selectedTab == 0 {
                    showGridMode.toggle()
                } else {
                    selectedTab = 0
                }
            }) {
                Group {
                    if isInSingleView {
                        // シングルビュー表示中は1つの大きな正方形（常に塗りつぶし）
                        Rectangle()
                            .fill(selectedTab == 0 ? Color(red: 0.949, green: 0.098, blue: 0.020) : (colorScheme == .dark ? .white : .black))
                            .frame(width: 20, height: 20)
                    } else if showGridMode && selectedTab == 0 {
                        // グリッドモード時は9つの小さな正方形（3x3）
                        VStack(spacing: 1.5) {
                            ForEach(0..<3) { _ in
                                HStack(spacing: 1.5) {
                                    ForEach(0..<3) { _ in
                                        if selectedTab == 0 {
                                            Rectangle()
                                                .fill(Color(red: 0.949, green: 0.098, blue: 0.020))
                                                .frame(width: 5.5, height: 5.5)
                                        } else {
                                            Rectangle()
                                                .stroke(colorScheme == .dark ? .white : .black, lineWidth: 0.8)
                                                .frame(width: 5.5, height: 5.5)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        // シングルモード時は1つの大きな正方形（選択時は塗りつぶし、非選択時は枠線のみ）
                        if selectedTab == 0 {
                            Rectangle()
                                .fill(Color(red: 0.949, green: 0.098, blue: 0.020))
                                .frame(width: 20, height: 20)
                        } else {
                            Rectangle()
                                .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // 雑誌ボタン
            Button(action: {
                selectedTab = 1
            }) {
                Image(systemName: selectedTab == 1 ? "book.fill" : "book")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(selectedTab == 1 ? Color(red: 0.949, green: 0.098, blue: 0.020) : (colorScheme == .dark ? .white : .black))
            }
            .frame(maxWidth: .infinity)
            
            // 投稿ボタン（中央）- 非表示にする
            /*
            Button(action: onCreatePost) {
                ZStack {
                    Circle()
                        .fill(MinimalDesign.Colors.accentRed)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            */
            
            // メッセージボタン
            Button(action: {
                selectedTab = 2
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: selectedTab == 2 ? "message.fill" : "message")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(selectedTab == 2 ? Color(red: 0.949, green: 0.098, blue: 0.020) : (colorScheme == .dark ? .white : .black))
                    
                    // 未読メッセージバッジ
                    if unreadMessageCount > 0 {
                        Circle()
                            .fill(Color(red: 0.949, green: 0.098, blue: 0.020))
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // アカウントボタン
            Button(action: {
                if selectedTab == 3 && onBackFromProfileSingleView != nil {
                    // プロフィールのシングルビューから戻る
                    onBackFromProfileSingleView?()
                } else {
                    selectedTab = 3
                }
            }) {
                Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(selectedTab == 3 ? Color(red: 0.949, green: 0.098, blue: 0.020) : (colorScheme == .dark ? .white : .black))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .padding(.bottom, 30) // タブバーを上に移動
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}