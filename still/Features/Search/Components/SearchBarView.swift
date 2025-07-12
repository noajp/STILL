//======================================================================
// MARK: - SearchBarView.swift (検索バーコンポーネント)
// Path: foodai/Features/Search/Components/SearchBarView.swift
//======================================================================
import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    let onSearch: (String) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(MinimalDesign.Colors.secondary)
                .padding(.leading, 12)
            
            TextField("Search for restaurants or cuisines", text: $searchText)
                .font(AppEnvironment.Fonts.primary(size: 16))
                .foregroundColor(MinimalDesign.Colors.primary)
                .onSubmit {
                    onSearch(searchText)
                }
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(MinimalDesign.Colors.secondary)
                }
                .padding(.trailing, 12)
            }
        }
        .frame(height: 48)
        .background(MinimalDesign.Colors.secondaryBackground)
        .cornerRadius(12)
    }
}

