//======================================================================
// MARK: - ScrollableHeader.swift
// Purpose: ScrollableHeader implementation (ScrollableHeaderの実装)
// Path: still/Core/Components/ScrollableHeader.swift
//======================================================================
import SwiftUI

// MARK: - Scrollable Header with Auto Hide/Show

struct ScrollableHeaderView<Content: View>: View {
    let title: String
    let showBackButton: Bool
    let rightButton: HeaderButton?
    let onBack: (() -> Void)?
    let content: Content
    
    @State private var headerOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    
    private let headerHeight: CGFloat = 105 // HomeFeedViewと統一
    
    init(
        title: String,
        showBackButton: Bool = false,
        rightButton: HeaderButton? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.rightButton = rightButton
        self.onBack = onBack
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main ScrollView
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header space
                    Color.clear
                        .frame(height: headerHeight - 50) // 補正分を考慮
                    
                    // Content
                    content
                }
                .background(
                    GeometryReader { geometry in
                        let offset = geometry.frame(in: .named("scrollView")).minY
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: offset)
                    }
                )
            }
            .coordinateSpace(name: "scrollView")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                handleScrollChange(offset: value)
            }
            
            // Floating Header
            UnifiedHeader(
                title: title,
                showBackButton: showBackButton,
                rightButton: rightButton,
                onBack: onBack
            )
            .offset(y: headerOffset - 50) // UnifiedHeaderのpadding-top(50pt)を完全に補正
            .animation(.easeInOut(duration: 0.5), value: headerOffset)
            .zIndex(1000)
        }
        .clipped()
        .background(MinimalDesign.Colors.background.ignoresSafeArea())
    }
    
    private func handleScrollChange(offset: CGFloat) {
        let currentOffset = offset
        
        // 一番上にいる場合（上端）
        if currentOffset >= 0 {
            if headerOffset != 0 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    headerOffset = 0
                }
            }
            lastScrollOffset = currentOffset
            return
        }
        
        // スクロール方向を判定
        let deltaY = currentOffset - lastScrollOffset
        
        // 小さなスクロールは無視
        guard abs(deltaY) > 10 else { return }
        
        if deltaY < 0 {
            // 下にスクロール（content上移動）→ ヘッダーを隠す
            if headerOffset != -headerHeight {
                withAnimation(.easeInOut(duration: 0.5)) {
                    headerOffset = -headerHeight
                }
            }
        } else {
            // 上にスクロール（content下移動）→ ヘッダーを表示
            if headerOffset != 0 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    headerOffset = 0
                }
            }
        }
        
        lastScrollOffset = currentOffset
    }
}

// MARK: - Preference Key for Scroll Offset

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}