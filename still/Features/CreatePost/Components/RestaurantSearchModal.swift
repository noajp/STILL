//======================================================================
// MARK: - RestaurantSearchModal（レストラン検索モーダル）
// Path: foodai/Features/CreatePost/Components/RestaurantSearchModal.swift
//======================================================================
import SwiftUI
import CoreLocation

struct RestaurantSearchModal: View {
    @Binding var isPresented: Bool
    @Binding var selectedPlace: PlaceResult?
    @State private var searchText = ""
    @State private var searchResults: [PlaceResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @StateObject private var locationManager = LocationManager()
    
    private let searchService = RestaurantSearchService.shared
    
    var body: some View {
        NavigationView {
            VStack {
                // 検索バー
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("レストラン名や場所で検索", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            Task {
                                await searchRestaurants()
                            }
                        }
                }
                .padding()
                
                // 現在地で検索ボタン
                Button(action: {
                    Task {
                        await searchNearbyRestaurants()
                    }
                }) {
                    Label("現在地の近くを検索", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(MinimalDesign.Colors.accentRed.opacity(0.1))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // 検索結果
                if isSearching {
                    ProgressView("検索中...")
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(searchResults) { place in
                        RestaurantRow(place: place) {
                            selectedPlace = place
                            isPresented = false
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("レストランを選択")
            .navigationBarItems(trailing: Button("キャンセル") {
                isPresented = false
            }
            .foregroundColor(MinimalDesign.Colors.accentRed)
            )
        }
        .onAppear {
            locationManager.requestLocation()
        }
    }
    
    private func searchRestaurants() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            let results = try await searchService.searchRestaurantsByText(
                query: searchText,
                location: locationManager.currentLocation
            )
            searchResults = results
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    private func searchNearbyRestaurants() async {
        guard let location = locationManager.currentLocation else {
            errorMessage = "位置情報を取得できません"
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        do {
            let results = try await searchService.searchNearbyRestaurants(
                location: location,
                keyword: searchText.isEmpty ? nil : searchText
            )
            searchResults = results
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
}

// レストラン行の表示
struct RestaurantRow: View {
    let place: PlaceResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // レストラン画像
                if let photo = place.photos?.first {
                    AsyncImage(url: URL(string: RestaurantSearchService.shared.getPhotoURL(
                        photoReference: photo.photoReference,
                        maxWidth: 60
                    ))) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(place.vicinity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if let rating = place.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            if let priceLevel = place.priceLevel {
                                Text("・")
                                    .foregroundColor(.secondary)
                                Text(String(repeating: "¥", count: priceLevel))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
