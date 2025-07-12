//======================================================================
// MARK: - FilmGrainFilter.swift
// Purpose: FilmGrainFilter implementation (FilmGrainFilterの実装)
// Path: still/Core/ImageProcessing/FilmGrainFilter.swift
//======================================================================
//
//  FilmGrainFilter.swift
//  tete
//
//  リアルなフィルムグレインエフェクト
//

import CoreImage

// MARK: - Film Grain Filter
class FilmGrainFilter: CIFilter {
    
    @objc dynamic var inputImage: CIImage?
    @objc dynamic var inputIntensity: Float = 0.5
    @objc dynamic var inputSize: Float = 1.0
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else { return nil }
        
        // ノイズ生成
        let noiseImage = generateNoise(size: inputImage.extent.size)
        
        // ブレンド
        let blendFilter = CIFilter.screenBlendMode()
        blendFilter.inputImage = noiseImage
        blendFilter.backgroundImage = inputImage
        
        // 強度調整
        let colorMatrix = CIFilter.colorMatrix()
        colorMatrix.inputImage = blendFilter.outputImage
        colorMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(inputIntensity * 0.3))
        
        return colorMatrix.outputImage
    }
    
    private func generateNoise(size: CGSize) -> CIImage {
        // ランダムノイズ生成
        let noiseFilter = CIFilter.randomGenerator()
        var noiseImage = noiseFilter.outputImage!
        
        // スケール調整
        let scaleTransform = CGAffineTransform(scaleX: CGFloat(inputSize), y: CGFloat(inputSize))
        noiseImage = noiseImage.transformed(by: scaleTransform)
        
        // グレースケール化
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = noiseImage
        colorControls.saturation = 0
        
        // サイズに合わせてクロップ
        let cropRect = CGRect(origin: .zero, size: size)
        return colorControls.outputImage!.cropped(to: cropRect)
    }
}

// MARK: - Light Leak Filter
class LightLeakFilter: CIFilter {
    
    @objc dynamic var inputImage: CIImage?
    @objc dynamic var inputIntensity: Float = 0.5
    @objc dynamic var inputColor: CIColor = CIColor(red: 1.0, green: 0.8, blue: 0.4)
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else { return nil }
        
        let size = inputImage.extent.size
        
        // グラデーション作成
        let gradient = CIFilter.radialGradient()
        gradient.center = CGPoint(x: size.width * 0.7, y: size.height * 0.8)
        gradient.radius0 = Float(size.width * 0.1)
        gradient.radius1 = Float(size.width * 0.5)
        gradient.color0 = inputColor.copy(alpha: CGFloat(inputIntensity))
        gradient.color1 = CIColor.clear
        
        // オーバーレイブレンド
        let blend = CIFilter.screenBlendMode()
        blend.inputImage = gradient.outputImage
        blend.backgroundImage = inputImage
        
        return blend.outputImage
    }
}

// MARK: - Vintage Vignette Filter
class VintageVignetteFilter: CIFilter {
    
    @objc dynamic var inputImage: CIImage?
    @objc dynamic var inputIntensity: Float = 0.8
    @objc dynamic var inputRadius: Float = 1.5
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else { return nil }
        
        // ビネット効果
        let vignette = CIFilter.vignette()
        vignette.inputImage = inputImage
        vignette.intensity = inputIntensity
        vignette.radius = inputRadius
        
        // 色温度調整（暖色系に）
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = vignette.outputImage
        colorControls.saturation = 0.9
        
        return colorControls.outputImage
    }
}

// MARK: - Helper Extensions
extension CIColor {
    func copy(alpha: CGFloat) -> CIColor {
        return CIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}