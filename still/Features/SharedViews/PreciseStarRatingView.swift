//======================================================================
// MARK: - PreciseStarRatingView（精密な星評価表示）
// Path: foodai/Features/SharedViews/PreciseStarRatingView.swift
//======================================================================
import SwiftUI

struct PreciseStarRatingView: View {
    let rating: Double
    let maxRating: Int = 5
    let size: CGFloat
    let filledColor: Color
    let emptyColor: Color
    
    init(rating: Double, size: CGFloat = 16, filledColor: Color = .yellow, emptyColor: Color = .gray.opacity(0.3)) {
        self.rating = rating
        self.size = size
        self.filledColor = filledColor
        self.emptyColor = emptyColor
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maxRating, id: \.self) { index in
                StarShape()
                    .fill(emptyColor)
                    .frame(width: size, height: size)
                    .overlay(
                        GeometryReader { geometry in
                            StarShape()
                                .fill(filledColor)
                                .frame(width: geometry.size.width * fillAmount(for: index))
                                .clipped()
                        }
                    )
            }
        }
    }
    
    private func fillAmount(for index: Int) -> Double {
        let starNumber = Double(index + 1)
        if rating >= starNumber {
            return 1.0
        } else if rating > Double(index) {
            return rating - Double(index)
        } else {
            return 0.0
        }
    }
}

// カスタム星形シェイプ
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let points = 5
        var path = Path()
        
        for i in 0..<points * 2 {
            let angle = (Double(i) * .pi / Double(points)) - (.pi / 2)
            let r = i % 2 == 0 ? radius : radius * 0.4
            let x = center.x + CGFloat(cos(angle)) * r
            let y = center.y + CGFloat(sin(angle)) * r
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// シンプルな評価表示（数値付き）
struct StarRatingBadge: View {
    let rating: Double
    let size: CGFloat
    
    init(rating: Double, size: CGFloat = 12) {
        self.rating = rating
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 4) {
            PreciseStarRatingView(rating: rating, size: size)
            Text(String(format: "%.1f", rating))
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

