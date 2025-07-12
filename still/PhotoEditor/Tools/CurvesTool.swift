//======================================================================
// MARK: - CurvesTool
// Purpose: プロ仕様のカーブ調整ツール
// Features: RGB・個別チャンネル調整、ベジェ曲線、プリセット
//======================================================================

import SwiftUI
import CoreGraphics

struct CurvesTool: View {
    @ObservedObject var editingEngine: AdvancedEditingEngine
    @State private var selectedChannel: CurveChannel = .rgb
    @State private var curvePoints: [CGPoint] = [
        CGPoint(x: 0, y: 0),
        CGPoint(x: 0.25, y: 0.25),
        CGPoint(x: 0.5, y: 0.5),
        CGPoint(x: 0.75, y: 0.75),
        CGPoint(x: 1, y: 1)
    ]
    @State private var isDragging = false
    @State private var selectedPointIndex: Int? = nil
    @State private var showPresets = false
    
    private let gridLines = 4
    private let curveSize: CGFloat = 300
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Curves")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Presets button
                Button(action: { showPresets.toggle() }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                }
                
                // Reset button
                Button("Reset") {
                    resetCurve()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Channel selector
            channelSelector
            
            // Curve editor
            curveEditor
                .frame(width: curveSize, height: curveSize)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Curve info
            curveInfo
            
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
            resetCurve()
        }
        .onChange(of: selectedChannel) { oldValue, newValue in
            updateCurveForChannel()
        }
        .onChange(of: curvePoints) { oldValue, newValue in
            applyCurveAdjustment()
        }
    }
    
    // MARK: - Channel Selector
    
    private var channelSelector: some View {
        HStack(spacing: 12) {
            ForEach(CurveChannel.allCases, id: \.self) { channel in
                Button(action: {
                    selectedChannel = channel
                }) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(channel.color)
                            .frame(width: 12, height: 12)
                        
                        Text(channel.displayName)
                            .font(.caption)
                            .fontWeight(selectedChannel == channel ? .bold : .regular)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedChannel == channel ? Color.blue.opacity(0.2) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedChannel == channel ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .foregroundColor(selectedChannel == channel ? .blue : .primary)
            }
        }
    }
    
    // MARK: - Curve Editor
    
    private var curveEditor: some View {
        ZStack {
            // Background grid
            curveGrid
            
            // Histogram background (simplified)
            histogramBackground
            
            // Curve line
            curvePath
                .stroke(selectedChannel.color, lineWidth: 3)
                .shadow(color: selectedChannel.color.opacity(0.3), radius: 2)
            
            // Control points
            ForEach(curvePoints.indices, id: \.self) { index in
                if index > 0 && index < curvePoints.count - 1 { // Skip first and last points
                    CurveControlPoint(
                        point: curvePoints[index],
                        isSelected: selectedPointIndex == index,
                        color: selectedChannel.color,
                        onDrag: { newPoint in
                            updatePoint(at: index, to: newPoint)
                        },
                        onSelect: {
                            selectedPointIndex = index
                        }
                    )
                    .position(
                        x: curvePoints[index].x * curveSize,
                        y: (1 - curvePoints[index].y) * curveSize
                    )
                }
            }
            
            // Input/Output values display
            if let selectedIndex = selectedPointIndex {
                inputOutputDisplay(for: selectedIndex)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleCurveDrag(value: value)
                }
                .onEnded { _ in
                    isDragging = false
                    selectedPointIndex = nil
                }
        )
        .onTapGesture { location in
            addCurvePoint(at: location)
        }
    }
    
    // MARK: - Curve Grid
    
    private var curveGrid: some View {
        ZStack {
            // Major grid lines
            ForEach(0...gridLines, id: \.self) { i in
                let position = CGFloat(i) / CGFloat(gridLines) * curveSize
                
                // Vertical lines
                Path { path in
                    path.move(to: CGPoint(x: position, y: 0))
                    path.addLine(to: CGPoint(x: position, y: curveSize))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                
                // Horizontal lines
                Path { path in
                    path.move(to: CGPoint(x: 0, y: position))
                    path.addLine(to: CGPoint(x: curveSize, y: position))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            }
            
            // Diagonal reference line
            Path { path in
                path.move(to: CGPoint(x: 0, y: curveSize))
                path.addLine(to: CGPoint(x: curveSize, y: 0))
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        }
    }
    
    // MARK: - Histogram Background
    
    private var histogramBackground: some View {
        // Simplified histogram representation
        Path { path in
            let points = generateHistogramPoints()
            if let firstPoint = points.first {
                path.move(to: firstPoint)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                path.addLine(to: CGPoint(x: curveSize, y: curveSize))
                path.addLine(to: CGPoint(x: 0, y: curveSize))
                path.closeSubpath()
            }
        }
        .fill(
            LinearGradient(
                gradient: Gradient(colors: [
                    selectedChannel.color.opacity(0.1),
                    selectedChannel.color.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Curve Path
    
    private var curvePath: Path {
        Path { path in
            if let firstPoint = curvePoints.first {
                let startPoint = CGPoint(
                    x: firstPoint.x * curveSize,
                    y: (1 - firstPoint.y) * curveSize
                )
                path.move(to: startPoint)
                
                // Create smooth curve through all points
                for i in 1..<curvePoints.count {
                    let currentPoint = CGPoint(
                        x: curvePoints[i].x * curveSize,
                        y: (1 - curvePoints[i].y) * curveSize
                    )
                    
                    if i == 1 {
                        path.addLine(to: currentPoint)
                    } else {
                        // Use quadratic curve for smoothness
                        let previousPoint = CGPoint(
                            x: curvePoints[i-1].x * curveSize,
                            y: (1 - curvePoints[i-1].y) * curveSize
                        )
                        
                        let controlPoint = CGPoint(
                            x: (previousPoint.x + currentPoint.x) / 2,
                            y: (previousPoint.y + currentPoint.y) / 2
                        )
                        
                        path.addQuadCurve(to: currentPoint, control: controlPoint)
                    }
                }
            }
        }
    }
    
    // MARK: - Curve Info
    
    private var curveInfo: some View {
        HStack {
            if let selectedIndex = selectedPointIndex {
                let point = curvePoints[selectedIndex]
                Text("Input: \(String(format: "%.0f", point.x * 255))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Output: \(String(format: "%.0f", point.y * 255))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Tap to add points • Drag to adjust • Double-tap to remove")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(curvePoints.count - 2) points")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Presets Panel
    
    private var presetsPanel: some View {
        VStack(spacing: 12) {
            Text("Curve Presets")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(CurvePreset.allCases, id: \.self) { preset in
                    Button(action: {
                        applyCurvePreset(preset)
                    }) {
                        VStack(spacing: 4) {
                            // Mini curve preview
                            MiniCurvePreview(points: preset.curvePoints)
                                .frame(width: 60, height: 60)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            Text(preset.displayName)
                                .font(.caption)
                                .lineLimit(1)
                        }
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
    
    private func resetCurve() {
        curvePoints = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 0.25, y: 0.25),
            CGPoint(x: 0.5, y: 0.5),
            CGPoint(x: 0.75, y: 0.75),
            CGPoint(x: 1, y: 1)
        ]
        selectedPointIndex = nil
    }
    
    private func updateCurveForChannel() {
        // In a real implementation, this would load the curve for the selected channel
        // For now, we'll keep the same curve for all channels
    }
    
    private func applyCurveAdjustment() {
        let adjustment = CurveAdjustment(
            rgbCurve: selectedChannel == .rgb ? (
                curvePoints[0],
                curvePoints[1],
                curvePoints[2],
                curvePoints[3],
                curvePoints[4]
            ) : nil,
            redCurve: selectedChannel == .red ? curvePoints : nil,
            greenCurve: selectedChannel == .green ? curvePoints : nil,
            blueCurve: selectedChannel == .blue ? curvePoints : nil
        )
        
        editingEngine.adjustCurves(adjustment)
    }
    
    private func updatePoint(at index: Int, to newPoint: CGPoint) {
        guard index > 0 && index < curvePoints.count - 1 else { return }
        
        // Clamp to valid range and maintain order
        let clampedX = max(curvePoints[index - 1].x + 0.01, 
                          min(curvePoints[index + 1].x - 0.01, newPoint.x))
        let clampedY = max(0, min(1, newPoint.y))
        
        curvePoints[index] = CGPoint(x: clampedX, y: clampedY)
    }
    
    private func handleCurveDrag(value: DragGesture.Value) {
        let location = value.location
        let normalizedPoint = CGPoint(
            x: location.x / curveSize,
            y: 1 - (location.y / curveSize)
        )
        
        if !isDragging {
            // Find closest point
            selectedPointIndex = findClosestPointIndex(to: location)
            isDragging = true
        }
        
        if let index = selectedPointIndex {
            updatePoint(at: index, to: normalizedPoint)
        }
    }
    
    private func addCurvePoint(at location: CGPoint) {
        let normalizedPoint = CGPoint(
            x: location.x / curveSize,
            y: 1 - (location.y / curveSize)
        )
        
        // Find insertion point
        var insertIndex = 1
        for i in 1..<curvePoints.count {
            if curvePoints[i].x > normalizedPoint.x {
                insertIndex = i
                break
            }
        }
        
        curvePoints.insert(normalizedPoint, at: insertIndex)
        selectedPointIndex = insertIndex
    }
    
    private func findClosestPointIndex(to location: CGPoint) -> Int? {
        var closestIndex: Int? = nil
        var closestDistance: CGFloat = CGFloat.infinity
        
        for i in 1..<curvePoints.count - 1 {
            let pointLocation = CGPoint(
                x: curvePoints[i].x * curveSize,
                y: (1 - curvePoints[i].y) * curveSize
            )
            
            let distance = hypot(location.x - pointLocation.x, location.y - pointLocation.y)
            
            if distance < 20 && distance < closestDistance {
                closestDistance = distance
                closestIndex = i
            }
        }
        
        return closestIndex
    }
    
    private func applyCurvePreset(_ preset: CurvePreset) {
        curvePoints = preset.curvePoints
        selectedPointIndex = nil
        showPresets = false
    }
    
    private func generateHistogramPoints() -> [CGPoint] {
        // Simplified histogram generation
        var points: [CGPoint] = []
        let segments = 50
        
        for i in 0...segments {
            let x = CGFloat(i) / CGFloat(segments) * curveSize
            let height = CGFloat.random(in: 0.3...0.8) * curveSize
            points.append(CGPoint(x: x, y: curveSize - height))
        }
        
        return points
    }
    
    private func inputOutputDisplay(for index: Int) -> some View {
        let point = curvePoints[index]
        let screenPoint = CGPoint(
            x: point.x * curveSize,
            y: (1 - point.y) * curveSize
        )
        
        return VStack(spacing: 2) {
            Text("In: \(Int(point.x * 255))")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("Out: \(Int(point.y * 255))")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(4)
        .background(Color.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .position(x: screenPoint.x, y: max(30, screenPoint.y - 30))
    }
}

// MARK: - Supporting Views

struct CurveControlPoint: View {
    let point: CGPoint
    let isSelected: Bool
    let color: Color
    let onDrag: (CGPoint) -> Void
    let onSelect: () -> Void
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(color: color.opacity(0.3), radius: 2)
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .onTapGesture {
                onSelect()
            }
    }
}

struct MiniCurvePreview: View {
    let points: [CGPoint]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let size = geometry.size
                if let firstPoint = points.first {
                    let startPoint = CGPoint(
                        x: firstPoint.x * size.width,
                        y: (1 - firstPoint.y) * size.height
                    )
                    path.move(to: startPoint)
                    
                    for i in 1..<points.count {
                        let currentPoint = CGPoint(
                            x: points[i].x * size.width,
                            y: (1 - points[i].y) * size.height
                        )
                        path.addLine(to: currentPoint)
                    }
                }
            }
            .stroke(Color.green, lineWidth: 1.5)
        }
    }
}

// MARK: - Enums and Data

enum CurveChannel: String, CaseIterable {
    case rgb = "RGB"
    case red = "Red"
    case green = "Green"
    case blue = "Blue"
    
    var displayName: String {
        return rawValue
    }
    
    var color: Color {
        switch self {
        case .rgb: return .white
        case .red: return .red
        case .green: return .green
        case .blue: return .blue
        }
    }
}

enum CurvePreset: String, CaseIterable {
    case linear = "Linear"
    case contrast = "Contrast"
    case brightContrast = "Bright Contrast"
    case darkContrast = "Dark Contrast"
    case sHigh = "S-Curve High"
    case sLow = "S-Curve Low"
    case filmLook = "Film Look"
    case vintage = "Vintage"
    case fadeFilm = "Fade Film"
    
    var displayName: String {
        return rawValue
    }
    
    var curvePoints: [CGPoint] {
        switch self {
        case .linear:
            return [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 0.25, y: 0.25),
                CGPoint(x: 0.5, y: 0.5),
                CGPoint(x: 0.75, y: 0.75),
                CGPoint(x: 1, y: 1)
            ]
        case .contrast:
            return [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 0.25, y: 0.15),
                CGPoint(x: 0.5, y: 0.5),
                CGPoint(x: 0.75, y: 0.85),
                CGPoint(x: 1, y: 1)
            ]
        case .brightContrast:
            return [
                CGPoint(x: 0, y: 0.05),
                CGPoint(x: 0.25, y: 0.2),
                CGPoint(x: 0.5, y: 0.55),
                CGPoint(x: 0.75, y: 0.85),
                CGPoint(x: 1, y: 1)
            ]
        case .darkContrast:
            return [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 0.25, y: 0.15),
                CGPoint(x: 0.5, y: 0.45),
                CGPoint(x: 0.75, y: 0.8),
                CGPoint(x: 1, y: 0.95)
            ]
        case .sHigh:
            return [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 0.2, y: 0.1),
                CGPoint(x: 0.5, y: 0.6),
                CGPoint(x: 0.8, y: 0.9),
                CGPoint(x: 1, y: 1)
            ]
        case .sLow:
            return [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 0.2, y: 0.3),
                CGPoint(x: 0.5, y: 0.4),
                CGPoint(x: 0.8, y: 0.7),
                CGPoint(x: 1, y: 1)
            ]
        case .filmLook:
            return [
                CGPoint(x: 0, y: 0.1),
                CGPoint(x: 0.25, y: 0.3),
                CGPoint(x: 0.5, y: 0.55),
                CGPoint(x: 0.75, y: 0.8),
                CGPoint(x: 1, y: 0.95)
            ]
        case .vintage:
            return [
                CGPoint(x: 0, y: 0.15),
                CGPoint(x: 0.3, y: 0.35),
                CGPoint(x: 0.6, y: 0.6),
                CGPoint(x: 0.8, y: 0.75),
                CGPoint(x: 1, y: 0.9)
            ]
        case .fadeFilm:
            return [
                CGPoint(x: 0, y: 0.2),
                CGPoint(x: 0.25, y: 0.4),
                CGPoint(x: 0.5, y: 0.6),
                CGPoint(x: 0.75, y: 0.8),
                CGPoint(x: 1, y: 0.9)
            ]
        }
    }
}