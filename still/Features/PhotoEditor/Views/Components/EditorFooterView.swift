//======================================================================
// MARK: - EditorFooterView.swift
// Purpose: SwiftUI view component (EditorFooterViewビューコンポーネント)
// Path: still/Features/PhotoEditor/Views/Components/EditorFooterView.swift
//======================================================================
//
//  EditorFooterView.swift
//  tete
//
//  写真編集画面のフッタービュー
//

import SwiftUI

struct EditorFooterView: View {
    // MARK: - Properties
    @Binding var selectedTab: EditorTab
    let onTabSelected: (EditorTab) -> Void
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 0) {
            ForEach(EditorTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                    onTabSelected(tab)
                }) {
                    VStack(spacing: 4) {
                        // アイコン
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                            .frame(height: 24)
                        .foregroundColor(selectedTab == tab ? .white : Color(white: 0.56))
                        
                        // タブ名（オプショナル - デザインに応じて表示/非表示）
                        /*
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .white : Color(white: 0.56))
                        */
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8) // Home Indicatorのためのパディング
        .background(
            Rectangle()
                .fill(Color(white: 0.23))
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Extended Editor Footer View (with labels)
struct ExtendedEditorFooterView: View {
    @Binding var selectedTab: EditorTab
    let onTabSelected: (EditorTab) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(EditorTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                        onTabSelected(tab)
                    }
                }) {
                    VStack(spacing: 4) {
                        // アイコン
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                            .frame(height: 24)
                        
                        // タブ名
                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : Color(white: 0.56))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .background(Color(red: 28/255, green: 28/255, blue: 30/255))
    }
}

// MARK: - Preview
#if DEBUG
struct EditorFooterView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EditorFooterView(
                selectedTab: .constant(.presets),
                onTabSelected: { _ in }
            )
            .background(Color.black)
            .previewDisplayName("Simple Footer")
            
            ExtendedEditorFooterView(
                selectedTab: .constant(.presets),
                onTabSelected: { _ in }
            )
            .background(Color.black)
            .previewDisplayName("Extended Footer")
        }
    }
}
#endif