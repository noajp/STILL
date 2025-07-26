//======================================================================
// MARK: - ScrollableHeader.swift
// Purpose: Auto-hiding scrollable header component with scroll offset tracking and animated show/hide transitions (スクロールオフセット追跡とアニメーション付き表示/非表示遷移を持つ自動隠れるスクロール可能ヘッダーコンポーネント)
// Path: still/Core/Components/ScrollableHeader.swift
//======================================================================
import SwiftUI

// MARK: - Scrollable Header with Auto Hide/Show

struct ScrollableHeaderView<Content: View>: View {
    let title: String
    let showBackButton: Bool
    let rightButton: HeaderButton?
    let extraRightButton: HeaderButton?
    let onBack: (() -> Void)?
    let content: Content
    
    init(
        title: String,
        showBackButton: Bool = false,
        rightButton: HeaderButton? = nil,
        extraRightButton: HeaderButton? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.rightButton = rightButton
        self.extraRightButton = extraRightButton
        self.onBack = onBack
        self.content = content()
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // ヘッダーをコンテンツの一部として配置
                UnifiedHeader(
                    title: title,
                    showBackButton: showBackButton,
                    rightButton: rightButton,
                    extraRightButton: extraRightButton,
                    onBack: onBack
                )
                
                // コンテンツ
                content
            }
        }
        .background(MinimalDesign.Colors.background.ignoresSafeArea())
    }
}