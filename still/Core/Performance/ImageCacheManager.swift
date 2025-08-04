//======================================================================
// MARK: - ImageCacheManager.swift
// Purpose: Manager class for system operations (ImageCacheManagerのシステム操作管理クラス)
// Path: still/Core/Performance/ImageCacheManager.swift
//======================================================================
//
//  ImageCacheManager.swift
//  tete
//
//  高度な画像キャッシュとパフォーマンス最適化
//

import UIKit
import SwiftUI
import Combine

// MARK: - Image Cache Manager
@MainActor
final class ImageCacheManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ImageCacheManager()
    
    // MARK: - Properties
    let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var loadingTasks: [String: Task<UIImage?, Error>] = [:]
    
    // Configuration
    private let maxMemoryCache: Int = 100 * 1024 * 1024 // 100MB
    private let maxDiskCache: Int = 500 * 1024 * 1024   // 500MB
    private let cacheExpiration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    // MARK: - Initialization
    private init() {
        // Setup cache directory
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cacheDir.appendingPathComponent("ImageCache")
        
        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure memory cache
        cache.totalCostLimit = maxMemoryCache
        cache.countLimit = 200
        
        // Setup background cleanup
        setupCleanupTimer()
        
        print("📱 ImageCacheManager initialized")
    }
    
    // MARK: - Public Methods
    
    /// サムネイルを非同期で取得（キャッシュ優先）
    func loadThumbnail(from urlString: String, size: String = "medium") async -> UIImage? {
        guard URL(string: urlString) != nil else { 
            print("❌ Invalid URL for thumbnail: \(urlString)")
            return nil 
        }
        
        let cacheKey = "\(urlString)_thumb_\(size)" as NSString
        
        // 1. Memory cache check
        if let cachedImage = cache.object(forKey: cacheKey) {
            print("✅ Thumbnail found in cache: \(urlString)")
            return cachedImage
        }
        
        // 2. Check if already loading
        if let existingTask = loadingTasks["\(urlString)_thumb_\(size)"] {
            print("⏳ Thumbnail already loading: \(urlString)")
            return try? await existingTask.value
        }
        
        // 3. Load full image and create thumbnail
        print("🔄 Loading full image to create thumbnail: \(urlString)")
        if let fullImage = await loadImage(from: urlString) {
            let thumbnailSize = getThumbnailSize(for: size)
            print("📏 Creating thumbnail with size: \(thumbnailSize)")
            
            if let thumbnail = ImageProcessor().generateThumbnail(fullImage, size: thumbnailSize) {
                cache.setObject(thumbnail, forKey: cacheKey, cost: estimateMemoryUsage(for: thumbnail))
                print("✅ Thumbnail created successfully: \(urlString)")
                return thumbnail
            } else {
                print("❌ Failed to generate thumbnail: \(urlString)")
            }
        } else {
            print("❌ Failed to load full image for thumbnail: \(urlString)")
        }
        
        return nil
    }
    
    /// 画像を非同期で取得（キャッシュ優先）
    func loadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        let cacheKey = urlString as NSString
        
        // 1. Memory cache check
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // 2. Check if already loading
        if let existingTask = loadingTasks[urlString] {
            return try? await existingTask.value
        }
        
        // 3. Create new loading task
        let task = Task<UIImage?, Error> {
            // Check disk cache
            if let diskImage = await loadFromDisk(url: url) {
                cache.setObject(diskImage, forKey: cacheKey, cost: estimateMemoryUsage(for: diskImage))
                return diskImage
            }
            
            // Download from network
            return await downloadImage(from: url)
        }
        
        loadingTasks[urlString] = task
        
        do {
            let image = try await task.value
            loadingTasks.removeValue(forKey: urlString)
            return image
        } catch {
            loadingTasks.removeValue(forKey: urlString)
            print("❌ Failed to load image: \(error)")
            return nil
        }
    }
    
    /// 画像をプリロード（バックグラウンド）
    func preloadImages(_ urls: [String]) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        _ = await self.loadImage(from: url)
                    }
                }
            }
        }
    }
    
    /// グリッドビュー用のサムネイルプリロード（高速表示）
    func preloadThumbnailsForGrid(_ urls: [String], size: String = "medium") {
        Task.detached(priority: .background) {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        _ = await self.loadThumbnail(from: url, size: size)
                    }
                }
            }
        }
    }
    
    /// 圧縮された画像を取得（グリッドビュー用）
    func loadCompressedImage(from urlString: String, quality: CompressionQuality = .medium) async -> UIImage? {
        print("🔍 loadCompressedImage called for: \(urlString)")
        guard URL(string: urlString) != nil else { 
            print("❌ Invalid URL in loadCompressedImage: \(urlString)")
            return nil 
        }
        
        let cacheKey = "\(urlString)_compressed_\(quality.rawValue)" as NSString
        
        // 1. Memory cache check
        if let cachedImage = cache.object(forKey: cacheKey) {
            print("✅ Compressed image found in cache: \(urlString)")
            return cachedImage
        }
        
        // 2. Load full image and compress
        print("🔄 Loading full image for compression: \(urlString)")
        if let fullImage = await loadImage(from: urlString) {
            print("📏 Compressing image: \(urlString)")
            let compressedImage = compressImageForGrid(fullImage, quality: quality)
            
            // Cache compressed image
            cache.setObject(compressedImage, forKey: cacheKey, cost: estimateMemoryUsage(for: compressedImage))
            print("✅ Image compressed and cached: \(urlString)")
            return compressedImage
        }
        
        print("❌ Failed to load/compress image: \(urlString)")
        return nil
    }
    
    /// 画像圧縮品質レベル
    enum CompressionQuality: String, CaseIterable {
        case low = "low"           // 0.3 quality, 200px max
        case medium = "medium"     // 0.5 quality, 400px max  
        case high = "high"         // 0.7 quality, 600px max
        case grid = "grid"         // 0.8 quality, 800px max - optimized for grid
        case original = "original" // No compression
        
        var jpegQuality: CGFloat {
            switch self {
            case .low: return 0.3
            case .medium: return 0.5
            case .high: return 0.7
            case .grid: return 0.8
            case .original: return 1.0
            }
        }
        
        var maxDimension: CGFloat {
            switch self {
            case .low: return 200
            case .medium: return 400
            case .high: return 600
            case .grid: return 800
            case .original: return 2048
            }
        }
    }
    
    /// キャッシュをクリア
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        print("🗑️ Image cache cleared")
    }
    
    /// サムネイルサイズを取得
    private func getThumbnailSize(for size: String) -> CGSize {
        switch size {
        case "small":
            return CGSize(width: 80, height: 80)
        case "medium":
            return CGSize(width: 150, height: 150)
        case "large":
            return CGSize(width: 300, height: 300)
        default:
            return CGSize(width: 150, height: 150)
        }
    }
    
    /// キャッシュサイズを取得
    func getCacheSize() -> (memory: Int, disk: Int) {
        let memorySize = cache.totalCostLimit
        let diskSize = getDiskCacheSize()
        return (memory: memorySize, disk: diskSize)
    }
    
    // MARK: - Private Methods
    
    private func loadFromDisk(url: URL) async -> UIImage? {
        let filename = url.absoluteString.hashValue.description
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        // Check if file is expired
        if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
           let modificationDate = attributes[.modificationDate] as? Date,
           Date().timeIntervalSince(modificationDate) > cacheExpiration {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    private func downloadImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let image = UIImage(data: data) else { return nil }
            
            // Optimize image
            let optimizedImage = optimizeImage(image)
            
            // Cache in memory
            let cacheKey = url.absoluteString as NSString
            let cost = estimateMemoryUsage(for: optimizedImage)
            cache.setObject(optimizedImage, forKey: cacheKey, cost: cost)
            
            // Save to disk
            await saveToDisk(image: optimizedImage, url: url)
            
            return optimizedImage
            
        } catch {
            print("❌ Download failed: \(error)")
            return nil
        }
    }
    
    private func optimizeImage(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024
        let size = image.size
        
        // Skip if already small enough
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if aspectRatio > 1 {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Resize image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// グリッドビュー用画像圧縮
    private func compressImageForGrid(_ image: UIImage, quality: CompressionQuality) -> UIImage {
        let maxDimension = quality.maxDimension
        let size = image.size
        
        // Calculate new size while maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if max(size.width, size.height) <= maxDimension {
            newSize = size
        } else if aspectRatio > 1 {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Resize image with high quality rendering
        let format = UIGraphicsImageRendererFormat()
        // Note: scale and opaque properties may not be available in all iOS versions
        // Using default format which should provide good quality
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        
        return renderer.image { context in
            // Set high quality rendering
            context.cgContext.interpolationQuality = .high
            context.cgContext.setShouldAntialias(true)
            context.cgContext.setAllowsAntialiasing(true)
            
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func saveToDisk(image: UIImage, url: URL) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let filename = url.absoluteString.hashValue.description
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        try? data.write(to: fileURL)
    }
    
    private func estimateMemoryUsage(for image: UIImage) -> Int {
        let pixelCount = Int(image.size.width * image.scale * image.size.height * image.scale)
        return pixelCount * 4 // 4 bytes per pixel (RGBA)
    }
    
    private func getDiskCacheSize() -> Int {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize = 0
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
    
    private func setupCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task { @MainActor in
                await self.cleanupExpiredFiles()
            }
        }
    }
    
    private func cleanupExpiredFiles() async {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }
        
        // Convert to array to avoid async iteration issues
        let allFiles = enumerator.allObjects.compactMap { $0 as? URL }
        
        for fileURL in allFiles {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
               let modificationDate = resourceValues.contentModificationDate,
               Date().timeIntervalSince(modificationDate) > cacheExpiration {
                try? fileManager.removeItem(at: fileURL)
            }
        }
        
        // Check if disk cache is too large
        let diskSize = getDiskCacheSize()
        if diskSize > maxDiskCache {
            await cleanupOldestFiles()
        }
    }
    
    private func cleanupOldestFiles() async {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) else {
            return
        }
        
        var files: [(url: URL, date: Date, size: Int)] = []
        
        // Convert to array to avoid async iteration issues
        let allFiles = enumerator.allObjects.compactMap { $0 as? URL }
        
        for fileURL in allFiles {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
               let modificationDate = resourceValues.contentModificationDate,
               let fileSize = resourceValues.fileSize {
                files.append((url: fileURL, date: modificationDate, size: fileSize))
            }
        }
        
        // Sort by modification date (oldest first)
        files.sort { $0.date < $1.date }
        
        var currentSize = getDiskCacheSize()
        let targetSize = maxDiskCache * 8 / 10 // Reduce to 80% of max
        
        for file in files {
            if currentSize <= targetSize { break }
            
            try? fileManager.removeItem(at: file.url)
            currentSize -= file.size
        }
    }
}

// MARK: - Optimized AsyncImage
struct OptimizedAsyncImage<Content: View>: View {
    let urlString: String
    let content: (AsyncImagePhase) -> Content
    
    @StateObject private var cacheManager = ImageCacheManager.shared
    @State private var image: UIImage?
    @State private var isLoading = true
    
    @MainActor
    init(urlString: String, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.urlString = urlString
        self.content = content
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(.success(Image(uiImage: image)))
            } else if isLoading {
                content(.empty)
            } else {
                content(.failure(URLError(.badURL)))
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        isLoading = true
        print("🔄 OptimizedAsyncImage loading: \(urlString)")
        image = await cacheManager.loadImage(from: urlString)
        print("✅ OptimizedAsyncImage result: \(image != nil ? "success" : "failed") for \(urlString)")
        isLoading = false
    }
}

// MARK: - Thumbnail Optimized AsyncImage for Grid View
@MainActor
struct ThumbnailAsyncImage: View {
    let urlString: String
    let thumbnailSize: ThumbnailSize
    let placeholder: AnyView
    
    @State private var thumbnailImage: UIImage?
    @State private var fullImage: UIImage?
    @State private var isLoading = true
    
    enum ThumbnailSize: String {
        case small = "small"
        case medium = "medium" 
        case large = "large"
    }
    
    @MainActor
    init(urlString: String, thumbnailSize: ThumbnailSize = .medium, @ViewBuilder placeholder: () -> some View) {
        self.urlString = urlString
        self.thumbnailSize = thumbnailSize
        self.placeholder = AnyView(placeholder())
    }
    
    var body: some View {
        Group {
            if let fullImage = fullImage {
                // Show full resolution image when available
                Image(uiImage: fullImage)
                    .resizable()
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            } else if let thumbnailImage = thumbnailImage {
                // Show thumbnail while full image loads
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .transition(.opacity.animation(.easeInOut(duration: 0.1)))
            } else {
                // Show placeholder while loading
                placeholder
            }
        }
        .task {
            await loadProgressively()
        }
    }
    
    private func loadProgressively() async {
        isLoading = true
        
        // Step 1: Try to load thumbnail first for instant display
        thumbnailImage = await ImageCacheManager.shared.loadThumbnail(from: urlString, size: thumbnailSize.rawValue)
        
        // Step 2: If thumbnail failed, try to load full image directly
        if thumbnailImage == nil {
            print("🔄 Thumbnail failed for \(urlString), loading full image directly")
            fullImage = await ImageCacheManager.shared.loadImage(from: urlString)
            isLoading = false
            return
        }
        
        // Step 3: Load full image in background with longer delay for grid optimization
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                // Longer delay for grid view to prioritize visible thumbnails
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                let fullImageResult = await ImageCacheManager.shared.loadImage(from: urlString)
                
                await MainActor.run {
                    if let fullImageResult = fullImageResult {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.fullImage = fullImageResult
                        }
                    }
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Compressed AsyncImage for Grid Views
struct CompressedAsyncImage: View {
    let urlString: String
    let compressionQuality: ImageCacheManager.CompressionQuality
    let placeholder: AnyView
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    @MainActor
    init(urlString: String, quality: ImageCacheManager.CompressionQuality = .medium, @ViewBuilder placeholder: () -> some View) {
        self.urlString = urlString
        self.compressionQuality = quality
        self.placeholder = AnyView(placeholder())
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            } else {
                placeholder
            }
        }
        .task {
            await loadCompressedImage()
        }
    }
    
    private func loadCompressedImage() async {
        isLoading = true
        print("🔄 CompressedAsyncImage loading: \(urlString)")
        image = await ImageCacheManager.shared.loadCompressedImage(from: urlString, quality: compressionQuality)
        print("✅ CompressedAsyncImage result: \(image != nil ? "success" : "failed") for \(urlString)")
        isLoading = false
    }
}

// MARK: - Simple Optimized AsyncImage
struct FastAsyncImage: View {
    let urlString: String
    let placeholder: AnyView
    
    @State private var image: UIImage?
    
    @MainActor
    init(urlString: String, @ViewBuilder placeholder: () -> some View) {
        self.urlString = urlString
        self.placeholder = AnyView(placeholder())
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                placeholder
            }
        }
        .task {
            image = await ImageCacheManager.shared.loadImage(from: urlString)
        }
    }
}