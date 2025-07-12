# ViewModel Architecture Refactoring

## Overview
This document outlines the refactored ViewModel architecture for improved maintainability, extensibility, and readability.

## Key Components

### 1. BaseViewModel Protocol
**Location**: `Core/ViewModels/BaseViewModel.swift`

Provides common functionality for all ViewModels:
- Loading state management
- Error handling
- Lifecycle management
- Cancellable subscriptions

```swift
@MainActor
protocol BaseViewModel: ObservableObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var showError: Bool { get set }
    var cancellables: Set<AnyCancellable> { get set }
}
```

### 2. ViewModelError Enum
**Location**: `Core/ViewModels/ViewModelError.swift`

Standardized error types across all ViewModels:
- Network errors
- Validation errors
- Authorization errors
- User-friendly messages
- Recovery actions

### 3. Repository Pattern
**Location**: `Core/Repositories/`

Abstracts data access logic:
- `UserRepositoryProtocol` for user operations
- Consistent error handling
- Testable architecture
- Single responsibility

### 4. Logging System
**Location**: `Core/Utilities/Logger.swift`

Centralized logging with:
- Different log levels (debug, info, warning, error)
- File/line information
- OS log integration
- Debug console output

### 5. Dependency Injection
**Location**: `Core/DI/DependencyContainer.swift`

Simple DI container with:
- Factory and singleton registration
- Type-safe resolution
- `@Injected` property wrapper
- Default registrations

## Benefits

### Readability
- Clear separation of concerns
- Consistent naming conventions
- Comprehensive documentation
- Type-safe error handling

### Extensibility
- Protocol-based design
- Dependency injection
- Repository pattern for data access
- Base classes for common functionality

### Maintainability
- Standardized error handling
- Centralized logging
- Testable architecture
- Consistent patterns across ViewModels

## Migration Guide

### For Existing ViewModels

1. **Inherit from BaseViewModelClass** or conform to `BaseViewModel`
2. **Replace print statements** with `Logger.shared`
3. **Use standardized errors** with `ViewModelError`
4. **Inject dependencies** through constructor or `@Injected`

### Example Migration

**Before:**
```swift
class MyViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadData() {
        isLoading = true
        // direct Supabase access
        print("Loading data...")
    }
}
```

**After:**
```swift
final class MyViewModel: BaseViewModelClass {
    @Injected private var repository: UserRepositoryProtocol
    
    func loadData() async {
        showLoading()
        do {
            let data = try await repository.fetchData()
            hideLoading()
            Logger.shared.info("Data loaded successfully")
        } catch {
            handleError(error)
        }
    }
}
```

## Best Practices

1. **Always use async/await** for asynchronous operations
2. **Handle errors consistently** using ViewModelError
3. **Log important events** with appropriate levels
4. **Use dependency injection** for testability
5. **Document public methods** with clear descriptions
6. **Follow naming conventions** for properties and methods

## Testing

The new architecture enables better testing:
- Mock repositories for unit tests
- Dependency injection for test doubles
- Clear separation of concerns
- Predictable error handling

## Future Improvements

1. **Analytics integration** in BaseViewModel
2. **Caching layer** in repositories
3. **Offline support** patterns
4. **Performance monitoring** hooks
5. **Automated testing** setup