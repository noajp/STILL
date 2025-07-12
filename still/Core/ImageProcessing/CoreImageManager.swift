//======================================================================
// MARK: - CoreImageManager.swift
// Purpose: Manager class for system operations (CoreImageManagerのシステム操作管理クラス)
// Path: still/Core/ImageProcessing/CoreImageManager.swift
//======================================================================
//
//  CoreImageManager.swift
//  tete
//
//  Core Image処理の中央管理クラス
//

import UIKit
@preconcurrency import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Core Image Manager
final class CoreImageManager: @unchecked Sendable {
    
    // MARK: - Singleton
    static let shared = CoreImageManager()
    
    // MARK: - Properties
    private let context: CIContext
    private let filterQueue = DispatchQueue(label: "com.tete.filterQueue", qos: .userInitiated)
    private let lutProcessor = LUTProcessor()
    
    // MARK: - Initialization
    private init() {
        // GPU優先でCIContext作成
        let options: [CIContextOption: Any] = [
            .useSoftwareRenderer: false,
            .highQualityDownsample: true,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        ]
        
        if let mtlDevice = MTLCreateSystemDefaultDevice() {
            self.context = CIContext(mtlDevice: mtlDevice, options: options)
            print("✅ CoreImageManager: Metal device initialized")
        } else {
            self.context = CIContext(options: options)
            print("⚠️ CoreImageManager: Fallback to CPU renderer")
        }
    }
    
    // MARK: - Public Methods
    
    /// UIImageからCIImageへの変換
    func createCIImage(from uiImage: UIImage) -> CIImage? {
        guard let ciImage = CIImage(image: uiImage) else {
            print("❌ Failed to create CIImage from UIImage")
            return nil
        }
        
        // 画像の向きを正規化
        let oriented = ciImage.oriented(forExifOrientation: imageOrientationToExif(uiImage.imageOrientation))
        return oriented
    }
    
    /// フィルター適用（非同期）
    func applyFilter(
        _ filterType: FilterType,
        to image: CIImage,
        intensity: Float = 1.0,
        completion: @escaping @Sendable (Result<UIImage, FilterError>) -> Void
    ) {
        filterQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // フィルター適用
                let filteredImage = try self.processImage(image, filterType: filterType, intensity: intensity)
                
                // UIImageに変換
                if let cgImage = self.context.createCGImage(filteredImage, from: filteredImage.extent) {
                    let uiImage = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        completion(.success(uiImage))
                    }
                } else {
                    throw FilterError.renderingFailed
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error as? FilterError ?? .unknown))
                }
            }
        }
    }
    
    /// 同期的なフィルター適用（プレビュー用）
    func applyFilterSync(
        _ filterType: FilterType,
        to image: CIImage,
        intensity: Float = 1.0
    ) -> CIImage? {
        do {
            return try processImage(image, filterType: filterType, intensity: intensity)
        } catch {
            print("❌ Filter application failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func processImage(
        _ inputImage: CIImage,
        filterType: FilterType,
        intensity: Float
    ) throws -> CIImage {
        
        var outputImage = inputImage
        
        switch filterType {
        case .none:
            return inputImage
            
        case .sepia:
            outputImage = applySepia(to: outputImage, intensity: intensity)
            
        case .noir:
            outputImage = applyNoir(to: outputImage, intensity: intensity)
            
        case .vintage:
            outputImage = applyVintage(to: outputImage, intensity: intensity)
            
        case .warm:
            outputImage = applyWarmth(to: outputImage, intensity: intensity)
            
        case .cool:
            outputImage = applyCool(to: outputImage, intensity: intensity)
        case .filmGrain:
            outputImage = applyFilmGrain(to: outputImage, intensity: intensity)
            
        case .lightLeak:
            outputImage = applyLightLeak(to: outputImage, intensity: intensity)
            
        case .retro:
            outputImage = applyRetro(to: outputImage, intensity: intensity)
        case .kodakPortra:
            outputImage = lutProcessor.applyLUT(to: outputImage, lutName: "kodak_portra_400", intensity: intensity) ?? outputImage
        case .fujiPro:
            outputImage = lutProcessor.applyLUT(to: outputImage, lutName: "fuji_pro_400h", intensity: intensity) ?? outputImage
        case .cinestill:
            outputImage = lutProcessor.applyLUT(to: outputImage, lutName: "cinestill_800t", intensity: intensity) ?? outputImage
        case .ilfordHP5:
            outputImage = lutProcessor.applyLUT(to: outputImage, lutName: "ilford_hp5", intensity: intensity) ?? outputImage
        case .polaroid:
            outputImage = lutProcessor.applyLUT(to: outputImage, lutName: "polaroid_600", intensity: intensity) ?? outputImage
        }
        
        return outputImage
    }
    
    // MARK: - Filter Implementations
    
    private func applySepia(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.sepiaTone()
        filter.inputImage = image
        filter.intensity = intensity
        return filter.outputImage ?? image
    }
    
    private func applyNoir(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.photoEffectNoir()
        filter.inputImage = image
        
        // intensity調整のためにブレンド
        if intensity < 1.0 {
            return blendWithOriginal(filtered: filter.outputImage ?? image, 
                                   original: image, 
                                   intensity: intensity)
        }
        
        return filter.outputImage ?? image
    }
    
    private func applyVintage(to image: CIImage, intensity: Float) -> CIImage {
        var outputImage = image
        
        // 1. 色温度調整
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = outputImage
        colorControls.saturation = 0.8
        colorControls.contrast = 1.1
        outputImage = colorControls.outputImage ?? outputImage
        
        // 2. ビネット効果
        let vignette = CIFilter.vignette()
        vignette.inputImage = outputImage
        vignette.intensity = 0.5 * intensity
        vignette.radius = 1.5
        outputImage = vignette.outputImage ?? outputImage
        
        // 3. セピア調のオーバーレイ
        let sepia = CIFilter.sepiaTone()
        sepia.inputImage = outputImage
        sepia.intensity = 0.3
        outputImage = sepia.outputImage ?? outputImage
        
        // intensity調整
        if intensity < 1.0 {
            outputImage = blendWithOriginal(filtered: outputImage, original: image, intensity: intensity)
        }
        
        return outputImage
    }
    
    private func applyWarmth(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        filter.neutral = CIVector(x: 6500, y: 0)
        filter.targetNeutral = CIVector(x: 4000 + (2500 * CGFloat(1.0 - intensity)), y: 0)
        return filter.outputImage ?? image
    }
    
    private func applyCool(to image: CIImage, intensity: Float) -> CIImage {
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        filter.neutral = CIVector(x: 6500, y: 0)
        filter.targetNeutral = CIVector(x: 6500 + (2500 * CGFloat(intensity)), y: 0)
        return filter.outputImage ?? image
    }
    
    private func applyFilmGrain(to image: CIImage, intensity: Float) -> CIImage {
        // カスタムフィルムグレインフィルターを使用
        let filmGrainFilter = FilmGrainFilter()
        filmGrainFilter.inputImage = image
        filmGrainFilter.inputIntensity = intensity
        return filmGrainFilter.outputImage ?? image
    }
    
    private func applyLightLeak(to image: CIImage, intensity: Float) -> CIImage {
        // カスタム光漏れフィルターを使用
        let lightLeakFilter = LightLeakFilter()
        lightLeakFilter.inputImage = image
        lightLeakFilter.inputIntensity = intensity
        return lightLeakFilter.outputImage ?? image
    }
    
    private func applyRetro(to image: CIImage, intensity: Float) -> CIImage {
        var outputImage = image
        
        // 1. ビンテージビネット
        let vignetteFilter = VintageVignetteFilter()
        vignetteFilter.inputImage = outputImage
        vignetteFilter.inputIntensity = intensity * 0.7
        outputImage = vignetteFilter.outputImage ?? outputImage
        
        // 2. セピア調
        let sepia = CIFilter.sepiaTone()
        sepia.inputImage = outputImage
        sepia.intensity = intensity * 0.3
        outputImage = sepia.outputImage ?? outputImage
        
        // 3. フィルムグレイン
        let grain = FilmGrainFilter()
        grain.inputImage = outputImage
        grain.inputIntensity = intensity * 0.2
        outputImage = grain.outputImage ?? outputImage
        
        return outputImage
    }
    
    // MARK: - Helper Methods
    
    private func blendWithOriginal(filtered: CIImage, original: CIImage, intensity: Float) -> CIImage {
        let blendFilter = CIFilter.sourceOverCompositing()
        
        // アルファ値を調整してブレンド
        let alphaFilter = CIFilter.colorMatrix()
        alphaFilter.inputImage = filtered
        alphaFilter.aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity))
        
        blendFilter.inputImage = alphaFilter.outputImage
        blendFilter.backgroundImage = original
        
        return blendFilter.outputImage ?? filtered
    }
    
    private func imageOrientationToExif(_ orientation: UIImage.Orientation) -> Int32 {
        switch orientation {
        case .up: return 1
        case .down: return 3
        case .left: return 8
        case .right: return 6
        case .upMirrored: return 2
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .rightMirrored: return 7
        @unknown default: return 1
        }
    }
}

// MARK: - Error Types
enum FilterError: LocalizedError {
    case imageConversionFailed
    case filterNotFound
    case renderingFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "画像の変換に失敗しました"
        case .filterNotFound:
            return "フィルターが見つかりません"
        case .renderingFailed:
            return "画像のレンダリングに失敗しました"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}
