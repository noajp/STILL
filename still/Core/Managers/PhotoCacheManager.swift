//======================================================================
// MARK: - PhotoCacheManager.swift
// Purpose: Centralized photo caching manager to prevent duplicate loading across screens
// Path: still/Core/Managers/PhotoCacheManager.swift
//======================================================================

import SwiftUI
import Photos
import Combine

@MainActor
final class PhotoCacheManager: ObservableObject {
    static let shared = PhotoCacheManager()
    
    // MARK: - Published Properties
    @Published var recentPhotos: [UIImage] = []
    @Published var recentAssets: [PHAsset] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    
    // MARK: - Private Properties
    private let imageManager = PHImageManager.default()
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    private var thumbnailCache: [String: UIImage] = [:]
    private var highQualityCache: [String: UIImage] = [:]
    
    private init() {}
    
    // MARK: - Public Methods
    
    func loadPhotosIfNeeded(limit: Int = 200) async {
        // Check if we need to refresh
        if shouldRefreshCache() {
            await loadRecentPhotos(limit: limit)
        }
    }
    
    func forceRefresh(limit: Int = 200) async {
        await loadRecentPhotos(limit: limit)
    }
    
    func getThumbnailImage(for asset: PHAsset) -> UIImage? {
        return thumbnailCache[asset.localIdentifier]
    }
    
    func getHighQualityImage(for asset: PHAsset) async -> UIImage? {
        // Check cache first
        if let cachedImage = highQualityCache[asset.localIdentifier] {
            return cachedImage
        }
        
        // Load high quality image
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .none
        options.version = .current
        
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { [weak self] image, _ in
                if let image = image {
                    self?.highQualityCache[asset.localIdentifier] = image
                }
                continuation.resume(returning: image)
            }
        }
    }
    
    func clearCache() {
        thumbnailCache.removeAll()
        highQualityCache.removeAll()
        recentPhotos.removeAll()
        recentAssets.removeAll()
        lastUpdated = nil
    }
    
    // MARK: - Private Methods
    
    private func shouldRefreshCache() -> Bool {
        guard let lastUpdated = lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > cacheExpiration
    }
    
    private func loadRecentPhotos(limit: Int) async {
        guard !isLoading else { return }
        
        isLoading = true
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var photos: [UIImage] = []
        var assetArray: [PHAsset] = []
        
        let targetSize = CGSize(width: 400, height: 400)
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        
        assets.enumerateObjects { [weak self] asset, _, _ in
            self?.imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                if let image = image {
                    photos.append(image)
                    assetArray.append(asset)
                    self?.thumbnailCache[asset.localIdentifier] = image
                }
            }
        }
        
        self.recentPhotos = photos
        self.recentAssets = assetArray
        self.lastUpdated = Date()
        self.isLoading = false
    }
}