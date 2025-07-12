//======================================================================
// MARK: - PresetSelectionView.swift
// Purpose: SwiftUI view component (PresetSelectionViewビューコンポーネント)
// Path: still/Features/PhotoEditor/Views/Components/PresetSelectionView.swift
//======================================================================
//
//  PresetSelectionView.swift
//  tete
//
//  プリセット選択ビュー
//

import SwiftUI

struct PresetSelectionView: View {
    // MARK: - Properties
    @Binding var selectedPreset: PresetType
    @Binding var selectedCategory: PresetCategory
    let originalImage: UIImage
    let onPresetSelected: (PresetType) -> Void
    
    @State private var presets: [Preset] = []
    @State private var isGeneratingThumbnails = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // カテゴリータブ
            categoryTabsView
            
            // プリセットサムネイル
            presetThumbnailsView
        }
        .background(Color(red: 28/255, green: 28/255, blue: 30/255))
        .onAppear {
            generatePresetThumbnails()
        }
    }
    
    // MARK: - Views
    
    private var categoryTabsView: some View {
        HStack(spacing: 0) {
            ForEach(PresetCategory.allCases, id: \.self) { category in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = category
                    }
                }) {
                    VStack(spacing: 10) {
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedCategory == category ? .white : Color(white: 0.56))
                        
                        // アンダーライン
                        Rectangle()
                            .fill(selectedCategory == category ? Color.white : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(
            Rectangle()
                .fill(Color(white: 0.23))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var presetThumbnailsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(filteredPresets) { preset in
                    PresetThumbnailItemView(
                        preset: preset,
                        isSelected: selectedPreset == preset.type,
                        onTap: {
                            selectedPreset = preset.type
                            onPresetSelected(preset.type)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredPresets: [Preset] {
        switch selectedCategory {
        case .basePresets:
            return presets.filter { $0.type.category == .basePresets }
        case .colorPresets:
            return presets.filter { $0.type.category == .colorPresets }
        }
    }
    
    // MARK: - Methods
    
    private func generatePresetThumbnails() {
        guard presets.isEmpty else { return }
        
        isGeneratingThumbnails = true
        
        Task {
            var generatedPresets: [Preset] = []
            
            for presetType in PresetType.allCases {
                let thumbnail = await generateThumbnail(for: presetType)
                let preset = Preset(type: presetType, thumbnail: thumbnail)
                generatedPresets.append(preset)
            }
            
            await MainActor.run {
                self.presets = generatedPresets
                self.isGeneratingThumbnails = false
            }
        }
    }
    
    private func generateThumbnail(for presetType: PresetType) async -> UIImage? {
        // サムネイル生成（簡易実装）
        guard let ciImage = CIImage(image: originalImage) else { return nil }
        
        // プリセットに応じたフィルター適用
        let settings = presetType.filterSettings
        
        var filteredImage = ciImage
        
        // 明るさ調整
        if let brightnessFilter = CIFilter(name: "CIColorControls") {
            brightnessFilter.setValue(filteredImage, forKey: kCIInputImageKey)
            brightnessFilter.setValue(settings.brightness, forKey: kCIInputBrightnessKey)
            brightnessFilter.setValue(settings.contrast, forKey: kCIInputContrastKey)
            brightnessFilter.setValue(settings.saturation, forKey: kCIInputSaturationKey)
            filteredImage = brightnessFilter.outputImage ?? filteredImage
        }
        
        // サムネイルサイズに縮小
        let targetSize = CGSize(width: 112, height: 112) // 56pt * 2 (Retina)
        let scale = min(targetSize.width / filteredImage.extent.width,
                       targetSize.height / filteredImage.extent.height)
        
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        filteredImage = filteredImage.transformed(by: transform)
        
        // UIImageに変換
        let context = CIContext()
        guard let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Preset Thumbnail Item View
struct PresetThumbnailItemView: View {
    let preset: Preset
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // サムネイル画像
                ZStack {
                    if let thumbnail = preset.thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(white: 0.2))
                            .frame(width: 56, height: 56)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .tint(.white)
                            )
                    }
                    
                    // 選択枠
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(red: 10/255, green: 132/255, blue: 255/255), lineWidth: 2)
                            .frame(width: 56, height: 56)
                    }
                }
                
                // プリセット名
                VStack(spacing: 4) {
                    Text(preset.type.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(preset.type.color ?? (isSelected ? .white : Color(white: 0.56)))
                    
                    // 選択インジケーター
                    if isSelected {
                        Circle()
                            .fill(Color(red: 10/255, green: 132/255, blue: 255/255))
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#if DEBUG
struct PresetSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        PresetSelectionView(
            selectedPreset: .constant(.natural),
            selectedCategory: .constant(.basePresets),
            originalImage: UIImage(systemName: "photo")!,
            onPresetSelected: { _ in }
        )
        .frame(height: 180)
        .background(Color.black)
    }
}
#endif