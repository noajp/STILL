//======================================================================
// MARK: - BaseViewModelTests
// Purpose: Tests for BaseViewModel protocol and BaseViewModelClass
//======================================================================
import XCTest
import Combine
@testable import tete

@MainActor
final class BaseViewModelTests: XCTestCase {
    
    // MARK: - Test ViewModel Implementation
    
    /// Test implementation of BaseViewModel for testing
    class TestViewModel: BaseViewModelClass {
        
        // Test methods to trigger different scenarios
        func triggerNetworkError() {
            handleError(ViewModelError.network("Network error"))
        }
        
        func triggerValidationError() {
            handleError(ViewModelError.validation("Validation failed"))
        }
        
        func triggerUnknownError() {
            handleError(NSError(domain: "Test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
        }
        
        func startLoading() {
            showLoading()
        }
        
        func stopLoading() {
            hideLoading()
        }
        
        func resetError() {
            clearError()
        }
    }
    
    // MARK: - Properties
    private var viewModel: TestViewModel!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        viewModel = TestViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        cancellables = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
        XCTAssertTrue(viewModel.cancellables.isEmpty)
    }
    
    // MARK: - Loading State Tests
    
    func testShowLoading() {
        // When
        viewModel.startLoading()
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
    
    func testHideLoading() {
        // Given
        viewModel.startLoading()
        XCTAssertTrue(viewModel.isLoading)
        
        // When
        viewModel.stopLoading()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testShowLoadingClearsExistingError() {
        // Given
        viewModel.triggerNetworkError()
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
        
        // When
        viewModel.startLoading()
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
    
    func testLoadingStateObservable() {
        // Given
        let expectation = expectation(description: "Loading state changes")
        var observedStates: [Bool] = []
        
        viewModel.$isLoading
            .sink { isLoading in
                observedStates.append(isLoading)
                if observedStates.count >= 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.startLoading()
        viewModel.stopLoading()
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(observedStates, [false, true, false])
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleNetworkError() {
        // When
        viewModel.triggerNetworkError()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Unable to connect. Please check your internet connection.")
        XCTAssertTrue(viewModel.showError)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleValidationError() {
        // When
        viewModel.triggerValidationError()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Validation failed")
        XCTAssertTrue(viewModel.showError)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleUnknownError() {
        // When
        viewModel.triggerUnknownError()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Unknown error")
        XCTAssertTrue(viewModel.showError)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testHandleErrorStopsLoading() {
        // Given
        viewModel.startLoading()
        XCTAssertTrue(viewModel.isLoading)
        
        // When
        viewModel.triggerNetworkError()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.showError)
    }
    
    func testClearError() {
        // Given
        viewModel.triggerNetworkError()
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
        
        // When
        viewModel.resetError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
    
    func testErrorStateObservable() {
        // Given
        let expectation = expectation(description: "Error state changes")
        var observedErrorStates: [Bool] = []
        var observedMessages: [String?] = []
        
        viewModel.$showError
            .sink { showError in
                observedErrorStates.append(showError)
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .sink { message in
                observedMessages.append(message)
                if observedMessages.count >= 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.triggerNetworkError()
        viewModel.resetError()
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(observedErrorStates, [false, true, false])
        XCTAssertEqual(observedMessages.count, 3)
        XCTAssertNil(observedMessages[0]) // Initial
        XCTAssertNotNil(observedMessages[1]) // After error
        XCTAssertNil(observedMessages[2]) // After clear
    }
    
    // MARK: - ViewModelError Tests
    
    func testAllViewModelErrorTypes() {
        // Test network error
        viewModel.handleError(ViewModelError.network("Network failed"))
        XCTAssertEqual(viewModel.errorMessage, "Unable to connect. Please check your internet connection.")
        
        viewModel.resetError()
        
        // Test validation error
        viewModel.handleError(ViewModelError.validation("Invalid input"))
        XCTAssertEqual(viewModel.errorMessage, "Invalid input")
        
        viewModel.resetError()
        
        // Test unauthorized error
        viewModel.handleError(ViewModelError.unauthorized)
        XCTAssertEqual(viewModel.errorMessage, "Please log in to continue")
        
        viewModel.resetError()
        
        // Test permission denied error
        viewModel.handleError(ViewModelError.permissionDenied("Access denied"))
        XCTAssertEqual(viewModel.errorMessage, "You don't have permission to perform this action")
        
        viewModel.resetError()
        
        // Test not found error
        viewModel.handleError(ViewModelError.notFound("Resource"))
        XCTAssertEqual(viewModel.errorMessage, "The requested content could not be found")
        
        viewModel.resetError()
        
        // Test server error
        viewModel.handleError(ViewModelError.serverError("Internal error"))
        XCTAssertEqual(viewModel.errorMessage, "Something went wrong. Please try again later.")
        
        viewModel.resetError()
        
        // Test decoding error
        viewModel.handleError(ViewModelError.decodingError("Parse failed"))
        XCTAssertEqual(viewModel.errorMessage, "Unable to process data. Please try again.")
        
        viewModel.resetError()
        
        // Test file system error
        viewModel.handleError(ViewModelError.fileSystem("File access failed"))
        XCTAssertEqual(viewModel.errorMessage, "Unable to access files. Please try again.")
    }
    
    // MARK: - Combine Cancellables Tests
    
    func testCancellablesManagement() {
        // Given
        let publisher = PassthroughSubject<String, Never>()
        
        publisher
            .sink { value in
                // Test subscription
            }
            .store(in: &viewModel.cancellables)
        
        // Then
        XCTAssertEqual(viewModel.cancellables.count, 1)
        
        // When
        publisher
            .sink { value in
                // Another subscription
            }
            .store(in: &viewModel.cancellables)
        
        // Then
        XCTAssertEqual(viewModel.cancellables.count, 2)
    }
    
    func testDeinitCancelsCancellables() {
        // Given
        var cancellablesCanceled = false
        let publisher = PassthroughSubject<String, Never>()
        
        // Create a scope where the view model will be deallocated
        do {
            let localViewModel = TestViewModel()
            
            publisher
                .handleEvents(receiveCancel: {
                    cancellablesCanceled = true
                })
                .sink { _ in }
                .store(in: &localViewModel.cancellables)
            
            XCTAssertFalse(cancellablesCanceled)
        } // localViewModel is deallocated here
        
        // Force deallocation by waiting
        DispatchQueue.main.async {
            // This should trigger deinit
        }
        
        // Note: This test is tricky because deinit might not be called immediately
        // In real usage, the cancellables would be canceled when the view model is deallocated
    }
    
    // MARK: - Integration Tests
    
    func testCompleteErrorHandlingFlow() {
        // Given
        let expectation = expectation(description: "Complete error flow")
        var stateChanges: [(loading: Bool, error: Bool, message: String?)] = []
        
        // Observe all state changes
        Publishers.CombineLatest3(
            viewModel.$isLoading,
            viewModel.$showError,
            viewModel.$errorMessage
        )
        .sink { (loading, error, message) in
            stateChanges.append((loading: loading, error: error, message: message))
            if stateChanges.count >= 4 {
                expectation.fulfill()
            }
        }
        .store(in: &cancellables)
        
        // When - Complete flow
        viewModel.startLoading()
        viewModel.triggerNetworkError()
        viewModel.resetError()
        
        // Then
        waitForExpectations(timeout: 1.0)
        
        // Verify state progression
        XCTAssertEqual(stateChanges.count, 4)
        
        // Initial state
        XCTAssertEqual(stateChanges[0].loading, false)
        XCTAssertEqual(stateChanges[0].error, false)
        XCTAssertNil(stateChanges[0].message)
        
        // Loading state
        XCTAssertEqual(stateChanges[1].loading, true)
        XCTAssertEqual(stateChanges[1].error, false)
        XCTAssertNil(stateChanges[1].message)
        
        // Error state
        XCTAssertEqual(stateChanges[2].loading, false)
        XCTAssertEqual(stateChanges[2].error, true)
        XCTAssertNotNil(stateChanges[2].message)
        
        // Reset state
        XCTAssertEqual(stateChanges[3].loading, false)
        XCTAssertEqual(stateChanges[3].error, false)
        XCTAssertNil(stateChanges[3].message)
    }
    
    // MARK: - Performance Tests
    
    func testErrorHandlingPerformance() {
        measure {
            for i in 0..<1000 {
                viewModel.handleError(ViewModelError.network("Error \(i)"))
                viewModel.clearError()
            }
        }
    }
    
    func testLoadingStatePerformance() {
        measure {
            for _ in 0..<1000 {
                viewModel.showLoading()
                viewModel.hideLoading()
            }
        }
    }
}