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
    private let rawProcessor = RAWImageProcessor.shared
    private var cancellables = Set<AnyCancellable>()
    
    // RAW-specific properties
    private var isRAWImage: Bool = false
    private var rawOptions: [String: Any] = [:]
    private var dngURL: URL?
    
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
        self.isRAWImage = rawInfo.isRAW
        
        // RAW画像を非同期で読み込み
        Task {
            if rawInfo.isRAW {
                await loadEnhancedRAWProcessing(asset: asset)
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

    
    /// カスタムプリセット適用結果を直接更新
    func updateProcessedImage(_ image: UIImage) {
        self.currentImage = image
        self.ciImage = CIImage(image: image)
    }
    
    /// Auto White Balance - Analyze image and return optimal temperature and tint
    func analyzeAutoWhiteBalance() -> (temperature: Float, tint: Float) {
        let ciImage = originalCIImage
        
        // Create a small version for faster analysis
        let extent = ciImage.extent
        let scale = min(1.0, 500.0 / max(extent.width, extent.height))
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // Get average color values
        let avgFilter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: scaledImage,
            kCIInputExtentKey: CIVector(cgRect: scaledImage.extent)
        ])
        
        guard let outputImage = avgFilter?.outputImage else {
            return (temperature: 0.0, tint: 0.0)
        }
        
        // Extract RGB values
        let context = CIContext()
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, 
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1), 
                      format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        let r = Float(bitmap[0]) / 255.0
        let g = Float(bitmap[1]) / 255.0
        let b = Float(bitmap[2]) / 255.0
        
        // Calculate color temperature correction and map to 0-100 range
        // Warmer if too blue, cooler if too yellow
        let tempCorrection = (b - r) * 0.5  // Range: -0.5 to 0.5
        let temperature = 50 + (tempCorrection * 50)  // Map to 25-75 range
        
        // Calculate tint correction (green/magenta balance) and map to 0-100 range
        let tintCorrection = ((r + b) / 2.0 - g) * 0.3  // Range: -0.3 to 0.3
        let tint = 50 + (tintCorrection * 83.33)  // Map to 25-75 range
        
        return (temperature: max(25, min(75, temperature)), tint: max(25, min(75, tint)))
    }
    
    /// Apply Auto White Balance
    func applyAutoWhiteBalance() {
        let (temperature, tint) = analyzeAutoWhiteBalance()
        
        // Create new filter settings with auto WB values
        var newSettings = FilterSettings()
        newSettings.temperature = temperature
        newSettings.tint = tint
        
        // Apply the settings
        applyFilterSettings(newSettings, toneCurve: ToneCurve())
    }
    
    // MARK: - RAW/DNG Processing
    
    /// Load enhanced RAW processing with DNG conversion
    private func loadEnhancedRAWProcessing(asset: PHAsset) async {
        do {
            print("🔍 Loading enhanced RAW processing...")
            
            // Check if it's actually a RAW image
            guard rawProcessor.isRAWAsset(asset) else {
                print("⚠️ Asset is not RAW format")
                return
            }
            
            // Load RAW image with enhanced processing
            let (ciImage, options) = try await rawProcessor.loadRAWImageForEditing(asset: asset)
            
            await MainActor.run {
                self.originalCIImage = ciImage
                self.ciImage = ciImage
                self.rawOptions = options
                
                // Create UIImage from CIImage
                let context = CIContext()
                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    self.originalImage = UIImage(cgImage: cgImage)
                    self.currentImage = self.originalImage
                }
                
                print("✅ Enhanced RAW processing completed")
            }
            
            // Optionally convert to DNG for advanced editing
            if isRAWImage {
                try await convertToDNGIfNeeded(asset: asset)
            }
            
        } catch {
            print("❌ Failed to load enhanced RAW processing: \(error)")
        }
    }
    
    /// Convert RAW to DNG for advanced editing
    private func convertToDNGIfNeeded(asset: PHAsset) async throws {
        print("🔄 Converting RAW to DNG...")
        
        let dngURL = try await rawProcessor.convertToDNG(asset: asset)
        
        await MainActor.run {
            self.dngURL = dngURL
            print("✅ DNG conversion completed: \(dngURL)")
        }
    }
    
    /// Export processed image as DNG
    func exportAsDNG() async throws -> URL {
        guard let currentCIImage = ciImage else {
            throw RAWProcessingError.failedToCreateCIImage
        }
        
        // Create DNG with current processing applied
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dngDirectory = documentsPath.appendingPathComponent("DNG", isDirectory: true)
        try FileManager.default.createDirectory(at: dngDirectory, withIntermediateDirectories: true)
        
        let exportURL = dngDirectory.appendingPathComponent("processed_\(UUID().uuidString).dng")
        
        // Export with current processing
        let context = CIContext()
        try context.writeTIFFRepresentation(of: currentCIImage, to: exportURL, format: .ARGB8, colorSpace: currentCIImage.colorSpace ?? CGColorSpaceCreateDeviceRGB())
        
        return exportURL
    }
    
    /// Get RAW processing capabilities
    var rawProcessingCapabilities: [String: Any] {
        return rawOptions
    }
    
    /// Check if current image is RAW
    var isProcessingRAW: Bool {
        return isRAWImage
    }
    
    /// Apply angle adjustments (rotation, straighten, flip)
    func applyAngleAdjustments(rotation: Double, straighten: Double, flipHorizontal: Bool, flipVertical: Bool) {
        Task {
            var transformedImage = originalCIImage
            
            // Apply rotation
            if rotation != 0 {
                let rotationRadians = rotation * .pi / 180
                let rotationTransform = CGAffineTransform(rotationAngle: CGFloat(rotationRadians))
                transformedImage = transformedImage.transformed(by: rotationTransform)
            }
            
            // Apply straighten (small angle correction)
            if straighten != 0 {
                let straightenRadians = straighten * .pi / 180
                let straightenTransform = CGAffineTransform(rotationAngle: CGFloat(straightenRadians))
                transformedImage = transformedImage.transformed(by: straightenTransform)
            }
            
            // Apply horizontal flip
            if flipHorizontal {
                let flipTransform = CGAffineTransform(scaleX: -1, y: 1)
                transformedImage = transformedImage.transformed(by: flipTransform)
            }
            
            // Apply vertical flip
            if flipVertical {
                let flipTransform = CGAffineTransform(scaleX: 1, y: -1)
                transformedImage = transformedImage.transformed(by: flipTransform)
            }
            
            await MainActor.run {
                self.ciImage = transformedImage
                
                // Create UIImage from transformed CIImage
                let context = CIContext()
                if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
                    self.currentImage = UIImage(cgImage: cgImage)
                }
            }
        }
    }
    
    /// フィルター設定を適用
    func applyFilterSettings(_ settings: FilterSettings, toneCurve: ToneCurve = ToneCurve()) {
        Task {
            var filteredImage = originalCIImage
            
            // White Balance (Temperature and Tint) adjustment
            if settings.temperature != 50 || settings.tint != 50 {
                if let tempTintFilter = CIFilter(name: "CITemperatureAndTint") {
                    tempTintFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                    
                    // Default neutral temperature is 6500K
                    let neutral = CIVector(x: 6500, y: 0)
                    
                    // Map 0-100 to temperature range (4500K to 8500K for subtle effect)
                    let normalizedTemp = (settings.temperature - 50) / 50.0  // -1 to 1
                    let targetTemp = 6500 + (normalizedTemp * 2000)  // ±2000K range (more subtle)
                    
                    // Map 0-100 to tint range (-30 to +30 for subtle effect)
                    let normalizedTint = (settings.tint - 50) / 50.0  // -1 to 1
                    let targetTint = normalizedTint * 30  // ±30 tint range (more subtle)
                    
                    let targetNeutral = CIVector(x: CGFloat(targetTemp), y: CGFloat(targetTint))
                    
                    tempTintFilter.setValue(neutral, forKey: "inputNeutral")
                    tempTintFilter.setValue(targetNeutral, forKey: "inputTargetNeutral")
                    
                    filteredImage = tempTintFilter.outputImage ?? filteredImage
                }
            }
            
            // 色調整フィルター適用
            if let colorFilter = CIFilter(name: "CIColorControls") {
                colorFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                
                // Map 0-100 to appropriate ranges (subtle effects)
                let brightness = (settings.brightness - 50) / 100.0  // -0.5 to 0.5
                let contrast = 0.8 + (settings.contrast / 100.0) * 0.4  // 0.8 to 1.2
                let saturation = 0.5 + (settings.saturation / 100.0)  // 0.5 to 1.5
                
                colorFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
                colorFilter.setValue(contrast, forKey: kCIInputContrastKey)
                colorFilter.setValue(saturation, forKey: kCIInputSaturationKey)
                filteredImage = colorFilter.outputImage ?? filteredImage
            }
            
            // ハイライト・シャドウ調整
            if settings.highlights != 50 || settings.shadows != 50 {
                if let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust") {
                    highlightShadowFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                    
                    // Map 0-100 to subtle ranges
                    let highlights = 1.0 + ((settings.highlights - 50) / 100.0) * 0.5  // 0.75 to 1.25
                    let shadows = (settings.shadows - 50) / 100.0 * 0.5  // -0.25 to 0.25
                    
                    highlightShadowFilter.setValue(highlights, forKey: "inputHighlightAmount")
                    highlightShadowFilter.setValue(shadows, forKey: "inputShadowAmount")
                    filteredImage = highlightShadowFilter.outputImage ?? filteredImage
                }
            }
            
            // ホワイト・ブラック調整（露出とガンマで近似）
            if settings.whites != 50 || settings.blacks != 50 {
                if let exposureFilter = CIFilter(name: "CIExposureAdjust") {
                    exposureFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                    
                    // Map 0-100 to subtle exposure range
                    let whites = (settings.whites - 50) / 100.0 * 0.5  // -0.25 to 0.25 EV
                    exposureFilter.setValue(whites, forKey: kCIInputEVKey)
                    filteredImage = exposureFilter.outputImage ?? filteredImage
                }
                
                if let gammaFilter = CIFilter(name: "CIGammaAdjust") {
                    gammaFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                    
                    // Map 0-100 to subtle gamma range
                    let blacks = 1.0 + ((settings.blacks - 50) / 100.0) * 0.3  // 0.85 to 1.15
                    gammaFilter.setValue(blacks, forKey: "inputPower")
                    filteredImage = gammaFilter.outputImage ?? filteredImage
                }
            }
            
            // 明瞭度調整（アンシャープマスクで近似）
            if settings.clarity != 50 {
                if let clarityFilter = CIFilter(name: "CIUnsharpMask") {
                    clarityFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                    
                    // Map 0-100 to subtle clarity range
                    let clarity = abs(settings.clarity - 50) / 100.0 * 1.5  // 0 to 0.75 intensity
                    clarityFilter.setValue(clarity, forKey: kCIInputIntensityKey)
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