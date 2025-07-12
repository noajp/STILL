//======================================================================
// MARK: - FilterDefinitions.swift
// Purpose: FilterDefinitions implementation (FilterDefinitionsの実装)
// Path: still/Core/ImageProcessing/FilterDefinitions.swift
//======================================================================
//
//  FilterDefinitions.swift
//  tete
//
//  フィルター定義とプリセット
//

import UIKit

// MARK: - Filter Type
enum FilterType: String, CaseIterable, Identifiable {
    case none = "オリジナル"
    case sepia = "セピア"
    case noir = "ノワール"
    case vintage = "ビンテージ"
    case warm = "ウォーム"
    case cool = "クール"
    case filmGrain = "フィルム"
    case lightLeak = "光漏れ"
    case retro = "レトロ"
    case kodakPortra = "Kodak Portra"
    case fujiPro = "Fuji Pro 400H"
    case cinestill = "CineStill 800T"
    case ilfordHP5 = "Ilford HP5"
    case polaroid = "Polaroid 600"
    
    var id: String { rawValue }
    
    // サムネイル用のプレビュー強度
    var previewIntensity: Float {
        switch self {
        case .none: return 0
        case .sepia: return 0.8
        case .noir: return 1.0
        case .vintage: return 1.0
        case .warm: return 0.7
        case .cool: return 0.7
        case .filmGrain: return 0.6
        case .lightLeak: return 0.5
        case .retro: return 0.8
        case .kodakPortra: return 1.0
        case .fujiPro: return 1.0
        case .cinestill: return 0.9
        case .ilfordHP5: return 1.0
        case .polaroid: return 0.8
        }
    }
    
    // デフォルトの適用強度
    var defaultIntensity: Float {
        switch self {
        case .none: return 0
        case .sepia: return 0.6
        case .noir: return 1.0
        case .vintage: return 0.8
        case .warm: return 0.5
        case .cool: return 0.5
        case .filmGrain: return 0.4
        case .lightLeak: return 0.3
        case .retro: return 0.7
        case .kodakPortra: return 0.8
        case .fujiPro: return 0.8
        case .cinestill: return 0.7
        case .ilfordHP5: return 1.0
        case .polaroid: return 0.6
        }
    }
    
    // 強度調整が可能かどうか
    var isAdjustable: Bool {
        switch self {
        case .none: return false
        default: return true
        }
    }
    
    // フィルターの説明
    var description: String {
        switch self {
        case .none:
            return "フィルターなし"
        case .sepia:
            return "暖かみのあるレトロな雰囲気"
        case .noir:
            return "クラシックな白黒写真"
        case .vintage:
            return "ノスタルジックな色合い"
        case .warm:
            return "暖色系の温かい印象"
        case .cool:
            return "寒色系のクールな印象"
        case .filmGrain:
            return "フィルム写真のような粒子感"
        case .lightLeak:
            return "光が漏れたような幻想的な効果"
        case .retro:
            return "80-90年代のレトロな雰囲気"
        case .kodakPortra:
            return "Kodak Portraの暖かみのある色調"
        case .fujiPro:
            return "Fuji Pro 400Hの自然な発色"
        case .cinestill:
            return "CineStill 800Tのシネマティック"
        case .ilfordHP5:
            return "Ilford HP5のクラシック白黒"
        case .polaroid:
            return "Polaroid 600の独特な色合い"
        }
    }
}

// MARK: - Filter Preset
struct FilterPreset: Identifiable {
    let id = UUID()
    let name: String
    let filterType: FilterType
    let intensity: Float
    let thumbnail: UIImage?
    
    static let defaults: [FilterPreset] = [
        FilterPreset(name: "オリジナル", filterType: .none, intensity: 0, thumbnail: nil),
        FilterPreset(name: "セピア", filterType: .sepia, intensity: 0.6, thumbnail: nil),
        FilterPreset(name: "ノワール", filterType: .noir, intensity: 1.0, thumbnail: nil),
        FilterPreset(name: "ビンテージ", filterType: .vintage, intensity: 0.8, thumbnail: nil),
        FilterPreset(name: "ウォーム", filterType: .warm, intensity: 0.5, thumbnail: nil),
        FilterPreset(name: "クール", filterType: .cool, intensity: 0.5, thumbnail: nil)
    ]
}

// MARK: - Filter State
struct FilterState {
    var filterType: FilterType = .none
    var intensity: Float = 1.0
    
    var isEdited: Bool {
        return filterType != .none
    }
}

// MARK: - Filter Processing Result
struct FilterResult {
    let originalImage: UIImage
    let filteredImage: UIImage
    let filterType: FilterType
    let intensity: Float
    let processingTime: TimeInterval
}

// MARK: - Advanced Filter System (for ProFilmFilterPack)

/// フィルター特性の詳細定義
struct FilterCharacteristics {
    let contrast: Float
    let saturation: Float
    let warmth: Float
    let grain: Float
    let vignette: Float
    let lightLeak: Float
    let filmGrain: Float
    let colorCast: Float
    
    init(contrast: Float = 1.0, saturation: Float = 1.0, warmth: Float = 0.0, 
         grain: Float = 0.0, vignette: Float = 0.0, lightLeak: Float = 0.0,
         filmGrain: Float = 0.0, colorCast: Float = 0.0) {
        self.contrast = contrast
        self.saturation = saturation
        self.warmth = warmth
        self.grain = grain
        self.vignette = vignette
        self.lightLeak = lightLeak
        self.filmGrain = filmGrain
        self.colorCast = colorCast
    }
}

/// フィルターカテゴリー
enum FilterCategory: String, CaseIterable {
    case filmEmulation = "Film Emulation"
    case modern = "Modern"
    case creative = "Creative"
    case vintage = "Vintage"
    case blackAndWhite = "Black & White"
    case cinematic = "Cinematic"
    
    var displayName: String {
        return rawValue
    }
}

/// 拡張フィルター定義
struct FilterDefinition {
    let id: String
    let name: String
    let category: FilterCategory
    let description: String
    let lutFileName: String?
    let intensity: Float
    let characteristics: FilterCharacteristics
    
    init(id: String, name: String, category: FilterCategory, description: String,
         lutFileName: String? = nil, intensity: Float = 1.0, 
         characteristics: FilterCharacteristics = FilterCharacteristics()) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.lutFileName = lutFileName
        self.intensity = intensity
        self.characteristics = characteristics
    }
}