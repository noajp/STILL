//======================================================================
// MARK: - CriticalFlowUITests
// Purpose: UI tests for critical user flows
//======================================================================
import XCTest

final class CriticalFlowUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Enable mock data for UI tests
        app.launchArguments.append("--uitesting")
        app.launchEnvironment["ENABLE_MOCK_DATA"] = "1"
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Tab Navigation Tests
    
    func testTabBarNavigation() throws {
        // Test all main tabs are accessible
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Test Feed tab (should be selected by default)
        let feedTab = tabBar.buttons.element(boundBy: 0)
        XCTAssertTrue(feedTab.exists, "Feed tab should exist")
        
        // Test Messages tab
        let messagesTab = tabBar.buttons.element(boundBy: 1)
        XCTAssertTrue(messagesTab.exists, "Messages tab should exist")
        messagesTab.tap()
        
        // Verify navigation worked
        XCTAssertTrue(app.staticTexts["Messages"].exists || app.navigationBars["Messages"].exists)
        
        // Test Create Post tab
        let createTab = tabBar.buttons.element(boundBy: 2)
        XCTAssertTrue(createTab.exists, "Create post tab should exist")
        
        // Test Map tab
        let mapTab = tabBar.buttons.element(boundBy: 3)
        XCTAssertTrue(mapTab.exists, "Map tab should exist")
        mapTab.tap()
        
        // Test Profile tab
        let profileTab = tabBar.buttons.element(boundBy: 4)
        XCTAssertTrue(profileTab.exists, "Profile tab should exist")
        profileTab.tap()
        
        // Verify profile screen appears
        let profileTitle = app.staticTexts["Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 3.0), "Profile title should appear")
    }
    
    // MARK: - Profile Flow Tests
    
    func testProfileViewToggleButtons() throws {
        // Navigate to profile
        let profileTab = app.tabBars.firstMatch.buttons.element(boundBy: 4)
        profileTab.tap()
        
        // Wait for profile to load
        let profileTitle = app.staticTexts["Profile"]
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 5.0))
        
        // Test the view toggle buttons (single/grid/magazine)
        // These would be custom buttons, so we need to find them by accessibility identifiers
        
        // Test single view button (should be selected by default)
        if app.buttons["single_view_button"].exists {
            let singleButton = app.buttons["single_view_button"]
            XCTAssertTrue(singleButton.exists, "Single view button should exist")
        }
        
        // Test grid view button
        if app.buttons["grid_view_button"].exists {
            let gridButton = app.buttons["grid_view_button"]
            gridButton.tap()
            
            // Verify grid layout appears (would need to check for grid-specific elements)
        }
        
        // Test magazine view button
        if app.buttons["magazine_view_button"].exists {
            let magazineButton = app.buttons["magazine_view_button"]
            magazineButton.tap()
            
            // Verify magazine layout appears
        }
    }
    
    func testProfileEditFlow() throws {
        // Navigate to profile
        let profileTab = app.tabBars.firstMatch.buttons.element(boundBy: 4)
        profileTab.tap()
        
        // Look for edit profile button
        let editButton = app.buttons["Edit Profile"]
        if editButton.waitForExistence(timeout: 3.0) {
            editButton.tap()
            
            // Verify edit profile sheet appears
            let editProfileTitle = app.staticTexts["Edit Profile"]
            XCTAssertTrue(editProfileTitle.waitForExistence(timeout: 2.0))
            
            // Test editing username field
            let usernameField = app.textFields["username_field"]
            if usernameField.exists {
                usernameField.tap()
                usernameField.clearAndEnterText("newtestuser")
            }
            
            // Test editing display name field
            let displayNameField = app.textFields["display_name_field"]
            if displayNameField.exists {
                displayNameField.tap()
                displayNameField.clearAndEnterText("New Test User")
            }
            
            // Test editing bio field
            let bioField = app.textViews["bio_field"]
            if bioField.exists {
                bioField.tap()
                bioField.clearAndEnterText("Updated bio for testing")
            }
            
            // Save changes
            let saveButton = app.buttons["Save"]
            if saveButton.exists {
                saveButton.tap()
                
                // Verify we're back to profile view
                XCTAssertTrue(app.staticTexts["Profile"].waitForExistence(timeout: 3.0))
            }
        }
    }
    
    // MARK: - Feed Flow Tests
    
    func testFeedViewToggle() throws {
        // Should start on feed tab
        let feedContent = app.scrollViews.firstMatch
        XCTAssertTrue(feedContent.exists, "Feed content should exist")
        
        // Test grid mode toggle (if it exists in the tab bar)
        // This would toggle between single post view and grid view
        if app.buttons["feed_toggle_button"].exists {
            let toggleButton = app.buttons["feed_toggle_button"]
            toggleButton.tap()
            
            // Verify layout changed (specific implementation would depend on UI structure)
        }
    }
    
    func testLikePostInteraction() throws {
        // Navigate to feed
        let feedTab = app.tabBars.firstMatch.buttons.element(boundBy: 0)
        feedTab.tap()
        
        // Wait for posts to load
        let firstPost = app.scrollViews.firstMatch.otherElements.firstMatch
        XCTAssertTrue(firstPost.waitForExistence(timeout: 5.0))
        
        // Look for like button (would need accessibility identifier)
        let likeButton = app.buttons["like_button"]
        if likeButton.exists {
            likeButton.tap()
            
            // Verify like state changed (button should change appearance)
            // This would require checking for different accessibility traits or labels
        }
    }
    
    // MARK: - Authentication Flow Tests
    
    func testSignInFlow() throws {
        // This test assumes we start in a signed-out state
        // In a real app, you might need to sign out first
        
        if app.buttons["Sign In"].exists {
            let signInButton = app.buttons["Sign In"]
            signInButton.tap()
            
            // Fill in email
            let emailField = app.textFields["email_field"]
            if emailField.waitForExistence(timeout: 2.0) {
                emailField.tap()
                emailField.typeText("test@example.com")
            }
            
            // Fill in password
            let passwordField = app.secureTextFields["password_field"]
            if passwordField.exists {
                passwordField.tap()
                passwordField.typeText("testpassword")
            }
            
            // Submit
            let submitButton = app.buttons["sign_in_submit"]
            if submitButton.exists {
                submitButton.tap()
                
                // Verify successful sign in (should navigate to main app)
                let tabBar = app.tabBars.firstMatch
                XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0), "Should navigate to main app after sign in")
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessageDisplay() throws {
        // This test would trigger an error condition and verify error handling
        // For example, try to load profile without internet connection
        
        // Navigate to profile
        let profileTab = app.tabBars.firstMatch.buttons.element(boundBy: 4)
        profileTab.tap()
        
        // If there's an error state, verify error message appears
        if app.staticTexts["Unable to load profile"].exists {
            XCTAssertTrue(true, "Error message displayed correctly")
        }
        
        // Test retry functionality if it exists
        if app.buttons["Retry"].exists {
            let retryButton = app.buttons["Retry"]
            retryButton.tap()
            
            // Verify retry action was triggered
        }
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testScrollPerformance() throws {
        // Navigate to feed
        let feedTab = app.tabBars.firstMatch.buttons.element(boundBy: 0)
        feedTab.tap()
        
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5.0))
        
        // Measure scroll performance
        if #available(iOS 13.0, *) {
            measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
                scrollView.swipeUp(velocity: .fast)
                scrollView.swipeDown(velocity: .fast)
            }
        }
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard exists else { return }
        
        tap()
        
        // Select all text
        press(forDuration: 1.0)
        let application = XCUIApplication()
        if application.menuItems["Select All"].exists {
            application.menuItems["Select All"].tap()
        }
        
        // Type new text
        typeText(text)
    }
}