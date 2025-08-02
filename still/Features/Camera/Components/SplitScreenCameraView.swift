//======================================================================
// MARK: - SplitScreenCameraView.swift
// Purpose: Split screen camera view for capturing multiple images as one
// Path: still/Features/Camera/Components/SplitScreenCameraView.swift
//======================================================================
import SwiftUI
import AVFoundation
import Photos

/**
 * Split screen camera view that allows capturing multiple separate images
 * and combining them into a single composite photograph
 */
struct SplitScreenCameraView: View {
    @StateObject private var cameraManager = SplitScreenCameraManager()
    @State private var splitMode: SplitMode = .dual
    @State private var capturedImages: [Int: UIImage] = [:]
    @State private var isCapturingAll = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Split camera views
                splitCameraViews(geometry: geometry)
                
                // Overlay controls
                VStack {
                    // Top controls
                    HStack {
                        splitModeSelector
                        Spacer()
                        captureProgressIndicator
                    }
                    .padding(.top, 50)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack(spacing: 30) {
                        // Individual capture buttons
                        individualCaptureButtons
                        
                        Spacer()
                        
                        // Master capture button
                        masterCaptureButton
                        
                        Spacer()
                        
                        // Reset button
                        resetButton
                    }
                    .padding(.bottom, 50)
                    .padding(.horizontal, 20)
                }
            }
        }
        .onAppear {
            cameraManager.setupCamera()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    // MARK: - Split Camera Views
    @ViewBuilder
    private func splitCameraViews(geometry: GeometryProxy) -> some View {
        switch splitMode {
        case .dual:
            dualSplitView(geometry: geometry)
        case .triple:
            tripleSplitView(geometry: geometry)
        case .quad:
            quadSplitView(geometry: geometry)
        }
    }
    
    // MARK: - Dual Split View
    private func dualSplitView(geometry: GeometryProxy) -> some View {
        HStack(spacing: 2) {
            // Left split
            SplitCameraFrame(
                splitIndex: 0,
                previewLayer: cameraManager.previewLayer,
                capturedImage: capturedImages[0],
                isActive: cameraManager.activeSplit == 0,
                onTap: { cameraManager.activeSplit = 0 }
            )
            .frame(width: geometry.size.width / 2 - 1)
            
            // Vertical divider
            Rectangle()
                .fill(Color.white)
                .frame(width: 2)
            
            // Right split
            SplitCameraFrame(
                splitIndex: 1,
                previewLayer: cameraManager.previewLayer,
                capturedImage: capturedImages[1],
                isActive: cameraManager.activeSplit == 1,
                onTap: { cameraManager.activeSplit = 1 }
            )
            .frame(width: geometry.size.width / 2 - 1)
        }
    }
    
    // MARK: - Triple Split View (Placeholder)
    private func tripleSplitView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 2) {
            // Top split
            SplitCameraFrame(
                splitIndex: 0,
                previewLayer: cameraManager.previewLayer,
                capturedImage: capturedImages[0],
                isActive: cameraManager.activeSplit == 0,
                onTap: { cameraManager.activeSplit = 0 }
            )
            .frame(height: geometry.size.height * 0.5)
            
            HStack(spacing: 2) {
                SplitCameraFrame(
                    splitIndex: 1,
                    previewLayer: cameraManager.previewLayer,
                    capturedImage: capturedImages[1],
                    isActive: cameraManager.activeSplit == 1,
                    onTap: { cameraManager.activeSplit = 1 }
                )
                
                SplitCameraFrame(
                    splitIndex: 2,
                    previewLayer: cameraManager.previewLayer,
                    capturedImage: capturedImages[2],
                    isActive: cameraManager.activeSplit == 2,
                    onTap: { cameraManager.activeSplit = 2 }
                )
            }
            .frame(height: geometry.size.height * 0.5)
        }
    }
    
    // MARK: - Quad Split View (Placeholder)
    private func quadSplitView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                SplitCameraFrame(
                    splitIndex: 0,
                    previewLayer: cameraManager.previewLayer,
                    capturedImage: capturedImages[0],
                    isActive: cameraManager.activeSplit == 0,
                    onTap: { cameraManager.activeSplit = 0 }
                )
                
                SplitCameraFrame(
                    splitIndex: 1,
                    previewLayer: cameraManager.previewLayer,
                    capturedImage: capturedImages[1],
                    isActive: cameraManager.activeSplit == 1,
                    onTap: { cameraManager.activeSplit = 1 }
                )
            }
            
            HStack(spacing: 2) {
                SplitCameraFrame(
                    splitIndex: 2,
                    previewLayer: cameraManager.previewLayer,
                    capturedImage: capturedImages[2],
                    isActive: cameraManager.activeSplit == 2,
                    onTap: { cameraManager.activeSplit = 2 }
                )
                
                SplitCameraFrame(
                    splitIndex: 3,
                    previewLayer: cameraManager.previewLayer,
                    capturedImage: capturedImages[3],
                    isActive: cameraManager.activeSplit == 3,
                    onTap: { cameraManager.activeSplit = 3 }
                )
            }
        }
    }
    
    // MARK: - UI Components
    private var splitModeSelector: some View {
        Menu {
            ForEach(SplitMode.allCases, id: \.self) { mode in
                Button(mode.displayName) {
                    splitMode = mode
                    capturedImages.removeAll()
                }
            }
        } label: {
            HStack {
                Image(systemName: splitMode.iconName)
                Text(splitMode.displayName)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(20)
        }
    }
    
    private var captureProgressIndicator: some View {
        HStack {
            ForEach(0..<splitMode.splitCount, id: \.self) { index in
                Circle()
                    .fill(capturedImages[index] != nil ? Color.green : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
    }
    
    private var individualCaptureButtons: some View {
        HStack(spacing: 10) {
            ForEach(0..<splitMode.splitCount, id: \.self) { index in
                Button(action: { captureSplit(index) }) {
                    Circle()
                        .fill(capturedImages[index] != nil ? Color.green : Color.white)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(capturedImages[index] != nil ? .white : .black)
                        )
                }
                .disabled(isCapturingAll)
            }
        }
    }
    
    private var masterCaptureButton: some View {
        Button(action: captureAllSplits) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .fill(isCapturingAll ? Color.red : Color.white)
                    .frame(width: 65, height: 65)
                
                if isCapturingAll {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        }
        .disabled(isCapturingAll)
    }
    
    private var resetButton: some View {
        Button(action: resetAllCaptures) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.6))
                .cornerRadius(22)
        }
    }
    
    // MARK: - Actions
    private func captureSplit(_ index: Int) {
        print("📷 Capturing split \(index)")
        cameraManager.capturePhoto { image in
            if let image = image {
                capturedImages[index] = image
                print("📷 Split \(index) captured successfully")
            }
        }
    }
    
    private func captureAllSplits() {
        guard !isCapturingAll else { return }
        
        isCapturingAll = true
        capturedImages.removeAll()
        
        let totalSplits = splitMode.splitCount
        var capturedCount = 0
        
        func captureNext() {
            guard capturedCount < totalSplits else {
                // All splits captured, create composite
                createCompositeImage()
                isCapturingAll = false
                return
            }
            
            cameraManager.activeSplit = capturedCount
            
            // Wait a moment for camera to adjust
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                cameraManager.capturePhoto { image in
                    if let image = image {
                        capturedImages[capturedCount] = image
                        print("📷 Auto-captured split \(capturedCount)")
                    }
                    
                    capturedCount += 1
                    captureNext()
                }
            }
        }
        
        captureNext()
    }
    
    private func resetAllCaptures() {
        capturedImages.removeAll()
        cameraManager.activeSplit = 0
    }
    
    private func createCompositeImage() {
        guard !capturedImages.isEmpty else { return }
        
        Task.detached {
            let composite = await SplitScreenCompositor.createComposite(
                images: capturedImages,
                mode: splitMode
            )
            
            if let composite = composite {
                await CameraManager.savePhotoToLibraryStatic(image: composite)
                print("✅ Composite image saved to library")
            }
        }
    }
}

// MARK: - Split Mode Enum
enum SplitMode: CaseIterable {
    case dual
    case triple  
    case quad
    
    var displayName: String {
        switch self {
        case .dual: return "2分割"
        case .triple: return "3分割"
        case .quad: return "4分割"
        }
    }
    
    var iconName: String {
        switch self {
        case .dual: return "rectangle.split.2x1"
        case .triple: return "rectangle.split.3x1"
        case .quad: return "rectangle.split.2x2"
        }
    }
    
    var splitCount: Int {
        switch self {
        case .dual: return 2
        case .triple: return 3
        case .quad: return 4
        }
    }
}

// MARK: - Split Camera Frame
struct SplitCameraFrame: View {
    let splitIndex: Int
    let previewLayer: AVCaptureVideoPreviewLayer?
    let capturedImage: UIImage?
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            // Camera preview or captured image
            if let capturedImage = capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else if let previewLayer = previewLayer {
                CameraPreviewRepresentable(previewLayer: previewLayer)
                    .opacity(isActive ? 1.0 : 0.3)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            
            // Active indicator
            if isActive && capturedImage == nil {
                Rectangle()
                    .stroke(Color.yellow, lineWidth: 3)
            }
            
            // Split number indicator
            VStack {
                HStack {
                    Text("\(splitIndex + 1)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                    Spacer()
                }
                Spacer()
            }
            .padding(8)
            
            // Tap overlay
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
        }
        .clipped()
    }
}