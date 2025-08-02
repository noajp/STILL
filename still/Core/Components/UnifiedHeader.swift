//======================================================================
// MARK: - UnifiedHeader.swift
// Purpose: Consistent header component with title, optional back button, and right action button supporting custom icons and dark mode (タイトル、オプションの戻るボタン、カスタムアイコンとダークモードに対応した右アクションボタンを持つ一貫したヘッダーコンポーネント)
// Path: still/Core/Components/UnifiedHeader.swift
//======================================================================
import SwiftUI

struct UnifiedHeader: View {
    let title: String
    let showBackButton: Bool
    let rightButton: HeaderButton?
    let extraRightButton: HeaderButton?
    let onBack: (() -> Void)?
    let isDarkMode: Bool
    
    init(
        title: String,
        showBackButton: Bool = false,
        rightButton: HeaderButton? = nil,
        extraRightButton: HeaderButton? = nil,
        onBack: (() -> Void)? = nil,
        isDarkMode: Bool = false
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.rightButton = rightButton
        self.extraRightButton = extraRightButton
        self.onBack = onBack
        self.isDarkMode = isDarkMode
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header content
            HStack(spacing: 0) {
                // Left button area (if back button is needed)
                if showBackButton {
                    Button(action: {
                        onBack?()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(isDarkMode ? .white : MinimalDesign.Colors.primary)
                    }
                    .frame(width: 30, height: 44)
                    .padding(.leading, 0)
                }
                
                // Title - 戻るボタンの右側または左端に配置
                Text(title)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(isDarkMode ? .white : MinimalDesign.Colors.primary)
                    .padding(.leading, showBackButton ? -8 : 8)
                
                Spacer()
                
                // Right buttons area
                HStack(spacing: 8) {
                    // Extra right button (bell icon)
                    if let extraRightButton = extraRightButton {
                        Button(action: {
                            extraRightButton.action()
                        }) {
                            Image(systemName: extraRightButton.icon)
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(isDarkMode ? .white : MinimalDesign.Colors.primary)
                        }
                        .frame(width: 44, height: 44)
                    }
                    
                    // Main right button (three lines)
                    if let rightButton = rightButton {
                        Button(action: {
                            rightButton.action()
                        }) {
                            if rightButton.icon == "custom.three.lines" {
                                // カスタム3本線
                                VStack(spacing: 5) {
                                    ForEach(0..<3) { _ in
                                        RoundedRectangle(cornerRadius: 0.5)
                                            .fill(isDarkMode ? Color.white : MinimalDesign.Colors.primary)
                                            .frame(width: 22, height: 1.5)
                                    }
                                }
                            } else {
                                Image(systemName: rightButton.icon)
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(isDarkMode ? .white : MinimalDesign.Colors.primary)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .padding(.trailing, 2)
                    }
                }
            }
            .padding(.horizontal, showBackButton ? MinimalDesign.Spacing.xs : MinimalDesign.Spacing.sm)
            .padding(.bottom, MinimalDesign.Spacing.xs)
            .padding(.top, 0) // Safe Areaを考慮した適切な位置
            .background(Color.clear)
        }
    }
}

struct HeaderButton {
    let icon: String
    let action: () -> Void
}

// Unified navigation wrapper
struct UnifiedNavigationView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationBarHidden(true)
        }
    }
}
