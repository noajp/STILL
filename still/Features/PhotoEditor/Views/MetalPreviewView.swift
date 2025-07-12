//======================================================================
// MARK: - MetalPreviewView.swift
// Purpose: SwiftUI view component (MetalPreviewViewビューコンポーネント)
// Path: still/Features/PhotoEditor/Views/MetalPreviewView.swift
//======================================================================
//
//  MetalPreviewView.swift
//  tete
//
//  Metalを使用したリアルタイムプレビュー
//

import SwiftUI
import MetalKit
import CoreImage

// MARK: - Metal Preview View
struct MetalPreviewView: UIViewRepresentable {
    @Binding var currentImage: CIImage?
    @Binding var filterType: FilterType
    @Binding var filterIntensity: Float
    let metalDevice = MTLCreateSystemDefaultDevice()
    
    typealias UIViewType = MTKView
    typealias Coordinator = MetalCoordinator
    
    func makeUIView(context: UIViewRepresentableContext<MetalPreviewView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = metalDevice
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.contentScaleFactor = UIScreen.main.scale
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.preferredFramesPerSecond = 30 // リアルタイム更新用
        
        // 背景を黒に
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        return mtkView
    }
    
    func updateUIView(_ mtkView: MTKView, context: UIViewRepresentableContext<MetalPreviewView>) {
        // フィルター変更を通知
        context.coordinator.updateFilter(filterType, intensity: filterIntensity)
    }
    
    func makeCoordinator() -> MetalCoordinator {
        MetalCoordinator(self, device: metalDevice)
    }
    
    // MARK: - MetalCoordinator (Optimized)
    class MetalCoordinator: NSObject, MTKViewDelegate {
        var parent: MetalPreviewView
        private let ciContext: CIContext
        private let imageProcessor = UnifiedImageProcessor.shared
        private var currentFilterType: FilterType = .none
        private var currentIntensity: Float = 1.0
        private let commandQueue: MTLCommandQueue?
        
        nonisolated init(_ parent: MetalPreviewView, device: MTLDevice?) {
            self.parent = parent
            
            // Metal用のCIContext作成
            if let device = device {
                self.ciContext = CIContext(mtlDevice: device, options: [
                    .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                    .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                    .useSoftwareRenderer: false
                ])
                self.commandQueue = device.makeCommandQueue()
            } else {
                self.ciContext = CIContext()
                self.commandQueue = nil
            }
            
            super.init()
        }
        
        func updateFilter(_ filterType: FilterType, intensity: Float) {
            currentFilterType = filterType
            currentIntensity = intensity
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // サイズ変更時の処理
        }
        
        func draw(in view: MTKView) {
            autoreleasepool {
                guard let currentImage = parent.currentImage,
                      let drawable = view.currentDrawable,
                      let commandBuffer = commandQueue?.makeCommandBuffer() else {
                    return
                }
                
                // Optimized filter application using UnifiedImageProcessor
                let filteredImage = imageProcessor.applyFilterRealtime(
                    currentFilterType,
                    to: currentImage,
                    intensity: currentIntensity
                )
                
                // アスペクト比を保持してスケーリング
                let drawableSize = view.drawableSize
                let imageSize = filteredImage.extent.size
                
                let scaleX = drawableSize.width / imageSize.width
                let scaleY = drawableSize.height / imageSize.height
                let scale = min(scaleX, scaleY)
                
                let scaledImage = filteredImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                
                // センタリング
                let x = (drawableSize.width - imageSize.width * scale) / 2
                let y = (drawableSize.height - imageSize.height * scale) / 2
                let centeredImage = scaledImage.transformed(by: CGAffineTransform(translationX: x, y: y))
                
                // レンダリング
                let renderDestination = CIRenderDestination(
                    width: Int(drawableSize.width),
                    height: Int(drawableSize.height),
                    pixelFormat: view.colorPixelFormat,
                    commandBuffer: commandBuffer,
                    mtlTextureProvider: { () -> MTLTexture in
                        return drawable.texture
                    }
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
    }
}