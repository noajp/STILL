//======================================================================
// MARK: - CameraView（フィルムカメラ機能）
// Path: still/Features/Camera/Views/CameraView.swift
//======================================================================
import SwiftUI
@preconcurrency import AVFoundation
import Photos

struct CameraView: View {
    @Namespace private var filmAnimationNamespace
    @State private var selectedFilm: Film?
    @State private var isFilmLoaded = false
    @State private var isShutterEnabled = false
    @StateObject private var cameraManager = CameraManager()
    @State private var previewLayer: AVCaptureVideoPreviewLayer?
    @State private var isSplitScreenMode = false
    
    // Story mode parameter
    var isForStory: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    let films: [Film] = [
        Film(id: "1", name: "Classic", color: Color.orange),
        Film(id: "2", name: "Noir", color: Color.gray),
        Film(id: "3", name: "Vivid", color: Color.blue),
        Film(id: "4", name: "Vintage", color: Color.brown)
    ]
    
    var body: some View {
        ZStack {
            if isSplitScreenMode {
                // Split screen camera view
                SplitScreenCameraView()
            } else {
                // Normal camera view
                normalCameraView
            }
        }
    }
    
    private var normalCameraView: some View {
        ZStack {
            // カメラプレビュー
            if let previewLayer = previewLayer {
                CameraPreviewRepresentable(previewLayer: previewLayer)
                    .ignoresSafeArea()
            } else {
                Rectangle()
                    .fill(Color(hex: "121212"))
                    .ignoresSafeArea()
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Setting up camera...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                    )
            }
            
            // オーバーレイUI
            VStack {
                // 上部コントロール
                HStack {
                    // Close button for story mode OR Split screen toggle for regular mode
                    if isForStory {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(22)
                        }
                        .padding(.top, 50)
                        .padding(.leading, 20)
                    } else {
                        // Split screen toggle button
                        Button(action: { isSplitScreenMode.toggle() }) {
                            Image(systemName: isSplitScreenMode ? "rectangle" : "rectangle.split.2x1")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(22)
                        }
                        .padding(.top, 50)
                        .padding(.leading, 20)
                    }
                    
                    Spacer()
                    
                    if let film = selectedFilm {
                        FilmLoadedView(
                            film: film,
                            namespace: filmAnimationNamespace,
                            isFilmLoaded: $isFilmLoaded,
                            isShutterEnabled: $isShutterEnabled
                        )
                        .padding(.top, 50)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // Camera shutter button
                ShutterButton(isEnabled: cameraManager.isSessionRunning && previewLayer != nil) {
                    print("📷 Shutter button pressed")
                    cameraManager.takePhoto()
                }
                .padding(.bottom, 30)
                
                // Film selection interface removed
            }
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.isSessionRunning) { _, isRunning in
            if !isRunning {
                print("⚠️ Camera session stopped unexpectedly")
            }
        }
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        // Check current permission status
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            // Permission already granted, setup camera immediately
            cameraManager.setupCamera { layer in
                self.previewLayer = layer
            }
        case .notDetermined:
            // Request permission first
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.cameraManager.setupCamera { layer in
                            self.previewLayer = layer
                        }
                    }
                }
            }
        default:
            // Permission denied or restricted
            print("Camera access denied")
        }
    }
}


// MARK: - Film Model

/**
 * Film represents a camera film type with visual characteristics.
 * 
 * Each film type has a unique identifier, display name, and associated
 * color that affects the visual appearance of the film cylinder in the UI.
 */
struct Film: Identifiable {
    /// Unique identifier for the film
    let id: String
    
    /// Display name for the film type
    let name: String
    
    /// Color associated with this film type for UI representation
    let color: Color
}


// MARK: - Film Loaded View

/**
 * FilmLoadedView shows a film canister after loading with interactive pull tab.
 * 
 * This view simulates the film loading process where users can pull the film
 * tail to activate the camera. Features include:
 * - Animated film tail extension
 * - Pull-to-activate gesture interaction
 * - Visual feedback for successful activation
 * - Smooth spring animations for realistic feel
 */
struct FilmLoadedView: View {
    /// The loaded film type
    let film: Film
    
    /// Animation namespace for matched geometry effects
    let namespace: Namespace.ID
    
    /// Whether the film loading animation has completed
    @Binding var isFilmLoaded: Bool
    
    /// Whether the camera shutter is enabled for capture
    @Binding var isShutterEnabled: Bool
    
    /// Current pull offset for the film tail
    @State private var pullOffset: CGFloat = 0
    
    /// Height of the extended film tail
    @State private var filmTailHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Film loaded indicator
            Text(film.name + " Loaded")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(film.color.opacity(0.8))
                .cornerRadius(10)
            
            // Hanging film tail for user interaction
            if isFilmLoaded {
                // Film tail and pull tab
                VStack(spacing: 0) {
                    // Film strip body
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "121212"), Color(hex: "121212").opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 35, height: filmTailHeight)
                    
                    // Pull tab for user interaction
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.orange)
                        .frame(width: 40, height: 20)
                        .overlay(
                            Text("PULL")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.black)
                        )
                }
                .offset(y: pullOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                pullOffset = value.translation.height
                                filmTailHeight = 50 + value.translation.height * 0.5
                            }
                        }
                        .onEnded { value in
                            if pullOffset > 80 {
                                // Successful pull - enable camera
                                withAnimation(.spring()) {
                                    isShutterEnabled = true
                                    filmTailHeight = 100
                                }
                            } else {
                                // Insufficient pull - reset position
                                withAnimation(.spring()) {
                                    pullOffset = 0
                                    filmTailHeight = 50
                                }
                            }
                        }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isFilmLoaded = true
                    filmTailHeight = 50
                }
            }
        }
    }
}

// MARK: - Shutter Button

/**
 * ShutterButton provides a camera-style shutter button with tactile feedback.
 * 
 * Features traditional camera shutter design with:
 * - Circular button with outer ring
 * - Press animation with scale effects
 * - Enabled/disabled visual states
 * - Smooth spring animations for natural feel
 */
struct ShutterButton: View {
    /// Whether the button can be pressed
    let isEnabled: Bool
    
    /// Action to perform when button is pressed
    let action: () -> Void
    
    /// Current pressed state for visual feedback
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring border
                Circle()
                    .stroke(
                        isEnabled ? Color.white : Color.gray,
                        lineWidth: 3
                    )
                    .frame(width: 80, height: 80)
                
                // Inner button surface
                Circle()
                    .fill(isEnabled ? Color.white : Color.gray.opacity(0.5))
                    .frame(width: 65, height: 65)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
        }
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Camera Preview View (Placeholder)
// Currently unused - Rectangle placeholder is used for preview background

// MARK: - Camera Manager

/**
 * CameraManager handles camera operations and photo capture.
 * 
 * Manages the AVFoundation camera session, permission handling,
 * and photo capture functionality for the film camera interface.
 */
class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    /// Camera capture session
    private var captureSession: AVCaptureSession?
    
    /// Photo output for capturing images
    private var photoOutput: AVCapturePhotoOutput?
    
    /// Most recently captured image
    @Published var capturedImage: UIImage?
    
    /// Session queue for camera operations
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    /// Is session currently running
    @Published var isSessionRunning = false
    
    override init() {
        super.init()
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PhotoCaptured"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let image = notification.userInfo?["image"] as? UIImage {
                self?.capturedImage = image
                print("📷 Photo assigned to capturedImage property via notification")
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /**
     * Checks and requests camera permissions if needed.
     */
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Already authorized - no need to setup here as it's handled by the view
            print("Camera permission already granted")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    print("Camera permission granted")
                } else {
                    print("Camera permission denied")
                }
            }
        case .denied, .restricted:
            print("Camera permission denied or restricted")
        @unknown default:
            print("Unknown camera permission status")
        }
    }
    
    /**
     * Sets up the camera session with input and output configuration.
     * 
     * - Parameter completion: Callback with configured preview layer
     */
    func setupCamera(completion: @escaping @MainActor (AVCaptureVideoPreviewLayer) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            print("📷 Setting up camera session...")
            
            let session = AVCaptureSession()
            
            // Set session preset for better performance
            if session.canSetSessionPreset(.photo) {
                session.sessionPreset = .photo
            }
            
            session.beginConfiguration()
            
            // Configure camera device input
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("❌ Failed to get camera device")
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                
                if session.canAddInput(input) {
                    session.addInput(input)
                    print("✅ Camera input added to session")
                } else {
                    print("❌ Failed to add camera input to session")
                    return
                }
            } catch {
                print("❌ Failed to create camera input: \(error)")
                return
            }
            
            // Configure photo output
            let output = AVCapturePhotoOutput()
            
            // Enable high resolution capture (iOS 16+)
            if #available(iOS 16.0, *) {
                output.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
            } else {
                output.isHighResolutionCaptureEnabled = true
            }
            
            if session.canAddOutput(output) {
                session.addOutput(output)
                self.photoOutput = output
                print("✅ Photo output added to session")
            } else {
                print("❌ Failed to add photo output to session")
                return
            }
            
            session.commitConfiguration()
            self.captureSession = session
            
            // Create preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            
            // Start session
            session.startRunning()
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isSessionRunning = session.isRunning
                print("📷 Camera session started: \(self.isSessionRunning)")
                completion(previewLayer)
            }
        }
    }
    
    /**
     * Captures a photo using current camera settings.
     */
    func takePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let photoOutput = self.photoOutput,
                  let session = self.captureSession,
                  session.isRunning else {
                print("❌ Cannot take photo: session not ready")
                return
            }
            
            // Create settings with appropriate format
            let settings: AVCapturePhotoSettings
            
            // Use HEVC format if available, otherwise use default
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                settings = AVCapturePhotoSettings()
            }
            
            // Enable high resolution if available (iOS 16+)
            if #available(iOS 16.0, *) {
                settings.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
            } else {
                if photoOutput.isHighResolutionCaptureEnabled {
                    settings.isHighResolutionPhotoEnabled = true
                }
            }
            
            print("📷 Taking photo with settings: \(settings)")
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    /**
     * Called when photo capture is completed.
     * 
     * Processes the captured photo and applies film effects if needed.
     */
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("❌ Photo capture error: \(error.localizedDescription)")
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            print("❌ Failed to get photo data representation")
            return
        }
        
        guard let image = UIImage(data: data) else {
            print("❌ Failed to create UIImage from photo data")
            return
        }
        
        print("📷 Photo captured successfully - Size: \(image.size)")
        
        // Notify about photo capture without self reference
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("PhotoCaptured"), 
                object: nil, 
                userInfo: ["image": image]
            )
        }
        
        // Save to photo library in completely isolated task
        Task.detached {
            await CameraManager.savePhotoToLibraryStatic(image: image)
        }
    }
    
    /**
     * Static method to save photo without any instance dependencies
     */
    static func savePhotoToLibraryStatic(image: UIImage) async {
        // Check photo library permission
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            await performSaveStatic(image: image)
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if newStatus == .authorized || newStatus == .limited {
                await performSaveStatic(image: image)
            } else {
                print("❌ Photo library access denied")
            }
        case .denied, .restricted:
            print("❌ Photo library access denied or restricted")
        @unknown default:
            print("❌ Unknown photo library authorization status")
        }
    }
    
    /**
     * Saves the captured photo to the device's photo library (isolated version)
     */
    private func savePhotoToLibraryIsolated(image: UIImage) async {
        await CameraManager.savePhotoToLibraryStatic(image: image)
    }
    
    /**
     * Saves the captured photo to the device's photo library (MainActor version)
     */
    @MainActor
    private func savePhotoToLibrary(image: UIImage) {
        // Check photo library permission
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            performSave(image: image)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                Task { @MainActor [weak self] in
                    if newStatus == .authorized || newStatus == .limited {
                        self?.performSave(image: image)
                    } else {
                        print("❌ Photo library access denied")
                    }
                }
            }
        case .denied, .restricted:
            print("❌ Photo library access denied or restricted")
        @unknown default:
            print("❌ Unknown photo library authorization status")
        }
    }
    
    /**
     * Static method to perform the actual save operation
     */
    static func performSaveStatic(image: UIImage) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            print("✅ Photo saved to library successfully")
        } catch {
            print("❌ Failed to save photo to library: \(error.localizedDescription)")
        }
    }
    
    /**
     * Performs the actual save operation to photo library (isolated version)
     */
    private func performSaveIsolated(image: UIImage) async {
        await CameraManager.performSaveStatic(image: image)
    }
    
    /**
     * Performs the actual save operation to photo library (MainActor version)
     */
    @MainActor
    private func performSave(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            Task { @MainActor in
                if success {
                    print("✅ Photo saved to library successfully")
                    // Optional: Show success feedback to user
                } else if let error = error {
                    print("❌ Failed to save photo to library: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /**
     * Stops the camera session
     */
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, let session = self.captureSession else { return }
            
            if session.isRunning {
                session.stopRunning()
                print("📷 Camera session stopped")
                
                Task { @MainActor [weak self] in
                    self?.isSessionRunning = false
                }
            }
        }
    }
    
    /**
     * Restarts the camera session if needed
     */
    func restartSessionIfNeeded() {
        sessionQueue.async { [weak self] in
            guard let self = self, let session = self.captureSession else { return }
            
            if !session.isRunning {
                session.startRunning()
                print("📷 Camera session restarted")
                
                Task { @MainActor [weak self] in
                    self?.isSessionRunning = session.isRunning
                }
            }
        }
    }
}
