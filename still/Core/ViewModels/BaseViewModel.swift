//======================================================================
// MARK: - BaseViewModel Protocol
// Purpose: Provides common functionality for all ViewModels
// Usage: All ViewModels should conform to this protocol
//======================================================================
import SwiftUI
@preconcurrency import Combine

/// Base protocol for all ViewModels providing common functionality
/// such as loading states, error handling, and lifecycle management
@MainActor
protocol BaseViewModel: ObservableObject {
    /// Indicates if the ViewModel is currently loading data
    var isLoading: Bool { get set }
    
    /// Current error message to display to the user
    var errorMessage: String? { get set }
    
    /// Controls the visibility of error alerts
    var showError: Bool { get set }
    
    /// Stores cancellable subscriptions
    var cancellables: Set<AnyCancellable> { get set }
    
    /// Handle errors in a consistent way
    func handleError(_ error: Error)
    
    /// Show loading state
    func showLoading()
    
    /// Hide loading state
    func hideLoading()
    
    /// Reset error state
    func clearError()
}

/// Default implementations for BaseViewModel
extension BaseViewModel {
    
    /// Handles errors by setting appropriate error message and hiding loading
    /// - Parameter error: The error to handle
    func handleError(_ error: Error) {
        Task { @MainActor in
            if let vmError = error as? ViewModelError {
                self.errorMessage = vmError.userFriendlyMessage
            } else {
                self.errorMessage = error.localizedDescription
            }
            self.showError = true
            self.hideLoading()
            
            Logger.shared.error("ViewModel Error: \(error)")
        }
    }
    
    /// Shows loading indicator and clears any existing errors
    func showLoading() {
        isLoading = true
        clearError()
    }
    
    /// Hides loading indicator
    func hideLoading() {
        isLoading = false
    }
    
    /// Clears error state
    func clearError() {
        errorMessage = nil
        showError = false
    }
}

/// Base class providing common ViewModel functionality
/// Use this when you need a class-based ViewModel
@MainActor
class BaseViewModelClass: BaseViewModel {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    var cancellables = Set<AnyCancellable>()
    
    deinit {
        // Note: In Swift 6, deinit cannot access MainActor-isolated properties
        // Cancellables will be automatically cleaned up when the object is deallocated
    }
}