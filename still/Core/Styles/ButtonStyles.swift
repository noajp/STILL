//======================================================================
// MARK: - ButtonStyles.swift
// Purpose: ButtonStyles implementation (ButtonStylesの実装)
// Path: still/Core/Styles/ButtonStyles.swift
//======================================================================
import SwiftUI

// MARK: - Unified Text Button Styles

extension View {
    /// Applies accent red color to action text buttons (Cancel, Done, Save, etc.)
    func actionTextButtonStyle() -> some View {
        self
            .foregroundColor(MinimalDesign.Colors.accentRed)
            .font(.system(size: 17, weight: .regular))
    }
    
    /// Applies destructive red style for dangerous actions
    func destructiveTextButtonStyle() -> some View {
        self
            .foregroundColor(.red)
            .font(.system(size: 17, weight: .regular))
    }
}

// MARK: - Custom Button Style for Consistent Tap Effects

struct ActionTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? MinimalDesign.Colors.accentRed.opacity(0.6) : MinimalDesign.Colors.accentRed)
            .font(.system(size: 17, weight: .regular))
    }
}

struct DestructiveTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.red.opacity(0.6) : .red)
            .font(.system(size: 17, weight: .regular))
    }
}

// MARK: - Convenience Button Creators

/// Creates a standard action text button (red colored)
func ActionTextButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button(title, action: action)
        .buttonStyle(ActionTextButtonStyle())
}

/// Creates a destructive text button
func DestructiveTextButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button(title, action: action)
        .buttonStyle(DestructiveTextButtonStyle())
}