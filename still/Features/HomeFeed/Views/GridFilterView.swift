//======================================================================
// MARK: - GridFilterView.swift
// Purpose: Filter and sorting functionality for the home grid
// Path: still/Features/HomeFeed/Views/GridFilterView.swift
//======================================================================

import SwiftUI

/**
 * GridFilterView provides filtering and sorting options for the home grid.
 * 
 * Features:
 * - Sort by date, popularity, or user
 * - Filter by post type, location, or tags
 * - Search functionality
 * - Category selection
 * - Time range filtering
 * - Visual filter indicators
 */
struct GridFilterView: View {
    // MARK: - Properties
    
    @Binding var selectedFilter: GridFilter
    @Binding var selectedSort: GridSort
    @Binding var searchText: String
    @State private var showFilters = false
    
    let onFilterChanged: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Main filter bar
            mainFilterBar
            
            // Expandable filter options
            if showFilters {
                expandedFiltersSection
            }
        }
        .background(MinimalDesign.Colors.background)
    }
    
    // MARK: - Main Filter Bar
    
    @ViewBuilder
    private var mainFilterBar: some View {
        HStack(spacing: 12) {
            // Search field
            searchField
            
            // Sort button
            sortButton
            
            // Filter toggle button
            filterToggleButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 14))
            
            TextField("Search posts...", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .onChange(of: searchText) { _, _ in
                    onFilterChanged()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onFilterChanged()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    @ViewBuilder
    private var sortButton: some View {
        Menu {
            ForEach(GridSort.allCases, id: \.self) { sort in
                Button(action: {
                    selectedSort = sort
                    onFilterChanged()
                }) {
                    HStack {
                        Text(sort.displayName)
                        if selectedSort == sort {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedSort.iconName)
                    .font(.system(size: 12))
                Text(selectedSort.shortName)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
    
    @ViewBuilder
    private var filterToggleButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showFilters.toggle()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 12))
                
                if selectedFilter != .all {
                    Circle()
                        .fill(MinimalDesign.Colors.accentRed)
                        .frame(width: 6, height: 6)
                }
            }
            .foregroundColor(.white)
            .padding(8)
            .background(
                Circle()
                    .fill(Color.white.opacity(showFilters ? 0.2 : 0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Expanded Filters Section
    
    @ViewBuilder
    private var expandedFiltersSection: some View {
        VStack(spacing: 16) {
            // Filter categories
            filterCategoriesRow
            
            // Additional filter options
            additionalFiltersRow
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.05))
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    @ViewBuilder
    private var filterCategoriesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GridFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter,
                        onTap: {
                            selectedFilter = filter
                            onFilterChanged()
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    @ViewBuilder
    private var additionalFiltersRow: some View {
        HStack {
            // Clear filters button
            if selectedFilter != .all || !searchText.isEmpty {
                Button(action: {
                    selectedFilter = .all
                    searchText = ""
                    onFilterChanged()
                }) {
                    Text("Clear All")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(MinimalDesign.Colors.accentRed, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            // Active filter count
            if selectedFilter != .all || !searchText.isEmpty {
                Text("\(activeFilterCount) filter\(activeFilterCount == 1 ? "" : "s") active")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var activeFilterCount: Int {
        var count = 0
        if selectedFilter != .all { count += 1 }
        if !searchText.isEmpty { count += 1 }
        return count
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? MinimalDesign.Colors.background : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? MinimalDesign.Colors.primary : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter and Sort Enums

enum GridFilter: String, CaseIterable {
    case all = "all"
    case photos = "photos"
    case videos = "videos"
    case following = "following"
    case recent = "recent"
    case popular = "popular"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .photos: return "Photos"
        case .videos: return "Videos"
        case .following: return "Following"
        case .recent: return "Recent"
        case .popular: return "Popular"
        }
    }
}

enum GridSort: String, CaseIterable {
    case newest = "newest"
    case oldest = "oldest"
    case popular = "popular"
    case trending = "trending"
    
    var displayName: String {
        switch self {
        case .newest: return "Newest First"
        case .oldest: return "Oldest First"
        case .popular: return "Most Popular"
        case .trending: return "Trending"
        }
    }
    
    var shortName: String {
        switch self {
        case .newest: return "New"
        case .oldest: return "Old"
        case .popular: return "Popular"
        case .trending: return "Trending"
        }
    }
    
    var iconName: String {
        switch self {
        case .newest: return "arrow.down"
        case .oldest: return "arrow.up"
        case .popular: return "heart"
        case .trending: return "flame"
        }
    }
}

// MARK: - Compact Filter Bar

/**
 * CompactFilterBar provides a minimal filter interface for smaller spaces.
 */
struct CompactFilterBar: View {
    @Binding var selectedSort: GridSort
    @Binding var searchText: String
    let onFilterChanged: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Compact search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
                
                TextField("Search", text: $searchText)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .onChange(of: searchText) { _, _ in
                        onFilterChanged()
                    }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            
            // Sort picker
            Menu {
                ForEach(GridSort.allCases, id: \.self) { sort in
                    Button(sort.displayName) {
                        selectedSort = sort
                        onFilterChanged()
                    }
                }
            } label: {
                Image(systemName: selectedSort.iconName)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
    }
}

// MARK: - Preview Provider

struct GridFilterView_Previews: PreviewProvider {
    static var previews: some View {
        GridFilterView(
            selectedFilter: .constant(.all),
            selectedSort: .constant(.newest),
            searchText: .constant(""),
            onFilterChanged: {}
        )
        .background(MinimalDesign.Colors.background)
    }
}