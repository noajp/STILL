//======================================================================
// MARK: - RAWImageProcessor.swift
// Purpose: RAWImageProcessor implementation (RAWImageProcessorの実装)
// Path: still/Features/PhotoEditor/Models/RAWImageProcessor.swift
//======================================================================
//
//  RAWImageProcessor.swift
//  tete
//
//  RAW画像処理エンジン
//

import Foundation
import CoreImage
import Photos
import UniformTypeIdentifiers
import UIKit

// MARK: - Photo Editor Data
struct PhotoEditorData: Hashable {
    let asset: PHAsset
    let rawInfo: RAWImageInfo
    let previewImage: UIImage?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(asset.localIdentifier)
        hasher.combine(rawInfo.isRAW)
        hasher.combine(rawInfo.format)
    }
    
    static func == (lhs: PhotoEditorData, rhs: PhotoEditorData) -> Bool {
        return lhs.asset.localIdentifier == rhs.asset.localIdentifier &&
               lhs.rawInfo.isRAW == rhs.rawInfo.isRAW &&
               lhs.rawInfo.format == rhs.rawInfo.format
    }
}

// MARK: - RAW Image Info
struct RAWImageInfo: Hashable {
    let isRAW: Bool
    let format: String?
    let fileSize: Int64
    let dimensions: CGSize
    let asset: PHAsset
    
    var displayFormat: String {
        if isRAW {
            return format?.uppercased() ?? "RAW"
        }
        return "JPEG"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(isRAW)
        hasher.combine(format)
        hasher.combine(fileSize)
        hasher.combine(asset.localIdentifier)
    }
    
    static func == (lhs: RAWImageInfo, rhs: RAWImageInfo) -> Bool {
        return lhs.isRAW == rhs.isRAW &&
               lhs.format == rhs.format &&
               lhs.fileSize == rhs.fileSize &&
               lhs.asset.localIdentifier == rhs.asset.localIdentifier
    }
}

// MARK: - RAW Processing Options
struct RAWProcessingOptions {
    var exposure: Float = 0.0
    var temperature: Float = 6500
    var tint: Float = 0.0
    var highlights: Float = 0.0
    var shadows: Float = 0.0
    var noiseReduction: Float = 0.5
    var colorNoiseReduction: Float = 0.5
    var enableLensCorrection: Bool = true
    var boostAmount: Float = 1.0
    var decoderVersion: Int = 8 // Latest decoder
}

// MARK: - RAW Image Processor
@MainActor
final class RAWImageProcessor: ObservableObject, @unchecked Sendable {
    static let shared = RAWImageProcessor()
    
    private let context = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.extendedSRGB)!,
        .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
    ])
    
    private init() {}
    
    // MARK: - Detection
    
    /// PHAssetがRAW画像かどうかを判定
    func getRAWInfo(for asset: PHAsset) -> RAWImageInfo {
        let resources = PHAssetResource.assetResources(for: asset)
        
        for resource in resources {
            let uti = resource.uniformTypeIdentifier
            
            // RAW形式の検出
            if let utType = UTType(uti), utType.conforms(to: .rawImage) {
                let format = extractFormatFromUTI(uti)
                let fileSize = resource.value(forKey: "fileSize") as? Int64 ?? 0
                
                return RAWImageInfo(
                    isRAW: true,
                    format: format,
                    fileSize: fileSize,
                    dimensions: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                    asset: asset
                )
            }
        }
        
        // 非RAW画像
        return RAWImageInfo(
            isRAW: false,
            format: nil,
            fileSize: 0,
            dimensions: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
            asset: asset
        )
    }
    
    private func extractFormatFromUTI(_ uti: String) -> String? {
        // Canon CR2
        if uti.contains("canon") || uti.contains("cr2") {
            return "CR2"
        }
        // Sony ARW
        if uti.contains("sony") || uti.contains("arw") {
            return "ARW"
        }
        // Nikon NEF
        if uti.contains("nikon") || uti.contains("nef") {
            return "NEF"
        }
        // Adobe DNG
        if uti.contains("adobe") || uti.contains("dng") {
            return "DNG"
        }
        // Fujifilm RAF
        if uti.contains("fuji") || uti.contains("raf") {
            return "RAF"
        }
        // Olympus ORF
        if uti.contains("olympus") || uti.contains("orf") {
            return "ORF"
        }
        
        // 汎用RAW
        return "RAW"
    }
    
    // MARK: - Loading
    
    /// RAW画像を非同期で読み込み
    func loadRAWImage(from asset: PHAsset, 
                     options: RAWProcessingOptions = RAWProcessingOptions(),
                     completion: @escaping (Result<CIImage, Error>) -> Void) {
        
        let requestOptions = PHContentEditingInputRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.canHandleAdjustmentData = { _ in true }
        
        asset.requestContentEditingInput(with: requestOptions) { [weak self] input, info in
            guard let self = self,
                  let input = input,
                  let url = input.fullSizeImageURL else {
                completion(.failure(RAWProcessorError.loadFailed))
                return
            }
            
            autoreleasepool {
                do {
                    let processedImage = try self.processRAWFile(url: url, options: options)
                    DispatchQueue.main.async {
                        completion(.success(processedImage))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    private func processRAWFile(url: URL, options: RAWProcessingOptions) throws -> CIImage {
        // CIRAWFilterを作成
        let rawFilterOptions: [CIRAWFilterOption: Any] = [
            .decoderVersion: options.decoderVersion,
            .noiseReductionAmount: options.noiseReduction,
            .colorNoiseReductionAmount: options.colorNoiseReduction,
            .enableVendorLensCorrection: options.enableLensCorrection,
            .boostAmount: options.boostAmount
        ]
        
        guard let rawFilter = CIRAWFilter(imageURL: url, options: rawFilterOptions) else {
            throw RAWProcessorError.rawFilterCreationFailed
        }
        
        // RAW調整を適用
        rawFilter.exposure = options.exposure
        rawFilter.neutralTemperature = options.temperature
        rawFilter.neutralTint = options.tint
        
        // 基本的なフィルター値を設定
        rawFilter.baselineExposure = 0.0
        rawFilter.shadowBias = options.shadows
        
        guard let outputImage = rawFilter.outputImage else {
            throw RAWProcessorError.processingFailed
        }
        
        return outputImage
    }
    
    // MARK: - Export
    
    /// RAW画像を編集してJPEGに変換（アップロード用）
    func convertRAWToJPEG(image: CIImage, 
                         quality: CGFloat = 0.85,
                         maxDimension: CGFloat = 2048) -> Data? {
        
        return autoreleasepool {
            let extent = image.extent
            let aspectRatio = extent.width / extent.height
            
            // サイズ制限を適用
            var targetSize = extent.size
            if max(extent.width, extent.height) > maxDimension {
                if aspectRatio > 1 {
                    targetSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
                } else {
                    targetSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
                }
            }
            
            // リサイズが必要な場合
            let processedImage: CIImage
            if targetSize != extent.size {
                let scaleX = targetSize.width / extent.width
                let scaleY = targetSize.height / extent.height
                let scale = min(scaleX, scaleY)
                
                processedImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            } else {
                processedImage = image
            }
            
            // JPEG形式で出力
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
            
            // CIContextのcreateImageメソッドを使用してCGImageを作成し、その後JPEGに変換
            guard let cgImage = context.createCGImage(
                processedImage,
                from: processedImage.extent,
                format: .RGBA8,
                colorSpace: colorSpace
            ) else { return nil }
            
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.jpegData(compressionQuality: quality)
        }
    }
    
    /// プレビュー用の軽量画像を生成
    func createPreviewImage(from ciImage: CIImage, targetSize: CGSize = CGSize(width: 512, height: 512)) -> UIImage? {
        let extent = ciImage.extent
        let scaleX = targetSize.width / extent.width
        let scaleY = targetSize.height / extent.height
        let scale = min(scaleX, scaleY)
        
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = context.createCGImage(
            scaledImage,
            from: scaledImage.extent,
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        ) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Errors
enum RAWProcessorError: LocalizedError {
    case loadFailed
    case rawFilterCreationFailed
    case processingFailed
    case conversionFailed
    
    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "Failed to load RAW image"
        case .rawFilterCreationFailed:
            return "Failed to create RAW filter"
        case .processingFailed:
            return "Failed to process RAW image"
        case .conversionFailed:
            return "Failed to convert image format"
        }
    }
}

// MARK: - Extensions
extension PHAsset {
    @MainActor
    var isRAW: Bool {
        return RAWImageProcessor.shared.getRAWInfo(for: self).isRAW
    }
    
    @MainActor
    var rawFormat: String? {
        return RAWImageProcessor.shared.getRAWInfo(for: self).format
    }
}