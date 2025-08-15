//======================================================================
// MARK: - BasicEditingView.swift
// Purpose: Basic editing controls with presets and white balance (基本編集コントロール)
// Path: still/Features/PhotoEditor/Views/Components/BasicEditingView.swift
//======================================================================

import SwiftUI

struct BasicEditingView: View {
    // MARK: - Properties
    @Binding var selectedPreset: PresetType
    @Binding var selectedCategory: PresetCategory
    @Binding var filterSettings: FilterSettings
    let originalImage: UIImage
    let onPresetSelected: (PresetType) -> Void
    let onCustomPresetSelected: ((CustomPreset) -> Void)?
    let onSettingsChanged: (FilterSettings) -> Void
    
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Preset Section
            presetSectionView
        }
        .frame(height: 140) // Fixed height for consistency
        .background(Color(hex: "1a1a1a"))
    }
    
    // MARK: - Preset Section
    private var presetSectionView: some View {
        VStack(spacing: 0) {
            // Category selector
            HStack(spacing: 12) {
                ForEach(PresetCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedCategory == category ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Rectangle()
                                    .fill(selectedCategory == category ? .white : Color.clear)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                            )
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Preset content view
            PresetSelectionView(
                selectedPreset: $selectedPreset,
                selectedCategory: $selectedCategory,
                originalImage: originalImage,
                onPresetSelected: onPresetSelected,
                onCustomPresetSelected: onCustomPresetSelected
            )
            .frame(height: 100)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct BasicEditingView_Previews: PreviewProvider {
    static var previews: some View {
        BasicEditingView(
            selectedPreset: .constant(.natural),
            selectedCategory: .constant(.light),
            filterSettings: .constant(FilterSettings()),
            originalImage: UIImage(systemName: "photo")!,
            onPresetSelected: { _ in },
            onCustomPresetSelected: nil,
            onSettingsChanged: { _ in }
        )
        .background(Color.black)
    }
}
#endif