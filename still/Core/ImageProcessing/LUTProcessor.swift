//======================================================================
// MARK: - LUTProcessor.swift
// Purpose: LUTProcessor implementation (LUTProcessorの実装)
// Path: still/Core/ImageProcessing/LUTProcessor.swift
//======================================================================
//
//  LUTProcessor.swift
//  tete
//
//  LUT（ルックアップテーブル）処理システム
//

import UIKit
import CoreImage

// MARK: - LUT Processor (Optimized)
final class LUTProcessor {
    
    // MARK: - Properties
    private static let lutSize = 64
    private let lutCache = NSCache<NSString, NSData>()
    
    // MARK: - Initialization
    init() {
        // Configure cache for memory efficiency
        lutCache.countLimit = 20  // Maximum 20 LUTs in memory
        lutCache.totalCostLimit = 50 * 1024 * 1024  // 50MB max
    }
    
    // MARK: - LUT Application
    
    /// LUTを適用
    func applyLUT(to image: CIImage, lutName: String, intensity: Float = 1.0) -> CIImage? {
        guard let lutData = loadLUT(named: lutName) else {
            print("❌ LUT not found: \(lutName)")
            return image
        }
        
        // CIColorCubeフィルターでLUT適用
        let colorCube = CIFilter(name: "CIColorCube")!
        colorCube.setValue(image, forKey: kCIInputImageKey)
        colorCube.setValue(lutData, forKey: "inputCubeData")
        colorCube.setValue(Self.lutSize, forKey: "inputCubeDimension")
        
        guard let outputImage = colorCube.outputImage else { return image }
        
        // 強度調整
        if intensity < 1.0 {
            return blendImages(original: image, filtered: outputImage, intensity: intensity)
        }
        
        return outputImage
    }
    
    // MARK: - LUT Loading
    
    /// LUTファイルを読み込み (Optimized with NSCache)
    private func loadLUT(named lutName: String) -> Data? {
        let cacheKey = NSString(string: lutName)
        
        // キャッシュチェック (NSCache使用)
        if let cachedData = lutCache.object(forKey: cacheKey) {
            return cachedData as Data
        }
        
        // バンドルからLUTファイルを読み込み
        if let lutData = loadLUTFromBundle(named: lutName) {
            let nsData = NSData(data: lutData)
            lutCache.setObject(nsData, forKey: cacheKey, cost: lutData.count)
            return lutData
        }
        
        // 生成済みLUTをチェック
        if let generatedData = generateLUT(named: lutName) {
            let nsData = NSData(data: generatedData)
            lutCache.setObject(nsData, forKey: cacheKey, cost: generatedData.count)
            return generatedData
        }
        
        return nil
    }
    
    /// キャッシュクリア
    func clearCache() {
        lutCache.removeAllObjects()
        print("🧹 LUT cache cleared")
    }
    
    /// バンドルからLUTを読み込み
    private func loadLUTFromBundle(named lutName: String) -> Data? {
        // .cubeファイル形式対応
        if let cubeUrl = Bundle.main.url(forResource: lutName, withExtension: "cube") {
            return loadCubeFile(url: cubeUrl)
        }
        
        // PNGファイル形式対応
        if let pngUrl = Bundle.main.url(forResource: lutName, withExtension: "png") {
            return loadPngLUT(url: pngUrl)
        }
        
        return nil
    }
    
    /// .cubeファイルを読み込み
    private func loadCubeFile(url: URL) -> Data? {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return parseCubeFile(content: content)
        } catch {
            print("❌ Failed to load cube file: \(error)")
            return nil
        }
    }
    
    /// .cubeファイルをパース
    private func parseCubeFile(content: String) -> Data? {
        let lines = content.components(separatedBy: .newlines)
        var lutData = [Float]()
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // コメント行をスキップ
            if trimmed.hasPrefix("#") || trimmed.isEmpty {
                continue
            }
            
            // RGB値の行をパース
            let components = trimmed.components(separatedBy: .whitespaces)
            if components.count == 3,
               let r = Float(components[0]),
               let g = Float(components[1]),
               let b = Float(components[2]) {
                lutData.append(r)
                lutData.append(g)
                lutData.append(b)
                lutData.append(1.0) // Alpha
            }
        }
        
        // データサイズチェック
        let expectedSize = Self.lutSize * Self.lutSize * Self.lutSize * 4
        if lutData.count == expectedSize {
            return Data(bytes: lutData, count: lutData.count * MemoryLayout<Float>.size)
        }
        
        print("❌ Invalid LUT data size: \(lutData.count), expected: \(expectedSize)")
        return nil
    }
    
    /// PNG形式のLUTを読み込み
    private func loadPngLUT(url: URL) -> Data? {
        guard let image = UIImage(contentsOfFile: url.path),
              let cgImage = image.cgImage else {
            return nil
        }
        
        return extractLUTFromImage(cgImage: cgImage)
    }
    
    /// 画像からLUTデータを抽出
    private func extractLUTFromImage(cgImage: CGImage) -> Data? {
        // 512x512のLUT画像を想定 (8x8グリッド、各64x64)
        let width = cgImage.width
        let height = cgImage.height
        
        guard width == 512 && height == 512 else {
            print("❌ Invalid LUT image size: \(width)x\(height)")
            return nil
        }
        
        // ピクセルデータを取得
        guard let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return nil
        }
        
        var lutData = [Float]()
        let bytesPerPixel = 4
        
        // 8x8グリッドで64x64の各ブロックを処理
        for blueIndex in 0..<8 {
            for redIndex in 0..<8 {
                for greenY in 0..<64 {
                    for greenX in 0..<64 {
                        let x = redIndex * 64 + greenX
                        let y = blueIndex * 64 + greenY
                        let pixelIndex = (y * width + x) * bytesPerPixel
                        
                        let r = Float(data[pixelIndex]) / 255.0
                        let g = Float(data[pixelIndex + 1]) / 255.0
                        let b = Float(data[pixelIndex + 2]) / 255.0
                        
                        lutData.append(r)
                        lutData.append(g)
                        lutData.append(b)
                        lutData.append(1.0)
                    }
                }
            }
        }
        
        return Data(bytes: lutData, count: lutData.count * MemoryLayout<Float>.size)
    }
    
    // MARK: - Helper Methods
    
    /// 画像をブレンド
    private func blendImages(original: CIImage, filtered: CIImage, intensity: Float) -> CIImage {
        let blendFilter = CIFilter(name: "CISourceOverCompositing")!
        
        // アルファを調整
        let colorMatrix = CIFilter(name: "CIColorMatrix")!
        colorMatrix.setValue(filtered, forKey: kCIInputImageKey)
        colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity)), forKey: "inputAVector")
        
        blendFilter.setValue(colorMatrix.outputImage, forKey: kCIInputImageKey)
        blendFilter.setValue(original, forKey: kCIInputBackgroundImageKey)
        
        return blendFilter.outputImage ?? original
    }
}

// MARK: - Built-in LUT Generation
extension LUTProcessor {
    
    /// 内蔵LUTを生成
    private func generateLUT(named lutName: String) -> Data? {
        switch lutName {
        case "kodak_portra_400":
            return generateKodakPortraLUT()
        case "fuji_pro_400h":
            return generateFujiProLUT()
        case "cinestill_800t":
            return generateCineStillLUT()
        case "ilford_hp5":
            return generateIlfordHP5LUT()
        case "polaroid_600":
            return generatePolaroidLUT()
        default:
            return nil
        }
    }
    
    /// Kodak Portra 400 LUT生成
    private func generateKodakPortraLUT() -> Data {
        var lutData = [Float]()
        let size = Self.lutSize
        
        for b in 0..<size {
            for g in 0..<size {
                for r in 0..<size {
                    let rNorm = Float(r) / Float(size - 1)
                    let gNorm = Float(g) / Float(size - 1)
                    let bNorm = Float(b) / Float(size - 1)
                    
                    // Kodak Portra特有の色調整
                    let newR = portraRedCurve(rNorm)
                    let newG = portraGreenCurve(gNorm)
                    let newB = portraBlueCurve(bNorm)
                    
                    lutData.append(newR)
                    lutData.append(newG)
                    lutData.append(newB)
                    lutData.append(1.0)
                }
            }
        }
        
        return Data(bytes: lutData, count: lutData.count * MemoryLayout<Float>.size)
    }
    
    /// Fuji Pro 400H LUT生成
    private func generateFujiProLUT() -> Data {
        var lutData = [Float]()
        let size = Self.lutSize
        
        for b in 0..<size {
            for g in 0..<size {
                for r in 0..<size {
                    let rNorm = Float(r) / Float(size - 1)
                    let gNorm = Float(g) / Float(size - 1)
                    let bNorm = Float(b) / Float(size - 1)
                    
                    // Fuji Pro特有の色調整（グリーン寄り）
                    let newR = fujiRedCurve(rNorm)
                    let newG = fujiGreenCurve(gNorm)
                    let newB = fujiBlueCurve(bNorm)
                    
                    lutData.append(newR)
                    lutData.append(newG)
                    lutData.append(newB)
                    lutData.append(1.0)
                }
            }
        }
        
        return Data(bytes: lutData, count: lutData.count * MemoryLayout<Float>.size)
    }
    
    /// CineStill 800T LUT生成
    private func generateCineStillLUT() -> Data {
        var lutData = [Float]()
        let size = Self.lutSize
        
        for b in 0..<size {
            for g in 0..<size {
                for r in 0..<size {
                    let rNorm = Float(r) / Float(size - 1)
                    let gNorm = Float(g) / Float(size - 1)
                    let bNorm = Float(b) / Float(size - 1)
                    
                    // CineStill特有の色調整（シネマティック）
                    let newR = cinestillRedCurve(rNorm)
                    let newG = cinestillGreenCurve(gNorm)
                    let newB = cinestillBlueCurve(bNorm)
                    
                    lutData.append(newR)
                    lutData.append(newG)
                    lutData.append(newB)
                    lutData.append(1.0)
                }
            }
        }
        
        return Data(bytes: lutData, count: lutData.count * MemoryLayout<Float>.size)
    }
    
    /// Ilford HP5 LUT生成（モノクロ）
    private func generateIlfordHP5LUT() -> Data {
        var lutData = [Float]()
        let size = Self.lutSize
        
        for b in 0..<size {
            for g in 0..<size {
                for r in 0..<size {
                    let rNorm = Float(r) / Float(size - 1)
                    let gNorm = Float(g) / Float(size - 1)
                    let bNorm = Float(b) / Float(size - 1)
                    
                    // グレースケール変換（Ilford HP5特有のコントラスト）
                    let luminance = 0.299 * rNorm + 0.587 * gNorm + 0.114 * bNorm
                    let adjustedLum = ilfordContrastCurve(luminance)
                    
                    lutData.append(adjustedLum)
                    lutData.append(adjustedLum)
                    lutData.append(adjustedLum)
                    lutData.append(1.0)
                }
            }
        }
        
        return Data(bytes: lutData, count: lutData.count * MemoryLayout<Float>.size)
    }
    
    /// Polaroid 600 LUT生成
    private func generatePolaroidLUT() -> Data {
        var lutData = [Float]()
        let size = Self.lutSize
        
        for b in 0..<size {
            for g in 0..<size {
                for r in 0..<size {
                    let rNorm = Float(r) / Float(size - 1)
                    let gNorm = Float(g) / Float(size - 1)
                    let bNorm = Float(b) / Float(size - 1)
                    
                    // Polaroid特有の色調整（青みがかった感じ）
                    let newR = polaroidRedCurve(rNorm)
                    let newG = polaroidGreenCurve(gNorm)
                    let newB = polaroidBlueCurve(bNorm)
                    
                    lutData.append(newR)
                    lutData.append(newG)
                    lutData.append(newB)
                    lutData.append(1.0)
                }
            }
        }
        
        return Data(bytes: lutData, count: lutData.count * MemoryLayout<Float>.size)
    }
}

// MARK: - Color Curve Functions
extension LUTProcessor {
    
    // Kodak Portra カーブ関数
    private func portraRedCurve(_ x: Float) -> Float {
        // 暖色系に調整
        return min(1.0, x * 1.05 + 0.02)
    }
    
    private func portraGreenCurve(_ x: Float) -> Float {
        return x
    }
    
    private func portraBlueCurve(_ x: Float) -> Float {
        // 青を少し抑える
        return min(1.0, x * 0.95)
    }
    
    // Fuji Pro カーブ関数
    private func fujiRedCurve(_ x: Float) -> Float {
        return x * 0.98
    }
    
    private func fujiGreenCurve(_ x: Float) -> Float {
        // グリーンを強調
        return min(1.0, x * 1.03)
    }
    
    private func fujiBlueCurve(_ x: Float) -> Float {
        return x * 0.97
    }
    
    // CineStill カーブ関数
    private func cinestillRedCurve(_ x: Float) -> Float {
        // シネマティックな赤
        return min(1.0, pow(x, 0.9) * 1.1)
    }
    
    private func cinestillGreenCurve(_ x: Float) -> Float {
        return pow(x, 0.95)
    }
    
    private func cinestillBlueCurve(_ x: Float) -> Float {
        // 青を強調
        return min(1.0, pow(x, 0.85) * 1.05)
    }
    
    // Ilford HP5 コントラストカーブ
    private func ilfordContrastCurve(_ x: Float) -> Float {
        // S字カーブでコントラスト調整
        return 1.0 / (1.0 + exp(-8.0 * (x - 0.5)))
    }
    
    // Polaroid カーブ関数
    private func polaroidRedCurve(_ x: Float) -> Float {
        return min(1.0, x * 0.95 + 0.05)
    }
    
    private func polaroidGreenCurve(_ x: Float) -> Float {
        return min(1.0, x * 0.98 + 0.02)
    }
    
    private func polaroidBlueCurve(_ x: Float) -> Float {
        // 青みを強調
        return min(1.0, x * 1.08)
    }
}