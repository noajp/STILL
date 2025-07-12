//======================================================================
// MARK: - ViewModelError
// Purpose: Standardized error types for all ViewModels
// Usage: Throw these errors in ViewModels for consistent error handling
//======================================================================
import Foundation

/// Standardized error types for ViewModels
enum ViewModelError: LocalizedError {
    /// Network-related errors
    case network(String)
    
    /// Validation errors for user input
    case validation(String)
    
    /// Authentication/authorization errors
    case unauthorized
    
    /// Permission denied errors
    case permissionDenied(String)
    
    /// Resource not found
    case notFound(String)
    
    /// Server errors
    case serverError(String)
    
    /// Data parsing/decoding errors
    case decodingError(String)
    
    /// File system errors
    case fileSystem(String)
    
    /// Generic unknown error
    case unknown(Error)
    
    /// User-friendly error description
    var errorDescription: String? {
        switch self {
        case .network(let message):
            return "Network Error: \(message)"
        case .validation(let message):
            return message
        case .unauthorized:
            return "Please log in to continue"
        case .permissionDenied(let message):
            return "Permission Denied: \(message)"
        case .notFound(let resource):
            return "\(resource) not found"
        case .serverError(let message):
            return "Server Error: \(message)"
        case .decodingError(let message):
            return "Data Error: \(message)"
        case .fileSystem(let message):
            return "File Error: \(message)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    /// User-friendly message for display in UI
    var userFriendlyMessage: String {
        switch self {
        case .network:
            return "Unable to connect. Please check your internet connection."
        case .validation(let message):
            return message
        case .unauthorized:
            return "Please log in to continue"
        case .permissionDenied:
            return "You don't have permission to perform this action"
        case .notFound:
            return "The requested content could not be found"
        case .serverError:
            return "Something went wrong. Please try again later."
        case .decodingError:
            return "Unable to process data. Please try again."
        case .fileSystem:
            return "Unable to access files. Please try again."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    /// Suggested recovery action for the error
    var recoveryAction: String? {
        switch self {
        case .network:
            return "Check Connection"
        case .validation:
            return "Fix Errors"
        case .unauthorized:
            return "Log In"
        case .permissionDenied:
            return "Request Access"
        case .notFound:
            return "Go Back"
        case .serverError, .decodingError, .fileSystem, .unknown:
            return "Retry"
        }
    }
    
    /// Whether the error is retryable
    var isRetryable: Bool {
        switch self {
        case .network, .serverError, .unknown:
            return true
        case .validation, .unauthorized, .permissionDenied, .notFound, .decodingError, .fileSystem:
            return false
        }
    }
}

/// Extension to convert common errors to ViewModelError
extension Error {
    /// Converts various error types to ViewModelError
    var asViewModelError: ViewModelError {
        if let vmError = self as? ViewModelError {
            return vmError
        }
        
        // Check for common error types
        if (self as NSError).domain == NSURLErrorDomain {
            return .network("Connection failed")
        }
        
        // Default to unknown
        return .unknown(self)
    }
}