//======================================================================
// MARK: - AppEnvironment
// Purpose: App-wide environment settings using MinimalDesign system
// Deprecated: Use MinimalDesign directly for new code
//======================================================================
import SwiftUI

// Import MinimalDesignSystem if it's in a separate module
// If it's in the same module, ensure it's included in the target

struct AppEnvironment {
    
    // MARK: - Fonts (Bridged to MinimalDesign)
    struct Fonts {
        static func primary(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            Font.system(size: size, weight: weight, design: .default)
        }
        
        static func primaryBold(size: CGFloat) -> Font {
            primary(size: size, weight: .bold)
        }
        
        // Standard sizes - define directly to avoid dependency issues
        static let title = Font.system(size: 24, weight: .bold, design: .default)
        static let headline = Font.system(size: 18, weight: .semibold, design: .default)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .medium, design: .default)
        static let small = Font.system(size: 10, weight: .regular, design: .default)
    }
}

