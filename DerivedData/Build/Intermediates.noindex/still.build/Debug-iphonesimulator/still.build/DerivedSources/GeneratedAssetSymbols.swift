import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "Background" asset catalog color resource.
    @available(watchOS, unavailable)
    static let background = DeveloperToolsSupport.ColorResource(thinnableName: "Background", bundle: resourceBundle)

    /// The "appBackground" asset catalog color resource.
    @available(watchOS, unavailable)
    static let appBackground = DeveloperToolsSupport.ColorResource(thinnableName: "appBackground", bundle: resourceBundle)

    /// The "buttonText" asset catalog color resource.
    static let buttonText = DeveloperToolsSupport.ColorResource(name: "buttonText", bundle: resourceBundle)

    /// The "inputBackground" asset catalog color resource.
    static let inputBackground = DeveloperToolsSupport.ColorResource(name: "inputBackground", bundle: resourceBundle)

    /// The "lightGreenButtonBackground" asset catalog color resource.
    static let lightGreenButtonBackground = DeveloperToolsSupport.ColorResource(name: "lightGreenButtonBackground", bundle: resourceBundle)

    /// The "textPrimary" asset catalog color resource.
    static let textPrimary = DeveloperToolsSupport.ColorResource(name: "textPrimary", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "Background" asset catalog color.
    static var background: AppKit.NSColor? {
#if !targetEnvironment(macCatalyst)
        .init(thinnableResource: .background)
#else
        .init()
#endif
    }

    /// The "appBackground" asset catalog color.
    static var appBackground: AppKit.NSColor? {
#if !targetEnvironment(macCatalyst)
        .init(thinnableResource: .appBackground)
#else
        .init()
#endif
    }

    /// The "buttonText" asset catalog color.
    static var buttonText: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .buttonText)
#else
        .init()
#endif
    }

    /// The "inputBackground" asset catalog color.
    static var inputBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .inputBackground)
#else
        .init()
#endif
    }

    /// The "lightGreenButtonBackground" asset catalog color.
    static var lightGreenButtonBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lightGreenButtonBackground)
#else
        .init()
#endif
    }

    /// The "textPrimary" asset catalog color.
    static var textPrimary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .textPrimary)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "Background" asset catalog color.
    static var background: UIKit.UIColor? {
#if !os(watchOS)
        .init(thinnableResource: .background)
#else
        .init()
#endif
    }

    /// The "appBackground" asset catalog color.
    static var appBackground: UIKit.UIColor? {
#if !os(watchOS)
        .init(thinnableResource: .appBackground)
#else
        .init()
#endif
    }

    /// The "buttonText" asset catalog color.
    static var buttonText: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .buttonText)
#else
        .init()
#endif
    }

    /// The "inputBackground" asset catalog color.
    static var inputBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .inputBackground)
#else
        .init()
#endif
    }

    /// The "lightGreenButtonBackground" asset catalog color.
    static var lightGreenButtonBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .lightGreenButtonBackground)
#else
        .init()
#endif
    }

    /// The "textPrimary" asset catalog color.
    static var textPrimary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .textPrimary)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "Background" asset catalog color.
    @available(watchOS, unavailable)
    static var background: SwiftUI.Color? { .init(thinnableResource: .background) }

    /// The "appBackground" asset catalog color.
    @available(watchOS, unavailable)
    static var appBackground: SwiftUI.Color? { .init(thinnableResource: .appBackground) }

    /// The "buttonText" asset catalog color.
    static var buttonText: SwiftUI.Color { .init(.buttonText) }

    /// The "inputBackground" asset catalog color.
    static var inputBackground: SwiftUI.Color { .init(.inputBackground) }

    /// The "lightGreenButtonBackground" asset catalog color.
    static var lightGreenButtonBackground: SwiftUI.Color { .init(.lightGreenButtonBackground) }

    /// The "textPrimary" asset catalog color.
    static var textPrimary: SwiftUI.Color { .init(.textPrimary) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "Background" asset catalog color.
    @available(watchOS, unavailable)
    static var background: SwiftUI.Color? { .init(thinnableResource: .background) }

    /// The "appBackground" asset catalog color.
    @available(watchOS, unavailable)
    static var appBackground: SwiftUI.Color? { .init(thinnableResource: .appBackground) }

    /// The "buttonText" asset catalog color.
    static var buttonText: SwiftUI.Color { .init(.buttonText) }

    /// The "inputBackground" asset catalog color.
    static var inputBackground: SwiftUI.Color { .init(.inputBackground) }

    /// The "lightGreenButtonBackground" asset catalog color.
    static var lightGreenButtonBackground: SwiftUI.Color { .init(.lightGreenButtonBackground) }

    /// The "textPrimary" asset catalog color.
    static var textPrimary: SwiftUI.Color { .init(.textPrimary) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

