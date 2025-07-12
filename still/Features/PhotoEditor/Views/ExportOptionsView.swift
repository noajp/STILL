//======================================================================
// MARK: - ExportOptionsView.swift
// Purpose: SwiftUI view component (ExportOptionsViewビューコンポーネント)
// Path: still/Features/PhotoEditor/Views/ExportOptionsView.swift
//======================================================================
//
//  ExportOptionsView.swift
//  tete
//
//  高解像度エクスポートオプション
//

import SwiftUI

struct ExportOptionsView: View {
    let originalImage: UIImage
    let selectedFilter: FilterType
    let filterIntensity: Float
    let onExport: (ExportSettings) -> Void
    let onCancel: () -> Void
    
    @State private var selectedQuality: ExportQuality = .high
    @State private var selectedFormat: ExportFormat = .jpeg
    @State private var includeMetadata = false
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case jpeg = "JPEG"
        case png = "PNG" 
        case heif = "HEIF"
        
        var id: String { rawValue }
        
        var fileExtension: String {
            switch self {
            case .jpeg: return "jpg"
            case .png: return "png"
            case .heif: return "heic"
            }
        }
        
        var supportsTransparency: Bool {
            self == .png
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Preview Section
                previewSection
                
                Divider()
                
                // Export Options
                ScrollView {
                    VStack(spacing: 20) {
                        qualitySection
                        formatSection
                        metadataSection
                        estimatedSizeSection
                    }
                    .padding()
                }
                
                // Export Button
                exportButton
            }
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .disabled(isExporting)
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Image(uiImage: originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if isExporting {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.7))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                ProgressView(value: exportProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                    .frame(width: 120)
                                
                                Text("Exporting... \\(Int(exportProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        )
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filter: \\(selectedFilter.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if selectedFilter != .none {
                        Text("Intensity: \\(Int(filterIntensity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\\(Int(originalImage.size.width))×\\(Int(originalImage.size.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(selectedFormat.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Quality Section
    
    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quality")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach([ExportQuality.maximum, .high, .standard, .compressed]) { quality in
                    QualityOption(
                        quality: quality,
                        isSelected: selectedQuality == quality,
                        onSelect: { selectedQuality = quality }
                    )
                }
            }
        }
    }
    
    // MARK: - Format Section
    
    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Format")
                .font(.headline)
            
            Picker("Format", selection: $selectedFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Text(formatDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metadata")
                .font(.headline)
            
            Toggle("Include EXIF Data", isOn: $includeMetadata)
            
            Text("Include camera settings and location data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Estimated Size Section
    
    private var estimatedSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimated File Size")
                .font(.headline)
            
            HStack {
                Text(estimatedFileSize)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\\(estimatedMegapixels) MP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Export Button
    
    private var exportButton: some View {
        Button(action: performExport) {
            HStack {
                if isExporting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                }
                
                Text(isExporting ? "Exporting..." : "Export Photo")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.accentColor)
            .cornerRadius(12)
        }
        .disabled(isExporting)
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var formatDescription: String {
        switch selectedFormat {
        case .jpeg:
            return "Best compatibility, smaller file size"
        case .png:
            return "Lossless quality, supports transparency"
        case .heif:
            return "Modern format, best compression"
        }
    }
    
    private var estimatedFileSize: String {
        let pixels = originalImage.size.width * originalImage.size.height
        let bytesPerPixel: Double
        
        switch selectedFormat {
        case .jpeg:
            bytesPerPixel = selectedQuality == .maximum ? 3.0 : (selectedQuality == .high ? 2.0 : 1.5)
        case .png:
            bytesPerPixel = 4.0
        case .heif:
            bytesPerPixel = selectedQuality == .maximum ? 2.5 : 1.8
        }
        
        let estimatedBytes = pixels * bytesPerPixel
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(estimatedBytes))
    }
    
    private var estimatedMegapixels: String {
        let megapixels = (originalImage.size.width * originalImage.size.height) / 1_000_000
        return String(format: "%.1f", megapixels)
    }
    
    // MARK: - Methods
    
    private func performExport() {
        let settings = ExportSettings(
            quality: selectedQuality,
            format: selectedFormat,
            includeMetadata: includeMetadata
        )
        
        isExporting = true
        exportProgress = 0
        
        // プログレス更新をシミュレート
        Task {
            for step in 1...10 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                await MainActor.run {
                    exportProgress = Double(step) / 10.0
                    if step == 10 {
                        isExporting = false
                        onExport(settings)
                    }
                }
            }
        }
    }
}

// MARK: - Quality Option
struct QualityOption: View {
    let quality: ExportQuality
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quality.description)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                    
                    Text(qualityDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var qualityDescription: String {
        switch quality {
        case .maximum:
            return "Original quality, largest file"
        case .high:
            return "High quality, good balance"
        case .standard:
            return "Standard quality, smaller file"
        case .compressed:
            return "Optimized for sharing"
        }
    }
}

// MARK: - Export Settings
struct ExportSettings {
    let quality: ExportQuality
    let format: ExportOptionsView.ExportFormat
    let includeMetadata: Bool
}

// MARK: - Preview
#if DEBUG
struct ExportOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        ExportOptionsView(
            originalImage: UIImage(systemName: "photo") ?? UIImage(),
            selectedFilter: .vintage,
            filterIntensity: 0.8,
            onExport: { _ in },
            onCancel: { }
        )
    }
}
#endif