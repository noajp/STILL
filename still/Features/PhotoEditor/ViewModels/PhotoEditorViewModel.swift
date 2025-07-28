//======================================================================
// MARK: - PhotoEditorViewModel.swift
// Purpose: View model for data and business logic (PhotoEditorViewModelのデータとビジネスロジック)
// Path: still/Features/PhotoEditor/ViewModels/PhotoEditorViewModel.swift
//======================================================================
//
//  PhotoEditorViewModel.swift
//  tete
//
//  写真編集ViewのViewModel
//

import SwiftUI
import Combine
@preconcurrency import CoreImage
import Photos

@MainActor
class PhotoEditorViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentImage: UIImage?
    @Published var ciImage: CIImage?
    @Published var filterThumbnails: [FilterType: UIImage] = [:]
    @Published var isProcessing = false
    @Published var currentFilter = FilterState()
    
    // MARK: - Private Properties
    private var originalImage: UIImage
    private var originalCIImage: CIImage
    private let imageProcessor = ImageProcessor()
    private let coreImageManager = CoreImageManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(image: UIImage) {
        // 画像を最適化
        self.originalImage = imageProcessor.resizeImageIfNeeded(image)
        
        // CIImage作成
        if let ciImage = coreImageManager.createCIImage(from: self.originalImage) {
            self.originalCIImage = ciImage
        } else {
            self.originalCIImage = CIImage()
            print("❌ Failed to create CIImage")
        }
        
        // 初期画像設定
        self.currentImage = self.originalImage
        self.ciImage = self.originalCIImage
        
        // サムネイル生成
        Task {
            await generateFilterThumbnails()
        }
    }
    
    // RAW画像対応のイニシャライザ
    init(asset: PHAsset, rawInfo: RAWImageInfo, previewImage: UIImage?) {
        // 一時的にプレビュー画像を使用
        let tempImage = previewImage ?? UIImage()
        self.originalImage = imageProcessor.resizeImageIfNeeded(tempImage)
        
        // CIImage作成
        if let ciImage = coreImageManager.createCIImage(from: self.originalImage) {
            self.originalCIImage = ciImage
        } else {
            self.originalCIImage = CIImage()
        }
        
        // 初期画像設定
        self.currentImage = self.originalImage
        self.ciImage = self.originalCIImage
        
        // RAW画像を非同期で読み込み
        Task {
            if rawInfo.isRAW {
                await loadRAWImage(asset: asset, rawInfo: rawInfo)
            }
            await generateFilterThumbnails()
        }
    }
    
    // MARK: - Public Methods
    
    /// フィルター適用（リアルタイムプレビューは自動更新される）
    func applyFilter(_ filterType: FilterType, intensity: Float) {
        // 現在のフィルター状態を更新
        currentFilter = FilterState(filterType: filterType, intensity: intensity)
        
        // 最終的な出力画像を非同期で生成（エクスポート用）
        Task {
            coreImageManager.applyFilter(
                filterType,
                to: originalCIImage,
                intensity: intensity
            ) { [weak self] result in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    switch result {
                    case .success(let filteredImage):
                        self.currentImage = filteredImage
                        
                    case .failure(let error):
                        print("❌ Filter application failed: \(error)")
                        self.currentImage = self.originalImage
                    }
                }
            }
        }
    }
    
    /// オリジナルに戻す
    func resetToOriginal() {
        currentImage = originalImage
        ciImage = originalCIImage
        currentFilter = FilterState()
    }
    
    /// 編集済み画像を保存用に準備
    func prepareForExport(quality: ExportQuality = .high) -> Data? {
        guard let image = currentImage else { return nil }
        return imageProcessor.exportImage(image, quality: quality)
    }
    
    /// フィルター設定を適用
    func applyFilterSettings(_ settings: FilterSettings, toneCurve: ToneCurve = ToneCurve()) {
        Task {
            var filteredImage = originalCIImage
            
            // 色調整フィルター適用
            if let colorFilter = CIFilter(name: "CIColorControls") {
                colorFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                colorFilter.setValue(settings.brightness, forKey: kCIInputBrightnessKey)
                colorFilter.setValue(settings.contrast, forKey: kCIInputContrastKey)
                colorFilter.setValue(settings.saturation, forKey: kCIInputSaturationKey)
                filteredImage = colorFilter.outputImage ?? filteredImage
            }
            
            // ハイライト・シャドウ調整
            if settings.highlights != 0 || settings.shadows != 0 {
                if let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust") {
                    highlightShadowFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                    highlightShadowFilter.setValue(1.0 + settings.highlights / 100, forKey: "inputHighlightAmount")
                    highlightShadowFilter.setValue(settings.shadows / 100, forKey: "inputShadowAmount")
                    filteredImage = highlightShadowFilter.outputImage ?? filteredImage
                }
            }
            
            // ホワイト・ブラック調整（露出とガンマで近似）
            if settings.whites != 0 || settings.blacks != 0 {
                if let exposureFilter = CIFilter(name: "CIExposureAdjust") {
                    exposureFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                    exposureFilter.setValue(settings.whites / 200, forKey: kCIInputEVKey) // ホワイト調整
                    filteredImage = exposureFilter.outputImage ?? filteredImage
                }
                
                if let gammaFilter = CIFilter(name: "CIGammaAdjust") {
                    gammaFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                    gammaFilter.setValue(1.0 - settings.blacks / 200, forKey: "inputPower") // ブラック調整
                    filteredImage = gammaFilter.outputImage ?? filteredImage
                }
            }
            
            // 明瞭度調整（アンシャープマスクで近似）
            if settings.clarity != 0 {
                if let clarityFilter = CIFilter(name: "CIUnsharpMask") {
                    clarityFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                    clarityFilter.setValue(abs(settings.clarity) / 50, forKey: kCIInputIntensityKey)
                    clarityFilter.setValue(2.5, forKey: kCIInputRadiusKey)
                    filteredImage = clarityFilter.outputImage ?? filteredImage
                }
            }
            
            // 温度とティント調整
            if let tempFilter = CIFilter(name: "CITemperatureAndTint") {
                tempFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                let neutralVector = CIVector(x: CGFloat(settings.temperature), y: CGFloat(settings.tint))
                let targetVector = CIVector(x: 6500, y: 0) // 標準的な色温度
                tempFilter.setValue(neutralVector, forKey: "inputNeutral")
                tempFilter.setValue(targetVector, forKey: "inputTargetNeutral")
                filteredImage = tempFilter.outputImage ?? filteredImage
            }
            
            // トーンカーブ適用
            filteredImage = applyToneCurve(to: filteredImage, curve: toneCurve)
            
            // CIImageを更新
            await MainActor.run {
                self.ciImage = filteredImage
                
                // UIImageも更新
                if let cgImage = CIContext().createCGImage(filteredImage, from: filteredImage.extent) {
                    self.currentImage = UIImage(cgImage: cgImage)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Loads RAW image data asynchronously from photo library asset.
     * 
     * - Parameters:
     *   - asset: Photo library asset containing RAW data
     *   - rawInfo: RAW image metadata
     */
    private func loadRAWImage(asset: PHAsset, rawInfo: RAWImageInfo) async {
        RAWImageProcessor.shared.loadRAWImage(from: asset) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                
                switch result {
                case .success(let rawImage):
                    // Convert RAW image from Core Image to UIImage
                    if let uiImage = RAWImageProcessor.shared.createPreviewImage(from: rawImage) {
                        self.originalImage = uiImage
                        self.currentImage = uiImage
                        self.originalCIImage = rawImage
                        self.ciImage = rawImage
                    }
                case .failure(let error):
                    print("❌ RAW loading failed: \(error)")
                }
            }
        }
    }
    
    /**
     * Applies tone curve adjustments to the image.
     * 
     * Uses multiple CIFilters to approximate tone curve effects for iOS 12+
     * compatibility, combining filters to achieve the desired curve response.
     * 
     * - Parameters:
     *   - image: Source image
     *   - curve: Tone curve definition
     * - Returns: Image with tone curve applied
     */
    private func applyToneCurve(to image: CIImage, curve: ToneCurve) -> CIImage {
        
        let points = curve.points.sorted { $0.input < $1.input }
        guard points.count >= 2 else { return image }
        
        var processedImage = image
        
        // Calculate shadow, midtone, and highlight adjustments
        let shadowPoint = points.first!
        let highlightPoint = points.last!
        let midPoint = points.count > 2 ? points[points.count / 2] : ToneCurvePoint(input: 0.5, output: 0.5)
        
        // Approximate tone curve with gamma adjustment
        let gamma = calculateGamma(from: midPoint)
        if gamma != 1.0 {
            if let gammaFilter = CIFilter(name: "CIGammaAdjust") {
                gammaFilter.setValue(processedImage, forKey: kCIInputImageKey)
                gammaFilter.setValue(gamma, forKey: "inputPower")
                processedImage = gammaFilter.outputImage ?? processedImage
            }
        }
        
        // Calculate highlight and shadow adjustments
        let shadowAdjust = (shadowPoint.output - shadowPoint.input) * 2
        let highlightAdjust = (highlightPoint.output - highlightPoint.input) * 2
        
        if shadowAdjust != 0 || highlightAdjust != 0 {
            if let hlsFilter = CIFilter(name: "CIHighlightShadowAdjust") {
                hlsFilter.setValue(processedImage, forKey: kCIInputImageKey)
                hlsFilter.setValue(1.0 + highlightAdjust, forKey: "inputHighlightAmount")
                hlsFilter.setValue(shadowAdjust, forKey: "inputShadowAmount")
                processedImage = hlsFilter.outputImage ?? processedImage
            }
        }
        
        return processedImage
    }
    
    /**
     * Calculates gamma value from tone curve midpoint.
     * 
     * Uses the gamma correction formula: output = input^gamma
     * where gamma = log(output) / log(input)
     * 
     * - Parameter point: Tone curve point for calculation
     * - Returns: Calculated gamma value
     */
    private func calculateGamma(from point: ToneCurvePoint) -> Float {
        if point.input > 0 && point.output > 0 {
            return log(point.output) / log(point.input)
        }
        return 1.0
    }
    
    /**
     * Generates filter thumbnails for UI preview.
     * 
     * Creates small thumbnail images for each filter type to display in the
     * filter selection interface, improving user experience and performance.
     */
    private func generateFilterThumbnails() async {
        // Create small thumbnail image for processing
        guard let thumbnailImage = imageProcessor.createThumbnail(from: originalImage),
              let thumbnailCIImage = coreImageManager.createCIImage(from: thumbnailImage) else {
            return
        }
        
        // Generate thumbnails for each filter asynchronously
        await withTaskGroup(of: (FilterType, UIImage?).self) { group in
            for filterType in FilterType.allCases {
                group.addTask { @Sendable [weak self] in
                    guard let self = self else { return (filterType, nil) }
                    
                    if filterType == .none {
                        return (filterType, thumbnailImage)
                    }
                    
                    // Apply filter to thumbnail
                    let filtered = self.coreImageManager.applyFilterSync(
                        filterType,
                        to: thumbnailCIImage,
                        intensity: filterType.previewIntensity
                    )
                    
                    // Convert to UIImage
                    if let filtered = filtered,
                       let cgImage = CIContext().createCGImage(filtered, from: filtered.extent) {
                        return (filterType, UIImage(cgImage: cgImage))
                    }
                    
                    return (filterType, nil)
                }
            }
            
            // Collect results
            for await (filterType, thumbnail) in group {
                await MainActor.run {
                    self.filterThumbnails[filterType] = thumbnail
                }
            }
        }
    }
    
    // MARK: - Memory Management
    
    /**
     * Provides an estimate of current memory usage for the editing session.
     * 
     * Calculates memory usage based on the original image size and processing
     * requirements, formatted as a human-readable string.
     * 
     * - Returns: Formatted memory usage string
     */
    var estimatedMemoryUsage: String {
        let bytes = imageProcessor.estimateMemoryUsage(for: originalImage)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}