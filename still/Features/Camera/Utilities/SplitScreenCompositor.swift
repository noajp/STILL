//======================================================================
// MARK: - SplitScreenCompositor.swift
// Purpose: Utility for compositing split screen images into single photo
// Path: still/Features/Camera/Utilities/SplitScreenCompositor.swift
//======================================================================
import UIKit
import CoreImage

/**
 * Utility class for creating composite images from split screen captures
 * Combines multiple images into a single photo with proper layout
 */
class SplitScreenCompositor {
    
    // MARK: - Composite Creation
    /**
     * Creates a composite image from split screen captures
     * - Parameter images: Dictionary of split index to captured image
     * - Parameter mode: Split screen mode defining layout
     * - Returns: Composite UIImage or nil if creation fails
     */
    static func createComposite(images: [Int: UIImage], mode: SplitMode) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let composite = createCompositeSync(images: images, mode: mode)
                continuation.resume(returning: composite)
            }
        }
    }
    
    /**
     * Synchronous composite creation for internal use
     */
    private static func createCompositeSync(images: [Int: UIImage], mode: SplitMode) -> UIImage? {
        guard !images.isEmpty else {
            print("❌ No images provided for composite")
            return nil
        }
        
        print("🎨 Creating composite image for \(mode.displayName) with \(images.count) images")
        
        // Determine canvas size based on the largest image
        let canvasSize = determineCanvasSize(from: images)
        
        // Create graphics context
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            print("❌ Failed to create graphics context")
            return nil
        }
        
        // Fill background with black
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: canvasSize))
        
        // Draw images based on split mode
        switch mode {
        case .dual:
            drawDualSplit(images: images, canvasSize: canvasSize, context: context)
        case .triple:
            drawTripleSplit(images: images, canvasSize: canvasSize, context: context)
        case .quad:
            drawQuadSplit(images: images, canvasSize: canvasSize, context: context)
        }
        
        // Get final composite image
        let composite = UIGraphicsGetImageFromCurrentImageContext()
        
        if composite != nil {
            print("✅ Composite image created successfully - Size: \(canvasSize)")
        } else {
            print("❌ Failed to create composite image")
        }
        
        return composite
    }
    
    // MARK: - Canvas Size Determination
    /**
     * Determines optimal canvas size based on input images
     */
    private static func determineCanvasSize(from images: [Int: UIImage]) -> CGSize {
        // Find the largest dimensions
        var maxWidth: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for image in images.values {
            maxWidth = max(maxWidth, image.size.width)
            maxHeight = max(maxHeight, image.size.height)
        }
        
        // Use standard photo aspect ratio if needed
        if maxWidth == 0 || maxHeight == 0 {
            return CGSize(width: 1080, height: 1920) // Standard portrait
        }
        
        return CGSize(width: maxWidth, height: maxHeight)
    }
    
    // MARK: - Dual Split Drawing
    /**
     * Draws images in dual split layout (left/right)
     */
    private static func drawDualSplit(images: [Int: UIImage], canvasSize: CGSize, context: CGContext) {
        let splitWidth = canvasSize.width / 2
        let dividerWidth: CGFloat = 2
        
        // Left split (index 0)
        if let leftImage = images[0] {
            let leftRect = CGRect(x: 0, y: 0, width: splitWidth - dividerWidth/2, height: canvasSize.height)
            drawImageInRect(image: leftImage, rect: leftRect, context: context)
        }
        
        // Right split (index 1)
        if let rightImage = images[1] {
            let rightRect = CGRect(x: splitWidth + dividerWidth/2, y: 0, width: splitWidth - dividerWidth/2, height: canvasSize.height)
            drawImageInRect(image: rightImage, rect: rightRect, context: context)
        }
        
        // Draw vertical divider
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: splitWidth - dividerWidth/2, y: 0, width: dividerWidth, height: canvasSize.height))
    }
    
    // MARK: - Triple Split Drawing
    /**
     * Draws images in triple split layout (top + bottom left/right)
     */
    private static func drawTripleSplit(images: [Int: UIImage], canvasSize: CGSize, context: CGContext) {
        let topHeight = canvasSize.height * 0.5
        let bottomHeight = canvasSize.height * 0.5
        let bottomWidth = canvasSize.width / 2
        let dividerWidth: CGFloat = 2
        
        // Top split (index 0)
        if let topImage = images[0] {
            let topRect = CGRect(x: 0, y: 0, width: canvasSize.width, height: topHeight - dividerWidth/2)
            drawImageInRect(image: topImage, rect: topRect, context: context)
        }
        
        // Bottom left split (index 1)
        if let bottomLeftImage = images[1] {
            let bottomLeftRect = CGRect(x: 0, y: topHeight + dividerWidth/2, width: bottomWidth - dividerWidth/2, height: bottomHeight - dividerWidth/2)
            drawImageInRect(image: bottomLeftImage, rect: bottomLeftRect, context: context)
        }
        
        // Bottom right split (index 2)
        if let bottomRightImage = images[2] {
            let bottomRightRect = CGRect(x: bottomWidth + dividerWidth/2, y: topHeight + dividerWidth/2, width: bottomWidth - dividerWidth/2, height: bottomHeight - dividerWidth/2)
            drawImageInRect(image: bottomRightImage, rect: bottomRightRect, context: context)
        }
        
        // Draw horizontal divider
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: topHeight - dividerWidth/2, width: canvasSize.width, height: dividerWidth))
        
        // Draw vertical divider for bottom splits
        context.fill(CGRect(x: bottomWidth - dividerWidth/2, y: topHeight + dividerWidth/2, width: dividerWidth, height: bottomHeight - dividerWidth/2))
    }
    
    // MARK: - Quad Split Drawing
    /**
     * Draws images in quad split layout (2x2 grid)
     */
    private static func drawQuadSplit(images: [Int: UIImage], canvasSize: CGSize, context: CGContext) {
        let quadWidth = canvasSize.width / 2
        let quadHeight = canvasSize.height / 2
        let dividerWidth: CGFloat = 2
        
        // Top left (index 0)
        if let topLeftImage = images[0] {
            let topLeftRect = CGRect(x: 0, y: 0, width: quadWidth - dividerWidth/2, height: quadHeight - dividerWidth/2)
            drawImageInRect(image: topLeftImage, rect: topLeftRect, context: context)
        }
        
        // Top right (index 1)
        if let topRightImage = images[1] {
            let topRightRect = CGRect(x: quadWidth + dividerWidth/2, y: 0, width: quadWidth - dividerWidth/2, height: quadHeight - dividerWidth/2)
            drawImageInRect(image: topRightImage, rect: topRightRect, context: context)
        }
        
        // Bottom left (index 2)
        if let bottomLeftImage = images[2] {
            let bottomLeftRect = CGRect(x: 0, y: quadHeight + dividerWidth/2, width: quadWidth - dividerWidth/2, height: quadHeight - dividerWidth/2)
            drawImageInRect(image: bottomLeftImage, rect: bottomLeftRect, context: context)
        }
        
        // Bottom right (index 3)
        if let bottomRightImage = images[3] {
            let bottomRightRect = CGRect(x: quadWidth + dividerWidth/2, y: quadHeight + dividerWidth/2, width: quadWidth - dividerWidth/2, height: quadHeight - dividerWidth/2)
            drawImageInRect(image: bottomRightImage, rect: bottomRightRect, context: context)
        }
        
        // Draw dividers
        context.setFillColor(UIColor.white.cgColor)
        // Vertical divider
        context.fill(CGRect(x: quadWidth - dividerWidth/2, y: 0, width: dividerWidth, height: canvasSize.height))
        // Horizontal divider
        context.fill(CGRect(x: 0, y: quadHeight - dividerWidth/2, width: canvasSize.width, height: dividerWidth))
    }
    
    // MARK: - Image Drawing Helper
    /**
     * Draws an image scaled to fit within the specified rectangle
     */
    private static func drawImageInRect(image: UIImage, rect: CGRect, context: CGContext) {
        // Calculate aspect fit scaling
        let imageAspect = image.size.width / image.size.height
        let rectAspect = rect.width / rect.height
        
        var drawRect = rect
        
        if imageAspect > rectAspect {
            // Image is wider - fit to width
            let scaledHeight = rect.width / imageAspect
            drawRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y + (rect.height - scaledHeight) / 2,
                width: rect.width,
                height: scaledHeight
            )
        } else {
            // Image is taller - fit to height
            let scaledWidth = rect.height * imageAspect
            drawRect = CGRect(
                x: rect.origin.x + (rect.width - scaledWidth) / 2,
                y: rect.origin.y,
                width: scaledWidth,
                height: rect.height
            )
        }
        
        // Draw the image
        context.saveGState()
        context.translateBy(x: 0, y: rect.height + 2 * rect.origin.y)
        context.scaleBy(x: 1, y: -1)
        
        if let cgImage = image.cgImage {
            context.draw(cgImage, in: CGRect(
                x: drawRect.origin.x,
                y: rect.height + 2 * rect.origin.y - drawRect.origin.y - drawRect.height,
                width: drawRect.width,
                height: drawRect.height
            ))
        }
        
        context.restoreGState()
    }
}