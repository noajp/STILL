//======================================================================
// MARK: - AngleAdjustmentView.swift
// Purpose: Angle and rotation adjustment controls (角度調整コントロール)
// Path: still/Features/PhotoEditor/Views/Components/AngleAdjustmentView.swift
//======================================================================

import SwiftUI

struct AngleAdjustmentView: View {
    // MARK: - Properties
    @State private var rotationAngle: Double = 0.0
    @State private var straightenAngle: Double = 0.0
    @State private var flipHorizontal: Bool = false
    @State private var flipVertical: Bool = false
    
    let onAngleChanged: (Double, Double, Bool, Bool) -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 8) {
            // Header with reset button
            HStack {
                Text("Angle & Rotation")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                
                // Reset button as icon
                Button(action: {
                    rotationAngle = 0.0
                    straightenAngle = 0.0
                    flipHorizontal = false
                    flipVertical = false
                    onAngleChanged(rotationAngle, straightenAngle, flipHorizontal, flipVertical)
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Compact angle controls
            VStack(spacing: 4) {
                // Rotation control
                HStack {
                    Text("Rotate")
                        .font(.system(size: 10))
                        .foregroundColor(Color(white: 0.8))
                        .frame(width: 40, alignment: .leading)
                    
                    Slider(
                        value: $rotationAngle,
                        in: -180...180,
                        step: 1
                    ) { _ in
                        onAngleChanged(rotationAngle, straightenAngle, flipHorizontal, flipVertical)
                    }
                    .accentColor(MinimalDesign.Colors.accentRed)
                    
                    Text("\(Int(rotationAngle))°")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                        .frame(width: 32)
                }
                
                // Straighten control
                HStack {
                    Text("Fine")
                        .font(.system(size: 10))
                        .foregroundColor(Color(white: 0.8))
                        .frame(width: 40, alignment: .leading)
                    
                    Slider(
                        value: $straightenAngle,
                        in: -45...45,
                        step: 0.1
                    ) { _ in
                        onAngleChanged(rotationAngle, straightenAngle, flipHorizontal, flipVertical)
                    }
                    .accentColor(MinimalDesign.Colors.accentRed)
                    
                    Text("\(String(format: "%.1f", straightenAngle))°")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                        .frame(width: 32)
                }
            }
            .padding(.horizontal, 16)
            
            // Quick action buttons (compact)
            HStack(spacing: 12) {
                // 90° left rotation
                Button(action: {
                    rotationAngle = rotationAngle - 90
                    if rotationAngle < -180 { rotationAngle += 360 }
                    onAngleChanged(rotationAngle, straightenAngle, flipHorizontal, flipVertical)
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "rotate.left")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        Text("90°L")
                            .font(.system(size: 8))
                            .foregroundColor(Color(white: 0.7))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 90° right rotation
                Button(action: {
                    rotationAngle = rotationAngle + 90
                    if rotationAngle > 180 { rotationAngle -= 360 }
                    onAngleChanged(rotationAngle, straightenAngle, flipHorizontal, flipVertical)
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "rotate.right")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        Text("90°R")
                            .font(.system(size: 8))
                            .foregroundColor(Color(white: 0.7))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Horizontal flip
                Button(action: {
                    flipHorizontal.toggle()
                    onAngleChanged(rotationAngle, straightenAngle, flipHorizontal, flipVertical)
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 16))
                            .foregroundColor(flipHorizontal ? MinimalDesign.Colors.accentRed : .white)
                        Text("Flip H")
                            .font(.system(size: 8))
                            .foregroundColor(flipHorizontal ? MinimalDesign.Colors.accentRed : Color(white: 0.7))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Vertical flip
                Button(action: {
                    flipVertical.toggle()
                    onAngleChanged(rotationAngle, straightenAngle, flipHorizontal, flipVertical)
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.up.and.down")
                            .font(.system(size: 16))
                            .foregroundColor(flipVertical ? MinimalDesign.Colors.accentRed : .white)
                        Text("Flip V")
                            .font(.system(size: 8))
                            .foregroundColor(flipVertical ? MinimalDesign.Colors.accentRed : Color(white: 0.7))
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 140) // Same height as Preset section
        .background(Color(hex: "1a1a1a"))
    }
}

// MARK: - Preview
#if DEBUG
struct AngleAdjustmentView_Previews: PreviewProvider {
    static var previews: some View {
        AngleAdjustmentView { _, _, _, _ in }
            .background(Color.black)
    }
}
#endif