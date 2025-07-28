//======================================================================
// MARK: - CustomCameraViewModel.swift
// Purpose: View model for camera functionality with manual controls and image processing
// Path: still/Features/Camera/ViewModels/CustomCameraViewModel.swift
//======================================================================

import SwiftUI
import AVFoundation
import CoreImage
import Photos

/**
 * CustomCameraViewModel manages camera functionality for the STILL app.
 * 
 * This view model provides comprehensive camera control including:
 * - Basic camera operations (capture, zoom, focus, flash)
 * - Manual camera controls (ISO, shutter speed, white balance, focus)
 * - Real-time filter application
 * - Camera switching (front/back)
 * - Error handling and permission management
 * 
 * The view model uses AVFoundation for camera operations and integrates
 * with the app's image processing pipeline for filter application.
 */
@MainActor
class CustomCameraViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Indicates if a photo capture is currently in progress
    @Published var isCapturing = false
    
    /// Controls display of error alert
    @Published var showError = false
    
    /// Current error message to display to user
    @Published var errorMessage: String?
    
    /// Current flash mode setting (off, on, auto)
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    
    /// Current focus point for tap-to-focus indicator
    @Published var focusPoint: CGPoint?
    
    /// Currently selected filter for real-time preview
    @Published var currentFilter: FilterType = .none
    
    /// Whether manual camera controls are enabled
    @Published var isManualMode = false
    
    /// Manual ISO value (camera sensitivity)
    @Published var manualISO: Float = 400
    
    /// Manual shutter speed in fractions of a second
    @Published var manualShutterSpeed: Float = 60
    
    /// Manual white balance in Kelvin temperature
    @Published var manualWhiteBalance: Float = 5600
    
    /// Manual focus position (0.0 = near, 1.0 = far)
    @Published var manualFocus: Float = 0.5
    
    /// Exposure compensation adjustment (-2.0 to +2.0)
    @Published var exposureCompensation: Float = 0.0
    
    // MARK: - Camera Properties
    
    /// Main capture session for coordinating camera input and output
    let session = AVCaptureSession()
    
    /// Current video input device (camera)
    private var videoInput: AVCaptureDeviceInput?
    
    /// Photo capture output for taking pictures
    private var photoOutput = AVCapturePhotoOutput()
    
    /// Front-facing camera device
    private var frontCamera: AVCaptureDevice?
    
    /// Back-facing camera device
    private var backCamera: AVCaptureDevice?
    
    /// Currently active camera device for manual controls access
    var currentCamera: AVCaptureDevice? {
        return videoInput?.device
    }
    
    // MARK: - Image Processing
    
    /// Image processor for optimization and resizing
    private let imageProcessor = ImageProcessor()
    
    /// Advanced filter manager for real-time filter application
    private let filterManager = AdvancedFilterManager()
    
    /// Completion handler called when photo capture and processing is complete
    private var photoCompletionHandler: ((UIImage) -> Void)?
    
    // MARK: - Initialization
    
    /**
     * Initializes the camera view model and begins camera setup.
     */
    override init() {
        super.init()
        setupCamera()
    }
    
    // MARK: - Camera Setup
    
    /**
     * Initiates camera setup by requesting permissions.
     */
    private func setupCamera() {
        Task {
            await requestCameraPermission()
        }
    }
    
    /**
     * Requests camera access permission and configures session if granted.
     */
    private func requestCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            configureSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                configureSession()
            } else {
                showCameraError("Camera access was denied")
            }
        case .denied, .restricted:
            showCameraError("Camera access is denied. Please enable camera access in Settings.")
        @unknown default:
            showCameraError("Camera status could not be determined")
        }
    }
    
    /**
     * Configures the camera session with devices, inputs, and outputs.
     */
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Setup camera devices
        setupCameraDevices()
        
        // Initialize with back camera as default
        if let backCamera = backCamera {
            do {
                videoInput = try AVCaptureDeviceInput(device: backCamera)
                if session.canAddInput(videoInput!) {
                    session.addInput(videoInput!)
                }
            } catch {
                showCameraError("Failed to initialize camera: \(error.localizedDescription)")
                return
            }
        }
        
        // Configure photo output settings
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            // Setup photo quality settings
            if #available(iOS 16.0, *) {
                photoOutput.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
            } else {
                photoOutput.isHighResolutionCaptureEnabled = true
            }
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoOutput.isDepthDataDeliveryEnabled = false
            }
        }
        
        session.commitConfiguration()
    }
    
    /**
     * Discovers and configures available camera devices (front and back).
     */
    private func setupCameraDevices() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        for device in discoverySession.devices {
            switch device.position {
            case .back:
                backCamera = device
            case .front:
                frontCamera = device
            default:
                break
            }
        }
    }
    
    // MARK: - Session Control
    
    func startSession() {
        guard !session.isRunning else { return }
        
        Task {
            session.startRunning()
        }
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        
        session.stopRunning()
    }
    
    // MARK: - Camera Controls
    
    func switchCamera() {
        guard let currentInput = videoInput else { return }
        
        session.beginConfiguration()
        session.removeInput(currentInput)
        
        let newCamera: AVCaptureDevice?
        if currentCamera?.position == .back {
            newCamera = frontCamera
        } else {
            newCamera = backCamera
        }
        
        guard let camera = newCamera else {
            session.addInput(currentInput)
            session.commitConfiguration()
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                videoInput = newInput
            } else {
                session.addInput(currentInput)
            }
        } catch {
            session.addInput(currentInput)
            showCameraError("カメラの切り替えに失敗しました")
        }
        
        session.commitConfiguration()
    }
    
    func setZoomLevel(_ zoomLevel: CGFloat) {
        guard let device = currentCamera else { return }
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = min(max(zoomLevel, 1.0), device.activeFormat.videoMaxZoomFactor)
            device.unlockForConfiguration()
        } catch {
            print("ズーム設定エラー: \(error)")
        }
    }
    
    func focusAt(point: CGPoint) {
        guard let device = currentCamera else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
            
            // フォーカス指示を表示
            focusPoint = point
            
            // 1秒後に非表示
            Task {
                try await Task.sleep(for: .seconds(1))
                focusPoint = nil
            }
            
        } catch {
            print("フォーカス設定エラー: \(error)")
        }
    }
    
    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
    }
    
    func setCurrentFilter(_ filterType: FilterType) {
        currentFilter = filterType
    }
    
    // MARK: - Manual Camera Controls
    
    func setManualMode(_ enabled: Bool) {
        isManualMode = enabled
        
        guard let device = currentCamera else { return }
        
        do {
            try device.lockForConfiguration()
            
            if enabled {
                // Switch to manual mode
                if device.isExposureModeSupported(.custom) {
                    device.exposureMode = .custom
                }
                if device.isFocusModeSupported(.locked) {
                    device.focusMode = .locked
                }
                if device.isWhiteBalanceModeSupported(.locked) {
                    device.whiteBalanceMode = .locked
                }
                
                // Get current values for manual controls
                getCurrentCameraSettings()
            } else {
                // Switch back to auto mode
                resetToAutoMode()
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Manual mode setup error: \(error)")
        }
    }
    
    func getCurrentCameraSettings() {
        guard let device = currentCamera else { return }
        
        // Get current ISO
        manualISO = device.iso
        
        // Get current shutter speed (convert from CMTime to fraction)
        let currentDuration = device.exposureDuration
        if currentDuration.timescale > 0 {
            manualShutterSpeed = Float(currentDuration.timescale) / Float(currentDuration.value)
        }
        
        // Get current white balance (convert to Kelvin approximation)
        let gains = device.deviceWhiteBalanceGains
        manualWhiteBalance = calculateKelvinFromGains(gains)
        
        // Get current focus position
        manualFocus = device.lensPosition
    }
    
    /**
     * Sets manual ISO value for camera exposure.
     * 
     * - Parameter iso: ISO value within device supported range
     */
    func setManualISO(_ iso: Float) {
        guard let device = currentCamera, isManualMode else { return }
        
        let clampedISO = max(device.activeFormat.minISO, min(device.activeFormat.maxISO, iso))
        
        do {
            try device.lockForConfiguration()
            
            if device.isExposureModeSupported(.custom) {
                let currentDuration = device.exposureDuration
                device.setExposureModeCustom(duration: currentDuration, iso: clampedISO)
                manualISO = clampedISO
            }
            
            device.unlockForConfiguration()
        } catch {
            print("ISO setting error: \(error)")
        }
    }
    
    /**
     * Sets manual shutter speed for camera exposure.
     * 
     * - Parameter shutterSpeed: Shutter speed in fractions of a second (e.g., 60 = 1/60s)
     */
    func setManualShutterSpeed(_ shutterSpeed: Float) {
        guard let device = currentCamera, isManualMode else { return }
        
        let duration = CMTime(seconds: 1.0 / Double(shutterSpeed), preferredTimescale: 1000000)
        let clampedDuration = CMTimeClampToRange(duration, range: CMTimeRangeMake(
            start: device.activeFormat.minExposureDuration,
            duration: device.activeFormat.maxExposureDuration
        ))
        
        do {
            try device.lockForConfiguration()
            
            if device.isExposureModeSupported(.custom) {
                device.setExposureModeCustom(duration: clampedDuration, iso: device.iso)
                manualShutterSpeed = shutterSpeed
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Shutter speed setting error: \(error)")
        }
    }
    
    /**
     * Sets manual white balance using Kelvin temperature.
     * 
     * - Parameter kelvin: Color temperature in Kelvin (2000-8000K typical range)
     */
    func setManualWhiteBalance(_ kelvin: Float) {
        guard let device = currentCamera, isManualMode else { return }
        
        let gains = calculateGainsFromKelvin(kelvin)
        let adjustedGains = normalizeGains(gains, for: device)
        
        do {
            try device.lockForConfiguration()
            
            if device.isWhiteBalanceModeSupported(.locked) {
                device.setWhiteBalanceModeLocked(with: adjustedGains)
                manualWhiteBalance = kelvin
            }
            
            device.unlockForConfiguration()
        } catch {
            print("White balance setting error: \(error)")
        }
    }
    
    /**
     * Sets manual focus position.
     * 
     * - Parameter focus: Focus position from 0.0 (near) to 1.0 (far)
     */
    func setManualFocus(_ focus: Float) {
        guard let device = currentCamera, isManualMode else { return }
        
        let clampedFocus = max(0.0, min(1.0, focus))
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusModeSupported(.locked) {
                device.setFocusModeLocked(lensPosition: clampedFocus)
                manualFocus = clampedFocus
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Focus setting error: \(error)")
        }
    }
    
    /**
     * Sets exposure compensation adjustment.
     * 
     * - Parameter compensation: Exposure adjustment typically from -2.0 to +2.0
     */
    func setExposureCompensation(_ compensation: Float) {
        guard let device = currentCamera else { return }
        
        let clampedCompensation = max(device.minExposureTargetBias, min(device.maxExposureTargetBias, compensation))
        
        do {
            try device.lockForConfiguration()
            device.setExposureTargetBias(clampedCompensation)
            exposureCompensation = clampedCompensation
            device.unlockForConfiguration()
        } catch {
            print("Exposure compensation setting error: \(error)")
        }
    }
    
    /**
     * Resets camera to automatic modes for all controls.
     * 
     * This method switches the camera back to continuous auto exposure,
     * auto focus, and auto white balance, and resets exposure compensation.
     */
    func resetToAutoMode() {
        guard let device = currentCamera else { return }
        
        do {
            try device.lockForConfiguration()
            
            // Reset to auto modes
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            // Reset exposure compensation
            device.setExposureTargetBias(0.0)
            exposureCompensation = 0.0
            
            device.unlockForConfiguration()
        } catch {
            print("Auto mode reset error: \(error)")
        }
    }
    
    // MARK: - Camera Settings Utility
    
    /**
     * Calculates approximate Kelvin temperature from white balance gains.
     * 
     * - Parameter gains: Current white balance gains from camera
     * - Returns: Approximate color temperature in Kelvin
     */
    private func calculateKelvinFromGains(_ gains: AVCaptureDevice.WhiteBalanceGains) -> Float {
        // Simplified color temperature calculation
        let ratio = gains.blueGain / gains.redGain
        let kelvin = 2000 + (ratio * 3000)
        return max(2000, min(8000, kelvin))
    }
    
    /**
     * Calculates white balance gains from Kelvin temperature.
     * 
     * - Parameter kelvin: Color temperature in Kelvin
     * - Returns: RGB gain values for white balance adjustment
     */
    private func calculateGainsFromKelvin(_ kelvin: Float) -> AVCaptureDevice.WhiteBalanceGains {
        // Simplified conversion from Kelvin to RGB gains
        let normalized = (kelvin - 2000) / 6000 // 0.0 to 1.0
        let redGain: Float = 1.0 + (normalized * 0.5)
        let greenGain: Float = 1.0
        let blueGain: Float = 1.0 + ((1.0 - normalized) * 0.5)
        
        return AVCaptureDevice.WhiteBalanceGains(redGain: redGain, greenGain: greenGain, blueGain: blueGain)
    }
    
    /**
     * Normalizes white balance gains to device-supported range.
     * 
     * - Parameters:
     *   - gains: Raw calculated gains
     *   - device: Camera device with gain limits
     * - Returns: Normalized gains within device limits
     */
    private func normalizeGains(_ gains: AVCaptureDevice.WhiteBalanceGains, for device: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
        let maxGain = device.maxWhiteBalanceGain
        
        return AVCaptureDevice.WhiteBalanceGains(
            redGain: max(1.0, min(maxGain, gains.redGain)),
            greenGain: max(1.0, min(maxGain, gains.greenGain)),
            blueGain: max(1.0, min(maxGain, gains.blueGain))
        )
    }
    
    // MARK: - Photo Capture
    
    /**
     * Captures a photo with current camera settings and applies filters.
     * 
     * - Parameter completion: Callback with the processed image
     */
    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        photoCompletionHandler = completion
        
        var settings = AVCapturePhotoSettings()
        
        // Configure flash settings
        if let device = currentCamera, device.hasFlash {
            settings.flashMode = flashMode
        }
        
        // Configure high resolution settings
        if #available(iOS 16.0, *) {
            settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        } else {
            settings.isHighResolutionPhotoEnabled = true
        }
        
        // Configure format settings
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        
        isCapturing = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Error Handling
    
    /**
     * Displays an error message to the user.
     * 
     * - Parameter message: Error message to display
     */
    private func showCameraError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

/**
 * Extension implementing photo capture delegate methods.
 */
extension CustomCameraViewModel: AVCapturePhotoCaptureDelegate {
    
    /**
     * Called when photo capture processing is completed.
     * 
     * Handles the captured photo data, applies filters, and calls completion handler.
     */
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        // Extract data immediately in nonisolated context to avoid sending non-Sendable photo
        let imageData = photo.fileDataRepresentation()
        
        Task { @MainActor in
            defer { isCapturing = false }
            
            if let error = error {
                showCameraError("Photo capture failed: \(error.localizedDescription)")
                return
            }
            
            guard let data = imageData,
                  let uiImage = UIImage(data: data) else {
                showCameraError("Failed to process image data")
                return
            }
            
            // Apply filters and processing
            let processedImage = await processImage(uiImage)
            photoCompletionHandler?(processedImage)
        }
    }
    
    /**
     * Processes captured image with optimization and filter application.
     * 
     * - Parameter image: Raw captured image
     * - Returns: Processed image with filters and optimizations applied
     */
    private func processImage(_ image: UIImage) async -> UIImage {
        // Optimize image size and quality
        let optimizedImage = imageProcessor.resizeImageIfNeeded(image)
        
        // Apply selected filter
        if currentFilter != .none,
           let ciImage = CIImage(image: optimizedImage) {
            let filteredCIImage = filterManager.applyFilterRealtime(currentFilter, to: ciImage, intensity: 1.0)
            
            if let cgImage = CIContext().createCGImage(filteredCIImage, from: filteredCIImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return optimizedImage
    }
}
