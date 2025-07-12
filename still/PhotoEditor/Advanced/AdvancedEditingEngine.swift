//======================================================================
// MARK: - AdvancedEditingEngine
// Purpose: 高度な画像編集エンジン（プロ仕様ツール群）
// Features: カーブ、レベル、選択的カラー、レイヤー、マスク
//======================================================================

import Foundation
import CoreImage
import Metal
import MetalPerformanceShaders
import UIKit

class AdvancedEditingEngine: ObservableObject {
    
    // MARK: - Properties
    
    @Published var currentImage: CIImage?
    @Published var editHistory: [EditOperation] = []
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    
    private var originalImage: CIImage?
    private var undoStack: [EditOperation] = []
    private var redoStack: [EditOperation] = []
    
    private let metalDevice = MTLCreateSystemDefaultDevice()
    private var ciContext: CIContext?
    private var commandQueue: MTLCommandQueue?
    
    // Non-destructive editing layers
    @Published var layers: [EditLayer] = []
    @Published var activeLayerIndex: Int = 0
    
    // MARK: - Initialization
    
    init() {
        setupMetal()
    }
    
    private func setupMetal() {
        guard let device = metalDevice else { return }
        
        commandQueue = device.makeCommandQueue()
        ciContext = CIContext(mtlDevice: device, options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3) as Any,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any,
            .cacheIntermediates: false
        ])
    }
    
    // MARK: - Image Management
    
    func loadImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        
        originalImage = ciImage
        currentImage = ciImage
        
        // Create base layer
        layers = [EditLayer(
            id: UUID(),
            name: "Background",
            image: ciImage,
            opacity: 1.0,
            blendMode: .normal,
            isVisible: true,
            isLocked: false
        )]
        
        activeLayerIndex = 0
        clearHistory()
    }
    
    func exportImage(quality: CGFloat = 0.9) -> UIImage? {
        guard let finalImage = compositeLayers() else { return nil }
        
        guard let cgImage = ciContext?.createCGImage(finalImage, from: finalImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Layer Management
    
    func addLayer(name: String = "New Layer") {
        guard let baseImage = originalImage else { return }
        
        let newLayer = EditLayer(
            id: UUID(),
            name: name,
            image: baseImage,
            opacity: 1.0,
            blendMode: .normal,
            isVisible: true,
            isLocked: false
        )
        
        layers.append(newLayer)
        activeLayerIndex = layers.count - 1
        
        updateCurrentImage()
    }
    
    func duplicateLayer(at index: Int) {
        guard index < layers.count else { return }
        
        let originalLayer = layers[index]
        let duplicatedLayer = EditLayer(
            id: UUID(),
            name: "\(originalLayer.name) Copy",
            image: originalLayer.image,
            opacity: originalLayer.opacity,
            blendMode: originalLayer.blendMode,
            isVisible: originalLayer.isVisible,
            isLocked: false
        )
        
        layers.insert(duplicatedLayer, at: index + 1)
        activeLayerIndex = index + 1
        
        updateCurrentImage()
    }
    
    func deleteLayer(at index: Int) {
        guard layers.count > 1 && index < layers.count else { return }
        
        layers.remove(at: index)
        activeLayerIndex = min(activeLayerIndex, layers.count - 1)
        
        updateCurrentImage()
    }
    
    func moveLayer(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex < layers.count && destinationIndex < layers.count else { return }
        
        let layer = layers.remove(at: sourceIndex)
        layers.insert(layer, at: destinationIndex)
        
        if activeLayerIndex == sourceIndex {
            activeLayerIndex = destinationIndex
        }
        
        updateCurrentImage()
    }
    
    // MARK: - Advanced Editing Tools
    
    func adjustCurves(_ curves: CurveAdjustment) {
        guard let image = getCurrentLayerImage() else { return }
        
        let adjustedImage = applyCurveAdjustment(to: image, curves: curves)
        updateActiveLayer(with: adjustedImage)
        
        addToHistory(.curves(curves))
    }
    
    func adjustLevels(_ levels: LevelAdjustment) {
        guard let image = getCurrentLayerImage() else { return }
        
        let adjustedImage = applyLevelAdjustment(to: image, levels: levels)
        updateActiveLayer(with: adjustedImage)
        
        addToHistory(.levels(levels))
    }
    
    func selectiveColorAdjustment(_ adjustment: SelectiveColorAdjustment) {
        guard let image = getCurrentLayerImage() else { return }
        
        let adjustedImage = applySelectiveColorAdjustment(to: image, adjustment: adjustment)
        updateActiveLayer(with: adjustedImage)
        
        addToHistory(.selectiveColor(adjustment))
    }
    
    func hueColorAdjustment(_ adjustment: HSLAdjustment) {
        guard let image = getCurrentLayerImage() else { return }
        
        let adjustedImage = applyHSLAdjustment(to: image, adjustment: adjustment)
        updateActiveLayer(with: adjustedImage)
        
        addToHistory(.hslAdjustment(adjustment))
    }
    
    func shadowHighlightAdjustment(_ adjustment: ShadowHighlightAdjustment) {
        guard let image = getCurrentLayerImage() else { return }
        
        let adjustedImage = applyShadowHighlightAdjustment(to: image, adjustment: adjustment)
        updateActiveLayer(with: adjustedImage)
        
        addToHistory(.shadowHighlight(adjustment))
    }
    
    func unsharpMask(_ settings: UnsharpMaskSettings) {
        guard let image = getCurrentLayerImage() else { return }
        
        let adjustedImage = applyUnsharpMask(to: image, settings: settings)
        updateActiveLayer(with: adjustedImage)
        
        addToHistory(.unsharpMask(settings))
    }
    
    func noiseReduction(_ settings: NoiseReductionSettings) {
        guard let image = getCurrentLayerImage() else { return }
        
        let adjustedImage = applyNoiseReduction(to: image, settings: settings)
        updateActiveLayer(with: adjustedImage)
        
        addToHistory(.noiseReduction(settings))
    }
    
    // MARK: - Advanced Filter Methods
    
    private func applyCurveAdjustment(to image: CIImage, curves: CurveAdjustment) -> CIImage {
        guard let curvesFilter = CIFilter(name: "CIToneCurve") else { return image }
        
        curvesFilter.setValue(image, forKey: kCIInputImageKey)
        
        // RGB Curve
        if let rgbPoints = curves.rgbCurve {
            curvesFilter.setValue(CIVector(x: rgbPoints.0.x, y: rgbPoints.0.y), forKey: "inputPoint0")
            curvesFilter.setValue(CIVector(x: rgbPoints.1.x, y: rgbPoints.1.y), forKey: "inputPoint1")
            curvesFilter.setValue(CIVector(x: rgbPoints.2.x, y: rgbPoints.2.y), forKey: "inputPoint2")
            curvesFilter.setValue(CIVector(x: rgbPoints.3.x, y: rgbPoints.3.y), forKey: "inputPoint3")
            curvesFilter.setValue(CIVector(x: rgbPoints.4.x, y: rgbPoints.4.y), forKey: "inputPoint4")
        }
        
        var result = curvesFilter.outputImage ?? image
        
        // Individual RGB channel curves
        if let redCurve = curves.redCurve {
            result = applySingleChannelCurve(to: result, points: redCurve, channel: .red)
        }
        
        if let greenCurve = curves.greenCurve {
            result = applySingleChannelCurve(to: result, points: greenCurve, channel: .green)
        }
        
        if let blueCurve = curves.blueCurve {
            result = applySingleChannelCurve(to: result, points: blueCurve, channel: .blue)
        }
        
        return result
    }
    
    private func applyLevelAdjustment(to image: CIImage, levels: LevelAdjustment) -> CIImage {
        guard let levelsFilter = CIFilter(name: "CIGammaAdjust") else { return image }
        
        // Input levels (black point, white point, gamma)
        var result = image
        
        // Black point adjustment
        if levels.inputBlack > 0 {
            guard let blackFilter = CIFilter(name: "CIExposureAdjust") else { return image }
            blackFilter.setValue(result, forKey: kCIInputImageKey)
            blackFilter.setValue(levels.inputBlack * -2.0, forKey: kCIInputEVKey)
            result = blackFilter.outputImage ?? result
        }
        
        // Gamma adjustment
        levelsFilter.setValue(result, forKey: kCIInputImageKey)
        levelsFilter.setValue(levels.gamma, forKey: "inputPower")
        result = levelsFilter.outputImage ?? result
        
        // White point adjustment
        if levels.inputWhite < 1.0 {
            guard let whiteFilter = CIFilter(name: "CIColorControls") else { return result }
            whiteFilter.setValue(result, forKey: kCIInputImageKey)
            whiteFilter.setValue(1.0 / levels.inputWhite, forKey: kCIInputContrastKey)
            result = whiteFilter.outputImage ?? result
        }
        
        return result
    }
    
    private func applySelectiveColorAdjustment(to image: CIImage, adjustment: SelectiveColorAdjustment) -> CIImage {
        var result = image
        
        // Selective color adjustment using color matrix
        guard CIFilter(name: "CIColorMatrix") != nil else { return image }
        
        for colorRange in adjustment.adjustments {
            let maskImage = createColorRangeMask(from: image, colorRange: colorRange.range)
            let adjustedImage = applyColorAdjustmentToRange(result, adjustment: colorRange.adjustment)
            
            // Blend using mask
            result = blendImagesWithMask(base: result, overlay: adjustedImage, mask: maskImage)
        }
        
        return result
    }
    
    private func applyHSLAdjustment(to image: CIImage, adjustment: HSLAdjustment) -> CIImage {
        var result = image
        
        // Hue adjustment
        if adjustment.hue != 0 {
            guard let hueFilter = CIFilter(name: "CIHueAdjust") else { return image }
            hueFilter.setValue(result, forKey: kCIInputImageKey)
            hueFilter.setValue(adjustment.hue * .pi, forKey: kCIInputAngleKey)
            result = hueFilter.outputImage ?? result
        }
        
        // Saturation adjustment
        if adjustment.saturation != 1.0 {
            guard let saturationFilter = CIFilter(name: "CIColorControls") else { return result }
            saturationFilter.setValue(result, forKey: kCIInputImageKey)
            saturationFilter.setValue(adjustment.saturation, forKey: kCIInputSaturationKey)
            result = saturationFilter.outputImage ?? result
        }
        
        // Lightness adjustment
        if adjustment.lightness != 0 {
            guard let lightnessFilter = CIFilter(name: "CIExposureAdjust") else { return result }
            lightnessFilter.setValue(result, forKey: kCIInputImageKey)
            lightnessFilter.setValue(adjustment.lightness, forKey: kCIInputEVKey)
            result = lightnessFilter.outputImage ?? result
        }
        
        return result
    }
    
    private func applyShadowHighlightAdjustment(to image: CIImage, adjustment: ShadowHighlightAdjustment) -> CIImage {
        guard let shadowHighlightFilter = CIFilter(name: "CIHighlightShadowAdjust") else { return image }
        
        shadowHighlightFilter.setValue(image, forKey: kCIInputImageKey)
        shadowHighlightFilter.setValue(adjustment.shadowAmount, forKey: "inputShadowAmount")
        shadowHighlightFilter.setValue(adjustment.highlightAmount, forKey: "inputHighlightAmount")
        shadowHighlightFilter.setValue(adjustment.radius, forKey: kCIInputRadiusKey)
        
        return shadowHighlightFilter.outputImage ?? image
    }
    
    private func applyUnsharpMask(to image: CIImage, settings: UnsharpMaskSettings) -> CIImage {
        guard let unsharpFilter = CIFilter(name: "CIUnsharpMask") else { return image }
        
        unsharpFilter.setValue(image, forKey: kCIInputImageKey)
        unsharpFilter.setValue(settings.radius, forKey: kCIInputRadiusKey)
        unsharpFilter.setValue(settings.intensity, forKey: kCIInputIntensityKey)
        
        return unsharpFilter.outputImage ?? image
    }
    
    private func applyNoiseReduction(to image: CIImage, settings: NoiseReductionSettings) -> CIImage {
        guard let noiseFilter = CIFilter(name: "CINoiseReduction") else { return image }
        
        noiseFilter.setValue(image, forKey: kCIInputImageKey)
        noiseFilter.setValue(settings.noiseLevel, forKey: "inputNoiseLevel")
        noiseFilter.setValue(settings.sharpness, forKey: "inputSharpness")
        
        return noiseFilter.outputImage ?? image
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentLayerImage() -> CIImage? {
        guard activeLayerIndex < layers.count else { return nil }
        return layers[activeLayerIndex].image
    }
    
    private func updateActiveLayer(with image: CIImage) {
        guard activeLayerIndex < layers.count else { return }
        layers[activeLayerIndex].image = image
        updateCurrentImage()
    }
    
    private func updateCurrentImage() {
        currentImage = compositeLayers()
    }
    
    private func compositeLayers() -> CIImage? {
        guard !layers.isEmpty else { return nil }
        
        var result = layers[0].image
        
        for i in 1..<layers.count {
            let layer = layers[i]
            if layer.isVisible {
                result = blendLayer(base: result, overlay: layer.image, blendMode: layer.blendMode, opacity: layer.opacity)
            }
        }
        
        return result
    }
    
    private func blendLayer(base: CIImage, overlay: CIImage, blendMode: BlendMode, opacity: Float) -> CIImage {
        let filterName = blendMode.ciFilterName
        
        guard let blendFilter = CIFilter(name: filterName) else { return base }
        blendFilter.setValue(base, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(overlay, forKey: kCIInputImageKey)
        
        guard let blendedImage = blendFilter.outputImage else { return base }
        
        if opacity < 1.0 {
            guard let opacityFilter = CIFilter(name: "CISourceOverCompositing") else { return blendedImage }
            
            let transparentOverlay = overlay.applyingFilter("CIColorMatrix", parameters: [
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(opacity))
            ])
            
            opacityFilter.setValue(base, forKey: kCIInputBackgroundImageKey)
            opacityFilter.setValue(transparentOverlay, forKey: kCIInputImageKey)
            
            return opacityFilter.outputImage ?? blendedImage
        }
        
        return blendedImage
    }
    
    // MARK: - Advanced Helper Methods
    
    private func applySingleChannelCurve(to image: CIImage, points: [(CGPoint)], channel: ColorChannel) -> CIImage {
        guard let colorMatrix = CIFilter(name: "CIColorMatrix") else { return image }
        
        colorMatrix.setValue(image, forKey: kCIInputImageKey)
        
        // Create curve transformation matrix for specific channel
        var rVector = CIVector(x: 1, y: 0, z: 0, w: 0)
        var gVector = CIVector(x: 0, y: 1, z: 0, w: 0)
        var bVector = CIVector(x: 0, y: 0, z: 1, w: 0)
        let aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        
        // Apply curve to specific channel
        let curveMultiplier = calculateCurveMultiplier(from: points)
        
        switch channel {
        case .red:
            rVector = CIVector(x: curveMultiplier, y: 0, z: 0, w: 0)
        case .green:
            gVector = CIVector(x: 0, y: curveMultiplier, z: 0, w: 0)
        case .blue:
            bVector = CIVector(x: 0, y: 0, z: curveMultiplier, w: 0)
        }
        
        colorMatrix.setValue(rVector, forKey: "inputRVector")
        colorMatrix.setValue(gVector, forKey: "inputGVector")
        colorMatrix.setValue(bVector, forKey: "inputBVector")
        colorMatrix.setValue(aVector, forKey: "inputAVector")
        
        return colorMatrix.outputImage ?? image
    }
    
    private func createColorRangeMask(from image: CIImage, colorRange: ColorRange) -> CIImage {
        // Create mask for specific color range
        guard let maskFilter = CIFilter(name: "CIColorCube") else { return CIImage.empty() }
        
        // Generate color cube data for the specific range
        let cubeData = generateColorRangeCube(for: colorRange)
        
        maskFilter.setValue(image, forKey: kCIInputImageKey)
        maskFilter.setValue(cubeData, forKey: "inputCubeData")
        maskFilter.setValue(64, forKey: "inputCubeDimension")
        
        return maskFilter.outputImage ?? CIImage.empty()
    }
    
    private func applyColorAdjustmentToRange(_ image: CIImage, adjustment: ColorAdjustment) -> CIImage {
        var result = image
        
        // Apply CMYK adjustments
        if adjustment.cyan != 0 {
            result = adjustColorComponent(result, component: .cyan, amount: adjustment.cyan)
        }
        
        if adjustment.magenta != 0 {
            result = adjustColorComponent(result, component: .magenta, amount: adjustment.magenta)
        }
        
        if adjustment.yellow != 0 {
            result = adjustColorComponent(result, component: .yellow, amount: adjustment.yellow)
        }
        
        if adjustment.black != 0 {
            result = adjustColorComponent(result, component: .black, amount: adjustment.black)
        }
        
        return result
    }
    
    private func blendImagesWithMask(base: CIImage, overlay: CIImage, mask: CIImage) -> CIImage {
        guard let blendFilter = CIFilter(name: "CIBlendWithAlphaMask") else { return base }
        
        blendFilter.setValue(base, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(overlay, forKey: kCIInputImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)
        
        return blendFilter.outputImage ?? base
    }
    
    // MARK: - History Management
    
    private func addToHistory(_ operation: EditOperation) {
        undoStack.append(operation)
        redoStack.removeAll()
        
        // Limit history size
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
        
        updateHistoryState()
    }
    
    func undo() {
        guard !undoStack.isEmpty else { return }
        
        let operation = undoStack.removeLast()
        redoStack.append(operation)
        
        // Reapply all operations except the last one
        rebuildImageFromHistory()
        updateHistoryState()
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        
        let operation = redoStack.removeLast()
        undoStack.append(operation)
        
        // Apply the operation
        applyOperation(operation)
        updateHistoryState()
    }
    
    private func rebuildImageFromHistory() {
        guard let original = originalImage else { return }
        
        // Reset to original
        layers[activeLayerIndex].image = original
        
        // Reapply all operations
        for operation in undoStack {
            applyOperation(operation)
        }
        
        updateCurrentImage()
    }
    
    private func applyOperation(_ operation: EditOperation) {
        switch operation {
        case .curves(let curves):
            adjustCurves(curves)
        case .levels(let levels):
            adjustLevels(levels)
        case .selectiveColor(let adjustment):
            selectiveColorAdjustment(adjustment)
        case .hslAdjustment(let adjustment):
            hueColorAdjustment(adjustment)
        case .shadowHighlight(let adjustment):
            shadowHighlightAdjustment(adjustment)
        case .unsharpMask(let settings):
            unsharpMask(settings)
        case .noiseReduction(let settings):
            noiseReduction(settings)
        }
    }
    
    private func updateHistoryState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
    
    private func clearHistory() {
        undoStack.removeAll()
        redoStack.removeAll()
        updateHistoryState()
    }
    
    // MARK: - Utility Functions
    
    private func calculateCurveMultiplier(from points: [(CGPoint)]) -> CGFloat {
        // Simplified curve calculation - in production, would use spline interpolation
        let midPoint = points[points.count / 2]
        return CGFloat(midPoint.y / midPoint.x)
    }
    
    private func generateColorRangeCube(for range: ColorRange) -> Data {
        // Generate 64x64x64 color cube for specific color selection
        // This is a simplified version - production would use proper color science
        let cubeSize = 64
        let cubeData = Data(count: cubeSize * cubeSize * cubeSize * 4)
        
        // Fill with identity transformation, modified for color range
        // Implementation would depend on specific color range requirements
        
        return cubeData
    }
    
    private func adjustColorComponent(_ image: CIImage, component: ColorComponent, amount: Float) -> CIImage {
        guard let colorMatrix = CIFilter(name: "CIColorMatrix") else { return image }
        
        colorMatrix.setValue(image, forKey: kCIInputImageKey)
        
        // Apply component-specific adjustment
        switch component {
        case .cyan:
            let rVector = CIVector(x: 1.0 - CGFloat(amount), y: 0, z: 0, w: 0)
            colorMatrix.setValue(rVector, forKey: "inputRVector")
        case .magenta:
            let gVector = CIVector(x: 0, y: 1.0 - CGFloat(amount), z: 0, w: 0)
            colorMatrix.setValue(gVector, forKey: "inputGVector")
        case .yellow:
            let bVector = CIVector(x: 0, y: 0, z: 1.0 - CGFloat(amount), w: 0)
            colorMatrix.setValue(bVector, forKey: "inputBVector")
        case .black:
            let biasVector = CIVector(x: -CGFloat(amount), y: -CGFloat(amount), z: -CGFloat(amount), w: 0)
            colorMatrix.setValue(biasVector, forKey: "inputBiasVector")
        }
        
        return colorMatrix.outputImage ?? image
    }
}

// MARK: - Supporting Data Structures

struct EditLayer: Identifiable {
    let id: UUID
    var name: String
    var image: CIImage
    var opacity: Float
    var blendMode: BlendMode
    var isVisible: Bool
    var isLocked: Bool
}

enum BlendMode: String, CaseIterable {
    case normal = "Normal"
    case multiply = "Multiply"
    case screen = "Screen"
    case overlay = "Overlay"
    case softLight = "Soft Light"
    case hardLight = "Hard Light"
    case colorDodge = "Color Dodge"
    case colorBurn = "Color Burn"
    case darken = "Darken"
    case lighten = "Lighten"
    case difference = "Difference"
    case exclusion = "Exclusion"
    
    var ciFilterName: String {
        switch self {
        case .normal: return "CISourceOverCompositing"
        case .multiply: return "CIMultiplyBlendMode"
        case .screen: return "CIScreenBlendMode"
        case .overlay: return "CIOverlayBlendMode"
        case .softLight: return "CISoftLightBlendMode"
        case .hardLight: return "CIHardLightBlendMode"
        case .colorDodge: return "CIColorDodgeBlendMode"
        case .colorBurn: return "CIColorBurnBlendMode"
        case .darken: return "CIDarkenBlendMode"
        case .lighten: return "CILightenBlendMode"
        case .difference: return "CIDifferenceBlendMode"
        case .exclusion: return "CIExclusionBlendMode"
        }
    }
}

enum EditOperation {
    case curves(CurveAdjustment)
    case levels(LevelAdjustment)
    case selectiveColor(SelectiveColorAdjustment)
    case hslAdjustment(HSLAdjustment)
    case shadowHighlight(ShadowHighlightAdjustment)
    case unsharpMask(UnsharpMaskSettings)
    case noiseReduction(NoiseReductionSettings)
}

struct CurveAdjustment {
    var rgbCurve: (CGPoint, CGPoint, CGPoint, CGPoint, CGPoint)?
    var redCurve: [(CGPoint)]?
    var greenCurve: [(CGPoint)]?
    var blueCurve: [(CGPoint)]?
}

struct LevelAdjustment {
    var inputBlack: Float = 0.0     // 0.0 - 1.0
    var inputWhite: Float = 1.0     // 0.0 - 1.0
    var gamma: Float = 1.0          // 0.1 - 3.0
    var outputBlack: Float = 0.0    // 0.0 - 1.0
    var outputWhite: Float = 1.0    // 0.0 - 1.0
}

struct SelectiveColorAdjustment {
    var adjustments: [(range: ColorRange, adjustment: ColorAdjustment)] = []
}

struct HSLAdjustment {
    var hue: Float = 0.0         // -1.0 to 1.0
    var saturation: Float = 1.0  // 0.0 to 2.0
    var lightness: Float = 0.0   // -1.0 to 1.0
}

struct ShadowHighlightAdjustment {
    var shadowAmount: Float = 0.0    // 0.0 to 1.0
    var highlightAmount: Float = 0.0 // 0.0 to 1.0
    var radius: Float = 40.0         // 0.0 to 150.0
}

struct UnsharpMaskSettings {
    var radius: Float = 1.0      // 0.0 to 10.0
    var intensity: Float = 0.5   // 0.0 to 2.0
    var threshold: Float = 0.0   // 0.0 to 1.0
}

struct NoiseReductionSettings {
    var noiseLevel: Float = 0.02  // 0.0 to 0.1
    var sharpness: Float = 0.4    // 0.0 to 2.0
}

enum ColorRange: String, CaseIterable {
    case reds = "Reds"
    case yellows = "Yellows"
    case greens = "Greens"
    case cyans = "Cyans"
    case blues = "Blues"
    case magentas = "Magentas"
    case whites = "Whites"
    case neutrals = "Neutrals"
    case blacks = "Blacks"
}

struct ColorAdjustment {
    var cyan: Float = 0.0      // -1.0 to 1.0
    var magenta: Float = 0.0   // -1.0 to 1.0
    var yellow: Float = 0.0    // -1.0 to 1.0
    var black: Float = 0.0     // -1.0 to 1.0
}

enum ColorChannel {
    case red, green, blue
}

enum ColorComponent {
    case cyan, magenta, yellow, black
}