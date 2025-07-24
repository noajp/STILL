//======================================================================
// MARK: - UnifiedScreenHeader.swift
// Purpose: Unified header component that scrolls naturally with content (コンテンツと自然にスクロールする統一ヘッダーコンポーネント)
// Path: still/Core/Components/UnifiedScreenHeader.swift
//======================================================================
import SwiftUI

struct UnifiedScreenView<Content: View>: View {
    let title: String
    let showBackButton: Bool
    let rightButton: HeaderButton?
    let onBack: (() -> Void)?
    let onRefresh: (() async -> Void)?
    let content: Content
    
    init(
        title: String,
        showBackButton: Bool = false,
        rightButton: HeaderButton? = nil,
        onBack: (() -> Void)? = nil,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.rightButton = rightButton
        self.onBack = onBack
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header - 画面の一部として実装
                headerView
                
                // Content
                content
            }
        }
        .refreshable {
            if let onRefresh = onRefresh {
                await onRefresh()
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(MinimalDesign.Colors.background)
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 0) {
            // Status bar space - 少し下に
            Color.clear
                .frame(height: max(UIApplication.shared.statusBarFrame.height - 10, 25))
            
            // Header content
            HStack(spacing: 0) {
                // Back button (if needed)
                if showBackButton {
                    Button(action: {
                        onBack?()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(MinimalDesign.Colors.primary)
                    }
                    .frame(width: 44, height: 44)
                    .padding(.leading, 8)
                }
                
                // Title - 左端に配置
                Text(title)
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .padding(.leading, showBackButton ? 0 : 16)
                
                Spacer()
                
                // Right button area
                if let rightButton = rightButton {
                    Button(action: {
                        rightButton.action()
                    }) {
                        if rightButton.icon == "custom.three.lines" {
                            // カスタム3本線
                            VStack(spacing: 5) {
                                ForEach(0..<3) { _ in
                                    RoundedRectangle(cornerRadius: 0.5)
                                        .fill(MinimalDesign.Colors.primary)
                                        .frame(width: 22, height: 1.5)
                                }
                            }
                        } else {
                            Image(systemName: rightButton.icon)
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(MinimalDesign.Colors.primary)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .padding(.trailing, 16)
                }
            }
            .padding(.vertical, 8)
            .background(MinimalDesign.Colors.background)
        }
    }
}

// Extension for status bar height
extension UIApplication {
    var statusBarFrame: CGRect {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let statusBarManager = windowScene.statusBarManager else {
            return .zero
        }
        return statusBarManager.statusBarFrame
    }
}