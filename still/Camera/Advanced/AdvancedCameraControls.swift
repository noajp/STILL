//======================================================================
// MARK: - AdvancedCameraControls
// Purpose: プロフェッショナル向けマニュアルカメラコントロール
// Features: ISO、シャッタースピード、ホワイトバランス、フォーカス制御
//======================================================================

import SwiftUI
import AVFoundation

struct AdvancedCameraControls: View {
    @StateObject private var cameraViewModel = CustomCameraViewModel()
    @State private var showingManualControls = false
    @State private var manualISO: Float = 400
    @State private var manualShutterSpeed: Float = 60 // 1/60秒
    @State private var manualWhiteBalance: Float = 5600 // Kelvin
    @State private var manualFocus: Float = 0.5 // 0.0-1.0
    @State private var isManualMode = false
    
    // 設定可能な範囲
    private let isoRange: ClosedRange<Float> = 25...6400
    private let shutterSpeedRange: ClosedRange<Float> = 4000...1 // 1/4000 - 1/1
    private let whiteBalanceRange: ClosedRange<Float> = 2000...8000
    private let focusRange: ClosedRange<Float> = 0.0...1.0
    
    var body: some View {
        VStack(spacing: 0) {
            // メインカメラビュー
            CustomCameraView { image in
                // Photo taken callback - implement as needed
            }
            
            // 高度なコントロールUI
            if showingManualControls {
                advancedControlsPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // コントロールツールバー
            controlToolbar
        }
        .animation(.easeInOut(duration: 0.3), value: showingManualControls)
    }
    
    // MARK: - Advanced Controls Panel
    
    private var advancedControlsPanel: some View {
        VStack(spacing: 16) {
            // モード切替
            HStack {
                Text("マニュアルモード")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $isManualMode)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: isManualMode) { oldValue, newValue in
                        toggleManualMode(newValue)
                    }
            }
            .padding(.horizontal)
            
            if isManualMode {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        // ISO制御
                        ManualControlSlider(
                            title: "ISO",
                            value: $manualISO,
                            range: isoRange,
                            displayValue: String(format: "%.0f", manualISO),
                            onValueChanged: { value in
                                setManualISO(value)
                            }
                        )
                        
                        // シャッタースピード制御
                        ManualControlSlider(
                            title: "SS",
                            value: $manualShutterSpeed,
                            range: shutterSpeedRange,
                            displayValue: "1/\(String(format: "%.0f", manualShutterSpeed))",
                            isLogarithmic: true,
                            onValueChanged: { value in
                                setManualShutterSpeed(value)
                            }
                        )
                        
                        // ホワイトバランス制御
                        ManualControlSlider(
                            title: "WB",
                            value: $manualWhiteBalance,
                            range: whiteBalanceRange,
                            displayValue: "\(String(format: "%.0f", manualWhiteBalance))K",
                            onValueChanged: { value in
                                setManualWhiteBalance(value)
                            }
                        )
                        
                        // フォーカス制御
                        ManualControlSlider(
                            title: "Focus",
                            value: $manualFocus,
                            range: focusRange,
                            displayValue: String(format: "%.1f", manualFocus),
                            onValueChanged: { value in
                                setManualFocus(value)
                            }
                        )
                    }
                    .padding(.horizontal)
                }
                
                // プリセットボタン
                presetButtons
            }
        }
        .padding(.vertical)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.9), Color.black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    // MARK: - Control Toolbar
    
    private var controlToolbar: some View {
        HStack {
            // Auto/Manual表示
            Button(action: {
                withAnimation {
                    showingManualControls.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isManualMode ? "m.circle.fill" : "a.circle.fill")
                        .font(.title2)
                        .foregroundColor(isManualMode ? .yellow : .green)
                    
                    Text(isManualMode ? "Manual" : "Auto")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // 露出補正表示
            if !isManualMode {
                ExposureCompensationControl(cameraViewModel: cameraViewModel)
            }
            
            Spacer()
            
            // カメラ設定メニュー
            Menu {
                Button("RAW + JPEG") {
                    toggleRAWCapture()
                }
                
                Button("ヒストグラム表示") {
                    toggleHistogramDisplay()
                }
                
                Button("グリッド表示") {
                    toggleGridDisplay()
                }
                
                Button("レベルメーター") {
                    toggleLevelMeter()
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Preset Buttons
    
    private var presetButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                PresetButton(title: "Portrait", icon: "person.fill") {
                    applyPortraitPreset()
                }
                
                PresetButton(title: "Landscape", icon: "mountain.2.fill") {
                    applyLandscapePreset()
                }
                
                PresetButton(title: "Night", icon: "moon.fill") {
                    applyNightPreset()
                }
                
                PresetButton(title: "Sport", icon: "figure.run") {
                    applySportPreset()
                }
                
                PresetButton(title: "Macro", icon: "magnifyingglass") {
                    applyMacroPreset()
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Manual Control Functions
    
    private func toggleManualMode(_ enabled: Bool) {
        cameraViewModel.setManualMode(enabled)
        
        if enabled {
            // 現在の自動設定値を取得してマニュアル値として設定
            getCurrentCameraSettings()
        }
    }
    
    private func getCurrentCameraSettings() {
        cameraViewModel.getCurrentCameraSettings()
        
        // Update local values from viewModel
        manualISO = cameraViewModel.manualISO
        manualShutterSpeed = cameraViewModel.manualShutterSpeed
        manualWhiteBalance = cameraViewModel.manualWhiteBalance
        manualFocus = cameraViewModel.manualFocus
    }
    
    private func setManualISO(_ iso: Float) {
        cameraViewModel.setManualISO(iso)
    }
    
    private func setManualShutterSpeed(_ shutterSpeed: Float) {
        cameraViewModel.setManualShutterSpeed(shutterSpeed)
    }
    
    private func setManualWhiteBalance(_ kelvin: Float) {
        cameraViewModel.setManualWhiteBalance(kelvin)
    }
    
    private func setManualFocus(_ focus: Float) {
        cameraViewModel.setManualFocus(focus)
    }
    
    // MARK: - Preset Functions
    
    private func applyPortraitPreset() {
        manualISO = 200
        manualShutterSpeed = 125
        manualWhiteBalance = 5600
        manualFocus = 0.8
        applyCurrentSettings()
    }
    
    private func applyLandscapePreset() {
        manualISO = 100
        manualShutterSpeed = 250
        manualWhiteBalance = 6500
        manualFocus = 0.0 // Infinity
        applyCurrentSettings()
    }
    
    private func applyNightPreset() {
        manualISO = 1600
        manualShutterSpeed = 30
        manualWhiteBalance = 4000
        manualFocus = 0.3
        applyCurrentSettings()
    }
    
    private func applySportPreset() {
        manualISO = 800
        manualShutterSpeed = 1000
        manualWhiteBalance = 5600
        manualFocus = 0.6
        applyCurrentSettings()
    }
    
    private func applyMacroPreset() {
        manualISO = 400
        manualShutterSpeed = 200
        manualWhiteBalance = 5600
        manualFocus = 0.9
        applyCurrentSettings()
    }
    
    private func applyCurrentSettings() {
        setManualISO(manualISO)
        setManualShutterSpeed(manualShutterSpeed)
        setManualWhiteBalance(manualWhiteBalance)
        setManualFocus(manualFocus)
    }
    
    // MARK: - Utility Functions
    
    private func calculateKelvinFromGains(_ gains: AVCaptureDevice.WhiteBalanceGains) -> Float {
        // Simple approximation - in practice, this would use a proper color temperature calculation
        let ratio = gains.blueGain / gains.redGain
        return 2000 + (ratio * 3000) // Rough approximation
    }
    
    private func calculateGainsFromKelvin(_ kelvin: Float) -> AVCaptureDevice.WhiteBalanceGains {
        // Simple approximation for demo - would need proper color science
        let normalized = (kelvin - 2000) / 6000 // 0.0 to 1.0
        let redGain: Float = 1.0 + (normalized * 0.5)
        let greenGain: Float = 1.0
        let blueGain: Float = 1.0 + ((1.0 - normalized) * 0.5)
        
        return AVCaptureDevice.WhiteBalanceGains(redGain: redGain, greenGain: greenGain, blueGain: blueGain)
    }
    
    private func toggleRAWCapture() {
        // RAW capture toggle - placeholder for future implementation
        print("RAW capture toggle requested")
    }
    
    private func toggleHistogramDisplay() {
        // Histogram display toggle - placeholder for future implementation
        print("Histogram display toggle requested")
    }
    
    private func toggleGridDisplay() {
        // Grid display toggle - placeholder for future implementation
        print("Grid display toggle requested")
    }
    
    private func toggleLevelMeter() {
        // Level meter toggle - placeholder for future implementation
        print("Level meter toggle requested")
    }
}

// MARK: - Manual Control Slider

struct ManualControlSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let displayValue: String
    var isLogarithmic: Bool = false
    let onValueChanged: (Float) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            Text(displayValue)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(minWidth: 60)
            
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { isLogarithmic ? log(value) : value },
                        set: { newValue in
                            let actualValue = isLogarithmic ? exp(newValue) : newValue
                            value = actualValue.clamped(to: range)
                            onValueChanged(value)
                        }
                    ),
                    in: isLogarithmic ? log(range.lowerBound)...log(range.upperBound) : range.lowerBound...range.upperBound
                )
                .frame(width: 80, height: 120)
                .rotationEffect(.degrees(-90))
                .accentColor(.blue)
                
                // Range indicators
                VStack {
                    Text(formatRangeValue(range.upperBound))
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(formatRangeValue(range.lowerBound))
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                }
                .frame(height: 120)
            }
        }
        .frame(width: 100)
    }
    
    private func formatRangeValue(_ value: Float) -> String {
        if title == "SS" {
            return "1/\(String(format: "%.0f", value))"
        } else if title == "WB" {
            return "\(String(format: "%.0f", value))K"
        } else {
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 50)
            .background(Color.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Exposure Compensation Control

struct ExposureCompensationControl: View {
    @ObservedObject var cameraViewModel: CustomCameraViewModel
    @State private var exposureValue: Float = 0.0
    
    var body: some View {
        VStack(spacing: 4) {
            Text("EV")
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text(String(format: "%+.1f", exposureValue))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Slider(value: $exposureValue, in: -2.0...2.0, step: 0.1)
                .frame(width: 80)
                .accentColor(.orange)
                .onChange(of: exposureValue) { oldValue, newValue in
                    cameraViewModel.setExposureCompensation(newValue)
                }
        }
    }
}

// MARK: - Float Extension

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}