//======================================================================
// MARK: - ViewSnapshotTests
// Purpose: Snapshot tests for key UI components
//======================================================================
import XCTest
import SwiftUI
@testable import tete

final class ViewSnapshotTests: XCTestCase {
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        // Configure for snapshot testing
    }
    
    // MARK: - Single Card View Tests
    
    func testSingleCardViewDefault() {
        // Given
        let testPost = TestUtilities.createTestPost(
            caption: "Beautiful sunset over the mountains 🌅",
            likeCount: 42,
            commentCount: 8
        )
        var postWithUser = testPost
        postWithUser.user = TestUtilities.createTestUserProfile(
            username: "photographer",
            displayName: "Mountain Photographer"
        )
        
        // When/Then
        let view = SnapshotTestHelper.createTestView {
            SingleCardView(post: postWithUser)
                .frame(width: 350)
        }
        
        assertSnapshot(matching: view, record: false)
    }
    
    func testSingleCardViewDarkMode() {
        // Given
        let testPost = TestUtilities.createTestPost(
            caption: "Night photography session 📸✨",
            likeCount: 128,
            commentCount: 23
        )
        var postWithUser = testPost
        postWithUser.user = TestUtilities.createTestUserProfile(
            username: "nightshooter",
            displayName: "Night Photographer"
        )
        
        // When/Then
        let view = SnapshotTestHelper.createTestViewDark {
            SingleCardView(post: postWithUser)
                .frame(width: 350)
        }
        
        assertSnapshot(
            matching: view, 
            configuration: .iPhone14Dark,
            record: false
        )
    }
    
    func testSingleCardViewWithLongCaption() {
        // Given
        let longCaption = "This is a very long caption that should test how the card handles text wrapping and layout when there's a lot of text content. It should demonstrate proper text truncation or expansion behavior. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        
        let testPost = TestUtilities.createTestPost(
            caption: longCaption,
            likeCount: 256,
            commentCount: 45
        )
        var postWithUser = testPost
        postWithUser.user = TestUtilities.createTestUserProfile(
            username: "storyteller",
            displayName: "The Storyteller"
        )
        
        // When/Then
        let view = SnapshotTestHelper.createTestView {
            SingleCardView(post: postWithUser)
                .frame(width: 350)
        }
        
        assertSnapshot(matching: view, record: false)
    }
    
    // MARK: - Custom Tab Bar Tests
    
    func testCustomTabBarDefault() {
        // Given
        @State var selectedTab: Int = 0
        
        // When/Then
        let view = SnapshotTestHelper.createTestView {
            CustomTabBar(selectedTab: .constant(0))
                .frame(height: 100)
        }
        
        assertSnapshot(matching: view, record: false)
    }
    
    func testCustomTabBarAllTabs() {
        // Test each tab selected
        for tabIndex in 0..<5 {
            let view = SnapshotTestHelper.createTestView {
                CustomTabBar(selectedTab: .constant(tabIndex))
                    .frame(height: 100)
            }
            
            assertSnapshot(
                matching: view,
                testName: "testCustomTabBarTab\(tabIndex)",
                record: false
            )
        }
    }
    
    func testCustomTabBarDarkMode() {
        // When/Then
        let view = SnapshotTestHelper.createTestViewDark {
            CustomTabBar(selectedTab: .constant(2))
                .frame(height: 100)
        }
        
        assertSnapshot(
            matching: view,
            configuration: .iPhone14Dark,
            record: false
        )
    }
    
    // MARK: - Search Components Tests
    
    func testSearchBarViewEmpty() {
        // When/Then
        let view = SnapshotTestHelper.createTestView {
            SearchBarView(
                searchText: .constant(""),
                onSearchChanged: { _ in }
            )
            .padding()
        }
        
        assertSnapshot(matching: view, record: false)
    }
    
    func testSearchBarViewWithText() {
        // When/Then
        let view = SnapshotTestHelper.createTestView {
            SearchBarView(
                searchText: .constant("Mountain photography"),
                onSearchChanged: { _ in }
            )
            .padding()
        }
        
        assertSnapshot(matching: view, record: false)
    }
    
    func testFilterChipView() {
        // When/Then
        let view = SnapshotTestHelper.createTestView {
            HStack {
                FilterChipView(
                    title: "Photos",
                    isSelected: true,
                    action: {}
                )
                
                FilterChipView(
                    title: "Videos",
                    isSelected: false,
                    action: {}
                )
                
                FilterChipView(
                    title: "Recent",
                    isSelected: false,
                    action: {}
                )
            }
            .padding()
        }
        
        assertSnapshot(matching: view, record: false)
    }
    
    // MARK: - Loading States Tests
    
    func testLoadingView() {
        // When/Then
        let view = SnapshotTestHelper.createTestView {
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 200, height: 100)
        }
        
        assertSnapshot(matching: view, record: false)
    }
    
    // MARK: - Error States Tests
    
    func testErrorView() {
        // When/Then
        let view = SnapshotTestHelper.createTestView {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("Something went wrong")
                    .font(.headline)
                
                Text("Please check your internet connection and try again.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Retry") {
                    // Action
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(width: 300)
        }
        
        assertSnapshot(matching: view, record: false)
    }
    
    // MARK: - Empty States Tests
    
    func testEmptyStateView() {
        // When/Then
        let view = SnapshotTestHelper.createTestView {
            VStack(spacing: 20) {
                Image(systemName: "photo")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                
                Text("No posts yet")
                    .font(.headline)
                
                Text("Share your first photo to get started!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Create Post") {
                    // Action
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(width: 300, height: 400)
        }
        
        assertSnapshot(matching: view, record: false)
    }
    
    // MARK: - iPad Layout Tests
    
    func testSingleCardViewIPad() {
        // Given
        let testPost = TestUtilities.createTestPost(
            caption: "iPad layout test for larger screens",
            likeCount: 99,
            commentCount: 12
        )
        var postWithUser = testPost
        postWithUser.user = TestUtilities.createTestUserProfile(
            username: "ipaduser",
            displayName: "iPad User"
        )
        
        // When/Then
        let view = SnapshotTestHelper.createTestView {
            SingleCardView(post: postWithUser)
                .frame(width: 500) // iPad-like width
        }
        
        assertSnapshot(
            matching: view,
            configuration: .iPadAir,
            record: false
        )
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLargeText() {
        // When/Then
        let view = SnapshotTestHelper.createTestView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Accessibility Test")
                    .font(.largeTitle)
                
                Text("This text should be readable with large text settings")
                    .font(.body)
                
                Button("Accessible Button") {
                    // Action
                }
            }
            .padding()
            .frame(width: 350)
        }
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        
        assertSnapshot(matching: view, record: false)
    }
    
    // MARK: - Component State Variations
    
    func testComponentStatesOverview() {
        // When/Then
        let view = SnapshotTestHelper.createTestContainer(title: "Component States") {
            VStack(spacing: 20) {
                // Button states
                HStack {
                    Button("Normal") { }
                    Button("Disabled") { }
                        .disabled(true)
                }
                
                // TextField states
                VStack {
                    TextField("Normal TextField", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("With Text", text: .constant("Sample text"))
                        .textFieldStyle(.roundedBorder)
                }
                
                // Toggle states
                HStack {
                    Toggle("Off Toggle", isOn: .constant(false))
                    Toggle("On Toggle", isOn: .constant(true))
                }
            }
            .padding()
        }
        
        assertSnapshot(matching: view, record: false)
    }
}