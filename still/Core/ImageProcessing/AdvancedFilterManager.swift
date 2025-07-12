//======================================================================
// MARK: - AdvancedFilterManager.swift
// Purpose: Manager class for system operations (AdvancedFilterManagerのシステム操作管理クラス)
// Path: still/Core/ImageProcessing/AdvancedFilterManager.swift
//======================================================================
//
//  AdvancedFilterManager.swift
//  tete
//
//  高度なフィルター管理とリアルタイム処理
//

import UIKit
import CoreImage
import Metal
import MetalPerformanceShaders

// MARK: - Advanced Filter Manager
final class AdvancedFilterManager {
    
    // MARK: - Properties
    private let device: MTLDevice
    private let library: MTLLibrary?
    private var kernelCache: [String: CIKernel] = [:]
    private var filterCache: [String: CIFilter] = [:]
    private let lutProcessor = LUTProcessor()
    
    // MARK: - Initialization
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }
        self.device = device
        self.library = device.makeDefaultLibrary()
        
        // カスタムカーネルを事前ロード
        loadCustomKernels()
    }
    
    // MARK: - Real-time Filter Application
    
    /// リアルタイム用の軽量フィルター適用
    func applyFilterRealtime(_ filterType: FilterType, to image: CIImage, intensity: Float) -> CIImage {
        // キャッシュチェック（将来の実装用）
        let _ = "\(filterType.rawValue)_\(intensity)"
        
        switch filterType {
        case .none:
            return image
            
        case .sepia:
            return applyFastSepia(to: image, intensity: intensity)
            
        case .noir:
            return applyFastNoir(to: image, intensity: intensity)
            
        case .vintage:
            return applyFastVintage(to: image, intensity: intensity)
            
        case .warm:
            return applyFastWarmth(to: image, intensity: intensity)
            
        case .cool:
            return applyFastCool(to: image, intensity: intensity)
        case .filmGrain:
            return applyFastFilmGrain(to: image, intensity: intensity)
        case .lightLeak:
            return applyFastLightLeak(to: image, intensity: intensity)
        case .retro:
            return applyFastRetro(to: image, intensity: intensity)
        case .kodakPortra:
            return applyLUT(to: image, lutName: "kodak_portra_400", intensity: intensity)
        case .fujiPro:
            return applyLUT(to: image, lutName: "fuji_pro_400h", intensity: intensity)
        case .cinestill:
            return applyLUT(to: image, lutName: "cinestill_800t", intensity: intensity)
        case .ilfordHP5:
            return applyLUT(to: image, lutName: "ilford_hp5", intensity: intensity)
        case .polaroid:
            return applyLUT(to: image, lutName: "polaroid_600", intensity: intensity)
        }
    }
    
    // MARK: - Fast Filter Implementations
    
    private func applyFastSepia(to image: CIImage, intensity: Float) -> CIImage {
        if let filter = filterCache["sepia"] {
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(intensity, forKey: kCIInputIntensityKey)
            return filter.outputImage ?? image
        }
        
        let filter = CIFilter(name: "CISepiaTone")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        filterCache["sepia"] = filter
        
        return filter.outputImage ?? image
    }
    
    private func applyFastNoir(to image: CIImage, intensity: Float) -> CIImage {
        if let filter = filterCache["noir"] {
            filter.setValue(image, forKey: kCIInputImageKey)
            return filter.outputImage ?? image
        }
        
        let filter = CIFilter(name: "CIPhotoEffectNoir")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filterCache["noir"] = filter
        
        return filter.outputImage ?? image
    }
    
    private func applyFastVintage(to image: CIImage, intensity: Float) -> CIImage {
        // シンプルなビンテージエフェクト（リアルタイム用）
        var outputImage = image
        
        // 色温度調整のみ
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            filter.setValue(0.9, forKey: "inputSaturation")
            filter.setValue(1.05, forKey: "inputContrast")
            outputImage = filter.outputImage ?? outputImage
        }
        
        return outputImage
    }
    
    private func applyFastWarmth(to image: CIImage, intensity: Float) -> CIImage {
        if let filter = filterCache["warm"] {
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            filter.setValue(CIVector(x: CGFloat(5000 - 1000 * intensity), y: 0), forKey: "inputTargetNeutral")
            return filter.outputImage ?? image
        }
        
        let filter = CIFilter(name: "CITemperatureAndTint")!
        filterCache["warm"] = filter
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
        filter.setValue(CIVector(x: CGFloat(5000 - 1000 * intensity), y: 0), forKey: "inputTargetNeutral")
        
        return filter.outputImage ?? image
    }
    
    private func applyFastCool(to image: CIImage, intensity: Float) -> CIImage {
        if let filter = filterCache["cool"] {
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            filter.setValue(CIVector(x: CGFloat(7500 + 1000 * intensity), y: 0), forKey: "inputTargetNeutral")
            return filter.outputImage ?? image
        }
        
        let filter = CIFilter(name: "CITemperatureAndTint")!
        filterCache["cool"] = filter
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
        filter.setValue(CIVector(x: CGFloat(7500 + 1000 * intensity), y: 0), forKey: "inputTargetNeutral")
        
        return filter.outputImage ?? image
    }
    
    private func applyFastFilmGrain(to image: CIImage, intensity: Float) -> CIImage {
        // 軽量版のフィルムグレイン（リアルタイム用）
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(1.0 + (intensity * 0.1), forKey: "inputContrast")
            return filter.outputImage ?? image
        }
        return image
    }
    
    private func applyFastLightLeak(to image: CIImage, intensity: Float) -> CIImage {
        // 軽量版の光漏れエフェクト
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(1.0 + (intensity * 0.2), forKey: "inputBrightness")
            filter.setValue(1.1, forKey: "inputSaturation")
            return filter.outputImage ?? image
        }
        return image
    }
    
    private func applyFastRetro(to image: CIImage, intensity: Float) -> CIImage {
        // 軽量版のレトロエフェクト
        var outputImage = image
        
        // セピア調 + 彩度調整
        if let filter = CIFilter(name: "CISepiaTone") {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            filter.setValue(intensity * 0.4, forKey: kCIInputIntensityKey)
            outputImage = filter.outputImage ?? outputImage
        }
        
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            filter.setValue(0.9, forKey: "inputSaturation")
            filter.setValue(1.05, forKey: "inputContrast")
            outputImage = filter.outputImage ?? outputImage
        }
        
        return outputImage
    }
    
    // MARK: - LUT Application
    
    private func applyLUT(to image: CIImage, lutName: String, intensity: Float) -> CIImage {
        return lutProcessor.applyLUT(to: image, lutName: lutName, intensity: intensity) ?? image
    }
    
    // MARK: - Custom Kernel Loading
    
    private func loadCustomKernels() {
        // カスタムMetalカーネルの読み込み（後で実装）
    }
}

// MARK: - Advanced Filter Types
extension FilterType {
    static let advancedFilters: [FilterType] = [
        // 将来の高度なフィルター用
    ]
}
