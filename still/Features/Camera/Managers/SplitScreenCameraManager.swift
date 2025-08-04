//======================================================================
// MARK: - SplitScreenCameraManager.swift
// Purpose: Manages camera for split screen photography
// Path: still/Features/Camera/Managers/SplitScreenCameraManager.swift
//======================================================================
import AVFoundation
import UIKit
import Combine

/**
 * Camera manager specialized for split screen photography
 * Handles single camera session with active split tracking
 */
class SplitScreenCameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    // MARK: - Published Properties
    @Published var isSessionRunning = false
    @Published var activeSplit: Int = 0
    
    // MARK: - Camera Session Properties
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private let sessionQueue = DispatchQueue(label: "split.camera.session.queue")
    
    // MARK: - Preview Layer
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Photo Capture Callback
    private var captureCompletion: ((UIImage?) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupNotificationObservers()
        print("🎬 SplitScreenCameraManager initialized")
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SplitCameraSetupComplete"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let previewLayer = notification.userInfo?["previewLayer"] as? AVCaptureVideoPreviewLayer,
               let isRunning = notification.userInfo?["isRunning"] as? Bool {
                self?.previewLayer = previewLayer
                self?.isSessionRunning = isRunning
                print("📷 Split screen camera session started: \(isRunning)")
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SplitPhotoCaptured"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let completion = self?.captureCompletion
            self?.captureCompletion = nil
            
            if let image = notification.userInfo?["image"] as? UIImage {
                completion?(image)
            } else {
                completion?(nil)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SplitCameraSessionRestarted"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let isRunning = notification.userInfo?["isRunning"] as? Bool {
                self?.isSessionRunning = isRunning
                print("📷 Split screen camera session restart status updated: \(isRunning)")
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SplitCameraSessionStopped"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let isRunning = notification.userInfo?["isRunning"] as? Bool {
                self?.isSessionRunning = isRunning
                print("📷 Split screen camera session stopped status updated: \(isRunning)")
            }
        }
    }
    
    // MARK: - Camera Setup
    /**
     * Sets up the camera session for split screen photography
     */
    func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            print("📷 Setting up split screen camera session...")
            
            let session = AVCaptureSession()
            
            // Set session preset for high quality
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
            
            // Notify about camera setup completion without self reference
            let capturedPreviewLayer = previewLayer
            let isRunning = session.isRunning
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("SplitCameraSetupComplete"),
                    object: nil,
                    userInfo: [
                        "previewLayer": capturedPreviewLayer,
                        "isRunning": isRunning
                    ]
                )
            }
        }
    }
    
    // MARK: - Photo Capture
    /**
     * Captures a photo for the current active split
     * - Parameter completion: Callback with captured image
     */
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let photoOutput = self.photoOutput,
                  let session = self.captureSession,
                  session.isRunning else {
                print("❌ Cannot capture photo: session not ready")
                completion(nil)
                return
            }
            
            // Store completion for delegate callback
            self.captureCompletion = completion
            
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
            
            print("📷 Taking photo for split \(self.activeSplit) with settings: \(settings)")
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    // MARK: - Session Management
    /**
     * Stops the camera session
     */
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, let session = self.captureSession else { return }
            
            if session.isRunning {
                session.stopRunning()
                print("📷 Split screen camera session stopped")
                
                // Notify about session stop without self reference
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SplitCameraSessionStopped"),
                        object: nil,
                        userInfo: ["isRunning": false]
                    )
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
                print("📷 Split screen camera session restarted")
                
                // Notify about session restart without self reference
                let isRunning = session.isRunning
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SplitCameraSessionRestarted"),
                        object: nil,
                        userInfo: ["isRunning": isRunning]
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        captureSession?.stopRunning()
        print("🎬 SplitScreenCameraManager deinitialized")
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension SplitScreenCameraManager {
    /**
     * Called when photo capture is completed
     */
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("❌ Split photo capture error: \(error.localizedDescription)")
            // Notify about capture failure
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("SplitPhotoCaptured"),
                    object: nil,
                    userInfo: ["image": NSNull()]
                )
            }
            return
        }
        
        guard let data = photo.fileDataRepresentation() else {
            print("❌ Failed to get split photo data representation")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("SplitPhotoCaptured"),
                    object: nil,
                    userInfo: ["image": NSNull()]
                )
            }
            return
        }
        
        guard let image = UIImage(data: data) else {
            print("❌ Failed to create UIImage from split photo data")
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("SplitPhotoCaptured"),
                    object: nil,
                    userInfo: ["image": NSNull()]
                )
            }
            return
        }
        
        print("📷 Split photo captured successfully - Size: \(image.size)")
        
        // Notify about successful capture
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("SplitPhotoCaptured"),
                object: nil,
                userInfo: ["image": image]
            )
        }
    }
}