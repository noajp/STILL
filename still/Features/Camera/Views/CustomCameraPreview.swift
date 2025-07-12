//======================================================================
// MARK: - CustomCameraPreview.swift
// Purpose: CustomCameraPreview implementation (CustomCameraPreviewの実装)
// Path: still/Features/Camera/Views/CustomCameraPreview.swift
//======================================================================
//
//  CustomCameraPreview.swift
//  tete
//
//  リアルタイムフィルタープレビュー付きカメラビュー
//

import SwiftUI
import AVFoundation
@preconcurrency import CoreImage

struct CustomCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let currentFilter: FilterType
    
    typealias UIViewType = CameraPreviewView
    
    func makeUIView(context: UIViewRepresentableContext<CustomCameraPreview>) -> CameraPreviewView {
        let previewView = CameraPreviewView()
        previewView.session = session
        previewView.currentFilter = currentFilter
        return previewView
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: UIViewRepresentableContext<CustomCameraPreview>) {
        uiView.currentFilter = currentFilter
    }
}

// MARK: - Camera Preview View
class CameraPreviewView: UIView {
    
    // MARK: - Properties
    var session: AVCaptureSession? {
        didSet {
            setupPreview()
        }
    }
    
    var currentFilter: FilterType = .none {
        didSet {
            updateFilter()
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var metalView: MetalFilterView?
    private let filterManager = AdvancedFilterManager()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .black
        
        // Metalビューをセットアップ（フィルター用）
        metalView = MetalFilterView()
        if let metalView = metalView {
            addSubview(metalView)
            metalView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                metalView.topAnchor.constraint(equalTo: topAnchor),
                metalView.leadingAnchor.constraint(equalTo: leadingAnchor),
                metalView.trailingAnchor.constraint(equalTo: trailingAnchor),
                metalView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }
    
    private func setupPreview() {
        guard let session = session else { return }
        
        // フィルターなしの場合は通常のプレビュー
        if currentFilter == .none {
            setupStandardPreview(session: session)
        } else {
            setupFilteredPreview(session: session)
        }
    }
    
    private func setupStandardPreview(session: AVCaptureSession) {
        // 既存のレイヤーを削除
        previewLayer?.removeFromSuperlayer()
        
        // 新しいプレビューレイヤーを作成
        let newPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        newPreviewLayer.videoGravity = .resizeAspectFill
        newPreviewLayer.frame = bounds
        
        layer.insertSublayer(newPreviewLayer, at: 0)
        previewLayer = newPreviewLayer
        
        // Metalビューを非表示
        metalView?.isHidden = true
    }
    
    private func setupFilteredPreview(session: AVCaptureSession) {
        // プレビューレイヤーを非表示
        previewLayer?.isHidden = true
        
        // Metalビューを表示
        metalView?.isHidden = false
        
        // ビデオ出力を設定
        if videoOutput == nil {
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.video.queue"))
            videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            if session.canAddOutput(videoOutput!) {
                session.addOutput(videoOutput!)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        metalView?.frame = bounds
    }
    
    private func updateFilter() {
        if currentFilter == .none {
            setupStandardPreview(session: session!)
        } else {
            setupFilteredPreview(session: session!)
        }
        metalView?.currentFilter = currentFilter
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Process the image completely in the delegate's context
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Capture a reference to the metal view and filter manager
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Skip if no filter is applied
            guard self.currentFilter != .none else {
                self.metalView?.isHidden = true
                return
            }
            
            // Apply filter and display on main queue
            let filteredImage = self.filterManager.applyFilterRealtime(self.currentFilter, to: ciImage, intensity: 1.0)
            self.metalView?.displayImage(filteredImage)
        }
    }
}

// MARK: - Metal Filter View
class MetalFilterView: UIView {
    
    // MARK: - Properties
    var currentFilter: FilterType = .none
    private var metalLayer: CAMetalLayer!
    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    private let ciContext: CIContext
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        ciContext = CIContext(mtlDevice: device, options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        ])
        
        super.init(frame: frame)
        setupMetal()
    }
    
    required init?(coder: NSCoder) {
        ciContext = CIContext(mtlDevice: device, options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        ])
        
        super.init(coder: coder)
        setupMetal()
    }
    
    private func setupMetal() {
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = false
        
        commandQueue = device.makeCommandQueue()
        
        layer.addSublayer(metalLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        metalLayer.frame = bounds
        metalLayer.contentsScale = UIScreen.main.scale
    }
    
    func displayImage(_ ciImage: CIImage) {
        guard let drawable = metalLayer.nextDrawable(),
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        let drawableSize = metalLayer.drawableSize
        let scaleX = drawableSize.width / ciImage.extent.width
        let scaleY = drawableSize.height / ciImage.extent.height
        let scale = min(scaleX, scaleY)
        
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // センタリング
        let x = (drawableSize.width - ciImage.extent.width * scale) / 2
        let y = (drawableSize.height - ciImage.extent.height * scale) / 2
        let centeredImage = scaledImage.transformed(by: CGAffineTransform(translationX: x, y: y))
        
        // レンダリング
        let renderDestination = CIRenderDestination(
            width: Int(drawableSize.width),
            height: Int(drawableSize.height),
            pixelFormat: metalLayer.pixelFormat,
            commandBuffer: commandBuffer,
            mtlTextureProvider: { drawable.texture }
        )
        
        do {
            try ciContext.startTask(toRender: centeredImage, to: renderDestination)
        } catch {
            print("Render error: \(error)")
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}