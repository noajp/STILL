//======================================================================
// MARK: - SplitScreenCameraView.swift
// Purpose: Split screen camera view for capturing multiple images as one
// Path: still/Features/Camera/Components/SplitScreenCameraView.swift
//======================================================================
import SwiftUI
import AVFoundation
import Photos
import MediaPlayer

/**
 * Split screen camera view that allows capturing multiple separate images
 * and combining them into a single composite photograph
 */
struct SplitScreenCameraView: View {
    @StateObject private var cameraManager = SplitScreenCameraManager()
    @State private var splitMode: SplitMode = .dual
    @State private var capturedImages: [Int: UIImage] = [:]
    @State private var isCapturingAll = false
    @State private var showSuccessAnimation = false
    @State private var currentInstructions = ""
    @State private var volumeObserver: Any?
    @State private var showCompositePreview = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                if showCompositePreview && capturedImages.count == splitMode.splitCount {
                    // Show captured images side by side
                    HStack(spacing: 2) {
                        ForEach(0..<splitMode.splitCount, id: \.self) { index in
                            if let image = capturedImages[index] {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width / CGFloat(splitMode.splitCount) - 1)
                                    .clipped()
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                } else {
                    // Split camera views
                    splitCameraViews(geometry: geometry)
                }
                
                // Overlay controls
                if !showCompositePreview {
                    VStack {
                        // Top controls - Only show progress indicator
                        HStack {
                            Spacer()
                            captureProgressIndicator
                            Spacer()
                        }
                        .padding(.top, 50)
                        .padding(.horizontal, 20)
                        
                        // Instructions
                        if !currentInstructions.isEmpty {
                            Text(currentInstructions)
                                .font(.callout)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                                .transition(.opacity)
                        }
                        
                        Spacer()
                        
                        // Bottom controls - Only reset button
                        HStack {
                            Spacer()
                            resetButton
                        }
                        .padding(.bottom, 50)
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .onAppear {
            cameraManager.setupCamera()
            updateInstructions()
            setupVolumeButtonObserver()
        }
        .onDisappear {
            cameraManager.stopSession()
            removeVolumeButtonObserver()
        }
        .onChange(of: cameraManager.activeSplit) { _, _ in updateInstructions() }
        .onChange(of: capturedImages) { _, _ in updateInstructions() }
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
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        cameraManager.capturePhoto { image in
            DispatchQueue.main.async {
                if let image = image {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        capturedImages[index] = image
                    }
                    
                    // Success animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSuccessAnimation = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSuccessAnimation = false
                        }
                    }
                    
                    print("📷 Split \(index) captured successfully")
                } else {
                    print("❌ Failed to capture split \(index)")
                }
            }
        }
    }
    
    
    private func resetAllCaptures() {
        capturedImages.removeAll()
        cameraManager.activeSplit = 0
    }
    
    private func createAndShowComposite() {
        guard capturedImages.count == splitMode.splitCount else { return }
        
        Task { @MainActor in
            // Show preview immediately
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showCompositePreview = true
            }
            
            // Save each image separately to photo library
            for (_, image) in capturedImages {
                await CameraManager.savePhotoToLibraryStatic(image: image)
            }
            print("✅ \(capturedImages.count) images saved to library")
            
            // Hide preview and reset after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showCompositePreview = false
                    self.resetAllCaptures()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func updateInstructions() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let capturedCount = capturedImages.count
            let totalCount = splitMode.splitCount
            
            if capturedCount == 0 {
                currentInstructions = "音量上げボタンで撮影 - 分割\(cameraManager.activeSplit + 1)"
            } else if capturedCount < totalCount {
                let remaining = totalCount - capturedCount
                currentInstructions = "残り\(remaining)枚 - 音量上げボタンで撮影"
            } else {
                currentInstructions = ""
                // All splits captured - create and show composite
                if !showCompositePreview {
                    createAndShowComposite()
                }
            }
        }
    }
    
    // MARK: - Volume Button Handling
    private func setupVolumeButtonObserver() {
        // Setup audio session for volume button capture
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
        
        // Hide system volume HUD
        let volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(volumeView)
        }
        
        // Store notification observer
        volumeObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil,
            queue: .main
        ) { notification in
            // Check if it's a physical button press
            if let userInfo = notification.userInfo,
               let changeReason = userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String,
               changeReason == "ExplicitVolumeChange" {
                Task { @MainActor in
                    self.handleVolumeButtonPress()
                }
            }
        }
    }
    
    private func removeVolumeButtonObserver() {
        if let observer = volumeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        volumeObserver = nil
    }
    
    private func handleVolumeButtonPress() {
        // Capture current split
        captureSplit(cameraManager.activeSplit)
        
        // Auto-advance to next split if not all captured
        if capturedImages.count < splitMode.splitCount {
            let nextSplit = (cameraManager.activeSplit + 1) % splitMode.splitCount
            // Skip if already captured
            var targetSplit = nextSplit
            while capturedImages[targetSplit] != nil && targetSplit != cameraManager.activeSplit {
                targetSplit = (targetSplit + 1) % splitMode.splitCount
            }
            if targetSplit != cameraManager.activeSplit {
                cameraManager.activeSplit = targetSplit
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
    
    @State private var isPressed = false
    
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
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isActive)
            }
            
            // Success checkmark for captured images
            if capturedImage != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                            .background(Color.white.clipShape(Circle()))
                            .scaleEffect(1.2)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: capturedImage != nil)
                    }
                }
                .padding(12)
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
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = false
                        }
                    }
                    
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    onTap()
                }
        }
        .clipped()
    }
}