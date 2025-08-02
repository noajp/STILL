//======================================================================
// MARK: - CameraPreviewRepresentable.swift
// Purpose: Shared UIViewRepresentable for camera preview layer
// Path: still/Features/Camera/Components/CameraPreviewRepresentable.swift
//======================================================================
import SwiftUI
import AVFoundation

/**
 * UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
 * Used by both single camera and multi-camera views
 */
struct CameraPreviewRepresentable: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.layer.addSublayer(previewLayer)
        previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            previewLayer.frame = uiView.bounds
        }
    }
}