//======================================================================
// MARK: - CustomPresetImportView.swift
// Purpose: Custom CUBE preset import interface (カスタムCUBEプリセットインポート画面)
// Path: still/Features/PhotoEditor/Views/Components/CustomPresetImportView.swift
//======================================================================

import SwiftUI
import UniformTypeIdentifiers

struct CustomPresetImportView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var presetManager = CustomPresetManager.shared
    let originalImage: UIImage
    let onPresetImported: (CustomPreset) -> Void
    
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isImporting = false
    @State private var presetName = ""
    @State private var showingNameInput = false
    @State private var selectedURL: URL?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "cube")
                        .font(.system(size: 48))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                    
                    Text("Import Custom Preset")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Import .cube files to create custom presets")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Import Options
                VStack(spacing: 16) {
                    // File picker button
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "folder")
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Choose CUBE File")
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text("Select a .cube file from your device")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(white: 0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(Color(white: 0.5))
                        }
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            Rectangle()
                                .stroke(Color(white: 0.3), lineWidth: 1)
                        )
                    }
                    .disabled(isImporting)
                    
                    // Sample presets info
                    VStack(spacing: 8) {
                        Text("Sample CUBE Files")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(white: 0.8))
                        
                        Text("You can download CUBE files from:\n• Adobe Creative Cloud\n• RNI Films\n• VSCO\n• Or create your own in Photoshop/Lightroom")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Existing presets count
                if !presetManager.customPresets.isEmpty {
                    Text("\(presetManager.customPresets.count) custom presets imported")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.6))
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.data, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Name Your Preset", isPresented: $showingNameInput) {
            TextField("Preset Name", text: $presetName)
            Button("Cancel") {
                selectedURL = nil
                presetName = ""
            }
            Button("Import") {
                importSelectedFile()
            }
            .disabled(presetName.isEmpty)
        } message: {
            Text("Enter a name for your custom preset")
        }
        .alert("Import Result", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - File Import
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedURL = url
            presetName = url.deletingPathExtension().lastPathComponent
            showingNameInput = true
            
        case .failure(let error):
            alertMessage = "Failed to select file: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func importSelectedFile() {
        guard let url = selectedURL else { return }
        
        isImporting = true
        
        Task {
            do {
                // Generate thumbnail
                let thumbnail = await generatePreviewThumbnail()
                
                // Import the preset
                let preset = try await presetManager.importCUBEFile(
                    from: url,
                    name: presetName,
                    thumbnail: thumbnail
                )
                
                await MainActor.run {
                    isImporting = false
                    onPresetImported(preset)
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isImporting = false
                    alertMessage = "Import failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    // MARK: - Thumbnail Generation
    private func generatePreviewThumbnail() async -> UIImage? {
        // Generate a small preview of the effect applied to the original image
        guard let ciImage = CIImage(image: originalImage) else { return nil }
        
        // Scale down for thumbnail
        let scale: CGFloat = 112.0 / max(ciImage.extent.width, ciImage.extent.height)
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Preview
#if DEBUG
struct CustomPresetImportView_Previews: PreviewProvider {
    static var previews: some View {
        CustomPresetImportView(
            originalImage: UIImage(systemName: "photo")!,
            onPresetImported: { _ in }
        )
    }
}
#endif