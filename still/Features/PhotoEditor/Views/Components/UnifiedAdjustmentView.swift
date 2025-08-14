//======================================================================
// MARK: - UnifiedAdjustmentView.swift
// Purpose: Unified adjustment controls with expandable sliders (統合調整コントロール)
// Path: still/Features/PhotoEditor/Views/Components/UnifiedAdjustmentView.swift
//======================================================================

import SwiftUI

struct UnifiedAdjustmentView: View {
    // MARK: - Properties
    @Binding var filterSettings: FilterSettings
    @Binding var toneCurve: ToneCurve
    @Binding var expandedParameter: AdjustmentParameter?
    @Binding var showToneCurve: Bool
    let onSettingsChanged: (FilterSettings) -> Void
    let onToneCurveChanged: (ToneCurve) -> Void
    var onAutoWB: (() -> Void)? = nil
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Icon bar for all controls
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    // Adjustment parameters
                    ForEach(AdjustmentParameter.allCases, id: \.self) { parameter in
                        iconButton(for: parameter)
                    }
                    
                    // Tone curve button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedParameter = nil
                            showToneCurve.toggle()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 20))
                                .foregroundColor(showToneCurve ? MinimalDesign.Colors.accentRed : .white)
                            
                            Text("Curve")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(showToneCurve ? MinimalDesign.Colors.accentRed : Color(white: 0.7))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 44)
            .background(Color(hex: "121212"))
            
            // Expanded control area or spacer to maintain consistent height
            if let parameter = expandedParameter {
                expandedSliderView(for: parameter)
                    .transition(.asymmetric(
                        insertion: .push(from: .bottom).combined(with: .opacity),
                        removal: .push(from: .top).combined(with: .opacity)
                    ))
            } else if showToneCurve {
                toneCurveView
                    .transition(.asymmetric(
                        insertion: .push(from: .bottom).combined(with: .opacity),
                        removal: .push(from: .top).combined(with: .opacity)
                    ))
            } else {
                // Empty spacer to maintain consistent height
                Spacer()
                    .frame(height: 96) // 140 - 44 = 96
                    .background(Color(hex: "1a1a1a"))
            }
        }
        .frame(height: 140) // Same height as Preset section
    }
    
    // MARK: - Icon Button
    private func iconButton(for parameter: AdjustmentParameter) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showToneCurve = false
                expandedParameter = expandedParameter == parameter ? nil : parameter
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: parameter.icon)
                    .font(.system(size: 20))
                    .foregroundColor(expandedParameter == parameter ? MinimalDesign.Colors.accentRed : .white)
                
                // Show current value as a small indicator
                if abs(currentValue(for: parameter)) > 5 {
                    Circle()
                        .fill(MinimalDesign.Colors.accentRed)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Expanded Slider View
    private func expandedSliderView(for parameter: AdjustmentParameter) -> some View {
        VStack(spacing: 6) {
            // Parameter name with reset button
            HStack {
                Text(parameter.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Current value display
                    Text("\(Int(binding(for: parameter).wrappedValue))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                    
                    // Reset button as icon
                    Button(action: {
                        resetParameter(parameter)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.7))
                    }
                }
            }
            
            // Compact slider
            HStack(spacing: 8) {
                Text("\(Int(parameter.range.lowerBound))")
                    .font(.system(size: 9))
                    .foregroundColor(Color(white: 0.6))
                    .frame(width: 24)
                
                Slider(
                    value: binding(for: parameter),
                    in: parameter.range,
                    step: 1
                )
                .accentColor(MinimalDesign.Colors.accentRed)
                
                Text("\(Int(parameter.range.upperBound))")
                    .font(.system(size: 9))
                    .foregroundColor(Color(white: 0.6))
                    .frame(width: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 96) // Match the spacer height
        .background(Color(hex: "1a1a1a"))
    }
    
    // MARK: - Tone Curve View
    private var toneCurveView: some View {
        VStack(spacing: 12) {
            Text("Tone Curve")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            
            ToneCurveEditor(toneCurve: $toneCurve, onCurveChanged: onToneCurveChanged)
                .frame(height: 140)
                .padding(.horizontal, 20)
            
            // Reset curve button
            Button(action: {
                toneCurve = ToneCurve()
                onToneCurveChanged(toneCurve)
            }) {
                Text("Reset Curve")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(white: 0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Rectangle()
                            .stroke(Color(white: 0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 16)
        .background(Color(hex: "1a1a1a"))
    }
    
    // MARK: - Helper Methods
    private func currentValue(for parameter: AdjustmentParameter) -> Float {
        switch parameter {
        case .brightness:
            return filterSettings.brightness
        case .highlights:
            return filterSettings.highlights
        case .shadows:
            return filterSettings.shadows
        case .whites:
            return filterSettings.whites
        case .blacks:
            return filterSettings.blacks
        case .contrast:
            return (filterSettings.contrast - 1) * 100
        case .clarity:
            return filterSettings.clarity
        }
    }
    
    private func resetParameter(_ parameter: AdjustmentParameter) {
        switch parameter {
        case .brightness:
            filterSettings.brightness = 50
        case .highlights:
            filterSettings.highlights = 50
        case .shadows:
            filterSettings.shadows = 50
        case .whites:
            filterSettings.whites = 50
        case .blacks:
            filterSettings.blacks = 50
        case .contrast:
            filterSettings.contrast = 50
        case .clarity:
            filterSettings.clarity = 50
        }
        onSettingsChanged(filterSettings)
    }
    
    private func binding(for parameter: AdjustmentParameter) -> Binding<Float> {
        switch parameter {
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

// MARK: - Preview
#if DEBUG
struct UnifiedAdjustmentView_Previews: PreviewProvider {
    static var previews: some View {
        UnifiedAdjustmentView(
            filterSettings: .constant(FilterSettings()),
            toneCurve: .constant(ToneCurve()),
            expandedParameter: .constant(nil),
            showToneCurve: .constant(false),
            onSettingsChanged: { _ in },
            onToneCurveChanged: { _ in }
        )
        .background(Color.black)
    }
}
#endif