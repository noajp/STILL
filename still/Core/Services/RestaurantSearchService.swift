//======================================================================
// MARK: - RestaurantSearchService（Google Places API連携）
// Path: foodai/Core/Services/RestaurantSearchService.swift
//======================================================================
import Foundation
import CoreLocation

// MARK: - データモデル
struct PlacesResponse: Codable {
    let results: [PlaceResult]
    let status: String
    let nextPageToken: String?
    
    enum CodingKeys: String, CodingKey {
        case results, status
        case nextPageToken = "next_page_token"
    }
}

struct PlaceResult: Codable, Identifiable, Equatable {
    let placeId: String
    let name: String
    let vicinity: String
    let geometry: Geometry
    let rating: Double?
    let priceLevel: Int?
    let photos: [PhotoReference]?
    let types: [String]?
    
    var id: String { placeId }
    
    // Equatable実装
    static func == (lhs: PlaceResult, rhs: PlaceResult) -> Bool {
        lhs.placeId == rhs.placeId
    }
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name, vicinity, geometry, rating, types
        case priceLevel = "price_level"
        case photos
    }
}

struct Geometry: Codable, Equatable {
    let location: Location
}

struct Location: Codable, Equatable {
    let lat: Double
    let lng: Double
}

struct PhotoReference: Codable, Equatable {
    let photoReference: String
    let height: Int
    let width: Int
    
    enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
        case height, width
    }
}

struct PlaceDetails: Codable {
    let result: PlaceDetailResult
    let status: String
}

struct PlaceDetailResult: Codable {
    let placeId: String
    let name: String
    let formattedAddress: String
    let formattedPhoneNumber: String?
    let website: String?
    let geometry: Geometry
    let rating: Double?
    let photos: [PhotoReference]?
    let openingHours: OpeningHours?
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case formattedAddress = "formatted_address"
        case formattedPhoneNumber = "formatted_phone_number"
        case website, geometry, rating, photos
        case openingHours = "opening_hours"
    }
}

struct OpeningHours: Codable {
    let openNow: Bool?
    let weekdayText: [String]?
    
    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
        case weekdayText = "weekday_text"
    }
}

// MARK: - サービスクラス
final class RestaurantSearchService: @unchecked Sendable {
    static let shared = RestaurantSearchService()
    private let apiKey = Config.googlePlacesAPIKey
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    
    private init() {}
    
    // 近くのレストランを検索
    func searchNearbyRestaurants(
        location: CLLocationCoordinate2D,
        radius: Int = 1500,
        keyword: String? = nil
    ) async throws -> [PlaceResult] {
        var urlComponents = URLComponents(string: "\(baseURL)/nearbysearch/json")!
        
        var queryItems = [
            URLQueryItem(name: "location", value: "\(location.latitude),\(location.longitude)"),
            URLQueryItem(name: "radius", value: String(radius)),
            URLQueryItem(name: "type", value: "restaurant"),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "language", value: "ja")
        ]
        
        if let keyword = keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        
        urlComponents.queryItems = queryItems
        
        let (data, _) = try await URLSession.shared.data(from: urlComponents.url!)
        let response = try JSONDecoder().decode(PlacesResponse.self, from: data)
        
        if response.status != "OK" && response.status != "ZERO_RESULTS" {
            throw RestaurantSearchError.apiError(response.status)
        }
        
        return response.results
    }
    
    // テキスト検索
    func searchRestaurantsByText(query: String, location: CLLocationCoordinate2D? = nil) async throws -> [PlaceResult] {
        var urlComponents = URLComponents(string: "\(baseURL)/textsearch/json")!
        
        var queryItems = [
            URLQueryItem(name: "query", value: "\(query) レストラン"),
            URLQueryItem(name: "type", value: "restaurant"),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "language", value: "ja")
        ]
        
        if let location = location {
            queryItems.append(URLQueryItem(name: "location", value: "\(location.latitude),\(location.longitude)"))
            queryItems.append(URLQueryItem(name: "radius", value: "5000"))
        }
        
        urlComponents.queryItems = queryItems
        
        let (data, _) = try await URLSession.shared.data(from: urlComponents.url!)
        let response = try JSONDecoder().decode(PlacesResponse.self, from: data)
        
        if response.status != "OK" && response.status != "ZERO_RESULTS" {
            throw RestaurantSearchError.apiError(response.status)
        }
        
        return response.results
    }
    
    // レストランの詳細情報を取得
    func getPlaceDetails(placeId: String) async throws -> PlaceDetailResult {
        var urlComponents = URLComponents(string: "\(baseURL)/details/json")!
        
        urlComponents.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "name,formatted_address,formatted_phone_number,website,geometry,rating,photos,opening_hours"),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "language", value: "ja")
        ]
        
        let (data, _) = try await URLSession.shared.data(from: urlComponents.url!)
        let response = try JSONDecoder().decode(PlaceDetails.self, from: data)
        
        if response.status != "OK" {
            throw RestaurantSearchError.apiError(response.status)
        }
        
        return response.result
    }
    
    // 写真URLを生成
    func getPhotoURL(photoReference: String, maxWidth: Int = 400) -> String {
        return "\(baseURL)/photo?maxwidth=\(maxWidth)&photo_reference=\(photoReference)&key=\(apiKey)"
    }
}

// MARK: - エラー定義
enum RestaurantSearchError: LocalizedError {
    case apiError(String)
    case networkError
    case invalidLocation
    
    var errorDescription: String? {
        switch self {
        case .apiError(let status):
            return "API エラー: \(status)"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .invalidLocation:
            return "位置情報が無効です"
        }
    }
}
