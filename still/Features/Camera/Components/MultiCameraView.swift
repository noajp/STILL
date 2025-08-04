//======================================================================
// MARK: - MultiCameraView.swift
// Purpose: Multi-camera capture view with simultaneous camera feeds
// Path: still/Features/Camera/Components/MultiCameraView.swift
//======================================================================
import SwiftUI
import AVFoundation

/**
 * Multi-camera view supporting simultaneous camera feeds
 * Displays multiple camera outputs in separate frames
 */
struct MultiCameraView: View {
    @StateObject private var multiCameraManager = MultiCameraManager()
    @State private var selectedLayout: CameraLayout = .dual
    @State private var isRecording = false
    
    var body: some View {
        if !AVCaptureMultiCamSession.isMultiCamSupported {
            unsupportedDeviceView
        } else {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(hex: "121212").ignoresSafeArea()
                
                // Camera frames based on selected layout
                cameraFramesView(geometry: geometry)
                
                // Controls overlay
                VStack {
                    Spacer()
                    controlsView
                        .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            if AVCaptureMultiCamSession.isMultiCamSupported {
                multiCameraManager.setupMultiCameraSession()
            }
        }
        .onDisappear {
            multiCameraManager.stopSession()
        }
        }
    }
    
    // MARK: - Unsupported Device View
    private var unsupportedDeviceView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "camera.badge.ellipsis")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Multi-Camera Not Supported")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(MinimalDesign.Colors.primary)
                
                Text("Multi-camera functionality requires iPhone 11 or newer")
                    .font(.system(size: 16))
                    .foregroundColor(MinimalDesign.Colors.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .background(MinimalDesign.Colors.background)
    }
    
    // MARK: - Camera Frames View
    @ViewBuilder
    private func cameraFramesView(geometry: GeometryProxy) -> some View {
        switch selectedLayout {
        case .dual:
            dualCameraLayout(geometry: geometry)
        case .triple:
            tripleCameraLayout(geometry: geometry)
        case .pictureInPicture:
            pictureInPictureLayout(geometry: geometry)
        case .grid:
            gridCameraLayout(geometry: geometry)
        }
    }
    
    // MARK: - Dual Camera Layout
    private func dualCameraLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 4) {
            // Front camera frame
            CameraFrameView(
                previewLayer: multiCameraManager.frontCameraPreviewLayer,
                title: "Front"
            )
            .frame(width: geometry.size.width / 2 - 2)
            
            // Back camera frame
            CameraFrameView(
                previewLayer: multiCameraManager.backCameraPreviewLayer,
                title: "Wide"
            )
            .frame(width: geometry.size.width / 2 - 2)
        }
    }
    
    // MARK: - Triple Camera Layout
    private func tripleCameraLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 4) {
            // Top: Wide camera (large)
            CameraFrameView(
                previewLayer: multiCameraManager.backCameraPreviewLayer,
                title: "Wide"
            )
            .frame(height: geometry.size.height * 0.6)
            
            HStack(spacing: 4) {
                // Bottom left: Ultra wide
                CameraFrameView(
                    previewLayer: multiCameraManager.ultraWideCameraPreviewLayer,
                    title: "Ultra Wide"
                )
                
                // Bottom right: Telephoto
                CameraFrameView(
                    previewLayer: multiCameraManager.telephotoPreviewLayer,
                    title: "Telephoto"
                )
            }
            .frame(height: geometry.size.height * 0.35)
        }
    }
    
    // MARK: - Picture in Picture Layout
    private func pictureInPictureLayout(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .topTrailing) {
            // Main camera (full screen)
            CameraFrameView(
                previewLayer: multiCameraManager.backCameraPreviewLayer,
                title: "Main"
            )
            
            // PiP camera (small overlay)
            CameraFrameView(
                previewLayer: multiCameraManager.frontCameraPreviewLayer,
                title: "Front"
            )
            .frame(width: 120, height: 160)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 2)
            )
            .padding(.top, 60)
            .padding(.trailing, 20)
        }
    }
    
    // MARK: - Grid Camera Layout
    private func gridCameraLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                CameraFrameView(
                    previewLayer: multiCameraManager.frontCameraPreviewLayer,
                    title: "Front"
                )
                CameraFrameView(
                    previewLayer: multiCameraManager.backCameraPreviewLayer,
                    title: "Wide"
                )
            }
            .frame(height: geometry.size.height / 2 - 2)
            
            HStack(spacing: 4) {
                CameraFrameView(
                    previewLayer: multiCameraManager.ultraWideCameraPreviewLayer,
                    title: "Ultra Wide"
                )
                CameraFrameView(
                    previewLayer: multiCameraManager.telephotoPreviewLayer,
                    title: "Telephoto"
                )
            }
            .frame(height: geometry.size.height / 2 - 2)
        }
    }
    
    // MARK: - Controls View
    private var controlsView: some View {
        HStack(spacing: 30) {
            // Layout selection
            Menu {
                ForEach(CameraLayout.allCases, id: \.self) { layout in
                    Button(layout.displayName) {
                        selectedLayout = layout
                        multiCameraManager.updateLayout(layout)
                    }
                }
            } label: {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.black.opacity(0.3)))
            }
            
            Spacer()
            
            // Capture button
            Button(action: capturePhoto) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "121212"), lineWidth: 3)
                            .frame(width: 60, height: 60)
                    )
            }
            
            Spacer()
            
            // Switch cameras button
            Button(action: switchCameras) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.black.opacity(0.3)))
            }
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Actions
    private func capturePhoto() {
        multiCameraManager.captureMultiCameraPhoto { results in
            // Handle captured photos from multiple cameras
            print("📸 Captured \(results.count) photos from different cameras")
            
            // Photos are automatically saved to camera roll by MultiCameraManager
            // Each camera's photo is saved individually with proper logging
        }
    }
    
    private func switchCameras() {
        multiCameraManager.switchCameraConfiguration()
    }
}

// MARK: - Camera Layout Enum
enum CameraLayout: String, CaseIterable {
    case dual = "dual"
    case triple = "triple"
    case pictureInPicture = "pip"
    case grid = "grid"
    
    var displayName: String {
        switch self {
        case .dual: return "Dual"
        case .triple: return "Triple"
        case .pictureInPicture: return "PiP"
        case .grid: return "Grid"
        }
    }
}

// MARK: - Camera Frame View
struct CameraFrameView: View {
    let previewLayer: AVCaptureVideoPreviewLayer?
    let title: String
    
    var body: some View {
        ZStack {
            // Camera preview
            if let previewLayer = previewLayer {
                CameraPreviewRepresentable(previewLayer: previewLayer)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                            Text("Camera Unavailable")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
            
            // Title overlay
            VStack {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.6))
                        )
                    Spacer()
                }
                Spacer()
            }
            .padding(8)
        }
        .cornerRadius(8)
        .clipped()
    }
}

