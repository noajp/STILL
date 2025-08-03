//======================================================================
// MARK: - MultiCameraPermissionView.swift
// Purpose: Camera permission handling for multi-camera functionality
// Path: still/Features/Camera/Components/MultiCameraPermissionView.swift
//======================================================================
import SwiftUI
import AVFoundation

/**
 * Permission handling view for multi-camera functionality
 * Checks and requests camera permissions before showing multi-camera interface
 */
struct MultiCameraPermissionView: View {
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false
    
    var body: some View {
        Group {
            switch cameraPermissionStatus {
            case .authorized:
                MultiCameraView()
            case .denied, .restricted:
                permissionDeniedView
            case .notDetermined:
                permissionRequestView
            @unknown default:
                permissionRequestView
            }
        }
        .onAppear {
            checkCameraPermission()
        }
    }
    
    // MARK: - Permission Request View
    private var permissionRequestView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "camera.fill.badge.ellipsis")
                    .font(.system(size: 80))
                    .foregroundColor(MinimalDesign.Colors.accentRed)
                
                Text("Multi-Camera Access")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("This feature uses multiple cameras simultaneously to create unique photo compositions")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: requestCameraPermission) {
                Text("Enable Camera Access")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(MinimalDesign.Colors.accentRed)
                    )
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(MinimalDesign.Colors.background)
    }
    
    // MARK: - Permission Denied View
    private var permissionDeniedView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "camera.fill.badge.xmark")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                Text("Camera Access Denied")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("To use multi-camera features, please enable camera access in Settings")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: openSettings) {
                Text("Open Settings")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(MinimalDesign.Colors.accentRed)
                    )
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(MinimalDesign.Colors.background)
    }
    
    // MARK: - Permission Methods
    private func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraPermissionStatus = granted ? .authorized : .denied
            }
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Preview
#Preview {
    MultiCameraPermissionView()
}