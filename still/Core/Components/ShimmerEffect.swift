//======================================================================
// MARK: - ShimmerEffect.swift
// Purpose: Shimmer loading effect for placeholders (プレースホルダー用のシマーローディングエフェクト)
// Path: still/Core/Components/ShimmerEffect.swift
//======================================================================

import SwiftUI

// MARK: - Shimmer View Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let bounce: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.03),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                    .animation(
                        Animation.linear(duration: duration)
                            .repeatForever(autoreverses: bounce),
                        value: phase
                    )
                }
                .clipped()
            )
            .onAppear {
                phase = 1
            }
    }
}

// MARK: - View Extension
extension View {
    /// Adds a shimmer effect to the view
    /// - Parameters:
    ///   - duration: Duration of one complete shimmer animation (default: 1.5 seconds)
    ///   - bounce: Whether the shimmer should reverse direction (default: false)
    func shimmerEffect(duration: Double = 1.5, bounce: Bool = false) -> some View {
        self.modifier(ShimmerModifier(duration: duration, bounce: bounce))
    }
}

// MARK: - Shimmer Placeholder View
struct ShimmerPlaceholder: View {
    let width: CGFloat?
    let height: CGFloat?
    let cornerRadius: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat = 0) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(hex: "1A1A1A"))
            .frame(width: width, height: height)
            .shimmerEffect()
    }
}

// MARK: - Image Shimmer Placeholder
struct ImageShimmerPlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(Color(hex: "1A1A1A"))
            .shimmerEffect()
    }
}

// MARK: - Preview
struct ShimmerEffect_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Image placeholder
            ImageShimmerPlaceholder()
                .frame(width: 300, height: 300)
            
            // Text placeholders
            VStack(alignment: .leading, spacing: 8) {
                ShimmerPlaceholder(width: 150, height: 20, cornerRadius: 4)
                ShimmerPlaceholder(width: 100, height: 16, cornerRadius: 4)
                ShimmerPlaceholder(width: 200, height: 14, cornerRadius: 4)
            }
        }
        .padding()
        .background(Color(hex: "121212"))
    }
}