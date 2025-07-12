//======================================================================
// MARK: - VisionContentModerator
// Purpose: Apple Vision Frameworkを使用したコンテンツモデレーション
// Features: 下半身露出検出、AI生成画像検出
//======================================================================
import Foundation
import Vision
import UIKit
import CoreImage

/// コンテンツモデレーション結果
struct ModerationResult {
    let isApproved: Bool
    let confidence: Float
    let flags: [ModerationFlag]
    let aiGenerationProbability: Float
    let qualityScore: Float
    let analysisTime: TimeInterval
    
    /// 警告メッセージ
    var warningMessage: String? {
        guard !isApproved else { return nil }
        
        let highPriorityFlags = flags.filter { $0.severity == .high }
        if !highPriorityFlags.isEmpty {
            return highPriorityFlags.first?.message
        }
        
        let mediumPriorityFlags = flags.filter { $0.severity == .medium }
        return mediumPriorityFlags.first?.message
    }
}

/// モデレーションフラグ
struct ModerationFlag {
    let type: FlagType
    let severity: Severity
    let confidence: Float
    let message: String
    
    enum FlagType: String, CaseIterable {
        case lowerBodyExposure = "lower_body_exposure"
        case aiGenerated = "ai_generated"
    }
    
    enum Severity: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
}

/// Vision Framework コンテンツモデレーター
@MainActor
class VisionContentModerator: ObservableObject {
    static let shared = VisionContentModerator()
    
    private let secureLogger = SecureLogger.shared
    private let imageAnalysisQueue = DispatchQueue(label: "com.tete.vision.analysis", qos: .userInitiated)
    
    // 設定可能なしきい値
    private let lowerBodyExposureThreshold: Float = 0.75
    private let aiGenerationThreshold: Float = 0.65
    
    private init() {
        secureLogger.info("VisionContentModerator initialized")
    }
    
    // MARK: - Public Methods
    
    /// 画像の簡潔なモデレーション分析（下半身露出・AI生成のみ）
    func moderateContent(_ image: UIImage) async -> ModerationResult {
        let startTime = Date()
        secureLogger.debug("Starting content moderation analysis")
        
        var flags: [ModerationFlag] = []
        var aiProbability: Float = 0.0
        
        // 並列実行でパフォーマンス向上
        async let lowerBodyExposure = detectLowerBodyExposure(image)
        async let aiGeneration = detectAIGeneration(image)
        
        // 結果を統合
        let exposureFlags = await lowerBodyExposure
        aiProbability = await aiGeneration
        
        flags.append(contentsOf: exposureFlags)
        
        // AI生成フラグ
        if aiProbability > aiGenerationThreshold {
            flags.append(ModerationFlag(
                type: .aiGenerated,
                severity: aiProbability > 0.8 ? .high : .medium,
                confidence: aiProbability,
                message: "This image appears to be AI-generated (Confidence: \(Int(aiProbability * 100))%)"
            ))
        }
        
        let analysisTime = Date().timeIntervalSince(startTime)
        
        // 承認判定
        let isApproved = !flags.contains { $0.severity == .high || $0.severity == .critical }
        let overallConfidence = flags.isEmpty ? 1.0 : flags.map { $0.confidence }.reduce(0, +) / Float(flags.count)
        
        let result = ModerationResult(
            isApproved: isApproved,
            confidence: overallConfidence,
            flags: flags,
            aiGenerationProbability: aiProbability,
            qualityScore: 1.0, // 品質チェックは無効化
            analysisTime: analysisTime
        )
        
        secureLogger.info("Content moderation completed", 
                         file: #file, function: #function, line: #line)
        
        return result
    }
    
    // MARK: - Lower Body Exposure Detection
    
    private func detectLowerBodyExposure(_ image: UIImage) async -> [ModerationFlag] {
        guard let cgImage = image.cgImage else {
            return [ModerationFlag(
                type: .lowerBodyExposure,
                severity: .medium,
                confidence: 0.5,
                message: "Unable to analyze image content"
            )]
        }
        
        return await withCheckedContinuation { continuation in
            imageAnalysisQueue.async {
                var flags: [ModerationFlag] = []
                
                // Vision リクエストの作成
                let classificationRequest = VNClassifyImageRequest { request, error in
                    if let error = error {
                        Task { @MainActor in
                            self.secureLogger.error("Vision classification failed: \(error.localizedDescription)")
                        }
                        continuation.resume(returning: flags)
                        return
                    }
                    
                    guard let observations = request.results as? [VNClassificationObservation] else {
                        continuation.resume(returning: flags)
                        return
                    }
                    
                    // 下半身露出の検出（特定のアダルトコンテンツのみ）
                    for observation in observations {
                        let identifier = observation.identifier.lowercased()
                        let confidence = observation.confidence
                        
                        // 下半身露出の特定キーワードチェック
                        let isLowerBody = self.checkLowerBodyExposure(identifier)
                        if isLowerBody && confidence > self.lowerBodyExposureThreshold {
                            flags.append(ModerationFlag(
                                type: .lowerBodyExposure,
                                severity: confidence > 0.9 ? .critical : .high,
                                confidence: confidence,
                                message: "Lower body exposure detected and blocked"
                            ))
                        }
                    }
                    
                    continuation.resume(returning: flags)
                }
                
                // リクエストの実行
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([classificationRequest])
                } catch {
                    Task { @MainActor in
                        self.secureLogger.error("Vision request failed: \(error.localizedDescription)")
                    }
                    continuation.resume(returning: flags)
                }
            }
        }
    }
    
    // MARK: - AI Generation Detection
    
    private func detectAIGeneration(_ image: UIImage) async -> Float {
        guard let cgImage = image.cgImage else { return 0.0 }
        
        var aiProbability: Float = 0.0
        
        // 複数の手法でAI生成を検出
        let noiseAnalysis = await self.analyzeNoisePatternsAsync(cgImage)
        let frequencyAnalysis = await self.analyzeFrequencyDomainAsync(cgImage)
        let artifactAnalysis = await self.detectAIArtifactsAsync(cgImage)
        
        // 総合スコアの計算
        aiProbability = (noiseAnalysis + frequencyAnalysis + artifactAnalysis) / 3.0
        
        Task { @MainActor in
            self.secureLogger.debug("AI generation probability: \(aiProbability)")
        }
        
        return aiProbability
    }
    
    
    // MARK: - Helper Methods
    
    // nonisolated版の下半身露出チェック
    private nonisolated func checkLowerBodyExposure(_ identifier: String) -> Bool {
        let lowerBodyKeywords = [
            "genital", "genitalia", "private", "buttocks", "hip", "groin",
            "nude", "naked", "explicit", "sexual", "intimate",
            "underwear", "lingerie", "bikini bottom"
        ]
        return lowerBodyKeywords.contains { identifier.contains($0) }
    }
    
    private func isLowerBodyExposure(_ identifier: String) -> Bool {
        let lowerBodyKeywords = [
            "genital", "genitalia", "private", "buttocks", "hip", "groin",
            "nude", "naked", "explicit", "sexual", "intimate",
            "underwear", "lingerie", "bikini bottom"
        ]
        return lowerBodyKeywords.contains { identifier.contains($0) }
    }
    
    // 非同期版のヘルパーメソッド
    private nonisolated func analyzeNoisePatternsAsync(_ cgImage: CGImage) async -> Float {
        return await withCheckedContinuation { continuation in
            let result = analyzeNoisePatternsSync(cgImage)
            continuation.resume(returning: result)
        }
    }
    
    private nonisolated func analyzeFrequencyDomainAsync(_ cgImage: CGImage) async -> Float {
        return await withCheckedContinuation { continuation in
            let result = analyzeFrequencyDomainSync(cgImage)
            continuation.resume(returning: result)
        }
    }
    
    private nonisolated func detectAIArtifactsAsync(_ cgImage: CGImage) async -> Float {
        return await withCheckedContinuation { continuation in
            let result = detectAIArtifactsSync(cgImage)
            continuation.resume(returning: result)
        }
    }
    
    // 同期版のヘルパーメソッド（nonisolated）
    private nonisolated func analyzeNoisePatternsSync(_ cgImage: CGImage) -> Float {
        // ノイズパターン解析（AI生成画像特有のパターンを検出）
        let width = cgImage.width
        let height = cgImage.height
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.1
        }
        
        var aiScore: Float = 0.0
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        
        // 1. 画像サイズに基づく判定
        let commonAISizes = [(512, 512), (1024, 1024), (768, 768), (256, 256), (640, 640)]
        for (w, h) in commonAISizes {
            if width == w && height == h {
                aiScore += 0.25
                break
            }
        }
        
        // 2. ピクセル値の異常な均一性チェック
        var pixelVariations: [Float] = []
        let sampleSize = min(1000, width * height / 100)
        
        for _ in 0..<sampleSize {
            let randomX = Int.random(in: 0..<width-1)
            let randomY = Int.random(in: 0..<height-1)
            let pixelOffset = randomY * bytesPerRow + randomX * bytesPerPixel
            
            if pixelOffset + 2 < CFDataGetLength(data) {
                let r1 = Float(bytes[pixelOffset])
                let g1 = Float(bytes[pixelOffset + 1])
                let b1 = Float(bytes[pixelOffset + 2])
                
                let neighborOffset = randomY * bytesPerRow + (randomX + 1) * bytesPerPixel
                let r2 = Float(bytes[neighborOffset])
                let g2 = Float(bytes[neighborOffset + 1])
                let b2 = Float(bytes[neighborOffset + 2])
                
                let variation = sqrt(pow(r2-r1, 2) + pow(g2-g1, 2) + pow(b2-b1, 2))
                pixelVariations.append(variation)
            }
        }
        
        if !pixelVariations.isEmpty {
            let avgVariation = pixelVariations.reduce(0, +) / Float(pixelVariations.count)
            let stdDev = sqrt(pixelVariations.map { pow($0 - avgVariation, 2) }.reduce(0, +) / Float(pixelVariations.count))
            
            // AI生成画像は異常に均一な場合が多い
            if stdDev < 10.0 && avgVariation < 15.0 {
                aiScore += 0.3
            }
        }
        
        // 3. エッジの不自然さ検出は簡略化
        // let edgeConsistency = analyzeEdgeConsistencySync(cgImage)
        // aiScore += edgeConsistency * 0.2
        
        return min(1.0, aiScore)
    }
    
    private nonisolated func analyzeFrequencyDomainSync(_ cgImage: CGImage) -> Float {
        // 周波数ドメイン解析（簡略化版）
        let width = cgImage.width
        let height = cgImage.height
        
        // 簡略なパターン検出
        var artificialPatterns: Float = 0.0
        
        // AI特有のサイズチェック
        let commonAISizes = [(512, 512), (1024, 1024), (768, 768)]
        for (w, h) in commonAISizes {
            if width == w && height == h {
                artificialPatterns += 0.3
                break
            }
        }
        
        return min(1.0, artificialPatterns)
    }
    
    private nonisolated func detectAIArtifactsSync(_ cgImage: CGImage) -> Float {
        var artifactScore: Float = 0.0
        
        // 1. グリッドパターンの検出簡略版
        let gridPattern = detectGridPatternSync(cgImage)
        artifactScore += gridPattern * 0.4
        
        // 2. 不自然な対称性の検出簡略版
        let symmetryArtifacts = detectUnnaturalSymmetrySync(cgImage)
        artifactScore += symmetryArtifacts * 0.3
        
        return min(1.0, artifactScore)
    }
    
    private nonisolated func detectGridPatternSync(_ cgImage: CGImage) -> Float {
        let width = cgImage.width
        let height = cgImage.height
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.0
        }
        
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        
        var gridScore: Float = 0.0
        let gridSizes = [8, 16, 32]
        
        for gridSize in gridSizes {
            var matches = 0
            var totalChecks = 0
            
            for y in stride(from: 0, to: height - gridSize, by: gridSize) {
                for x in stride(from: 0, to: width - gridSize, by: gridSize) {
                    let offset = y * bytesPerRow + x * bytesPerPixel
                    if offset + bytesPerPixel < CFDataGetLength(data) {
                        let r = Float(bytes[offset])
                        
                        if x + gridSize < width {
                            let nextOffset = y * bytesPerRow + (x + gridSize) * bytesPerPixel
                            let nextR = Float(bytes[nextOffset])
                            
                            if abs(r - nextR) > 20.0 {
                                matches += 1
                            }
                            totalChecks += 1
                        }
                    }
                }
            }
            
            if totalChecks > 0 {
                let gridRatio = Float(matches) / Float(totalChecks)
                gridScore = max(gridScore, gridRatio)
            }
        }
        
        return gridScore
    }
    
    private nonisolated func detectUnnaturalSymmetrySync(_ cgImage: CGImage) -> Float {
        let width = cgImage.width
        let height = cgImage.height
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.0
        }
        
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        
        var symmetryScore: Float = 0.0
        let sampleSize = min(50, width / 4)
        
        var horizontalMatches = 0
        for _ in 0..<sampleSize {
            let y = Int.random(in: height/4..<3*height/4)
            let x1 = Int.random(in: 0..<width/2)
            let x2 = width - 1 - x1
            
            let offset1 = y * bytesPerRow + x1 * bytesPerPixel
            let offset2 = y * bytesPerRow + x2 * bytesPerPixel
            
            if offset2 + 2 < CFDataGetLength(data) {
                let r1 = Float(bytes[offset1])
                let r2 = Float(bytes[offset2])
                
                if abs(r1 - r2) < 10.0 {
                    horizontalMatches += 1
                }
            }
        }
        
        let horizontalSymmetry = Float(horizontalMatches) / Float(sampleSize)
        if horizontalSymmetry > 0.8 {
            symmetryScore += 0.5
        }
        
        return symmetryScore
    }
    
    private func analyzeNoisePatterns(_ cgImage: CGImage) -> Float {
        // ノイズパターン解析（AI生成画像特有のパターンを検出）
        let width = cgImage.width
        let height = cgImage.height
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.1
        }
        
        var aiScore: Float = 0.0
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        
        // 1. 画像サイズに基づく判定
        let commonAISizes = [(512, 512), (1024, 1024), (768, 768), (256, 256), (640, 640)]
        for (w, h) in commonAISizes {
            if width == w && height == h {
                aiScore += 0.25
                break
            }
        }
        
        // 2. ピクセル値の異常な均一性チェック
        var pixelVariations: [Float] = []
        let sampleSize = min(1000, width * height / 100)
        
        for _ in 0..<sampleSize {
            let randomX = Int.random(in: 0..<width-1)
            let randomY = Int.random(in: 0..<height-1)
            let pixelOffset = randomY * bytesPerRow + randomX * bytesPerPixel
            
            if pixelOffset + 2 < CFDataGetLength(data) {
                let r1 = Float(bytes[pixelOffset])
                let g1 = Float(bytes[pixelOffset + 1])
                let b1 = Float(bytes[pixelOffset + 2])
                
                let neighborOffset = randomY * bytesPerRow + (randomX + 1) * bytesPerPixel
                let r2 = Float(bytes[neighborOffset])
                let g2 = Float(bytes[neighborOffset + 1])
                let b2 = Float(bytes[neighborOffset + 2])
                
                let variation = sqrt(pow(r2-r1, 2) + pow(g2-g1, 2) + pow(b2-b1, 2))
                pixelVariations.append(variation)
            }
        }
        
        if !pixelVariations.isEmpty {
            let avgVariation = pixelVariations.reduce(0, +) / Float(pixelVariations.count)
            let stdDev = sqrt(pixelVariations.map { pow($0 - avgVariation, 2) }.reduce(0, +) / Float(pixelVariations.count))
            
            // AI生成画像は異常に均一な場合が多い
            if stdDev < 10.0 && avgVariation < 15.0 {
                aiScore += 0.3
            }
        }
        
        // 3. エッジの不自然さ検出
        let edgeConsistency = analyzeEdgeConsistency(cgImage)
        aiScore += edgeConsistency * 0.2
        
        return min(1.0, aiScore)
    }
    
    private func analyzeFrequencyDomain(_ cgImage: CGImage) -> Float {
        // 周波数ドメイン解析（DCT係数の異常検出）
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        // 画像を小さなブロックに分割してDCT解析
        let blockSize = 8
        let width = cgImage.width
        let height = cgImage.height
        
        var artificialPatterns: Float = 0.0
        var totalBlocks = 0
        
        for y in stride(from: 0, to: height - blockSize, by: blockSize) {
            for x in stride(from: 0, to: width - blockSize, by: blockSize) {
                let rect = CGRect(x: x, y: y, width: blockSize, height: blockSize)
                let croppedImage = ciImage.cropped(to: rect)
                
                // 高周波成分の異常な規則性をチェック
                if let cgBlock = context.createCGImage(croppedImage, from: rect) {
                    let blockArtifacts = detectBlockArtifacts(cgBlock)
                    artificialPatterns += blockArtifacts
                    totalBlocks += 1
                }
            }
        }
        
        guard totalBlocks > 0 else { return 0.0 }
        
        let averageArtifacts = artificialPatterns / Float(totalBlocks)
        
        // JPEG圧縮アーティファクトの検出
        let compressionArtifacts = detectCompressionArtifacts(cgImage)
        
        return min(1.0, averageArtifacts + compressionArtifacts * 0.3)
    }
    
    private func detectAIArtifacts(_ cgImage: CGImage) -> Float {
        var artifactScore: Float = 0.0
        
        // 1. グリッドパターンの検出
        let gridPattern = detectGridPattern(cgImage)
        artifactScore += gridPattern * 0.4
        
        // 2. 不自然な対称性の検出
        let symmetryArtifacts = detectUnnaturalSymmetry(cgImage)
        artifactScore += symmetryArtifacts * 0.3
        
        // 3. テクスチャの異常な繰り返し
        let textureRepeats = detectTextureRepeats(cgImage)
        artifactScore += textureRepeats * 0.2
        
        // 4. 色の異常な分布
        let colorDistribution = analyzeColorDistribution(cgImage)
        artifactScore += colorDistribution * 0.1
        
        return min(1.0, artifactScore)
    }
    
    // MARK: - Advanced AI Detection Helper Methods
    
    private func analyzeEdgeConsistency(_ cgImage: CGImage) -> Float {
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        guard let edgeFilter = CIFilter(name: "CIEdges") else { return 0.0 }
        edgeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let edgeImage = edgeFilter.outputImage,
              let cgEdges = context.createCGImage(edgeImage, from: edgeImage.extent) else {
            return 0.0
        }
        
        // エッジの不自然な直線性をチェック
        return analyzeEdgeLinearity(cgEdges)
    }
    
    private func detectBlockArtifacts(_ cgImage: CGImage) -> Float {
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.0
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        
        var blockiness: Float = 0.0
        
        // 8x8ブロック境界での不連続性をチェック
        for y in stride(from: 8, to: height, by: 8) {
            for x in 0..<width {
                if y < height && x < width {
                    let offset1 = (y-1) * bytesPerRow + x * bytesPerPixel
                    let offset2 = y * bytesPerRow + x * bytesPerPixel
                    
                    if offset2 + 2 < CFDataGetLength(data) {
                        let diff = abs(Float(bytes[offset1]) - Float(bytes[offset2]))
                        blockiness += diff
                    }
                }
            }
        }
        
        return min(1.0, blockiness / Float(width * height / 64))
    }
    
    private func detectCompressionArtifacts(_ cgImage: CGImage) -> Float {
        // JPEG特有の8x8ブロックアーティファクトを検出
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        // ハイパスフィルターで高周波成分を抽出
        guard let filter = CIFilter(name: "CIHighlightShadowAdjust") else { return 0.0 }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(1.0, forKey: "inputHighlightAmount")
        
        guard let filteredImage = filter.outputImage else { return 0.0 }
        
        // 圧縮アーティファクトの特徴的なパターンを検出
        return analyzeCompressionPatterns(filteredImage, context: context)
    }
    
    private func detectGridPattern(_ cgImage: CGImage) -> Float {
        let width = cgImage.width
        let height = cgImage.height
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.0
        }
        
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        
        var gridScore: Float = 0.0
        let gridSizes = [8, 16, 32, 64] // 一般的なAI生成のグリッドサイズ
        
        for gridSize in gridSizes {
            var matches = 0
            var totalChecks = 0
            
            for y in stride(from: 0, to: height - gridSize, by: gridSize) {
                for x in stride(from: 0, to: width - gridSize, by: gridSize) {
                    // グリッド境界での色の急激な変化をチェック
                    let offset = y * bytesPerRow + x * bytesPerPixel
                    if offset + bytesPerPixel < CFDataGetLength(data) {
                        let r = Float(bytes[offset])
                        
                        // 隣接グリッドとの差分
                        if x + gridSize < width {
                            let nextOffset = y * bytesPerRow + (x + gridSize) * bytesPerPixel
                            let nextR = Float(bytes[nextOffset])
                            
                            if abs(r - nextR) > 20.0 { // 閾値は調整可能
                                matches += 1
                            }
                            totalChecks += 1
                        }
                    }
                }
            }
            
            if totalChecks > 0 {
                let gridRatio = Float(matches) / Float(totalChecks)
                gridScore = max(gridScore, gridRatio)
            }
        }
        
        return gridScore
    }
    
    private func detectUnnaturalSymmetry(_ cgImage: CGImage) -> Float {
        // 画像の左右、上下の異常な対称性を検出
        let width = cgImage.width
        let height = cgImage.height
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.0
        }
        
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        
        var symmetryScore: Float = 0.0
        let sampleSize = min(100, width / 4)
        
        // 水平対称性チェック
        var horizontalMatches = 0
        for _ in 0..<sampleSize {
            let y = Int.random(in: height/4..<3*height/4)
            let x1 = Int.random(in: 0..<width/2)
            let x2 = width - 1 - x1
            
            let offset1 = y * bytesPerRow + x1 * bytesPerPixel
            let offset2 = y * bytesPerRow + x2 * bytesPerPixel
            
            if offset2 + 2 < CFDataGetLength(data) {
                let r1 = Float(bytes[offset1])
                let r2 = Float(bytes[offset2])
                
                if abs(r1 - r2) < 10.0 { // 許容誤差
                    horizontalMatches += 1
                }
            }
        }
        
        let horizontalSymmetry = Float(horizontalMatches) / Float(sampleSize)
        if horizontalSymmetry > 0.8 { // 異常に高い対称性
            symmetryScore += 0.5
        }
        
        return symmetryScore
    }
    
    private func detectTextureRepeats(_ cgImage: CGImage) -> Float {
        // テクスチャの不自然な繰り返しパターンを検出
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        // テクスチャフィルターを適用
        guard let filter = CIFilter(name: "CIGloom") else { return 0.0 }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(10.0, forKey: kCIInputRadiusKey)
        filter.setValue(0.5, forKey: kCIInputIntensityKey)
        
        guard let textureImage = filter.outputImage else { return 0.0 }
        
        return analyzeTexturePatterns(textureImage, context: context)
    }
    
    private func analyzeColorDistribution(_ cgImage: CGImage) -> Float {
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.0
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        
        var colorHistogram: [Int] = Array(repeating: 0, count: 256)
        let sampleSize = min(10000, width * height / 10)
        
        // カラーヒストグラムを作成
        for _ in 0..<sampleSize {
            let x = Int.random(in: 0..<width)
            let y = Int.random(in: 0..<height)
            let offset = y * bytesPerRow + x * bytesPerPixel
            
            if offset < CFDataGetLength(data) {
                let intensity = Int(bytes[offset])
                colorHistogram[intensity] += 1
            }
        }
        
        // 異常な色分布を検出（AI生成画像は特定の色域に偏りがち）
        var peakCount = 0
        for i in 1..<255 {
            if colorHistogram[i] > colorHistogram[i-1] && colorHistogram[i] > colorHistogram[i+1] {
                if colorHistogram[i] > sampleSize / 50 { // 閾値
                    peakCount += 1
                }
            }
        }
        
        // 異常に少ないピーク数はAI生成の可能性
        return peakCount < 5 ? 0.3 : 0.0
    }
    
    // MARK: - Helper Analysis Methods
    
    private func analyzeEdgeLinearity(_ cgImage: CGImage) -> Float {
        // エッジの直線性を分析（AI生成画像は異常に直線的なエッジが多い）
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.0
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = cgImage.bytesPerRow
        
        var linearEdges = 0
        var totalEdges = 0
        
        // 水平・垂直方向の直線的なエッジを検出
        for y in 1..<height-1 {
            for x in 1..<width-1 {
                let offset = y * bytesPerRow + x
                if offset < CFDataGetLength(data) {
                    let center = Int(bytes[offset])
                    let left = Int(bytes[offset - 1])
                    let right = Int(bytes[offset + 1])
                    let top = Int(bytes[(y-1) * bytesPerRow + x])
                    let bottom = Int(bytes[(y+1) * bytesPerRow + x])
                    
                    // エッジの検出
                    let horizontalGradient = abs(left - right)
                    let verticalGradient = abs(top - bottom)
                    
                    if horizontalGradient > 30 || verticalGradient > 30 {
                        totalEdges += 1
                        
                        // 直線性のチェック（隣接ピクセルとの一貫性）
                        if (horizontalGradient > 30 && abs(center - left) > 20 && abs(center - right) > 20) ||
                           (verticalGradient > 30 && abs(center - top) > 20 && abs(center - bottom) > 20) {
                            linearEdges += 1
                        }
                    }
                }
            }
        }
        
        guard totalEdges > 0 else { return 0.0 }
        
        let linearityRatio = Float(linearEdges) / Float(totalEdges)
        return linearityRatio > 0.7 ? 0.4 : 0.0 // 70%以上が直線的なら疑わしい
    }
    
    private func analyzeCompressionPatterns(_ ciImage: CIImage, context: CIContext) -> Float {
        // 圧縮パターンの分析（簡略化版）
        let extent = ciImage.extent
        let width = Int(extent.width)
        let height = Int(extent.height)
        
        guard width > 0 && height > 0 else { return 0.0 }
        
        // 8x8ブロックでの異常なパターンをチェック
        var artifactBlocks = 0
        var totalBlocks = 0
        
        for y in stride(from: 0, to: height - 8, by: 8) {
            for x in stride(from: 0, to: width - 8, by: 8) {
                let blockRect = CGRect(x: x, y: y, width: 8, height: 8)
                let blockImage = ciImage.cropped(to: blockRect)
                
                if hasCompressionArtifacts(blockImage, context: context) {
                    artifactBlocks += 1
                }
                totalBlocks += 1
            }
        }
        
        guard totalBlocks > 0 else { return 0.0 }
        return Float(artifactBlocks) / Float(totalBlocks)
    }
    
    private func analyzeTexturePatterns(_ ciImage: CIImage, context: CIContext) -> Float {
        // テクスチャパターンの分析（簡略化版）
        let extent = ciImage.extent
        guard extent.width > 32 && extent.height > 32 else { return 0.0 }
        
        // 小さなブロックでテクスチャの類似性をチェック
        let blockSize = 16
        var similarBlocks = 0
        var totalComparisons = 0
        
        for y in stride(from: 0, to: Int(extent.height) - blockSize * 2, by: blockSize) {
            for x in stride(from: 0, to: Int(extent.width) - blockSize * 2, by: blockSize) {
                let block1 = ciImage.cropped(to: CGRect(x: x, y: y, width: blockSize, height: blockSize))
                let block2 = ciImage.cropped(to: CGRect(x: x + blockSize, y: y, width: blockSize, height: blockSize))
                
                if areBlocksSimilar(block1, block2, context: context) {
                    similarBlocks += 1
                }
                totalComparisons += 1
            }
        }
        
        guard totalComparisons > 0 else { return 0.0 }
        let similarityRatio = Float(similarBlocks) / Float(totalComparisons)
        return similarityRatio > 0.6 ? 0.3 : 0.0 // 60%以上類似なら疑わしい
    }
    
    private func hasCompressionArtifacts(_ ciImage: CIImage, context: CIContext) -> Bool {
        // 簡略化された圧縮アーティファクト検出
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return false }
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else { return false }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = cgImage.bytesPerRow
        
        var blockiness = 0
        var totalChecks = 0
        
        // ブロック境界での急激な変化をチェック
        for y in 0..<height-1 {
            for x in 0..<width-1 {
                let offset = y * bytesPerRow + x
                if offset + bytesPerRow + 1 < CFDataGetLength(data) {
                    let current = Int(bytes[offset])
                    let right = Int(bytes[offset + 1])
                    let bottom = Int(bytes[offset + bytesPerRow])
                    
                    if abs(current - right) > 20 || abs(current - bottom) > 20 {
                        blockiness += 1
                    }
                    totalChecks += 1
                }
            }
        }
        
        return totalChecks > 0 && Float(blockiness) / Float(totalChecks) > 0.3
    }
    
    private func areBlocksSimilar(_ block1: CIImage, _ block2: CIImage, context: CIContext) -> Bool {
        // ブロック間の類似性を計算（簡略化版）
        guard let cgImage1 = context.createCGImage(block1, from: block1.extent),
              let cgImage2 = context.createCGImage(block2, from: block2.extent) else { return false }
        
        guard let data1 = cgImage1.dataProvider?.data,
              let data2 = cgImage2.dataProvider?.data,
              let bytes1 = CFDataGetBytePtr(data1),
              let bytes2 = CFDataGetBytePtr(data2) else { return false }
        
        let length = min(CFDataGetLength(data1), CFDataGetLength(data2))
        var differences = 0
        let sampleSize = min(100, length / 4)
        
        for i in stride(from: 0, to: sampleSize, by: 4) {
            if i < length {
                let diff = abs(Int(bytes1[i]) - Int(bytes2[i]))
                if diff > 20 {
                    differences += 1
                }
            }
        }
        
        return Float(differences) / Float(sampleSize / 4) < 0.2 // 20%未満の差異なら類似
    }
    
}

// MARK: - Content Moderation Extensions

extension VisionContentModerator {
    
    /// 迅速なプレスクリーニング（カメラプレビュー用）
    func quickScreening(_ image: UIImage) async -> Bool {
        let result = await moderateContent(image)
        return result.isApproved && !result.flags.contains { $0.severity == .critical }
    }
    
    /// 詳細分析レポート生成
    func generateDetailedReport(_ image: UIImage) async -> String {
        let result = await moderateContent(image)
        
        var report = "=== Content Moderation Report ===\n"
        report += "Status: \(result.isApproved ? "APPROVED" : "REJECTED")\n"
        report += "Overall Confidence: \(String(format: "%.2f", result.confidence))\n"
        report += "AI Generation Probability: \(String(format: "%.2f", result.aiGenerationProbability))\n"
        report += "Analysis Time: \(String(format: "%.3f", result.analysisTime))s\n\n"
        
        if !result.flags.isEmpty {
            report += "Flags:\n"
            for flag in result.flags {
                report += "- \(flag.type.rawValue): \(flag.message) (Confidence: \(String(format: "%.2f", flag.confidence)))\n"
            }
        }
        
        return report
    }
}