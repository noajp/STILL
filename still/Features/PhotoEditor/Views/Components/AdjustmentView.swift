//======================================================================
// MARK: - AdjustmentView.swift
// Purpose: SwiftUI view component (AdjustmentViewビューコンポーネント)
// Path: still/Features/PhotoEditor/Views/Components/AdjustmentView.swift
//======================================================================
//
//  AdjustmentView.swift
//  tete
//
//  詳細な画像調整機能
//

import SwiftUI

struct AdjustmentView: View {
    @Binding var filterSettings: FilterSettings
    @Binding var toneCurve: ToneCurve
    @State private var selectedTab: AdjustmentTab = .basic
    let onSettingsChanged: (FilterSettings) -> Void
    let onToneCurveChanged: (ToneCurve) -> Void
    
    enum AdjustmentTab: String, CaseIterable {
        case basic = "Basic"
        case curve = "Curve"
        
        var icon: String {
            switch self {
            case .basic:
                return "slider.horizontal.3"
            case .curve:
                return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // タブ選択
            tabSelectionView
            
            // コンテンツ
            switch selectedTab {
            case .basic:
                basicAdjustmentView
            case .curve:
                toneCurveView
            }
            
            // 完了ボタン
            completionButton
        }
    }
    
    // MARK: - Views
    
    private var tabSelectionView: some View {
        HStack(spacing: 0) {
            ForEach(AdjustmentTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : Color(white: 0.56))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .background(Color(white: 0.15))
    }
    
    private var basicAdjustmentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(AdjustmentParameter.allCases, id: \.self) { parameter in
                    adjustmentSlider(for: parameter)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 100)
    }
    
    private func adjustmentSlider(for parameter: AdjustmentParameter) -> some View {
        VStack(spacing: 8) {
            // アイコン
            Image(systemName: parameter.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(height: 24)
            
            // パラメータ名
            Text(parameter.rawValue)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // スライダー
            VStack(spacing: 4) {
                Slider(
                    value: binding(for: parameter),
                    in: parameter.range,
                    step: 1
                ) {
                    EmptyView()
                } minimumValueLabel: {
                    Text("\(Int(parameter.range.lowerBound))")
                        .font(.system(size: 8))
                        .foregroundColor(Color(white: 0.6))
                } maximumValueLabel: {
                    Text("\(Int(parameter.range.upperBound))")
                        .font(.system(size: 8))
                        .foregroundColor(Color(white: 0.6))
                }
                .frame(width: 80)
                .accentColor(MinimalDesign.Colors.accentRed)
                
                // 現在の値
                Text("\(Int(binding(for: parameter).wrappedValue))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 100)
    }
    
    private var toneCurveView: some View {
        VStack(spacing: 16) {
            Text("Tone Curve")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            // トーンカーブエディター
            ToneCurveEditor(toneCurve: $toneCurve, onCurveChanged: onToneCurveChanged)
            .frame(height: 120)
            .padding(.horizontal, 20)
        }
    }
    
    private var completionButton: some View {
        Button(action: {
            onSettingsChanged(filterSettings)
        }) {
            Text("Apply")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(MinimalDesign.Colors.accentRed)
                .cornerRadius(8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Helper Methods
    
    private func binding(for parameter: AdjustmentParameter) -> Binding<Float> {
        switch parameter {
        case .whiteBalance:
            return Binding(
                get: { filterSettings.temperature },
                set: { newValue in
                    filterSettings.temperature = newValue
                    onSettingsChanged(filterSettings)
                }
            )
        case .brightness:
            return Binding(
                get: { filterSettings.brightness * 100 },
                set: { newValue in
                    filterSettings.brightness = newValue / 100
                    onSettingsChanged(filterSettings)
                }
            )
        case .highlights:
            return Binding(
                get: { filterSettings.highlights },
                set: { newValue in
                    filterSettings.highlights = newValue
                    onSettingsChanged(filterSettings)
                }
            )
        case .shadows:
            return Binding(
                get: { filterSettings.shadows },
                set: { newValue in
                    filterSettings.shadows = newValue
                    onSettingsChanged(filterSettings)
                }
            )
        case .whites:
            return Binding(
                get: { filterSettings.whites },
                set: { newValue in
                    filterSettings.whites = newValue
                    onSettingsChanged(filterSettings)
                }
            )
        case .blacks:
            return Binding(
                get: { filterSettings.blacks },
                set: { newValue in
                    filterSettings.blacks = newValue
                    onSettingsChanged(filterSettings)
                }
            )
        case .contrast:
            return Binding(
                get: { (filterSettings.contrast - 1) * 100 },
                set: { newValue in
                    filterSettings.contrast = 1 + (newValue / 100)
                    onSettingsChanged(filterSettings)
                }
            )
        case .clarity:
            return Binding(
                get: { filterSettings.clarity },
                set: { newValue in
                    filterSettings.clarity = newValue
                    onSettingsChanged(filterSettings)
                }
            )
        }
    }
    
}

// MARK: - Tone Curve Editor
struct ToneCurveEditor: View {
    @Binding var toneCurve: ToneCurve
    let onCurveChanged: (ToneCurve) -> Void
    
    @State private var draggedPointIndex: Int? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // グリッド背景
                gridBackground(in: geometry.size)
                
                // カーブライン
                curvePath(in: geometry.size)
                    .stroke(MinimalDesign.Colors.accentRed, lineWidth: 2)
                
                // コントロールポイント
                ForEach(toneCurve.points.indices, id: \.self) { index in
                    if index > 0 && index < toneCurve.points.count - 1 {
                        controlPoint(at: index, in: geometry.size)
                    }
                }
            }
            .background(Color(white: 0.1))
            .cornerRadius(8)
        }
    }
    
    private func gridBackground(in size: CGSize) -> some View {
        Path { path in
            // 縦線
            for i in 1..<4 {
                let x = size.width * CGFloat(i) / 4
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            
            // 横線
            for i in 1..<4 {
                let y = size.height * CGFloat(i) / 4
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(Color(white: 0.3), lineWidth: 0.5)
    }
    
    private func curvePath(in size: CGSize) -> Path {
        Path { path in
            let points = toneCurve.points.map { point in
                CGPoint(
                    x: CGFloat(point.input) * size.width,
                    y: (1 - CGFloat(point.output)) * size.height
                )
            }
            
            guard !points.isEmpty else { return }
            
            path.move(to: points[0])
            
            if points.count == 1 {
                path.addLine(to: points[0])
            } else {
                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
            }
        }
    }
    
    private func controlPoint(at index: Int, in size: CGSize) -> some View {
        let point = toneCurve.points[index]
        let position = CGPoint(
            x: CGFloat(point.input) * size.width,
            y: (1 - CGFloat(point.output)) * size.height
        )
        
        return Circle()
            .fill(MinimalDesign.Colors.accentRed)
            .frame(width: 12, height: 12)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        draggedPointIndex = index
                        updatePoint(at: index, with: value.location, in: size)
                    }
                    .onEnded { _ in
                        draggedPointIndex = nil
                        onCurveChanged(toneCurve)
                    }
            )
    }
    
    private func updatePoint(at index: Int, with location: CGPoint, in size: CGSize) {
        let newInput = Float(max(0, min(1, location.x / size.width)))
        let newOutput = Float(max(0, min(1, 1 - (location.y / size.height))))
        
        toneCurve.points[index] = ToneCurvePoint(input: newInput, output: newOutput)
        toneCurve.points.sort { $0.input < $1.input }
    }
}

// MARK: - Preview
#if DEBUG
struct AdjustmentView_Previews: PreviewProvider {
    static var previews: some View {
        AdjustmentView(
            filterSettings: .constant(FilterSettings()),
            toneCurve: .constant(ToneCurve()),
            onSettingsChanged: { _ in },
            onToneCurveChanged: { _ in }
        )
        .frame(height: 180)
        .background(Color.black)
    }
}
#endif