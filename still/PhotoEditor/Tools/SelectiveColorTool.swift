//======================================================================
// MARK: - SelectiveColorTool
// Purpose: プロ仕様の選択的カラー調整ツール
// Features: 色域別CMYK調整、リアルタイムプレビュー、プリセット
//======================================================================

import SwiftUI

enum SelectiveColorToolPreviewMode: String, CaseIterable, Identifiable {
    case original = "Original"
    case split = "Split"
    case beforeAfter = "Before/After"

    var id: String { self.rawValue }
    var displayName: String {
        return rawValue
    }

    var iconName: String {
        switch self {
        case .original: return "photo"
        case .split: return "rectangle.split.2x1"
        case .beforeAfter: return "arrow.left.arrow.right"
        }
    }
}

struct SelectiveColorTool: View {
    @ObservedObject var editingEngine: AdvancedEditingEngine
    @State private var selectedColorRange: ColorRange = .reds
    @State private var adjustments: [ColorRange: ColorAdjustment] = [:]
    @State private var showPresets = false
    @State private var previewMode: SelectiveColorToolPreviewMode = .split
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Selective Color")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Preview mode selector
                previewModeSelector
                
                // Presets button
                Button(action: { showPresets.toggle() }) {
                    Image(systemName: "square.grid.3x3")
                        .font(.title3)
                }
                
                // Reset button
                Button("Reset") {
                    resetAdjustments()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Color range selector
            colorRangeSelector
            
            // CMYK adjustments
            cmykAdjustments
            
            // Color range preview
            colorRangePreview
            
            // Presets panel
            if showPresets {
                presetsPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
        }
        .padding()
        .animation(.easeInOut(duration: 0.3), value: showPresets)
        .onAppear {
            initializeAdjustments()
        }
    }
    
    // MARK: - Preview Mode Selector
    
    private var previewModeSelector: some View {
        Menu {
            ForEach(SelectiveColorToolPreviewMode.allCases, id: \.self) { mode in
                Button(action: {
                    previewMode = mode
                }) {
                    HStack {
                        Text(mode.displayName)
                        if previewMode == mode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: previewMode.iconName)
                .font(.title3)
        }
    }
    
    // MARK: - Color Range Selector
    
    private var colorRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ColorRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedColorRange = range
                    }) {
                        VStack(spacing: 6) {
                            // Color preview circle
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: range.previewGradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedColorRange == range ? Color.blue : Color.gray.opacity(0.3),
                                            lineWidth: selectedColorRange == range ? 3 : 1
                                        )
                                )
                            
                            Text(range.displayName)
                                .font(.caption)
                                .fontWeight(selectedColorRange == range ? .bold : .regular)
                                .foregroundColor(selectedColorRange == range ? .blue : .primary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - CMYK Adjustments
    
    private var cmykAdjustments: some View {
        VStack(spacing: 16) {
            Text("\(selectedColorRange.displayName) Adjustment")
                .font(.headline)
                .foregroundColor(.secondary)
            
            let currentAdjustment = adjustments[selectedColorRange] ?? ColorAdjustment()
            
            // Cyan adjustment
            CMYKSlider(
                title: "Cyan",
                value: Binding(
                    get: { currentAdjustment.cyan },
                    set: { updateAdjustment(\.cyan, value: $0) }
                ),
                color: .cyan,
                oppositeColor: .red
            )
            
            // Magenta adjustment
            CMYKSlider(
                title: "Magenta",
                value: Binding(
                    get: { currentAdjustment.magenta },
                    set: { updateAdjustment(\.magenta, value: $0) }
                ),
                color: .purple,
                oppositeColor: .green
            )
            
            // Yellow adjustment
            CMYKSlider(
                title: "Yellow",
                value: Binding(
                    get: { currentAdjustment.yellow },
                    set: { updateAdjustment(\.yellow, value: $0) }
                ),
                color: .yellow,
                oppositeColor: .blue
            )
            
            // Black adjustment
            CMYKSlider(
                title: "Black",
                value: Binding(
                    get: { currentAdjustment.black },
                    set: { updateAdjustment(\.black, value: $0) }
                ),
                color: .black,
                oppositeColor: .white
            )
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Color Range Preview
    
    private var colorRangePreview: some View {
        VStack(spacing: 8) {
            Text("Affected Colors")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Color range visualization
            HStack(spacing: 4) {
                ForEach(0..<20, id: \.self) { index in
                    let hue = selectedColorRange.hueRange.lowerBound + 
                             (selectedColorRange.hueRange.upperBound - selectedColorRange.hueRange.lowerBound) * 
                             (Double(index) / 19.0)
                    
                    Rectangle()
                        .fill(Color(hue: hue / 360.0, saturation: 0.8, brightness: 0.8))
                        .frame(width: 12, height: 20)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Current adjustment summary
            adjustmentSummary
        }
    }
    
    // MARK: - Adjustment Summary
    
    private var adjustmentSummary: some View {
        let adjustment = adjustments[selectedColorRange] ?? ColorAdjustment()
        let hasAdjustments = adjustment.cyan != 0 || adjustment.magenta != 0 || 
                           adjustment.yellow != 0 || adjustment.black != 0
        
        return HStack {
            if hasAdjustments {
                Text("C: \(formatValue(adjustment.cyan))")
                    .font(.caption2)
                    .foregroundColor(.cyan)
                
                Text("M: \(formatValue(adjustment.magenta))")
                    .font(.caption2)
                    .foregroundColor(.purple)
                
                Text("Y: \(formatValue(adjustment.yellow))")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                
                Text("K: \(formatValue(adjustment.black))")
                    .font(.caption2)
                    .foregroundColor(.primary)
            } else {
                Text("No adjustments")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Presets Panel
    
    private var presetsPanel: some View {
        VStack(spacing: 12) {
            Text("Selective Color Presets")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(SelectiveColorPreset.allCases, id: \.self) { preset in
                    Button(action: {
                        applyPreset(preset)
                    }) {
                        VStack(spacing: 6) {
                            // Preset preview
                            HStack(spacing: 2) {
                                ForEach(ColorRange.allCases.prefix(6), id: \.self) { range in
                                    Rectangle()
                                        .fill(range.previewColor)
                                        .frame(width: 8, height: 20)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            
                            Text(preset.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Methods
    
    private func initializeAdjustments() {
        for range in ColorRange.allCases {
            if adjustments[range] == nil {
                adjustments[range] = ColorAdjustment()
            }
        }
    }
    
    private func updateAdjustment(_ keyPath: WritableKeyPath<ColorAdjustment, Float>, value: Float) {
        var adjustment = adjustments[selectedColorRange] ?? ColorAdjustment()
        adjustment[keyPath: keyPath] = value
        adjustments[selectedColorRange] = adjustment
        
        applySelectiveColorAdjustment()
    }
    
    private func applySelectiveColorAdjustment() {
        let rangeAdjustments = adjustments.compactMap { (range, adjustment) -> (range: ColorRange, adjustment: ColorAdjustment)? in
            // Only include ranges with actual adjustments
            if adjustment.cyan != 0 || adjustment.magenta != 0 || 
               adjustment.yellow != 0 || adjustment.black != 0 {
                return (range: range, adjustment: adjustment)
            }
            return nil
        }
        
        let selectiveColorAdjustment = SelectiveColorAdjustment(adjustments: rangeAdjustments)
        editingEngine.selectiveColorAdjustment(selectiveColorAdjustment)
    }
    
    private func resetAdjustments() {
        adjustments.removeAll()
        initializeAdjustments()
        applySelectiveColorAdjustment()
    }
    
    private func applyPreset(_ preset: SelectiveColorPreset) {
        adjustments = preset.adjustments
        applySelectiveColorAdjustment()
        showPresets = false
    }
    
    private func formatValue(_ value: Float) -> String {
        return String(format: "%+.0f%%", value * 100)
    }
}

// MARK: - CMYK Slider

struct CMYKSlider: View {
    let title: String
    @Binding var value: Float
    let color: Color
    let oppositeColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(value > 0 ? color : (value < 0 ? oppositeColor : .secondary))
                    .frame(width: 40, alignment: .trailing)
            }
            
            HStack(spacing: 8) {
                // Negative indicator
                Text(oppositeColor == .white ? "W" : oppositeColor.description.prefix(1).uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(oppositeColor == .white ? .black : oppositeColor)
                    .frame(width: 20)
                
                // Slider
                Slider(value: $value, in: -1.0...1.0, step: 0.01)
                    .accentColor(value > 0 ? color : oppositeColor)
                
                // Positive indicator
                Text(color == .black ? "K" : color.description.prefix(1).uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(color == .black ? .black : color)
                    .frame(width: 20)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Extensions

extension ColorRange {
    var displayName: String {
        return rawValue
    }
    
    var previewColor: Color {
        switch self {
        case .reds: return .red
        case .yellows: return .yellow
        case .greens: return .green
        case .cyans: return .cyan
        case .blues: return .blue
        case .magentas: return .purple
        case .whites: return .white
        case .neutrals: return .gray
        case .blacks: return .black
        }
    }
    
    var previewGradient: Gradient {
        switch self {
        case .reds:
            return Gradient(colors: [.red, .orange])
        case .yellows:
            return Gradient(colors: [.yellow, .orange])
        case .greens:
            return Gradient(colors: [.green, .mint])
        case .cyans:
            return Gradient(colors: [.cyan, .blue])
        case .blues:
            return Gradient(colors: [.blue, .purple])
        case .magentas:
            return Gradient(colors: [.purple, .pink])
        case .whites:
            return Gradient(colors: [.white, .gray.opacity(0.3)])
        case .neutrals:
            return Gradient(colors: [.gray, .secondary])
        case .blacks:
            return Gradient(colors: [.black, .gray])
        }
    }
    
    var hueRange: ClosedRange<Double> {
        switch self {
        case .reds: return 345...360
        case .yellows: return 45...75
        case .greens: return 75...165
        case .cyans: return 165...195
        case .blues: return 195...255
        case .magentas: return 255...345
        case .whites: return 0...360 // Special case
        case .neutrals: return 0...360 // Special case
        case .blacks: return 0...360 // Special case
        }
    }
}

// MARK: - Preview Mode



// MARK: - Selective Color Presets

enum SelectiveColorPreset: String, CaseIterable {
    case none = "None"
    case warmSkin = "Warm Skin Tones"
    case coolSkin = "Cool Skin Tones"
    case vibrantLandscape = "Vibrant Landscape"
    case mutedTones = "Muted Tones"
    case filmLook = "Classic Film"
    case digitalVibrant = "Digital Vibrant"
    case autumn = "Autumn Colors"
    case oceanBlues = "Ocean Blues"
    
    var displayName: String {
        return rawValue
    }
    
    var adjustments: [ColorRange: ColorAdjustment] {
        switch self {
        case .none:
            return [:]
            
        case .warmSkin:
            return [
                .reds: ColorAdjustment(cyan: -0.2, magenta: 0.1, yellow: 0.3, black: 0.0),
                .yellows: ColorAdjustment(cyan: -0.1, magenta: -0.1, yellow: 0.2, black: 0.0),
                .neutrals: ColorAdjustment(cyan: -0.05, magenta: 0.05, yellow: 0.1, black: 0.0)
            ]
            
        case .coolSkin:
            return [
                .reds: ColorAdjustment(cyan: 0.1, magenta: -0.1, yellow: -0.2, black: 0.0),
                .yellows: ColorAdjustment(cyan: 0.2, magenta: 0.0, yellow: -0.3, black: 0.0),
                .neutrals: ColorAdjustment(cyan: 0.1, magenta: -0.05, yellow: -0.1, black: 0.0)
            ]
            
        case .vibrantLandscape:
            return [
                .greens: ColorAdjustment(cyan: 0.2, magenta: -0.3, yellow: 0.1, black: -0.1),
                .blues: ColorAdjustment(cyan: 0.3, magenta: 0.1, yellow: -0.4, black: 0.0),
                .yellows: ColorAdjustment(cyan: -0.2, magenta: 0.0, yellow: 0.4, black: 0.0)
            ]
            
        case .mutedTones:
            return [
                .reds: ColorAdjustment(cyan: 0.1, magenta: 0.0, yellow: 0.0, black: 0.1),
                .greens: ColorAdjustment(cyan: 0.0, magenta: 0.1, yellow: 0.0, black: 0.1),
                .blues: ColorAdjustment(cyan: 0.0, magenta: 0.1, yellow: 0.1, black: 0.1),
                .yellows: ColorAdjustment(cyan: 0.0, magenta: 0.0, yellow: -0.1, black: 0.1)
            ]
            
        case .filmLook:
            return [
                .whites: ColorAdjustment(cyan: 0.0, magenta: 0.1, yellow: 0.2, black: 0.0),
                .blacks: ColorAdjustment(cyan: 0.1, magenta: 0.2, yellow: 0.1, black: -0.1),
                .neutrals: ColorAdjustment(cyan: 0.05, magenta: 0.1, yellow: 0.15, black: 0.0)
            ]
            
        case .digitalVibrant:
            return [
                .reds: ColorAdjustment(cyan: -0.3, magenta: 0.2, yellow: 0.4, black: 0.0),
                .greens: ColorAdjustment(cyan: 0.2, magenta: -0.4, yellow: 0.2, black: 0.0),
                .blues: ColorAdjustment(cyan: 0.4, magenta: 0.2, yellow: -0.5, black: 0.0),
                .cyans: ColorAdjustment(cyan: 0.3, magenta: -0.2, yellow: -0.3, black: 0.0)
            ]
            
        case .autumn:
            return [
                .reds: ColorAdjustment(cyan: -0.2, magenta: 0.3, yellow: 0.5, black: 0.0),
                .yellows: ColorAdjustment(cyan: -0.3, magenta: 0.1, yellow: 0.3, black: 0.0),
                .greens: ColorAdjustment(cyan: 0.0, magenta: 0.2, yellow: 0.4, black: 0.1)
            ]
            
        case .oceanBlues:
            return [
                .blues: ColorAdjustment(cyan: 0.4, magenta: 0.0, yellow: -0.3, black: 0.0),
                .cyans: ColorAdjustment(cyan: 0.3, magenta: -0.2, yellow: -0.4, black: 0.0),
                .greens: ColorAdjustment(cyan: 0.2, magenta: -0.1, yellow: -0.2, black: 0.0)
            ]
        }
    }
}