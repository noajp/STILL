//======================================================================
// MARK: - EditSession.swift
// Purpose: EditSession implementation (EditSessionの実装)
// Path: still/Core/DataModels/EditSession.swift
//======================================================================
//
//  EditSession.swift
//  tete
//
//  編集セッションデータモデル
//

import UIKit
import Foundation

// MARK: - Edit Session
struct EditSession: Codable {
    let id: UUID
    let originalImageData: Data
    let filterType: FilterType
    let filterIntensity: Float
    let createdAt: Date
    let lastModified: Date
    
    init(originalImage: UIImage, filterType: FilterType = .none, intensity: Float = 1.0) {
        self.id = UUID()
        self.originalImageData = originalImage.jpegData(compressionQuality: 0.9) ?? Data()
        self.filterType = filterType
        self.filterIntensity = intensity
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    var originalImage: UIImage? {
        UIImage(data: originalImageData)
    }
}

// MARK: - Edit History Manager
@MainActor
final class EditHistoryManager: ObservableObject {
    @Published var recentSessions: [EditSession] = []
    @Published var favoriteFilters: [FilterType] = []
    
    private let maxHistoryCount = 10
    private let favoritesKey = "FavoriteFilters"
    private let historyKey = "EditHistory"
    
    init() {
        loadData()
    }
    
    // MARK: - Session Management
    
    func saveSession(_ session: EditSession) {
        // 新しいセッションを先頭に追加
        recentSessions.insert(session, at: 0)
        
        // 最大保存数を超えた場合は古いものを削除
        if recentSessions.count > maxHistoryCount {
            recentSessions = Array(recentSessions.prefix(maxHistoryCount))
        }
        
        saveData()
    }
    
    func deleteSession(_ session: EditSession) {
        recentSessions.removeAll { $0.id == session.id }
        saveData()
    }
    
    func clearHistory() {
        recentSessions.removeAll()
        saveData()
    }
    
    // MARK: - Favorite Filters
    
    func addFavoriteFilter(_ filterType: FilterType) {
        guard !favoriteFilters.contains(filterType) && filterType != .none else { return }
        favoriteFilters.append(filterType)
        saveData()
    }
    
    func removeFavoriteFilter(_ filterType: FilterType) {
        favoriteFilters.removeAll { $0 == filterType }
        saveData()
    }
    
    func isFavoriteFilter(_ filterType: FilterType) -> Bool {
        favoriteFilters.contains(filterType)
    }
    
    // MARK: - Data Persistence
    
    private func saveData() {
        // お気に入りフィルターを保存
        if let favoritesData = try? JSONEncoder().encode(favoriteFilters) {
            UserDefaults.standard.set(favoritesData, forKey: favoritesKey)
        }
        
        // 編集履歴を保存（セッションが大きいのでDocumentsディレクトリに保存）
        saveHistoryToDocuments()
    }
    
    private func loadData() {
        // お気に入りフィルターを読み込み
        if let favoritesData = UserDefaults.standard.data(forKey: favoritesKey),
           let favorites = try? JSONDecoder().decode([FilterType].self, from: favoritesData) {
            favoriteFilters = favorites
        }
        
        // 編集履歴を読み込み
        loadHistoryFromDocuments()
    }
    
    private func saveHistoryToDocuments() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let historyURL = documentsPath.appendingPathComponent("\(historyKey).json")
        
        do {
            let data = try JSONEncoder().encode(recentSessions)
            try data.write(to: historyURL)
        } catch {
            print("❌ Failed to save edit history: \(error)")
        }
    }
    
    private func loadHistoryFromDocuments() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let historyURL = documentsPath.appendingPathComponent("\(historyKey).json")
        
        do {
            let data = try Data(contentsOf: historyURL)
            recentSessions = try JSONDecoder().decode([EditSession].self, from: data)
        } catch {
            print("📝 No edit history found or failed to load: \(error)")
        }
    }
}

// MARK: - Filter Type Codable Extension
extension FilterType: Codable {
    enum CodingKeys: String, CodingKey {
        case rawValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = FilterType(rawValue: rawValue) ?? .none
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}