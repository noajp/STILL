//======================================================================
// MARK: - EnhancedFilterSelectionView.swift
// Purpose: SwiftUI view component (EnhancedFilterSelectionViewビューコンポーネント)
// Path: still/Features/PhotoEditor/Views/EnhancedFilterSelectionView.swift
//======================================================================
//
//  EnhancedFilterSelectionView.swift
//  tete
//
//  拡張フィルター選択UI
//

import SwiftUI

struct EnhancedFilterSelectionView: View {
    @ObservedObject var historyManager: EditHistoryManager
    @Binding var selectedFilter: FilterType
    @Binding var filterIntensity: Float
    let originalImage: UIImage?
    let onFilterApplied: (FilterType, Float) -> Void
    
    @State private var selectedCategory: FilterCategory = .all
    @State private var showingFavorites = false
    
    enum FilterCategory: String, CaseIterable {
        case all = "All"
        case favorites = "★"
        case vintage = "Vintage"
        case film = "Film"
        case modern = "Modern"
        
        var filters: [FilterType] {
            switch self {
            case .all:
                return FilterType.allCases
            case .favorites:
                return [] // historyManagerから取得
            case .vintage:
                return [.vintage, .sepia, .retro]
            case .film:
                return [.kodakPortra, .fujiPro, .cinestill, .ilfordHP5, .polaroid]
            case .modern:
                return [.warm, .cool, .noir, .filmGrain, .lightLeak]
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Selector
            categorySelector
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Filter Grid
            filterGrid
            
            // Intensity Slider
            if selectedFilter != .none && selectedFilter.isAdjustable {
                intensitySlider
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.black.opacity(0.95))
    }
    
    // MARK: - Category Selector
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(FilterCategory.allCases, id: \.self) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedCategory == category,
                        favoriteCount: category == .favorites ? historyManager.favoriteFilters.count : nil,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 50)
    }
    
    // MARK: - Filter Grid
    
    private var filterGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(filtersForCategory, id: \.self) { filter in
                    EnhancedFilterThumbnail(
                        filter: filter,
                        originalImage: originalImage,
                        isSelected: selectedFilter == filter,
                        isFavorite: historyManager.isFavoriteFilter(filter),
                        onTap: {
                            selectFilter(filter)
                        },
                        onFavoriteToggle: {
                            toggleFavorite(filter)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 120)
        .padding(.vertical, 10)
    }
    
    // MARK: - Intensity Slider
    
    private var intensitySlider: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Intensity")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\\(Int(filterIntensity * 100))%")
                    .font(.caption)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            
            HStack(spacing: 12) {
                Button("Reset") {
                    filterIntensity = selectedFilter.defaultIntensity
                    onFilterApplied(selectedFilter, filterIntensity)
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                
                Slider(value: $filterIntensity, in: 0...1) { _ in
                    onFilterApplied(selectedFilter, filterIntensity)
                }
                .accentColor(.white)
                
                Button("Max") {
                    filterIntensity = 1.0
                    onFilterApplied(selectedFilter, filterIntensity)
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Computed Properties
    
    private var filtersForCategory: [FilterType] {
        if selectedCategory == .favorites {
            return historyManager.favoriteFilters
        }
        return selectedCategory.filters
    }
    
    // MARK: - Methods
    
    private func selectFilter(_ filter: FilterType) {
        selectedFilter = filter
        filterIntensity = filter.defaultIntensity
        onFilterApplied(filter, filterIntensity)
        
        // 使用頻度を記録（お気に入りでない場合は自動でお気に入り候補に）
        if filter != .none && !historyManager.isFavoriteFilter(filter) {
            // TODO: 使用頻度ベースの自動お気に入り機能
        }
    }
    
    private func toggleFavorite(_ filter: FilterType) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if historyManager.isFavoriteFilter(filter) {
                historyManager.removeFavoriteFilter(filter)
            } else {
                historyManager.addFavoriteFilter(filter)
            }
        }
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let category: EnhancedFilterSelectionView.FilterCategory
    let isSelected: Bool
    let favoriteCount: Int?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text(category.rawValue)
                        .font(.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                    
                    if let count = favoriteCount, count > 0 {
                        Text("\\(count)")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isSelected ? .white : .clear)
            }
        }
        .foregroundColor(isSelected ? .white : .gray)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Enhanced Filter Thumbnail
struct EnhancedFilterThumbnail: View {
    let filter: FilterType
    let originalImage: UIImage?
    let isSelected: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavoriteToggle: () -> Void
    
    @State private var previewImage: UIImage?
    @State private var isGenerating = false
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Preview Image
                Group {
                    if let previewImage = previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let originalImage = originalImage {
                        Image(uiImage: originalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .overlay(
                                Rectangle()
                                    .fill(Color.black.opacity(0.3))
                            )
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Loading Indicator
                if isGenerating {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 80, height: 80)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.7)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
                
                // Selection Border
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 80, height: 80)
                }
                
                // Favorite Button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onFavoriteToggle) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.caption)
                                .foregroundColor(isFavorite ? .red : .white)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 20, height: 20)
                                )
                        }
                        .opacity(filter == .none ? 0 : 1)
                    }
                    Spacer()
                }
                .frame(width: 80, height: 80)
                .padding(4)
            }
            .onTapGesture {
                onTap()
            }
            
            // Filter Name
            Text(filter.rawValue)
                .font(.caption2)
                .foregroundColor(isSelected ? .white : .gray)
                .lineLimit(1)
                .frame(width: 80)
        }
        .onAppear {
            generatePreview()
        }
    }
    
    private func generatePreview() {
        guard let originalImage = originalImage,
              filter != .none,
              previewImage == nil else {
            previewImage = originalImage
            return
        }
        
        isGenerating = true
        
        Task {
            // サムネイル生成
            let thumbnailSize = CGSize(width: 160, height: 160)
            let thumbnail = originalImage.resizedAspectFit(to: thumbnailSize)
            
            guard let ciImage = CoreImageManager.shared.createCIImage(from: thumbnail) else {
                DispatchQueue.main.async {
                    self.previewImage = thumbnail
                    self.isGenerating = false
                }
                return
            }
            
            // フィルター適用
            if let filtered = CoreImageManager.shared.applyFilterSync(
                filter,
                to: ciImage,
                intensity: filter.previewIntensity
            ) {
                let context = CIContext()
                if let cgImage = context.createCGImage(filtered, from: filtered.extent) {
                    DispatchQueue.main.async {
                        self.previewImage = UIImage(cgImage: cgImage)
                        self.isGenerating = false
                    }
                    return
                }
            }
            
            DispatchQueue.main.async {
                self.previewImage = thumbnail
                self.isGenerating = false
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct EnhancedFilterSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedFilterSelectionView(
            historyManager: EditHistoryManager(),
            selectedFilter: .constant(.none),
            filterIntensity: .constant(1.0),
            originalImage: UIImage(systemName: "photo"),
            onFilterApplied: { _, _ in }
        )
        .frame(height: 300)
        .background(Color.black)
    }
}
#endif