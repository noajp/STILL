//======================================================================
// MARK: - ImageProcessor.swift
// Purpose: ImageProcessor implementation (ImageProcessorの実装)
// Path: still/Core/ImageProcessing/ImageProcessor.swift
//======================================================================
//
//  ImageProcessor.swift
//  tete
//
//  画像処理ユーティリティ
//

import UIKit
import CoreImage

// MARK: - Image Processor
final class ImageProcessor {
    
    // MARK: - Properties
    private let maxImageSize: CGFloat = 2048 // Instagram同等サイズ
    private let thumbnailSize: CGFloat = 100
    
    // MARK: - Image Resizing
    
    /// 画像を最適なサイズにリサイズ
    func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let size = image.size
        
        // 既に適切なサイズの場合はそのまま返す
        if size.width <= maxImageSize && size.height <= maxImageSize {
            return image
        }
        
        // アスペクト比を保持してリサイズ
        let scale = min(maxImageSize / size.width, maxImageSize / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        return resizeImage(image, to: newSize)
    }
    
    /// サムネイル生成
    func createThumbnail(from image: UIImage) -> UIImage? {
        let scale = min(thumbnailSize / image.size.width, thumbnailSize / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        return resizeImage(image, to: newSize)
    }
    
    /// 画像リサイズ実装
    private func resizeImage(_ image: UIImage, to newSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // MARK: - Memory Management
    
    /// メモリ使用量の推定
    func estimateMemoryUsage(for image: UIImage) -> Int {
        let pixelCount = Int(image.size.width * image.scale * image.size.height * image.scale)
        return pixelCount * 4 // 4 bytes per pixel (RGBA)
    }
    
    /// 画像の圧縮
    func compressImage(_ image: UIImage, maxSizeKB: Int = 1024) -> Data? {
        var compression: CGFloat = 1.0
        let maxSizeBytes = maxSizeKB * 1024
        
        while let data = image.jpegData(compressionQuality: compression),
              data.count > maxSizeBytes && compression > 0.1 {
            compression -= 0.1
        }
        
        return image.jpegData(compressionQuality: compression)
    }
    
    // MARK: - Export Functions
    
    /// 編集済み画像のエクスポート
    func exportImage(_ image: UIImage, quality: ExportQuality) -> Data? {
        switch quality {
        case .maximum:
            // PNG形式で最高品質
            return image.pngData()
            
        case .high:
            // JPEG 90%品質
            return image.jpegData(compressionQuality: 0.9)
            
        case .standard:
            // JPEG 80%品質
            return image.jpegData(compressionQuality: 0.8)
            
        case .compressed:
            // サイズ優先で圧縮
            return compressImage(image, maxSizeKB: 512)
        }
    }
}

// MARK: - Export Quality
enum ExportQuality: CaseIterable, Identifiable {
    case maximum    // 元画質を維持
    case high      // 高品質
    case standard  // 標準品質
    case compressed // サイズ優先
    
    var id: String { description }
    
    var description: String {
        switch self {
        case .maximum: return "最高品質"
        case .high: return "高品質"
        case .standard: return "標準"
        case .compressed: return "圧縮"
        }
    }
}

// MARK: - Processing Queue Manager
final class ProcessingQueueManager: @unchecked Sendable {
    static let shared = ProcessingQueueManager()
    
    private let processingQueue = OperationQueue()
    
    private init() {
        processingQueue.name = "com.foodai.imageProcessing"
        processingQueue.maxConcurrentOperationCount = 2
        processingQueue.qualityOfService = .userInitiated
    }
    
    func addOperation(_ operation: Operation) {
        processingQueue.addOperation(operation)
    }
    
    func cancelAllOperations() {
        processingQueue.cancelAllOperations()
    }
}

// MARK: - UIImage Extensions
extension UIImage {
    /// 指定サイズにリサイズ
    func resized(to newSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// アスペクト比を保持してリサイズ
    func resizedAspectFit(to maxSize: CGSize) -> UIImage {
        let scale = min(maxSize.width / size.width, maxSize.height / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return resized(to: newSize)
    }
    
    /// 正方形にクロップ
    func cropped(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
}