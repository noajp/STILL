//======================================================================
// MARK: - CustomCameraViewModel.swift
// Purpose: View model for data and business logic (CustomCameraViewModelのデータとビジネスロジック)
// Path: still/Features/Camera/ViewModels/CustomCameraViewModel.swift
//======================================================================
//
//  CustomCameraViewModel.swift
//  tete
//
//  カスタムカメラのViewModel
//

import SwiftUI
import AVFoundation
import CoreImage
import Photos

@MainActor
class CustomCameraViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isCapturing = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var focusPoint: CGPoint?
    @Published var currentFilter: FilterType = .none
    @Published var isManualMode = false
    @Published var manualISO: Float = 400
    @Published var manualShutterSpeed: Float = 60
    @Published var manualWhiteBalance: Float = 5600
    @Published var manualFocus: Float = 0.5
    @Published var exposureCompensation: Float = 0.0
    
    // MARK: - Camera Properties
    let session = AVCaptureSession()
    private var videoInput: AVCaptureDeviceInput?
    private var photoOutput = AVCapturePhotoOutput()
    private var frontCamera: AVCaptureDevice?
    private var backCamera: AVCaptureDevice?
    
    // Expose currentCamera for manual controls
    var currentCamera: AVCaptureDevice? {
        return videoInput?.device
    }
    
    // MARK: - Image Processing
    private let imageProcessor = ImageProcessor()
    private let filterManager = AdvancedFilterManager()
    private var photoCompletionHandler: ((UIImage) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupCamera()
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        Task {
            await requestCameraPermission()
        }
    }
    
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
                showCameraError("カメラへのアクセスが拒否されました")
            }
        case .denied, .restricted:
            showCameraError("カメラへのアクセスが拒否されています。設定で許可してください。")
        @unknown default:
            showCameraError("カメラの状態を確認できません")
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // カメラデバイスの設定
        setupCameraDevices()
        
        // バックカメラを初期設定
        if let backCamera = backCamera {
            do {
                videoInput = try AVCaptureDeviceInput(device: backCamera)
                if session.canAddInput(videoInput!) {
                    session.addInput(videoInput!)
                }
            } catch {
                showCameraError("カメラの初期化に失敗しました: \(error.localizedDescription)")
                return
            }
        }
        
        // 写真出力の設定
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            // 写真設定
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
    
    private func calculateKelvinFromGains(_ gains: AVCaptureDevice.WhiteBalanceGains) -> Float {
        // Simplified color temperature calculation
        let ratio = gains.blueGain / gains.redGain
        let kelvin = 2000 + (ratio * 3000)
        return max(2000, min(8000, kelvin))
    }
    
    private func calculateGainsFromKelvin(_ kelvin: Float) -> AVCaptureDevice.WhiteBalanceGains {
        // Simplified conversion from Kelvin to RGB gains
        let normalized = (kelvin - 2000) / 6000 // 0.0 to 1.0
        let redGain: Float = 1.0 + (normalized * 0.5)
        let greenGain: Float = 1.0
        let blueGain: Float = 1.0 + ((1.0 - normalized) * 0.5)
        
        return AVCaptureDevice.WhiteBalanceGains(redGain: redGain, greenGain: greenGain, blueGain: blueGain)
    }
    
    private func normalizeGains(_ gains: AVCaptureDevice.WhiteBalanceGains, for device: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
        let maxGain = device.maxWhiteBalanceGain
        
        return AVCaptureDevice.WhiteBalanceGains(
            redGain: max(1.0, min(maxGain, gains.redGain)),
            greenGain: max(1.0, min(maxGain, gains.greenGain)),
            blueGain: max(1.0, min(maxGain, gains.blueGain))
        )
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        photoCompletionHandler = completion
        
        var settings = AVCapturePhotoSettings()
        
        // フラッシュ設定
        if let device = currentCamera, device.hasFlash {
            settings.flashMode = flashMode
        }
        
        // 高解像度設定
        if #available(iOS 16.0, *) {
            settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        } else {
            settings.isHighResolutionPhotoEnabled = true
        }
        
        // フォーマット設定
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        
        isCapturing = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Error Handling
    
    private func showCameraError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CustomCameraViewModel: AVCapturePhotoCaptureDelegate {
    
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        // Extract data immediately in nonisolated context to avoid sending non-Sendable photo
        let imageData = photo.fileDataRepresentation()
        
        Task { @MainActor in
            defer { isCapturing = false }
            
            if let error = error {
                showCameraError("写真の撮影に失敗しました: \(error.localizedDescription)")
                return
            }
            
            guard let data = imageData,
                  let uiImage = UIImage(data: data) else {
                showCameraError("画像データの処理に失敗しました")
                return
            }
            
            // フィルター適用
            let processedImage = await processImage(uiImage)
            photoCompletionHandler?(processedImage)
        }
    }
    
    private func processImage(_ image: UIImage) async -> UIImage {
        // 画像を最適化
        let optimizedImage = imageProcessor.resizeImageIfNeeded(image)
        
        // フィルター適用
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
