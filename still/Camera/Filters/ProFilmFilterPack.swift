//======================================================================
// MARK: - ProFilmFilterPack
// Purpose: プロフェッショナル向け追加フィルムエミュレーション
// Features: 高品質フィルムストック、モダンデジタルルック、クリエイティブフィルター
//======================================================================

import Foundation
import CoreImage
import UIKit

struct ProFilmFilterPack {
    
    // MARK: - Professional Film Stocks
    
    static let professionalFilmStocks: [FilterDefinition] = [
        // Kodak Professional Series
        FilterDefinition(
            id: "kodak_ektar_100",
            name: "Kodak Ektar 100",
            category: .filmEmulation,
            description: "Ultra-fine grain color negative film with vivid saturation",
            lutFileName: "kodak_ektar_100.cube",
            intensity: 1.0,
            characteristics: .init(
                contrast: 1.2,
                saturation: 1.3,
                warmth: 0.1,
                grain: 0.05,
                vignette: 0.1
            )
        ),
        
        FilterDefinition(
            id: "kodak_gold_200",
            name: "Kodak Gold 200",
            category: .filmEmulation,
            description: "Warm, golden tones perfect for portraits",
            lutFileName: "kodak_gold_200.cube",
            intensity: 1.0,
            characteristics: .init(
                contrast: 1.1,
                saturation: 1.15,
                warmth: 0.3,
                grain: 0.1,
                vignette: 0.15
            )
        ),
        
        FilterDefinition(
            id: "kodak_tmax_400",
            name: "Kodak T-Max 400",
            category: .blackAndWhite,
            description: "Professional black and white with fine grain",
            lutFileName: "kodak_tmax_400.cube",
            intensity: 1.0,
            characteristics: .init(
                contrast: 1.25,
                saturation: 0.0,
                warmth: -0.1,
                grain: 0.08,
                vignette: 0.2
            )
        ),
        
        // Fujifilm Professional Series
        FilterDefinition(
            id: "fuji_velvia_50",
            name: "Fuji Velvia 50",
            category: .filmEmulation,
            description: "Ultra-saturated slide film, legendary for landscapes",
            lutFileName: "fuji_velvia_50.cube",
            intensity: 1.0,
            characteristics: .init(
                contrast: 1.4,
                saturation: 1.6,
                warmth: -0.05,
                grain: 0.03,
                vignette: 0.05
            )
        ),
        
        FilterDefinition(
            id: "fuji_provia_100f",
            name: "Fuji Provia 100F",
            category: .filmEmulation,
            description: "Natural color reproduction with excellent sharpness",
            lutFileName: "fuji_provia_100f.cube",
            intensity: 1.0,
            characteristics: .init(
                contrast: 1.15,
                saturation: 1.1,
                warmth: 0.0,
                grain: 0.04,
                vignette: 0.1
            )
        ),
        
        FilterDefinition(
            id: "fuji_superia_400",
            name: "Fuji Superia 400",
            category: .filmEmulation,
            description: "Consumer film with vibrant colors",
            lutFileName: "fuji_superia_400.cube",
            intensity: 1.0,
            characteristics: .init(
                contrast: 1.1,
                saturation: 1.25,
                warmth: 0.15,
                grain: 0.12,
                vignette: 0.18
            )
        ),
        
        // Ilford Black & White Series
        FilterDefinition(
            id: "ilford_delta_100",
            name: "Ilford Delta 100",
            category: .blackAndWhite,
            description: "Fine grain monochrome with excellent tonal range",
            lutFileName: "ilford_delta_100.cube",
            intensity: 1.0,
            characteristics: .init(
                contrast: 1.2,
                saturation: 0.0,
                warmth: -0.05,
                grain: 0.06,
                vignette: 0.15
            )
        ),
        
        FilterDefinition(
            id: "ilford_fp4_plus",
            name: "Ilford FP4 Plus",
            category: .blackAndWhite,
            description: "Classic medium speed B&W film",
            lutFileName: "ilford_fp4_plus.cube",
            intensity: 1.0,
            characteristics: .init(
                contrast: 1.15,
                saturation: 0.0,
                warmth: 0.0,
                grain: 0.09,
                vignette: 0.2
            )
        ),
        
        // Cinematic Films
        FilterDefinition(
            id: "vision3_250d",
            name: "Kodak Vision3 250D",
            category: .cinematic,
            description: "Professional cinema daylight stock",
            lutFileName: "vision3_250d.cube",
            intensity: 1.0,
            characteristics: .init(
                contrast: 1.1,
                saturation: 1.05,
                warmth: -0.1,
                grain: 0.07,
                vignette: 0.05
            )
        ),
        
        FilterDefinition(
            id: "vision3_500t",
            name: "Kodak Vision3 500T",
            category: .cinematic,
            description: "Professional cinema tungsten stock",
            lutFileName: "vision3_500t.cube",
            intensity: 1.0,
            characteristics: .init(
                contrast: 1.05,
                saturation: 1.0,
                warmth: 0.2,
                grain: 0.1,
                vignette: 0.1
            )
        )
    ]
    
    // MARK: - Modern Digital Looks
    
    static let modernDigitalLooks: [FilterDefinition] = [
        FilterDefinition(
            id: "digital_teal_orange",
            name: "Teal & Orange",
            category: .modern,
            description: "Modern cinematic color grading",
            lutFileName: "teal_orange.cube",
            intensity: 0.8,
            characteristics: .init(
                contrast: 1.15,
                saturation: 1.2,
                warmth: 0.1,
                grain: 0.0,
                vignette: 0.1
            )
        ),
        
        FilterDefinition(
            id: "digital_bleach_bypass",
            name: "Bleach Bypass",
            category: .creative,
            description: "High contrast desaturated look",
            lutFileName: "bleach_bypass.cube",
            intensity: 0.9,
            characteristics: .init(
                contrast: 1.5,
                saturation: 0.3,
                warmth: -0.1,
                grain: 0.0,
                vignette: 0.15
            )
        ),
        
        FilterDefinition(
            id: "digital_cross_process",
            name: "Cross Process",
            category: .creative,
            description: "Experimental color shifts",
            lutFileName: "cross_process.cube",
            intensity: 0.85,
            characteristics: .init(
                contrast: 1.3,
                saturation: 1.4,
                warmth: 0.15,
                grain: 0.05,
                vignette: 0.2
            )
        ),
        
        FilterDefinition(
            id: "digital_cyberpunk",
            name: "Cyberpunk",
            category: .creative,
            description: "Neon-enhanced futuristic look",
            lutFileName: "cyberpunk.cube",
            intensity: 0.9,
            characteristics: .init(
                contrast: 1.25,
                saturation: 1.5,
                warmth: -0.2,
                grain: 0.03,
                vignette: 0.25
            )
        ),
        
        FilterDefinition(
            id: "digital_moody_dark",
            name: "Moody Dark",
            category: .modern,
            description: "Dark, atmospheric look",
            lutFileName: "moody_dark.cube",
            intensity: 0.95,
            characteristics: .init(
                contrast: 1.4,
                saturation: 0.8,
                warmth: -0.15,
                grain: 0.08,
                vignette: 0.3
            )
        ),
        
        FilterDefinition(
            id: "digital_golden_hour",
            name: "Golden Hour",
            category: .modern,
            description: "Warm, glowing sunset look",
            lutFileName: "golden_hour.cube",
            intensity: 0.8,
            characteristics: .init(
                contrast: 1.1,
                saturation: 1.15,
                warmth: 0.4,
                grain: 0.02,
                vignette: 0.15
            )
        )
    ]
    
    // MARK: - Vintage & Retro Looks
    
    static let vintageRetroLooks: [FilterDefinition] = [
        FilterDefinition(
            id: "vintage_polaroid_sx70",
            name: "Polaroid SX-70",
            category: .vintage,
            description: "Classic instant photography look",
            lutFileName: "polaroid_sx70.cube",
            intensity: 0.9,
            characteristics: .init(
                contrast: 0.9,
                saturation: 1.3,
                warmth: 0.25,
                grain: 0.15,
                vignette: 0.3
            )
        ),
        
        FilterDefinition(
            id: "vintage_lomography",
            name: "Lomography",
            category: .vintage,
            description: "Soviet-era camera aesthetic",
            lutFileName: "lomography.cube",
            intensity: 0.85,
            characteristics: .init(
                contrast: 1.3,
                saturation: 1.4,
                warmth: 0.2,
                grain: 0.2,
                vignette: 0.4
            )
        ),
        
        FilterDefinition(
            id: "vintage_kodachrome_64",
            name: "Kodachrome 64",
            category: .vintage,
            description: "Legendary slide film from the 70s",
            lutFileName: "kodachrome_64.cube",
            intensity: 1.0,
            characteristics: .init(
                contrast: 1.25,
                saturation: 1.35,
                warmth: 0.1,
                grain: 0.08,
                vignette: 0.2
            )
        ),
        
        FilterDefinition(
            id: "vintage_agfa_vista",
            name: "Agfa Vista",
            category: .vintage,
            description: "European color film with unique tones",
            lutFileName: "agfa_vista.cube",
            intensity: 0.9,
            characteristics: .init(
                contrast: 1.15,
                saturation: 1.2,
                warmth: 0.05,
                grain: 0.12,
                vignette: 0.25
            )
        ),
        
        FilterDefinition(
            id: "vintage_super8",
            name: "Super 8mm",
            category: .vintage,
            description: "Home movie film aesthetic",
            lutFileName: "super8.cube",
            intensity: 0.8,
            characteristics: .init(
                contrast: 0.95,
                saturation: 1.1,
                warmth: 0.3,
                grain: 0.25,
                vignette: 0.35
            )
        )
    ]
    
    // MARK: - All Professional Filters
    
    static var allProFilters: [FilterDefinition] {
        return professionalFilmStocks + modernDigitalLooks + vintageRetroLooks
    }
    
    // MARK: - Filter Categories
    
    enum ProFilterCategory: String, CaseIterable {
        case filmEmulation = "Film Emulation"
        case modern = "Modern Digital"
        case creative = "Creative"
        case vintage = "Vintage & Retro"
        case blackAndWhite = "B&W"
        case cinematic = "Cinematic"
        
        var filters: [FilterDefinition] {
            switch self {
            case .filmEmulation:
                return professionalFilmStocks.filter { $0.category == .filmEmulation }
            case .modern:
                return modernDigitalLooks.filter { $0.category == .modern }
            case .creative:
                return modernDigitalLooks.filter { $0.category == .creative }
            case .vintage:
                return vintageRetroLooks
            case .blackAndWhite:
                return professionalFilmStocks.filter { $0.category == .blackAndWhite }
            case .cinematic:
                return professionalFilmStocks.filter { $0.category == .cinematic }
            }
        }
        
        var icon: String {
            switch self {
            case .filmEmulation: return "camera.fill"
            case .modern: return "sparkles"
            case .creative: return "paintbrush.fill"
            case .vintage: return "camera.vintage"
            case .blackAndWhite: return "circle.lefthalf.filled"
            case .cinematic: return "film.fill"
            }
        }
        
        var description: String {
            switch self {
            case .filmEmulation:
                return "Professional film stock emulations"
            case .modern:
                return "Contemporary digital looks"
            case .creative:
                return "Artistic and experimental styles"
            case .vintage:
                return "Classic analog aesthetics"
            case .blackAndWhite:
                return "Monochrome film stocks"
            case .cinematic:
                return "Motion picture film emulations"
            }
        }
    }
}

// MARK: - Filter Characteristics Extension

extension FilterCharacteristics {
    init(contrast: Float, saturation: Float, warmth: Float, grain: Float, vignette: Float) {
        self.contrast = contrast
        self.saturation = saturation
        self.warmth = warmth
        self.grain = grain
        self.vignette = vignette
        self.lightLeak = 0.0
        self.filmGrain = grain
        self.colorCast = warmth
    }
}

// MARK: - Custom Filter Processor

class ProFilmProcessor {
    
    private let context = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3) as Any,
        .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any
    ])
    
    // MARK: - Advanced Film Grain
    
    func applyAdvancedFilmGrain(_ image: CIImage, intensity: Float, filmType: String) -> CIImage {
        guard CIFilter(name: "CIColorMonochrome") != nil else { return image }
        
        // Generate film-specific grain pattern
        let grainTexture = generateFilmGrainTexture(for: filmType, size: image.extent.size)
        
        guard let blendFilter = CIFilter(name: "CIOverlayBlendMode") else { return image }
        blendFilter.setValue(image, forKey: kCIInputImageKey)
        blendFilter.setValue(grainTexture, forKey: kCIInputBackgroundImageKey)
        
        guard let grainedImage = blendFilter.outputImage else { return image }
        
        // Blend with original based on intensity
        guard let mixFilter = CIFilter(name: "CISourceOverCompositing") else { return grainedImage }
        mixFilter.setValue(grainedImage, forKey: kCIInputImageKey)
        mixFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return mixFilter.outputImage ?? image
    }
    
    // MARK: - Professional Color Grading
    
    func applyColorGrading(_ image: CIImage, characteristics: FilterCharacteristics) -> CIImage {
        var result = image
        
        // Shadows/Highlights adjustment
        if let shadowHighlightFilter = CIFilter(name: "CIHighlightShadowAdjust") {
            shadowHighlightFilter.setValue(result, forKey: kCIInputImageKey)
            shadowHighlightFilter.setValue(0.5 + characteristics.warmth * 0.3, forKey: "inputHighlightAmount")
            shadowHighlightFilter.setValue(0.5 - characteristics.warmth * 0.2, forKey: "inputShadowAmount")
            result = shadowHighlightFilter.outputImage ?? result
        }
        
        // Color curves adjustment
        if let curvesFilter = CIFilter(name: "CIToneCurve") {
            curvesFilter.setValue(result, forKey: kCIInputImageKey)
            
            // Film-like curve points
            let point0 = CIVector(x: 0, y: 0)
            let point1 = CIVector(x: 0.25, y: 0.2 + CGFloat(characteristics.contrast) * 0.05)
            let point2 = CIVector(x: 0.5, y: 0.5)
            let point3 = CIVector(x: 0.75, y: 0.8 - CGFloat(characteristics.contrast) * 0.05)
            let point4 = CIVector(x: 1, y: 1)
            
            curvesFilter.setValue(point0, forKey: "inputPoint0")
            curvesFilter.setValue(point1, forKey: "inputPoint1")
            curvesFilter.setValue(point2, forKey: "inputPoint2")
            curvesFilter.setValue(point3, forKey: "inputPoint3")
            curvesFilter.setValue(point4, forKey: "inputPoint4")
            
            result = curvesFilter.outputImage ?? result
        }
        
        return result
    }
    
    // MARK: - Helper Methods
    
    private func generateFilmGrainTexture(for filmType: String, size: CGSize) -> CIImage {
        // Generate noise based on film characteristics
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator") else {
            return CIImage.empty()
        }
        
        guard let noiseImage = noiseFilter.outputImage else {
            return CIImage.empty()
        }
        
        // Crop and scale noise to image size
        let croppedNoise = noiseImage.cropped(to: CGRect(origin: .zero, size: size))
        
        // Apply film-specific grain characteristics
        guard let grainFilter = CIFilter(name: "CIColorMatrix") else { return croppedNoise }
        grainFilter.setValue(croppedNoise, forKey: kCIInputImageKey)
        
        // Adjust grain characteristics based on film type
        let grainIntensity = getGrainIntensityForFilm(filmType)
        let rVector = CIVector(x: grainIntensity, y: 0, z: 0, w: 0)
        let gVector = CIVector(x: 0, y: grainIntensity, z: 0, w: 0)
        let bVector = CIVector(x: 0, y: 0, z: grainIntensity, w: 0)
        let aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        
        grainFilter.setValue(rVector, forKey: "inputRVector")
        grainFilter.setValue(gVector, forKey: "inputGVector")
        grainFilter.setValue(bVector, forKey: "inputBVector")
        grainFilter.setValue(aVector, forKey: "inputAVector")
        
        return grainFilter.outputImage ?? croppedNoise
    }
    
    private func getGrainIntensityForFilm(_ filmType: String) -> CGFloat {
        switch filmType {
        case "kodak_tmax_400", "ilford_delta_100":
            return 0.02 // Fine grain B&W
        case "kodak_ektar_100", "fuji_velvia_50":
            return 0.01 // Very fine grain
        case "kodak_gold_200", "fuji_superia_400":
            return 0.05 // Medium grain
        case "polaroid_sx70", "super8":
            return 0.15 // Heavy grain
        default:
            return 0.03 // Default grain
        }
    }
}