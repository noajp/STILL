//======================================================================
// MARK: - WhiteBalanceView.swift
// Purpose: White Balance adjustment controls (ホワイトバランス調整コントロール)
// Path: still/Features/PhotoEditor/Views/Components/WhiteBalanceView.swift
//======================================================================

import SwiftUI

struct WhiteBalanceView: View {
    // MARK: - Properties
    @Binding var filterSettings: FilterSettings
    let onSettingsChanged: (FilterSettings) -> Void
    var onAutoWB: (() -> Void)? = nil
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 8) {
            // Header with Auto WB and Reset
            HStack {
                Text("White Balance")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Reset button as back arrow icon
                    Button(action: {
                        filterSettings.temperature = 50
                        filterSettings.tint = 50
                        onSettingsChanged(filterSettings)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.7))
                    }
                    
                    // Auto WB button
                    if let autoWB = onAutoWB {
                        Button(action: autoWB) {
                            Text("Auto")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(MinimalDesign.Colors.accentRed)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Temperature and Tint controls in compact layout
            VStack(spacing: 12) {
                // Temperature control
                HStack {
                    Image(systemName: "snowflake")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                        .frame(width: 16)
                    
                    Text("Temp")
                        .font(.system(size: 10))
                        .foregroundColor(Color(white: 0.8))
                        .frame(width: 30, alignment: .leading)
                    
                    Slider(
                        value: Binding(
                            get: { filterSettings.temperature },
                            set: { newValue in
                                filterSettings.temperature = newValue
                                onSettingsChanged(filterSettings)
                            }
                        ),
                        in: 0...100,
                        step: 1
                    )
                    .accentColor(MinimalDesign.Colors.accentRed)
                    
                    Text("\(Int(filterSettings.temperature))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                        .frame(width: 24)
                    
                    Image(systemName: "sun.max")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                        .frame(width: 16)
                }
                
                // Tint control
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                        .frame(width: 16)
                    
                    Text("Tint")
                        .font(.system(size: 10))
                        .foregroundColor(Color(white: 0.8))
                        .frame(width: 30, alignment: .leading)
                    
                    Slider(
                        value: Binding(
                            get: { filterSettings.tint },
                            set: { newValue in
                                filterSettings.tint = newValue
                                onSettingsChanged(filterSettings)
                            }
                        ),
                        in: 0...100,
                        step: 1
                    )
                    .accentColor(MinimalDesign.Colors.accentRed)
                    
                    Text("\(Int(filterSettings.tint))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                        .frame(width: 24)
                    
                    Image(systemName: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.pink)
                        .frame(width: 16)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 140) // Same height as Preset section
        .background(Color(hex: "1a1a1a"))
    }
}

// MARK: - Preview
#if DEBUG
struct WhiteBalanceView_Previews: PreviewProvider {
    static var previews: some View {
        WhiteBalanceView(
            filterSettings: .constant(FilterSettings()),
            onSettingsChanged: { _ in }
        )
        .background(Color.black)
    }
}
#endif