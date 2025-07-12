//======================================================================
// MARK: - Restaurant+Supabase.swift
// Path: foodai/Core/DataModels/Restaurant+Supabase.swift
//======================================================================
import Foundation

// Supabaseから取得するデータ構造
struct RestaurantDTO: Codable {
    let id: String
    let name: String
    let description: String?
    let cuisineType: String?
    let priceCategory: String?
    let addressShort: String?
    let fullAddress: String?
    let phoneNumber: String?
    let websiteUrl: String?
    let averageRating: Double?
    let totalReviews: Int?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case cuisineType = "cuisine_type"
        case priceCategory = "price_category"
        case addressShort = "address_short"
        case fullAddress = "full_address"
        case phoneNumber = "phone_number"
        case websiteUrl = "website_url"
        case averageRating = "average_rating"
        case totalReviews = "total_reviews"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RestaurantImageDTO: Codable {
    let id: String
    let restaurantId: String
    let imageUrl: String
    let imageType: String
    let displayOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case restaurantId = "restaurant_id"
        case imageUrl = "image_url"
        case imageType = "image_type"
        case displayOrder = "display_order"
    }
}

