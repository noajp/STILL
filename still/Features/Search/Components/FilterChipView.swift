//======================================================================
// MARK: - FilterChipView.swift (検索フィルターチップ)
// Path: foodai/Features/Search/Components/FilterChipView.swift
//======================================================================

import SwiftUICore
import SwiftUI
struct FilterChipView: View {
    let title: String
    let action: () -> Void
    @State private var isSelected = false
    
    // 明示的にpublicな初期化子を定義
    init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
            action()
        }) {
            Text(title)
                .font(AppEnvironment.Fonts.primary(size: 14, weight: .medium))
                .foregroundColor(isSelected ? MinimalDesign.Colors.background : MinimalDesign.Colors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? MinimalDesign.Colors.accentRed : MinimalDesign.Colors.secondaryBackground)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

