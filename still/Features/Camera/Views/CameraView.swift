//======================================================================
// MARK: - CameraView（フィルムカメラ機能）
// Path: still/Features/Camera/Views/CameraView.swift
//======================================================================
import SwiftUI
@preconcurrency import AVFoundation

struct CameraView: View {
    @Namespace private var filmAnimationNamespace
    @State private var selectedFilm: Film?
    @State private var isFilmLoaded = false
    @State private var isShutterEnabled = false
    @StateObject private var cameraManager = CameraManager()
    
    let films: [Film] = [
        Film(id: "1", name: "Classic", color: Color.orange),
        Film(id: "2", name: "Noir", color: Color.gray),
        Film(id: "3", name: "Vivid", color: Color.blue),
        Film(id: "4", name: "Vintage", color: Color.brown)
    ]
    
    var body: some View {
        ZStack {
            // カメラプレビュー
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea()
            
            // オーバーレイUI
            VStack {
                // 上部のフィルム装填エリア
                HStack {
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
                ShutterButton(isEnabled: isShutterEnabled) {
                    cameraManager.takePhoto()
                }
                .padding(.bottom, 30)
                
                // Bottom film selection interface
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(films) { film in
                            if selectedFilm?.id != film.id {
                                FilmCylinderView(film: film)
                                    .matchedGeometryEffect(id: film.id, in: filmAnimationNamespace)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            // Reset camera state for new film
                                            isFilmLoaded = false
                                            isShutterEnabled = false
                                            selectedFilm = film
                                        }
                                    }
                            } else {
                                // Placeholder for selected film (shows loading position)
                                FilmCylinderView(film: film)
                                    .opacity(0.3)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
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

// MARK: - Film Cylinder View

/**
 * FilmCylinderView displays a 3D-styled film canister.
 * 
 * This view creates a visual representation of a film cylinder with:
 * - Gradient shading to simulate 3D appearance
 * - Top cap with elliptical perspective
 * - Rotated text label on the cylinder body
 * - Drop shadow for depth
 */
struct FilmCylinderView: View {
    /// The film to represent visually
    let film: Film
    
    var body: some View {
        VStack(spacing: 8) {
            // Film canister body
            ZStack {
                // Cylinder side surface with gradient shading
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: [film.color.opacity(0.8), film.color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 50, height: 80)
                
                // Top cap with perspective
                Ellipse()
                    .fill(film.color.opacity(0.9))
                    .frame(width: 50, height: 20)
                    .offset(y: -30)
                
                // Film label rotated to match cylinder orientation
                Text(film.name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(-90))
            }
            .shadow(radius: 5)
            
            // Film name below the cylinder
            Text(film.name)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
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
            // Loaded film canister (enlarged to show it's active)
            FilmCylinderView(film: film)
                .matchedGeometryEffect(id: film.id, in: namespace)
                .scaleEffect(1.2)
            
            // Hanging film tail for user interaction
            if isFilmLoaded {
                // Film tail and pull tab
                VStack(spacing: 0) {
                    // Film strip body
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.black, Color.black.opacity(0.8)],
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
@MainActor
class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    /// Camera capture session
    private var captureSession: AVCaptureSession?
    
    /// Photo output for capturing images
    private var photoOutput: AVCapturePhotoOutput?
    
    /// Most recently captured image
    @Published var capturedImage: UIImage?
    
    /**
     * Checks and requests camera permissions if needed.
     */
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Already authorized
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    Task { @MainActor in
                        self?.setupCamera { _ in }
                    }
                }
            }
        default:
            // Handle denied or restricted access
            break
        }
    }
    
    /**
     * Sets up the camera session with input and output configuration.
     * 
     * - Parameter completion: Callback with configured preview layer
     */
    func setupCamera(completion: @MainActor @escaping (AVCaptureVideoPreviewLayer) -> Void) {
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Configure camera device input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Configure photo output
        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            photoOutput = output
        }
        
        session.commitConfiguration()
        captureSession = session
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        // Start session on background queue
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        
        Task { @MainActor in
            completion(previewLayer)
        }
    }
    
    /**
     * Captures a photo using current camera settings.
     */
    func takePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    /**
     * Called when photo capture is completed.
     * 
     * Processes the captured photo and applies film effects if needed.
     */
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        
        Task { @MainActor [weak self] in
            self?.capturedImage = image
            // TODO: Apply film filter based on selected film type and save to photo library
        }
    }
}