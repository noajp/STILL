//======================================================================
// MARK: - MinimalDesignSystem.swift
// Purpose: Design system with colors, typography, and spacing (色、タイポグラフィ、スペーシングのデザインシステム)
// Path: still/Core/Design/MinimalDesignSystem.swift
//======================================================================
//
//  MinimalDesignSystem.swift
//  tete
//
//  シャープでミニマルなデザインシステム
//

import SwiftUI

// MARK: - Minimal Design System
struct MinimalDesign {
    
    // MARK: - Colors
    struct Colors {
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        
        static let primary = Color(.label)
        static let secondary = Color(.secondaryLabel)
        static let tertiary = Color(.tertiaryLabel)
        
        static let accent = Color(.systemBlue)
        static let accentRed = Color(red: 0.949, green: 0.098, blue: 0.020) // Custom TETE red #F21905
        static let destructive = Color(.systemRed)
        static let success = Color(.systemGreen)
        
        static let border = Color(.separator)
        static let divider = Color(.opaqueSeparator)
    }
    
    // MARK: - Typography
    struct Typography {
        static let title = Font.system(size: 24, weight: .bold, design: .default)
        static let headline = Font.system(size: 18, weight: .semibold, design: .default)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .medium, design: .default)
        static let small = Font.system(size: 10, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct Radius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let round: CGFloat = 50
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let sm = Shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        static let md = Shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        static let lg = Shadow(color: .black.opacity(0.15), radius: 16, y: 8)
        
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }
}

// MARK: - Custom View Modifiers
@MainActor
extension View {
    func minimalCard() -> some View {
        self
            .background(MinimalDesign.Colors.background)
            .cornerRadius(MinimalDesign.Radius.lg)
            .shadow(
                color: MinimalDesign.Shadow.sm.color,
                radius: MinimalDesign.Shadow.sm.radius,
                x: MinimalDesign.Shadow.sm.x,
                y: MinimalDesign.Shadow.sm.y
            )
    }
    
    func minimalCardBorder() -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: MinimalDesign.Radius.lg)
                    .stroke(MinimalDesign.Colors.border, lineWidth: 1)
            )
    }
    
    func minimalButton(style: MinimalButtonStyle = .primary) -> some View {
        self
            .font(MinimalDesign.Typography.body)
            .padding(.horizontal, MinimalDesign.Spacing.md)
            .padding(.vertical, MinimalDesign.Spacing.sm)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(MinimalDesign.Radius.md)
    }
}

// MARK: - Button Styles
enum MinimalButtonStyle {
    case primary
    case secondary
    case ghost
    case destructive
    
    var backgroundColor: Color {
        switch self {
        case .primary: return MinimalDesign.Colors.primary
        case .secondary: return MinimalDesign.Colors.secondaryBackground
        case .ghost: return Color.clear
        case .destructive: return MinimalDesign.Colors.destructive
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary: return Color(.systemBackground)
        case .secondary: return MinimalDesign.Colors.primary
        case .ghost: return MinimalDesign.Colors.primary
        case .destructive: return Color(.systemBackground)
        }
    }
}

// MARK: - Input Field Style
struct MinimalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(MinimalDesign.Typography.body)
            .padding(MinimalDesign.Spacing.md)
            .background(MinimalDesign.Colors.tertiaryBackground)
            .cornerRadius(MinimalDesign.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: MinimalDesign.Radius.md)
                    .stroke(MinimalDesign.Colors.border, lineWidth: 1)
            )
    }
}