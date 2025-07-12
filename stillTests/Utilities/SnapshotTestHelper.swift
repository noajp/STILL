//======================================================================
// MARK: - SnapshotTestHelper
// Purpose: Helper utilities for snapshot testing
// Note: This is a basic setup. For production use, consider Point-Free's SnapshotTesting library
//======================================================================
import XCTest
import SwiftUI
@testable import tete

/// Helper class for snapshot testing
/// This provides basic snapshot testing functionality. For production apps,
/// consider using Point-Free's SnapshotTesting library for more features.
final class SnapshotTestHelper {
    
    // MARK: - Configuration
    
    struct Configuration {
        let deviceName: String
        let size: CGSize
        let scale: CGFloat
        let colorScheme: ColorScheme
        
        static let iPhone14 = Configuration(
            deviceName: "iPhone14",
            size: CGSize(width: 390, height: 844),
            scale: 3.0,
            colorScheme: .light
        )
        
        static let iPhone14Dark = Configuration(
            deviceName: "iPhone14",
            size: CGSize(width: 390, height: 844),
            scale: 3.0,
            colorScheme: .dark
        )
        
        static let iPadAir = Configuration(
            deviceName: "iPadAir",
            size: CGSize(width: 820, height: 1180),
            scale: 2.0,
            colorScheme: .light
        )
    }
    
    // MARK: - Snapshot Methods
    
    /// Captures a snapshot of a SwiftUI view
    static func snapshot<V: View>(
        of view: V,
        configuration: Configuration = .iPhone14,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) -> UIImage? {
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(origin: .zero, size: configuration.size)
        hostingController.view.backgroundColor = UIColor.systemBackground
        
        // Set color scheme
        hostingController.overrideUserInterfaceStyle = configuration.colorScheme == .dark ? .dark : .light
        
        // Force layout
        hostingController.view.layoutIfNeeded()
        
        // Create image
        let renderer = UIGraphicsImageRenderer(size: configuration.size)
        let image = renderer.image { context in
            hostingController.view.layer.render(in: context.cgContext)
        }
        
        return image
    }
    
    /// Compares a view against a reference snapshot
    static func assertSnapshot<V: View>(
        matching view: V,
        configuration: Configuration = .iPhone14,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        record: Bool = false
    ) {
        let image = snapshot(of: view, configuration: configuration, file: file, testName: testName, line: line)
        
        guard let capturedImage = image else {
            XCTFail("Failed to capture snapshot", file: file, line: line)
            return
        }
        
        let snapshotDirectory = getSnapshotDirectory(file: file)
        let snapshotName = "\(testName)_\(configuration.deviceName)_\(configuration.colorScheme).png"
        let snapshotPath = snapshotDirectory.appendingPathComponent(snapshotName)
        
        if record {
            // Save new reference image
            saveImage(capturedImage, to: snapshotPath, file: file, line: line)
            XCTFail("Recorded new snapshot. Set record to false to run tests.", file: file, line: line)
            return
        }
        
        // Load reference image
        guard let referenceImage = loadImage(from: snapshotPath) else {
            saveImage(capturedImage, to: snapshotPath, file: file, line: line)
            XCTFail("No reference snapshot found. Generated new reference image.", file: file, line: line)
            return
        }
        
        // Compare images
        if !imagesAreEqual(capturedImage, referenceImage) {
            // Save diff image
            let diffPath = snapshotDirectory.appendingPathComponent("\(testName)_\(configuration.deviceName)_\(configuration.colorScheme)_diff.png")
            let diffImage = createDiffImage(captured: capturedImage, reference: referenceImage)
            saveImage(diffImage, to: diffPath, file: file, line: line)
            
            XCTFail("Snapshot does not match reference. Check diff image at: \(diffPath.path)", file: file, line: line)
        }
    }
    
    // MARK: - Private Helpers
    
    private static func getSnapshotDirectory(file: StaticString) -> URL {
        let fileURL = URL(fileURLWithPath: "\(file)")
        let testDirectory = fileURL.deletingLastPathComponent()
        let snapshotDirectory = testDirectory.appendingPathComponent("__Snapshots__")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: snapshotDirectory, withIntermediateDirectories: true)
        
        return snapshotDirectory
    }
    
    private static func saveImage(_ image: UIImage, to url: URL, file: StaticString, line: UInt) {
        guard let data = image.pngData() else {
            XCTFail("Failed to convert image to PNG data", file: file, line: line)
            return
        }
        
        do {
            try data.write(to: url)
        } catch {
            XCTFail("Failed to save snapshot: \(error)", file: file, line: line)
        }
    }
    
    private static func loadImage(from url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    private static func imagesAreEqual(_ image1: UIImage, _ image2: UIImage) -> Bool {
        guard let data1 = image1.pngData(),
              let data2 = image2.pngData() else {
            return false
        }
        return data1 == data2
    }
    
    private static func createDiffImage(captured: UIImage, reference: UIImage) -> UIImage {
        let size = captured.size
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw reference in red
            context.cgContext.setAlpha(0.5)
            reference.draw(in: CGRect(origin: .zero, size: size))
            
            // Draw captured in green with blend mode
            context.cgContext.setBlendMode(.difference)
            captured.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Test View Helpers

extension SnapshotTestHelper {
    
    /// Creates a test view with mock data for snapshot testing
    static func createTestView<V: View>(@ViewBuilder content: () -> V) -> some View {
        content()
            .environment(\.colorScheme, .light)
    }
    
    /// Creates a test view with dark mode
    static func createTestViewDark<V: View>(@ViewBuilder content: () -> V) -> some View {
        content()
            .environment(\.colorScheme, .dark)
    }
    
    /// Creates a preview container for testing different states
    static func createTestContainer<V: View>(
        title: String,
        @ViewBuilder content: () -> V
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }
}

// MARK: - XCTestCase Extension

extension XCTestCase {
    
    /// Convenience method for snapshot testing
    func assertSnapshot<V: View>(
        matching view: V,
        configuration: SnapshotTestHelper.Configuration = .iPhone14,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        record: Bool = false
    ) {
        SnapshotTestHelper.assertSnapshot(
            matching: view,
            configuration: configuration,
            file: file,
            testName: testName,
            line: line,
            record: record
        )
    }
}