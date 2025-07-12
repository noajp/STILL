//======================================================================
// MARK: - UnifiedImageProcessor
// Purpose: 統合画像処理エンジン（CoreImageManager + AdvancedFilterManager統合版）
// Features: 最適化されたメモリ使用、単一CIContext、効率的なフィルターパイプライン
//======================================================================

import UIKit
@preconcurrency import CoreImage
import CoreImage.CIFilterBuiltins
import Metal
import MetalPerformanceShaders

// MARK: - Filter Operation Protocol
protocol FilterOperation: Sendable {
    func apply(to image: CIImage, context: CIContext) -> CIImage
}

// MARK: - Unified Image Processor
final class UnifiedImageProcessor: ObservableObject, @unchecked Sendable {
    
    // MARK: - Singleton
    static let shared = UnifiedImageProcessor()
    
    // MARK: - Core Properties
    private let metalDevice: MTLDevice
    private let ciContext: CIContext
    private let metalLibrary: MTLLibrary?
    private let filterQueue = DispatchQueue(label: "com.tete.unifiedFilter", qos: .userInitiated)
    
    // MARK: - Cache Systems
    private var filterCache: [String: CIFilter] = [:]
    private var kernelCache: [String: CIKernel] = [:]
    private let lutProcessor = LUTProcessor()
    
    // MARK: - Performance Monitoring
    @Published var processingTime: TimeInterval = 0
    @Published var cacheHitRate: Float = 0
    private var totalOperations: Int = 0
    private var cacheHits: Int = 0
    
    // MARK: - Initialization
    private init() {
        // Metal device setup
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.metalDevice = device
        self.metalLibrary = device.makeDefaultLibrary()
        
        // Optimized CIContext setup
        let contextOptions: [CIContextOption: Any] = [
            .useSoftwareRenderer: false,
            .highQualityDownsample: true,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpace(name: CGColorSpace.sRGB)!,
            .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpace(name: CGColorSpace.sRGB)!,
            .cacheIntermediates: false // Memory optimization
        ]
        
        self.ciContext = CIContext(mtlDevice: device, options: contextOptions)
        
        // Preload essential kernels and filters
        preloadEssentialComponents()
        
        print("🚀 UnifiedImageProcessor initialized with Metal device: \(device.name)")
    }
    
    // MARK: - Preloading
    private func preloadEssentialComponents() {
        // Preload commonly used filters
        let essentialFilters: [String] = [
            "CISepiaTone", "CIColorMonochrome", "CIVibrancy",
            "CIGaussianBlur", "CIColorControls", "CIToneCurve"
        ]
        
        for filterName in essentialFilters {
            if let filter = CIFilter(name: filterName) {
                filterCache[filterName] = filter
            }
        }
        
        print("✅ Preloaded \(filterCache.count) essential filters")
    }
    
    // MARK: - Public Interface
    
    /// 統合フィルターパイプライン適用
    func applyFilterPipeline(filters: [FilterOperation], to image: CIImage) async -> CIImage {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = await Task.detached { [weak self] in
            guard let self = self else {
                return image
            }
            
            return filters.reduce(image) { currentImage, operation in
                operation.apply(to: currentImage, context: self.ciContext)
            }
        }.value
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        await MainActor.run {
            self.processingTime = processingTime
        }
        
        return result
    }
    
    /// リアルタイム単一フィルター適用（最適化版）
    func applyFilterRealtime(_ filterType: FilterType, to image: CIImage, intensity: Float = 1.0) -> CIImage {
        let cacheKey = "\(filterType.rawValue)_\(Int(intensity * 100))"
        totalOperations += 1
        
        // Quick return for no filter
        guard filterType != .none else { return image }
        
        let result = applyOptimizedFilter(filterType, to: image, intensity: intensity, cacheKey: cacheKey)
        
        // Update cache hit rate
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.cacheHitRate = Float(self.cacheHits) / Float(self.totalOperations)
        }
        
        return result
    }
    
    /// UIImage変換（最適化版）
    func convertToUIImage(_ ciImage: CIImage, size: CGSize? = nil) -> UIImage? {
        let targetSize = size ?? ciImage.extent.size
        let scale = min(targetSize.width / ciImage.extent.width, 
                       targetSize.height / ciImage.extent.height)
        
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = ciContext.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Optimized Filter Application
    private func applyOptimizedFilter(_ filterType: FilterType, to image: CIImage, intensity: Float, cacheKey: String) -> CIImage {
        switch filterType {
        case .none:
            return image
            
        case .sepia:
            return applySepia(to: image, intensity: intensity)
            
        case .noir:
            return applyNoir(to: image, intensity: intensity)
            
        case .vintage:
            return applyVintage(to: image, intensity: intensity)
            
        case .warm:
            return applyWarm(to: image, intensity: intensity)
            
        case .cool:
            return applyCool(to: image, intensity: intensity)
            
        case .filmGrain:
            return applyFilmGrain(to: image, intensity: intensity)
            
        case .lightLeak:
            return applyLightLeak(to: image, intensity: intensity)
            
        case .retro:
            return applyRetro(to: image, intensity: intensity)
            
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
    
    // MARK: - Optimized Filter Implementations
    private func applySepia(to image: CIImage, intensity: Float) -> CIImage {
        guard let filter = getCachedFilter("CISepiaTone") else { return image }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        
        return filter.outputImage ?? image
    }
    
    private func applyNoir(to image: CIImage, intensity: Float) -> CIImage {
        guard let filter = getCachedFilter("CIColorMonochrome") else { return image }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIColor.black, forKey: kCIInputColorKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        
        return filter.outputImage ?? image
    }
    
    
    private func applyVintage(to image: CIImage, intensity: Float) -> CIImage {
        // Combine sepia with noise and vignette
        let sepiaImage = applySepia(to: image, intensity: intensity * 0.7)
        let noisyImage = addFilmGrain(to: sepiaImage, intensity: intensity * 0.2)
        return applyVignette(to: noisyImage, intensity: intensity * 0.4)
    }
    
    
    private func applyWarm(to image: CIImage, intensity: Float) -> CIImage {
        guard let filter = getCachedFilter("CIColorControls") else { return image }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.0 + intensity * 0.2, forKey: kCIInputSaturationKey)
        
        // Add warm tone
        return applyColorTemperature(to: filter.outputImage ?? image, temperature: intensity * 500)
    }
    
    private func applyCool(to image: CIImage, intensity: Float) -> CIImage {
        guard let filter = getCachedFilter("CIColorControls") else { return image }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.0 + intensity * 0.2, forKey: kCIInputSaturationKey)
        
        // Add cool tone
        return applyColorTemperature(to: filter.outputImage ?? image, temperature: -intensity * 500)
    }
    
    private func applyFilmGrain(to image: CIImage, intensity: Float) -> CIImage {
        // Simplified film grain using contrast adjustment
        guard let filter = getCachedFilter("CIColorControls") else { return image }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.0 + intensity * 0.1, forKey: kCIInputContrastKey)
        
        return filter.outputImage ?? image
    }
    
    private func applyLightLeak(to image: CIImage, intensity: Float) -> CIImage {
        // Simulate light leak with brightness and saturation
        guard let filter = getCachedFilter("CIColorControls") else { return image }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(intensity * 0.2, forKey: kCIInputBrightnessKey)
        filter.setValue(1.0 + intensity * 0.1, forKey: kCIInputSaturationKey)
        
        return filter.outputImage ?? image
    }
    
    private func applyRetro(to image: CIImage, intensity: Float) -> CIImage {
        // Combine sepia with saturation adjustment
        let sepiaImage = applySepia(to: image, intensity: intensity * 0.4)
        
        guard let filter = getCachedFilter("CIColorControls") else { return sepiaImage }
        filter.setValue(sepiaImage, forKey: kCIInputImageKey)
        filter.setValue(0.9, forKey: kCIInputSaturationKey)
        filter.setValue(1.05, forKey: kCIInputContrastKey)
        
        return filter.outputImage ?? sepiaImage
    }
    
    private func applyLUT(to image: CIImage, lutName: String, intensity: Float) -> CIImage {
        return lutProcessor.applyLUT(to: image, lutName: lutName, intensity: intensity) ?? image
    }
    
    
    // MARK: - Helper Methods
    private func getCachedFilter(_ filterName: String) -> CIFilter? {
        if let cached = filterCache[filterName] {
            cacheHits += 1
            return cached
        }
        
        let filter = CIFilter(name: filterName)
        if let filter = filter {
            filterCache[filterName] = filter
        }
        
        return filter
    }
    
    private func applyVignette(to image: CIImage, intensity: Float) -> CIImage {
        guard let filter = CIFilter(name: "CIVignette") else { return image }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(intensity * 2.0, forKey: kCIInputIntensityKey)
        filter.setValue(intensity * 30.0, forKey: kCIInputRadiusKey)
        
        return filter.outputImage ?? image
    }
    
    private func applyColorGrading(to image: CIImage, intensity: Float) -> CIImage {
        guard let filter = getCachedFilter("CIColorControls") else { return image }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.0 + intensity * 0.3, forKey: kCIInputContrastKey)
        filter.setValue(intensity * 0.1, forKey: kCIInputBrightnessKey)
        
        return filter.outputImage ?? image
    }
    
    private func addFilmGrain(to image: CIImage, intensity: Float) -> CIImage {
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator"),
              let compositeFilter = CIFilter(name: "CISourceOverCompositing") else { return image }
        
        guard let noiseImage = noiseFilter.outputImage else { return image }
        
        let scaledNoise = noiseImage.cropped(to: image.extent)
            .applyingFilter("CIColorMatrix", parameters: [
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity * 0.1))
            ])
        
        compositeFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        compositeFilter.setValue(scaledNoise, forKey: kCIInputImageKey)
        
        return compositeFilter.outputImage ?? image
    }
    
    private func applyColorTemperature(to image: CIImage, temperature: Float) -> CIImage {
        guard let filter = CIFilter(name: "CITemperatureAndTint") else { return image }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: CGFloat(temperature), y: 0), forKey: "inputNeutral")
        filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
        
        return filter.outputImage ?? image
    }
    
    // MARK: - Memory Management
    func clearCaches() {
        filterCache.removeAll()
        kernelCache.removeAll()
        lutProcessor.clearCache()
        
        print("🧹 UnifiedImageProcessor caches cleared")
    }
    
    // MARK: - Performance Metrics
    func getPerformanceMetrics() -> (processingTime: TimeInterval, cacheHitRate: Float, totalOperations: Int) {
        return (processingTime, cacheHitRate, totalOperations)
    }
}

// MARK: - Filter Type Extensions
// FilterType already conforms to CaseIterable in FilterDefinitions.swift

// MARK: - Filter Operation Implementations
struct SepiaToneOperation: FilterOperation {
    let intensity: Float
    
    func apply(to image: CIImage, context: CIContext) -> CIImage {
        guard let filter = CIFilter(name: "CISepiaTone") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        return filter.outputImage ?? image
    }
}

struct ContrastOperation: FilterOperation {
    let contrast: Float
    
    func apply(to image: CIImage, context: CIContext) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        return filter.outputImage ?? image
    }
}