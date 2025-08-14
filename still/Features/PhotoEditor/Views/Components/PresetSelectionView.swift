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
    let onCustomPresetSelected: ((CustomPreset) -> Void)?
    
    @State private var presets: [Preset] = []
    @State private var isGeneratingThumbnails = false
    @State private var showingCustomImport = false
    @ObservedObject private var customPresetManager = CustomPresetManager.shared
    
    // MARK: - Body
    var body: some View {
        // プリセットサムネイルのみ表示（カテゴリータブは上位コンポーネントで処理）
        presetThumbnailsView
            .background(Color(red: 28/255, green: 28/255, blue: 30/255))
            .onAppear {
                generatePresetThumbnails()
            }
            .sheet(isPresented: $showingCustomImport) {
                CustomPresetImportView(
                    originalImage: originalImage,
                    onPresetImported: { newPreset in
                        // Refresh the preset list
                        generatePresetThumbnails()
                    }
                )
            }
    }
    
    // MARK: - Views
    
    private var presetThumbnailsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(filteredPresets) { preset in
                    PresetThumbnailItemView(
                        preset: preset,
                        isSelected: selectedPreset == preset.type,
                        onTap: {
                            if preset.type == .custom && preset.customPreset == nil {
                                // Show import view for "Add New" button
                                showingCustomImport = true
                            } else if let customPreset = preset.customPreset {
                                // Apply custom preset
                                selectedPreset = preset.type
                                onCustomPresetSelected?(customPreset)
                            } else {
                                selectedPreset = preset.type
                                onPresetSelected(preset.type)
                            }
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
        case .light:
            return presets.filter { $0.type.category == .light }
        case .color:
            return presets.filter { $0.type.category == .color }
        case .custom:
            return customPresets + [addNewPreset]
        }
    }
    
    private var customPresets: [Preset] {
        return customPresetManager.customPresets.map { customPreset in
            let thumbnail = customPreset.thumbnailData.flatMap { UIImage(data: $0) }
            return Preset(type: .custom, thumbnail: thumbnail, customPreset: customPreset)
        }
    }
    
    private var addNewPreset: Preset {
        return Preset(type: .custom, thumbnail: nil, customPreset: nil)
    }
    
    // MARK: - Methods
    
    private func generatePresetThumbnails() {
        guard presets.isEmpty else { return }
        
        isGeneratingThumbnails = true
        
        Task {
            var generatedPresets: [Preset] = []
            
            for presetType in PresetType.allCases {
                // Skip custom type as it's handled separately
                if presetType == .custom { continue }
                
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
                            .clipShape(Rectangle())
                    } else if preset.type == .custom && preset.customPreset == nil {
                        // Add new preset button
                        Rectangle()
                            .fill(Color(hex: "2a2a2a"))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundColor(.white)
                            )
                    } else {
                        Rectangle()
                            .fill(Color(hex: "1e1e1e"))
                            .frame(width: 56, height: 56)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .tint(.white)
                            )
                    }
                    
                    // 選択枠
                    if isSelected {
                        Rectangle()
                            .stroke(Color(red: 10/255, green: 132/255, blue: 255/255), lineWidth: 2)
                            .frame(width: 56, height: 56)
                    }
                }
                
                // プリセット名
                VStack(spacing: 4) {
                    Text(displayName(for: preset))
                        .font(.system(size: 9, weight: .medium))
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
    
    private func displayName(for preset: Preset) -> String {
        if let customPreset = preset.customPreset {
            return customPreset.name
        } else if preset.type == .custom && preset.customPreset == nil {
            return "Add New"
        } else {
            return preset.type.rawValue
        }
    }
}

// MARK: - Preview
#if DEBUG
struct PresetSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        PresetSelectionView(
            selectedPreset: .constant(.natural),
            selectedCategory: .constant(.light),
            originalImage: UIImage(systemName: "photo")!,
            onPresetSelected: { _ in },
            onCustomPresetSelected: nil
        )
        .frame(height: 180)
        .background(Color(hex: "121212"))
    }
}
#endif