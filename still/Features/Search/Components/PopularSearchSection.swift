//======================================================================
// MARK: - PopularSearchSection.swift
// Path: foodai/Features/Search/Components/PopularSearchSection.swift
//======================================================================

import SwiftUICore
import SwiftUI
struct PopularSearchSection: View {
    private let popularSearches = ["Italian", "Seafood", "Sushi", "Ramen", "Steak", "Pizza"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular searches")
                .font(AppEnvironment.Fonts.primaryBold(size: 18))
                .foregroundColor(MinimalDesign.Colors.primary)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80))
            ], spacing: 8) {
                ForEach(popularSearches, id: \.self) { search in
                    FilterChipView(title: search) {
                        // Handle search tap
                    }
                }
            }
        }
    }
}

