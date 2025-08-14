//======================================================================
// MARK: - CustomPresetManager.swift
// Purpose: Manages custom CUBE file presets (カスタムCUBEファイルプリセット管理)
// Path: still/Core/ImageProcessing/CustomPresetManager.swift
//======================================================================

import Foundation
import UIKit
import CoreImage

// MARK: - Custom Preset Model
struct CustomPreset: Codable, Identifiable {
    let id: String
    let name: String
    let fileName: String
    let dateAdded: Date
    let thumbnailData: Data?
    
    init(name: String, fileName: String, thumbnailData: Data? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.fileName = fileName
        self.dateAdded = Date()
        self.thumbnailData = thumbnailData
    }
}

// MARK: - Custom Preset Manager
@MainActor
final class CustomPresetManager: ObservableObject {
    
    // MARK: - Singleton
    @MainActor static let shared = CustomPresetManager()
    
    // MARK: - Properties
    @Published private(set) var customPresets: [CustomPreset] = []
    private let fileManager = FileManager.default
    private let presetsDirectoryName = "CustomPresets"
    private let metadataFileName = "presets_metadata.json"
    
    // Directories
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var presetsDirectory: URL {
        documentsDirectory.appendingPathComponent(presetsDirectoryName)
    }
    
    private var metadataFileURL: URL {
        presetsDirectory.appendingPathComponent(metadataFileName)
    }
    
    // MARK: - Initialization
    private init() {
        setupDirectories()
        loadPresets()
    }
    
    // MARK: - Setup
    private func setupDirectories() {
        if !fileManager.fileExists(atPath: presetsDirectory.path) {
            try? fileManager.createDirectory(at: presetsDirectory, 
                                            withIntermediateDirectories: true, 
                                            attributes: nil)
        }
    }
    
    // MARK: - Load & Save
    private func loadPresets() {
        guard fileManager.fileExists(atPath: metadataFileURL.path),
              let data = try? Data(contentsOf: metadataFileURL),
              let presets = try? JSONDecoder().decode([CustomPreset].self, from: data) else {
            customPresets = []
            return
        }
        
        // Filter out presets whose CUBE files no longer exist
        customPresets = presets.filter { preset in
            let cubeFileURL = presetsDirectory.appendingPathComponent(preset.fileName)
            return fileManager.fileExists(atPath: cubeFileURL.path)
        }
        
        // Save cleaned list if any were removed
        if customPresets.count != presets.count {
            savePresetsMetadata()
        }
    }
    
    private func savePresetsMetadata() {
        guard let data = try? JSONEncoder().encode(customPresets) else { return }
        try? data.write(to: metadataFileURL)
    }
    
    // MARK: - Import CUBE File
    func importCUBEFile(from sourceURL: URL, name: String? = nil, thumbnail: UIImage? = nil) async throws -> CustomPreset {
        // Validate CUBE file
        let cubeData = try Data(contentsOf: sourceURL)
        guard validateCUBEFile(data: cubeData) else {
            throw PresetError.invalidCUBEFile
        }
        
        // Generate unique filename
        let fileName = "\(UUID().uuidString).cube"
        let destinationURL = presetsDirectory.appendingPathComponent(fileName)
        
        // Copy CUBE file to app directory
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        
        // Generate thumbnail if not provided
        let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.8)
        
        // Create preset
        let presetName = name ?? sourceURL.deletingPathExtension().lastPathComponent
        let preset = CustomPreset(name: presetName, fileName: fileName, thumbnailData: thumbnailData)
        
        // Add to list and save
        customPresets.append(preset)
        savePresetsMetadata()
        
        return preset
    }
    
    // MARK: - Import from Data
    func importCUBEData(_ data: Data, name: String, thumbnail: UIImage? = nil) async throws -> CustomPreset {
        // Validate CUBE data
        guard validateCUBEFile(data: data) else {
            throw PresetError.invalidCUBEFile
        }
        
        // Generate unique filename
        let fileName = "\(UUID().uuidString).cube"
        let destinationURL = presetsDirectory.appendingPathComponent(fileName)
        
        // Save CUBE data to file
        try data.write(to: destinationURL)
        
        // Generate thumbnail if not provided
        let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.8)
        
        // Create preset
        let preset = CustomPreset(name: name, fileName: fileName, thumbnailData: thumbnailData)
        
        // Add to list and save
        customPresets.append(preset)
        savePresetsMetadata()
        
        return preset
    }
    
    // MARK: - Delete Preset
    func deletePreset(_ preset: CustomPreset) {
        // Remove CUBE file
        let cubeFileURL = presetsDirectory.appendingPathComponent(preset.fileName)
        try? fileManager.removeItem(at: cubeFileURL)
        
        // Remove from list
        customPresets.removeAll { $0.id == preset.id }
        
        // Save updated metadata
        savePresetsMetadata()
    }
    
    // MARK: - Get CUBE Data
    func getCUBEData(for preset: CustomPreset) -> Data? {
        let cubeFileURL = presetsDirectory.appendingPathComponent(preset.fileName)
        return try? Data(contentsOf: cubeFileURL)
    }
    
    // MARK: - Apply Preset
    func applyPreset(_ preset: CustomPreset, to image: CIImage, intensity: Float = 1.0) -> CIImage? {
        guard let cubeData = getCUBEData(for: preset) else { return nil }
        
        // Parse CUBE file
        guard let lutData = parseCUBEFile(data: cubeData) else { return nil }
        
        // Apply using CIColorCube filter
        guard let colorCubeFilter = CIFilter(name: "CIColorCube") else { return nil }
        
        colorCubeFilter.setValue(image, forKey: kCIInputImageKey)
        colorCubeFilter.setValue(lutData.data, forKey: "inputCubeData")
        colorCubeFilter.setValue(lutData.dimension, forKey: "inputCubeDimension")
        
        guard let outputImage = colorCubeFilter.outputImage else { return nil }
        
        // Apply intensity if less than 1.0
        if intensity < 1.0 {
            return blendWithOriginal(original: image, filtered: outputImage, intensity: intensity)
        }
        
        return outputImage
    }
    
    // MARK: - Validation
    private func validateCUBEFile(data: Data) -> Bool {
        guard let content = String(data: data, encoding: .utf8) else { return false }
        
        // Basic validation: check for LUT_3D_SIZE
        return content.contains("LUT_3D_SIZE") || content.contains("LUT_1D_SIZE")
    }
    
    // MARK: - Parse CUBE File
    private func parseCUBEFile(data: Data) -> (data: Data, dimension: Int)? {
        guard let content = String(data: data, encoding: .utf8) else { return nil }
        
        let lines = content.components(separatedBy: .newlines)
        var dimension = 0
        var values: [Float] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            // Parse dimension
            if trimmed.hasPrefix("LUT_3D_SIZE") {
                let parts = trimmed.components(separatedBy: .whitespaces)
                if parts.count >= 2, let size = Int(parts[1]) {
                    dimension = size
                }
                continue
            }
            
            // Parse RGB values
            let components = trimmed.components(separatedBy: .whitespaces)
            if components.count >= 3 {
                if let r = Float(components[0]),
                   let g = Float(components[1]),
                   let b = Float(components[2]) {
                    values.append(contentsOf: [r, g, b, 1.0]) // RGBA
                }
            }
        }
        
        // Validate parsed data
        let expectedCount = dimension * dimension * dimension * 4
        guard dimension > 0 && values.count == expectedCount else {
            print("Invalid CUBE data: dimension=\(dimension), values=\(values.count), expected=\(expectedCount)")
            return nil
        }
        
        // Convert to Data
        let lutData = values.withUnsafeBytes { Data($0) }
        
        return (lutData, dimension)
    }
    
    // MARK: - Blend Helper
    private func blendWithOriginal(original: CIImage, filtered: CIImage, intensity: Float) -> CIImage? {
        guard let blendFilter = CIFilter(name: "CISourceOverCompositing") else { return filtered }
        
        // Apply opacity to filtered image
        let alphaFilter = CIFilter(name: "CIColorMatrix")
        alphaFilter?.setValue(filtered, forKey: kCIInputImageKey)
        alphaFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity)), forKey: "inputAVector")
        
        guard let transparentFiltered = alphaFilter?.outputImage else { return filtered }
        
        // Blend with original
        blendFilter.setValue(original, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(transparentFiltered, forKey: kCIInputImageKey)
        
        return blendFilter.outputImage
    }
    
    // MARK: - Rename Preset
    func renamePreset(_ preset: CustomPreset, newName: String) {
        guard let index = customPresets.firstIndex(where: { $0.id == preset.id }) else { return }
        
        let updatedPreset = CustomPreset(
            name: newName,
            fileName: preset.fileName,
            thumbnailData: preset.thumbnailData
        )
        
        customPresets[index] = updatedPreset
        savePresetsMetadata()
    }
}

// MARK: - Error Types
enum PresetError: LocalizedError {
    case invalidCUBEFile
    case fileNotFound
    case importFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCUBEFile:
            return "Invalid CUBE file format"
        case .fileNotFound:
            return "Preset file not found"
        case .importFailed:
            return "Failed to import preset"
        }
    }
}