//======================================================================
// MARK: - PresetModels.swift
// Purpose: Data models and structures (PresetModelsのデータモデルと構造)
// Path: still/Features/PhotoEditor/Models/PresetModels.swift
//======================================================================
//
//  PresetModels.swift
//  tete
//
//  プリセット関連のデータモデル
//

import SwiftUI

// MARK: - Preset Category
enum PresetCategory: String, CaseIterable {
    case light = "LIGHT"
    case color = "COLOR"
    case custom = "CUSTOM"
    
    var icon: String {
        switch self {
        case .light:
            return "sun.max"
        case .color:
            return "paintpalette"
        case .custom:
            return "folder"
        }
    }
}

// MARK: - Preset Type
enum PresetType: String, CaseIterable {
    case none = "-"
    // Base Presets - 基本的な露出・コントラスト調整
    case natural = "Natural"
    case bright = "Bright"
    case dark = "Dark"
    case highContrast = "High Contrast"
    // Color Presets - 色調・雰囲気調整
    case warm = "Warm"
    case cool = "Cool"
    case vintage = "Vintage"
    case dramatic = "Dramatic"
    // Custom CUBE presets
    case custom = "Custom"
    
    var color: Color? {
        switch self {
        case .none:
            return nil
        // Base Presets - グレー系
        case .natural, .bright, .dark, .highContrast:
            return Color(white: 0.7)
        // Color Presets - カラー系
        case .warm:
            return Color(red: 255/255, green: 180/255, blue: 120/255) // オレンジ
        case .cool:
            return Color(red: 120/255, green: 180/255, blue: 255/255) // ブルー
        case .vintage:
            return Color(red: 210/255, green: 180/255, blue: 140/255) // セピア
        case .dramatic:
            return Color(red: 180/255, green: 120/255, blue: 180/255) // パープル
        case .custom:
            return Color(red: 255/255, green: 215/255, blue: 0/255) // ゴールド
        }
    }
    
    var filterSettings: FilterSettings {
        switch self {
        case .none:
            return FilterSettings()
        // Base Presets
        case .natural:
            return FilterSettings(
                brightness: 0.0,
                contrast: 1.0,
                saturation: 1.0,
                temperature: 6500,
                tint: 0
            )
        case .bright:
            return FilterSettings(
                brightness: 0.2,
                contrast: 1.1,
                saturation: 1.05,
                temperature: 6500,
                tint: 0,
                highlights: -10,
                shadows: 15
            )
        case .dark:
            return FilterSettings(
                brightness: -0.15,
                contrast: 1.2,
                saturation: 0.95,
                temperature: 6500,
                tint: 0,
                highlights: 10,
                shadows: -20
            )
        case .highContrast:
            return FilterSettings(
                brightness: 0.0,
                contrast: 1.4,
                saturation: 1.1,
                temperature: 6500,
                tint: 0,
                whites: 20,
                blacks: -15
            )
        // Color Presets
        case .warm:
            return FilterSettings(
                brightness: 0.05,
                contrast: 1.1,
                saturation: 1.15,
                temperature: 4800,
                tint: 10
            )
        case .cool:
            return FilterSettings(
                brightness: 0.0,
                contrast: 1.05,
                saturation: 1.1,
                temperature: 7500,
                tint: -8
            )
        case .vintage:
            return FilterSettings(
                brightness: -0.05,
                contrast: 1.15,
                saturation: 0.85,
                temperature: 4200,
                tint: 15,
                highlights: -20,
                shadows: 10
            )
        case .dramatic:
            return FilterSettings(
                brightness: -0.1,
                contrast: 1.3,
                saturation: 1.2,
                temperature: 5800,
                tint: -5,
                highlights: -25,
                shadows: 20,
                clarity: 15
            )
        case .custom:
            return FilterSettings() // Custom presets use CUBE files instead
        }
    }
    
    var category: PresetCategory {
        switch self {
        case .none, .natural, .bright, .dark, .highContrast:
            return .light
        case .warm, .cool, .vintage, .dramatic:
            return .color
        case .custom:
            return .custom
        }
    }
}

// MARK: - Filter Settings
struct FilterSettings {
    var brightness: Float = 50      // 0-100, center at 50
    var contrast: Float = 50        // 0-100, center at 50
    var saturation: Float = 50      // 0-100, center at 50
    var temperature: Float = 50     // 0-100, center at 50
    var tint: Float = 50           // 0-100, center at 50
    var highlights: Float = 50      // 0-100, center at 50
    var shadows: Float = 50         // 0-100, center at 50
    var whites: Float = 50          // 0-100, center at 50
    var blacks: Float = 50          // 0-100, center at 50
    var clarity: Float = 50         // 0-100, center at 50
}

// MARK: - Adjustment Parameter
enum AdjustmentParameter: String, CaseIterable {
    case brightness = "Brightness"
    case highlights = "Highlights"
    case shadows = "Shadows"
    case whites = "Whites"
    case blacks = "Blacks"
    case contrast = "Contrast"
    case clarity = "Clarity"
    
    var range: ClosedRange<Float> {
        return 0...100  // Unified range for all parameters
    }
    
    var defaultValue: Float {
        return 50  // Center value for 0-100 range
    }
    
    var icon: String {
        switch self {
        case .brightness:
            return "sun.max"
        case .highlights:
            return "light.max"
        case .shadows:
            return "light.min"
        case .whites:
            return "circle.fill"
        case .blacks:
            return "circle"
        case .contrast:
            return "circle.lefthalf.filled"
        case .clarity:
            return "sparkles"
        }
    }
}

// MARK: - Tone Curve Point
struct ToneCurvePoint {
    var input: Float
    var output: Float
    
    init(input: Float, output: Float) {
        self.input = max(0, min(1, input))
        self.output = max(0, min(1, output))
    }
}

// MARK: - Tone Curve
struct ToneCurve {
    var points: [ToneCurvePoint]
    
    init() {
        // デフォルトの直線カーブ
        self.points = [
            ToneCurvePoint(input: 0, output: 0),
            ToneCurvePoint(input: 0.25, output: 0.25),
            ToneCurvePoint(input: 0.5, output: 0.5),
            ToneCurvePoint(input: 0.75, output: 0.75),
            ToneCurvePoint(input: 1, output: 1)
        ]
    }
    
    func interpolate(at input: Float) -> Float {
        let clampedInput = max(0, min(1, input))
        
        // 最初の点より小さい場合
        if clampedInput <= points.first?.input ?? 0 {
            return points.first?.output ?? 0
        }
        
        // 最後の点より大きい場合
        if clampedInput >= points.last?.input ?? 1 {
            return points.last?.output ?? 1
        }
        
        // 二つの点の間で補間
        for i in 0..<points.count-1 {
            let p1 = points[i]
            let p2 = points[i+1]
            
            if clampedInput >= p1.input && clampedInput <= p2.input {
                let t = (clampedInput - p1.input) / (p2.input - p1.input)
                return p1.output + t * (p2.output - p1.output)
            }
        }
        
        return clampedInput
    }
}

// MARK: - Preset Model
struct Preset: Identifiable {
    let id = UUID()
    let type: PresetType
    let thumbnail: UIImage?
    let customPreset: CustomPreset?
    var isFavorite: Bool = false
    var usageCount: Int = 0
    
    init(type: PresetType, thumbnail: UIImage? = nil, customPreset: CustomPreset? = nil) {
        self.type = type
        self.thumbnail = thumbnail
        self.customPreset = customPreset
    }
}

// MARK: - Editor Tab
enum EditorTab: String, CaseIterable {
    case wb = "WB"
    case preset = "COLOR"
    case edit = "EDIT"
    case angle = "ANGLE"
    
    var icon: String {
        switch self {
        case .wb:
            return "thermometer"
        case .preset:
            return "film.fill"  // Film negative icon
        case .edit:
            return "slider.horizontal.3"  // Toolbar-like icon with sliders
        case .angle:
            return "crop.rotate"  // Right angle rotation icon
        }
    }
    
    var title: String {
        switch self {
        case .wb:
            return "WB"
        case .preset:
            return "COLOR"
        case .edit:
            return "EDIT"
        case .angle:
            return "ANGLE"
        }
    }
}