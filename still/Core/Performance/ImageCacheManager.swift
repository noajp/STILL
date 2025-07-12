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
    private let cache = NSCache<NSString, UIImage>()
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
    
    /// キャッシュをクリア
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        print("🗑️ Image cache cleared")
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
        image = await cacheManager.loadImage(from: urlString)
        isLoading = false
    }
}

// MARK: - Simple Optimized AsyncImage
@MainActor
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