//======================================================================
// MARK: - MultiCameraManager.swift
// Purpose: Manages multiple camera sessions and simultaneous capture
// Path: still/Features/Camera/Managers/MultiCameraManager.swift
//======================================================================
import AVFoundation
import UIKit
import Combine

/**
 * Manager for handling multiple camera sessions simultaneously
 * Supports dual, triple, and picture-in-picture camera configurations
 */
@MainActor
class MultiCameraManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isSetupComplete = false
    @Published var isSupported = false
    @Published var availableCameras: [AVCaptureDevice] = []
    @Published var currentLayout: CameraLayout = .dual
    
    // MARK: - Camera Session
    private var multiCamSession: AVCaptureMultiCamSession?
    private var photoOutputs: [String: AVCapturePhotoOutput] = [:]
    
    // MARK: - Camera Devices
    private var frontCamera: AVCaptureDevice?
    private var backWideCamera: AVCaptureDevice?
    private var backUltraWideCamera: AVCaptureDevice?
    private var backTelephotoCamera: AVCaptureDevice?
    
    // MARK: - Preview Layers
    var frontCameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var backCameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var ultraWideCameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var telephotoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Initialization
    override init() {
        super.init()
        checkMultiCamSupport()
        discoverCameras()
    }
    
    // MARK: - Setup Methods
    private func checkMultiCamSupport() {
        isSupported = AVCaptureMultiCamSession.isSupported
        print("🎥 Multi-camera support: \(isSupported)")
    }
    
    private func discoverCameras() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInUltraWideCamera,
                .builtInTelephotoCamera,
                .builtInTrueDepthCamera
            ],
            mediaType: .video,
            position: .unspecified
        )
        
        availableCameras = discoverySession.devices
        
        // Assign specific cameras
        frontCamera = availableCameras.first { $0.position == .front }
        backWideCamera = availableCameras.first { 
            $0.position == .back && $0.deviceType == .builtInWideAngleCamera 
        }
        backUltraWideCamera = availableCameras.first { 
            $0.position == .back && $0.deviceType == .builtInUltraWideCamera 
        }
        backTelephotoCamera = availableCameras.first { 
            $0.position == .back && $0.deviceType == .builtInTelephotoCamera 
        }
        
        print("🎥 Available cameras:")
        print("  - Front: \(frontCamera?.localizedName ?? "None")")
        print("  - Back Wide: \(backWideCamera?.localizedName ?? "None")")
        print("  - Back Ultra Wide: \(backUltraWideCamera?.localizedName ?? "None")")
        print("  - Back Telephoto: \(backTelephotoCamera?.localizedName ?? "None")")
    }
    
    func setupMultiCameraSession() {
        guard isSupported else {
            print("❌ Multi-camera not supported on this device")
            return
        }
        
        multiCamSession = AVCaptureMultiCamSession()
        
        guard let session = multiCamSession else { return }
        
        session.beginConfiguration()
        
        // Setup cameras based on current layout
        setupCamerasForLayout(currentLayout)
        
        session.commitConfiguration()
        
        // Start the session
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.startRunning()
            
            DispatchQueue.main.async {
                self?.isSetupComplete = true
            }
        }
    }
    
    private func setupCamerasForLayout(_ layout: CameraLayout) {
        guard let session = multiCamSession else { return }
        
        // Clear existing inputs and outputs
        clearSession()
        
        switch layout {
        case .dual:
            setupDualCamera(session: session)
        case .triple:
            setupTripleCamera(session: session)
        case .pictureInPicture:
            setupPictureInPictureCamera(session: session)
        case .grid:
            setupGridCamera(session: session)
        }
    }
    
    // MARK: - Camera Configuration Methods
    private func setupDualCamera(session: AVCaptureMultiCamSession) {
        // Setup front camera
        if let frontCamera = frontCamera {
            setupCamera(device: frontCamera, session: session, identifier: "front")
            frontCameraPreviewLayer = createPreviewLayer(for: session, deviceId: "front")
        }
        
        // Setup back wide camera
        if let backCamera = backWideCamera {
            setupCamera(device: backCamera, session: session, identifier: "back_wide")
            backCameraPreviewLayer = createPreviewLayer(for: session, deviceId: "back_wide")
        }
    }
    
    private func setupTripleCamera(session: AVCaptureMultiCamSession) {
        // Setup back wide camera (main)
        if let backCamera = backWideCamera {
            setupCamera(device: backCamera, session: session, identifier: "back_wide")
            backCameraPreviewLayer = createPreviewLayer(for: session, deviceId: "back_wide")
        }
        
        // Setup ultra wide camera
        if let ultraWideCamera = backUltraWideCamera {
            setupCamera(device: ultraWideCamera, session: session, identifier: "ultra_wide")
            ultraWideCameraPreviewLayer = createPreviewLayer(for: session, deviceId: "ultra_wide")
        }
        
        // Setup telephoto camera
        if let telephotoCamera = backTelephotoCamera {
            setupCamera(device: telephotoCamera, session: session, identifier: "telephoto")
            telephotoPreviewLayer = createPreviewLayer(for: session, deviceId: "telephoto")
        }
    }
    
    private func setupPictureInPictureCamera(session: AVCaptureMultiCamSession) {
        // Main camera (back wide)
        if let backCamera = backWideCamera {
            setupCamera(device: backCamera, session: session, identifier: "back_wide")
            backCameraPreviewLayer = createPreviewLayer(for: session, deviceId: "back_wide")
        }
        
        // PiP camera (front)
        if let frontCamera = frontCamera {
            setupCamera(device: frontCamera, session: session, identifier: "front")
            frontCameraPreviewLayer = createPreviewLayer(for: session, deviceId: "front")
        }
    }
    
    private func setupGridCamera(session: AVCaptureMultiCamSession) {
        // Setup all available cameras for grid view
        setupDualCamera(session: session) // Front + Back Wide
        
        // Add ultra wide if available
        if let ultraWideCamera = backUltraWideCamera {
            setupCamera(device: ultraWideCamera, session: session, identifier: "ultra_wide")
            ultraWideCameraPreviewLayer = createPreviewLayer(for: session, deviceId: "ultra_wide")
        }
        
        // Add telephoto if available
        if let telephotoCamera = backTelephotoCamera {
            setupCamera(device: telephotoCamera, session: session, identifier: "telephoto")
            telephotoPreviewLayer = createPreviewLayer(for: session, deviceId: "telephoto")
        }
    }
    
    private func setupCamera(device: AVCaptureDevice, session: AVCaptureMultiCamSession, identifier: String) {
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(input) {
                session.addInputWithNoConnections(input)
                
                // Create video data output
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_\(identifier)"))
                
                if session.canAddOutput(videoOutput) {
                    session.addOutputWithNoConnections(videoOutput)
                    
                    // Connect input to output
                    if let videoPort = input.ports(for: .video, sourceDeviceType: device.deviceType, sourceDevicePosition: device.position).first {
                        let connection = AVCaptureConnection(inputPorts: [videoPort], output: videoOutput)
                        if session.canAddConnection(connection) {
                            session.addConnection(connection)
                        }
                    }
                }
                
                // Create photo output
                let photoOutput = AVCapturePhotoOutput()
                if session.canAddOutput(photoOutput) {
                    session.addOutputWithNoConnections(photoOutput)
                    photoOutputs[identifier] = photoOutput
                    
                    // Connect input to photo output
                    if let videoPort = input.ports(for: .video, sourceDeviceType: device.deviceType, sourceDevicePosition: device.position).first {
                        let photoConnection = AVCaptureConnection(inputPorts: [videoPort], output: photoOutput)
                        if session.canAddConnection(photoConnection) {
                            session.addConnection(photoConnection)
                        }
                    }
                }
            }
        } catch {
            print("❌ Error setting up camera \(identifier): \(error)")
        }
    }
    
    private func createPreviewLayer(for session: AVCaptureMultiCamSession, deviceId: String) -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
    
    private func clearSession() {
        guard let session = multiCamSession else { return }
        
        // Remove all inputs and outputs
        for input in session.inputs {
            session.removeInput(input)
        }
        
        for output in session.outputs {
            session.removeOutput(output)
        }
        
        // Clear preview layers
        frontCameraPreviewLayer = nil
        backCameraPreviewLayer = nil
        ultraWideCameraPreviewLayer = nil
        telephotoPreviewLayer = nil
        
        // Clear photo outputs
        photoOutputs.removeAll()
    }
    
    // MARK: - Public Methods
    func updateLayout(_ layout: CameraLayout) {
        guard let session = multiCamSession else { return }
        
        currentLayout = layout
        
        session.beginConfiguration()
        setupCamerasForLayout(layout)
        session.commitConfiguration()
    }
    
    func switchCameraConfiguration() {
        // Implement camera switching logic
        let layouts: [CameraLayout] = [.dual, .triple, .pictureInPicture, .grid]
        if let currentIndex = layouts.firstIndex(of: currentLayout) {
            let nextIndex = (currentIndex + 1) % layouts.count
            updateLayout(layouts[nextIndex])
        }
    }
    
    func captureMultiCameraPhoto(completion: @escaping ([String: Data]) -> Void) {
        var capturedPhotos: [String: Data] = [:]
        let group = DispatchGroup()
        
        for (identifier, photoOutput) in photoOutputs {
            group.enter()
            
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            
            photoOutput.capturePhoto(with: settings, delegate: MultiCameraPhotoDelegate { photoData in
                if let data = photoData {
                    capturedPhotos[identifier] = data
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            completion(capturedPhotos)
        }
    }
    
    func stopSession() {
        multiCamSession?.stopRunning()
        isSetupComplete = false
    }
    
    deinit {
        stopSession()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension MultiCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Handle real-time video frames if needed
        // This can be used for real-time effects or analysis
    }
}

// MARK: - Multi-Camera Photo Delegate
class MultiCameraPhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Data?) -> Void
    
    init(completion: @escaping (Data?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("❌ Photo capture error: \(error)")
            completion(nil)
            return
        }
        
        completion(photo.fileDataRepresentation())
    }
}