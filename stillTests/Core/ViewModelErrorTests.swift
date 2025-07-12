//======================================================================
// MARK: - ViewModelErrorTests
// Purpose: Tests for ViewModelError enum and error handling
//======================================================================
import XCTest
@testable import tete

final class ViewModelErrorTests: XCTestCase {
    
    // MARK: - Error Description Tests
    
    func testNetworkErrorDescription() {
        let error = ViewModelError.network("Connection failed")
        XCTAssertEqual(error.errorDescription, "Network Error: Connection failed")
    }
    
    func testValidationErrorDescription() {
        let error = ViewModelError.validation("Invalid email format")
        XCTAssertEqual(error.errorDescription, "Invalid email format")
    }
    
    func testUnauthorizedErrorDescription() {
        let error = ViewModelError.unauthorized
        XCTAssertEqual(error.errorDescription, "Please log in to continue")
    }
    
    func testPermissionDeniedErrorDescription() {
        let error = ViewModelError.permissionDenied("Camera access required")
        XCTAssertEqual(error.errorDescription, "Permission Denied: Camera access required")
    }
    
    func testNotFoundErrorDescription() {
        let error = ViewModelError.notFound("User profile")
        XCTAssertEqual(error.errorDescription, "User profile not found")
    }
    
    func testServerErrorDescription() {
        let error = ViewModelError.serverError("Internal server error")
        XCTAssertEqual(error.errorDescription, "Server Error: Internal server error")
    }
    
    func testDecodingErrorDescription() {
        let error = ViewModelError.decodingError("Invalid JSON format")
        XCTAssertEqual(error.errorDescription, "Data Error: Invalid JSON format")
    }
    
    func testFileSystemErrorDescription() {
        let error = ViewModelError.fileSystem("Disk full")
        XCTAssertEqual(error.errorDescription, "File Error: Disk full")
    }
    
    func testUnknownErrorDescription() {
        let originalError = NSError(domain: "TestDomain", code: 500, userInfo: [NSLocalizedDescriptionKey: "Original error"])
        let error = ViewModelError.unknown(originalError)
        XCTAssertEqual(error.errorDescription, "Original error")
    }
    
    // MARK: - User Friendly Message Tests
    
    func testNetworkUserFriendlyMessage() {
        let error = ViewModelError.network("Any network message")
        XCTAssertEqual(error.userFriendlyMessage, "Unable to connect. Please check your internet connection.")
    }
    
    func testValidationUserFriendlyMessage() {
        let message = "Invalid email format"
        let error = ViewModelError.validation(message)
        XCTAssertEqual(error.userFriendlyMessage, message)
    }
    
    func testUnauthorizedUserFriendlyMessage() {
        let error = ViewModelError.unauthorized
        XCTAssertEqual(error.userFriendlyMessage, "Please log in to continue")
    }
    
    func testPermissionDeniedUserFriendlyMessage() {
        let error = ViewModelError.permissionDenied("Any permission message")
        XCTAssertEqual(error.userFriendlyMessage, "You don't have permission to perform this action")
    }
    
    func testNotFoundUserFriendlyMessage() {
        let error = ViewModelError.notFound("Any resource")
        XCTAssertEqual(error.userFriendlyMessage, "The requested content could not be found")
    }
    
    func testServerErrorUserFriendlyMessage() {
        let error = ViewModelError.serverError("Any server message")
        XCTAssertEqual(error.userFriendlyMessage, "Something went wrong. Please try again later.")
    }
    
    func testDecodingErrorUserFriendlyMessage() {
        let error = ViewModelError.decodingError("Any decoding message")
        XCTAssertEqual(error.userFriendlyMessage, "Unable to process data. Please try again.")
    }
    
    func testFileSystemErrorUserFriendlyMessage() {
        let error = ViewModelError.fileSystem("Any file message")
        XCTAssertEqual(error.userFriendlyMessage, "Unable to access files. Please try again.")
    }
    
    func testUnknownErrorUserFriendlyMessage() {
        let error = ViewModelError.unknown(NSError(domain: "Test", code: 1))
        XCTAssertEqual(error.userFriendlyMessage, "An unexpected error occurred. Please try again.")
    }
    
    // MARK: - Recovery Action Tests
    
    func testNetworkRecoveryAction() {
        let error = ViewModelError.network("Connection failed")
        XCTAssertEqual(error.recoveryAction, "Check Connection")
    }
    
    func testValidationRecoveryAction() {
        let error = ViewModelError.validation("Invalid input")
        XCTAssertEqual(error.recoveryAction, "Fix Errors")
    }
    
    func testUnauthorizedRecoveryAction() {
        let error = ViewModelError.unauthorized
        XCTAssertEqual(error.recoveryAction, "Log In")
    }
    
    func testPermissionDeniedRecoveryAction() {
        let error = ViewModelError.permissionDenied("Camera access")
        XCTAssertEqual(error.recoveryAction, "Request Access")
    }
    
    func testNotFoundRecoveryAction() {
        let error = ViewModelError.notFound("User")
        XCTAssertEqual(error.recoveryAction, "Go Back")
    }
    
    func testRetryableErrorsRecoveryAction() {
        let retryableErrors: [ViewModelError] = [
            .serverError("Server error"),
            .decodingError("Decoding error"),
            .fileSystem("File error"),
            .unknown(NSError(domain: "Test", code: 1))
        ]
        
        for error in retryableErrors {
            XCTAssertEqual(error.recoveryAction, "Retry", "Error \(error) should have Retry action")
        }
    }
    
    // MARK: - Retryable Tests
    
    func testRetryableErrors() {
        let retryableErrors: [ViewModelError] = [
            .network("Connection failed"),
            .serverError("Server error"),
            .unknown(NSError(domain: "Test", code: 1))
        ]
        
        for error in retryableErrors {
            XCTAssertTrue(error.isRetryable, "Error \(error) should be retryable")
        }
    }
    
    func testNonRetryableErrors() {
        let nonRetryableErrors: [ViewModelError] = [
            .validation("Invalid input"),
            .unauthorized,
            .permissionDenied("Access denied"),
            .notFound("Resource"),
            .decodingError("Invalid data"),
            .fileSystem("File error")
        ]
        
        for error in nonRetryableErrors {
            XCTAssertFalse(error.isRetryable, "Error \(error) should not be retryable")
        }
    }
    
    // MARK: - Error Conversion Tests
    
    func testAsViewModelErrorWithViewModelError() {
        let originalError = ViewModelError.network("Test")
        let convertedError = originalError.asViewModelError
        
        // Should return the same error
        switch convertedError {
        case .network(let message):
            XCTAssertEqual(message, "Test")
        default:
            XCTFail("Should return the same ViewModelError")
        }
    }
    
    func testAsViewModelErrorWithURLError() {
        let urlError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let convertedError = urlError.asViewModelError
        
        switch convertedError {
        case .network:
            break // Expected
        default:
            XCTFail("URL errors should convert to network errors")
        }
    }
    
    func testAsViewModelErrorWithGenericError() {
        let genericError = NSError(domain: "CustomDomain", code: 100)
        let convertedError = genericError.asViewModelError
        
        switch convertedError {
        case .unknown(let wrappedError):
            XCTAssertEqual((wrappedError as NSError).domain, "CustomDomain")
            XCTAssertEqual((wrappedError as NSError).code, 100)
        default:
            XCTFail("Generic errors should convert to unknown errors")
        }
    }
    
    // MARK: - Equality Tests
    
    func testViewModelErrorEquality() {
        // Test same error types are equal (for basic comparison)
        let error1 = ViewModelError.unauthorized
        let error2 = ViewModelError.unauthorized
        
        // Note: ViewModelError doesn't conform to Equatable, but we can test string representations
        XCTAssertEqual(error1.errorDescription, error2.errorDescription)
        XCTAssertEqual(error1.userFriendlyMessage, error2.userFriendlyMessage)
    }
    
    // MARK: - Integration Tests
    
    func testErrorInRealWorldScenario() {
        // Test a complete error handling scenario
        let networkError = ViewModelError.network("Connection timeout")
        
        // Verify all properties work together
        XCTAssertEqual(networkError.errorDescription, "Network Error: Connection timeout")
        XCTAssertEqual(networkError.userFriendlyMessage, "Unable to connect. Please check your internet connection.")
        XCTAssertEqual(networkError.recoveryAction, "Check Connection")
        XCTAssertTrue(networkError.isRetryable)
    }
    
    func testValidationErrorScenario() {
        let validationError = ViewModelError.validation("Email must be in valid format")
        
        XCTAssertEqual(validationError.errorDescription, "Email must be in valid format")
        XCTAssertEqual(validationError.userFriendlyMessage, "Email must be in valid format")
        XCTAssertEqual(validationError.recoveryAction, "Fix Errors")
        XCTAssertFalse(validationError.isRetryable)
    }
}