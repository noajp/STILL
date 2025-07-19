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
    let onProfileDoubleTap: (() -> Void)?
    @Binding var isUserSearchMode: Bool
    let onMessageDoubleTap: (() -> Void)?
    @Binding var isGroupChatMode: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    // プロフィールアイコンの名前を計算
    private var profileIconName: String {
        if selectedTab == 3 {
            return isUserSearchMode ? "person.2.fill" : "person.fill"
        } else {
            return isUserSearchMode ? "person.2" : "person"
        }
    }
    
    // メッセージアイコンの名前を計算（グループチャット用は独自デザイン）
    private var messageIconName: String {
        if isGroupChatMode {
            return "" // グループチャット時は独自デザイン
        } else {
            return selectedTab == 2 ? "message.fill" : "message"
        }
    }
    
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
                    if showGridMode && selectedTab == 0 {
                        // グリッドモード時
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(Color(red: 0.949, green: 0.098, blue: 0.020))
                    } else if selectedTab == 0 {
                        // シングルモード時（選択中）
                        Image(systemName: "square.fill")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(Color(red: 0.949, green: 0.098, blue: 0.020))
                    } else {
                        // 非選択時
                        Image(systemName: showGridMode ? "square.grid.3x3" : "square")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
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
            VStack {
                ZStack(alignment: .topTrailing) {
                    // 固定フレームで位置を統一
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 24, height: 20)
                    
                    Group {
                        if isGroupChatMode {
                            // グループチャット: 2つのメッセージボタンが向かい合う
                            HStack(alignment: .center, spacing: 4) {
                                // 左側のメッセージ（右向き、水平反転、小さい）
                                Image(systemName: selectedTab == 2 ? "message.fill" : "message")
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundColor(selectedTab == 2 ? Color(red: 0.949, green: 0.098, blue: 0.020) : (colorScheme == .dark ? .white : .black))
                                    .scaleEffect(x: -1, y: 1) // 水平反転で右向きに
                                    .frame(width: 12, height: 20, alignment: .center) // 固定フレーム
                                
                                // 右側のメッセージ（左向き、通常、大きい）
                                Image(systemName: selectedTab == 2 ? "message.fill" : "message")
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundColor(selectedTab == 2 ? Color(red: 0.949, green: 0.098, blue: 0.020) : (colorScheme == .dark ? .white : .black))
                                    .frame(width: 18, height: 20, alignment: .center) // 固定フレーム
                            }
                        } else {
                            // 個人メッセージ: 通常のメッセージアイコン
                            Image(systemName: messageIconName)
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(selectedTab == 2 ? Color(red: 0.949, green: 0.098, blue: 0.020) : (colorScheme == .dark ? .white : .black))
                                .frame(width: 20, height: 20, alignment: .center) // 固定フレーム
                        }
                    }
                    
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
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedTab == 2 {
                    // 既にメッセージタブが選択されている場合はグループチャットモードを切り替え
                    onMessageDoubleTap?()
                } else {
                    // メッセージタブに切り替え
                    selectedTab = 2
                }
            }
            
            // アカウントボタン（シングルタップで検索モード切り替え）
            VStack {
                Image(systemName: profileIconName)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(selectedTab == 3 ? Color(red: 0.949, green: 0.098, blue: 0.020) : (colorScheme == .dark ? .white : .black))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedTab == 3 {
                    // 既にプロフィールタブが選択されている場合は検索モードを切り替え
                    onProfileDoubleTap?()
                } else {
                    // プロフィールタブに切り替え
                    selectedTab = 3
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .padding(.bottom, 30) // タブバーを上に移動
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}