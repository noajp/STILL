//======================================================================
// MARK: - RestaurantRepository.swift (新規作成)
// Path: foodai/Core/Repositories/RestaurantRepository.swift
//======================================================================
import Foundation
import Supabase

class RestaurantRepository {
    private let client = SupabaseManager.shared.client
    
    // お気に入り追加/削除
    func toggleFavorite(restaurantId: String, userId: String) async throws {
        // 既存のお気に入りをチェック
        let existingFavorites: [FavoriteResponse] = try await client
            .from("favorites")
            .select("id")
            .eq("restaurant_id", value: restaurantId)
            .eq("user_id", value: userId)
            .execute()
            .value
        
        if existingFavorites.isEmpty {
            // お気に入り追加
            try await client
                .from("favorites")
                .insert([
                    "restaurant_id": restaurantId,
                    "user_id": userId
                ])
                .execute()
        } else {
            // お気に入り削除
            try await client
                .from("favorites")
                .delete()
                .eq("restaurant_id", value: restaurantId)
                .eq("user_id", value: userId)
                .execute()
        }
    }
}

struct FavoriteResponse: Codable {
    let id: String
}

