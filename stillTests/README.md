# Couleur Test Suite

## Overview

This test suite implements a comprehensive testing strategy for the Couleur app, following MVVM architecture testing best practices. The tests are designed to ensure high code quality, maintainability, and reliability.

## Test Architecture

### Test Pyramid Structure
```
    UI Tests (Small)
   ↑ Critical flows only
   
  Integration Tests (Medium)  
 ↑ Repository & Service layer
 
Unit Tests (Large)
↑ ViewModels, Models, Business Logic
```

## Test Categories

### 1. Unit Tests (`couleurTests/`)

#### ViewModels (`ViewModels/`)
- **MyPageViewModelTests.swift**: Comprehensive tests for user profile management
- **HomeFeedViewModelTests.swift**: Tests for main feed functionality and like operations
- **BaseViewModelTests.swift**: Tests for common ViewModel functionality

**Coverage**: Error handling, loading states, business logic, optimistic updates, async operations

#### Models (`Core/Models/`)
- **UserProfileTests.swift**: Tests for user profile data model
- **PostTests.swift**: Tests for post data model and business logic

**Coverage**: Initialization, Codable conformance, business logic, edge cases

#### Core Systems (`Core/`)
- **ViewModelErrorTests.swift**: Tests for error handling system

### 2. Integration Tests (`Repositories/`)
- **UserRepositoryIntegrationTests.swift**: Tests for repository integration with Supabase
- **UserRepositoryTests.swift**: Additional repository tests

**Coverage**: Database operations, API integration, error scenarios

### 3. UI Tests (`UI/`)
- **ViewSnapshotTests.swift**: Snapshot tests for UI components
- Visual regression testing for different device sizes and themes

### 4. End-to-End Tests (`couleurUITests/`)
- **CriticalFlowUITests.swift**: Tests for critical user journeys
- Navigation, authentication, core interactions

## Mock Infrastructure

### Dependency Injection
- **DependencyContainer**: Centralized DI container with test configuration
- **MockAuthManager**: Mock authentication for testing
- **MockUserRepository**: Mock repository for unit tests
- **MockPostService**: Mock post service for feed tests
- **MockSupabaseClient**: Mock Supabase client for integration tests

### Test Utilities
- **TestUtilities**: Helper functions for creating test data
- **SnapshotTestHelper**: Utilities for snapshot testing
- **TestRunner**: Test configuration and setup

## Test Data Management

### Mock Data Strategy
- Consistent test data creation through `TestUtilities`
- Isolated test environments with `TestRunner.configureForTesting()`
- Automatic cleanup between tests

### Test User Profiles
```swift
let testProfile = TestUtilities.createTestUserProfile(
    id: "test-user-id",
    username: "testuser",
    displayName: "Test User"
)
```

### Test Posts
```swift
let testPosts = TestUtilities.createTestPosts(count: 5)
```

## Running Tests

### Unit Tests
```bash
xcodebuild test -scheme couleur -destination 'platform=iOS Simulator,name=iPhone 14'
```

### UI Tests
```bash
xcodebuild test -scheme couleur -destination 'platform=iOS Simulator,name=iPhone 14' -only-testing:couleurUITests
```

### Snapshot Tests
Set `record: true` in snapshot test calls to record new reference images, then set to `false` to run comparisons.

## Test Coverage Goals

### Target Coverage by Layer
- **ViewModels**: 90%+ (Critical business logic)
- **Models**: 85%+ (Data integrity)
- **Repositories**: 80%+ (Data access)
- **UI Components**: 70%+ (Visual regression prevention)

### Current Coverage
Run the following to generate coverage reports:
```bash
xcodebuild test -scheme couleur -enableCodeCoverage YES -derivedDataPath ./DerivedData
```

## Best Practices

### Test Naming
- **Pattern**: `test[MethodUnderTest][Scenario][ExpectedBehavior]()`
- **Example**: `testLoadUserDataWhenNotAuthenticated()`

### Test Structure (AAA Pattern)
```swift
func testExample() async {
    // Given (Arrange)
    let testData = TestUtilities.createTestData()
    mockService.setupData(testData)
    
    // When (Act)
    await viewModel.performAction()
    
    // Then (Assert)
    XCTAssertEqual(viewModel.result, expectedResult)
}
```

### Async Testing
```swift
// Use async/await for cleaner async tests
await viewModel.loadData()
XCTAssertFalse(viewModel.isLoading)

// Use expectations for complex async scenarios
let expectation = expectation(description: "Data loaded")
// ... setup and fulfill expectation
await fulfillment(of: [expectation], timeout: 1.0)
```

## Continuous Integration

### Test Automation
- All tests run automatically on PR creation
- Snapshot tests prevent visual regressions
- Performance tests catch performance degradations

### Quality Gates
- Tests must pass before merge
- Code coverage must meet thresholds
- No new SwiftLint violations

## Troubleshooting

### Common Issues

#### Snapshot Test Failures
1. Check if UI changes are intentional
2. Record new snapshots if changes are expected
3. Verify test runs on correct device/simulator

#### Async Test Flakiness
1. Increase timeout values for slow operations
2. Use proper async/await patterns
3. Ensure proper test isolation

#### Mock Data Issues
1. Verify mock setup in test setUp()
2. Check TestRunner.configureForTesting() is called
3. Ensure proper cleanup in tearDown()

## Future Improvements

### Planned Enhancements
1. **Performance Testing**: Add more comprehensive performance benchmarks
2. **A11y Testing**: Automated accessibility testing
3. **Contract Testing**: API contract validation
4. **Load Testing**: Stress testing for core operations

### Additional ViewModels to Test
- CreatePostViewModel (High Priority)
- SearchViewModel (Medium Priority)
- MessagesViewModel (High Priority)
- PhotoEditorViewModel (High Priority)

## Contributing

### Adding New Tests
1. Follow existing patterns and naming conventions
2. Include both success and failure scenarios
3. Add appropriate mock data setup
4. Update this documentation

### Test Review Checklist
- [ ] Tests follow AAA pattern
- [ ] Both happy path and error cases covered
- [ ] Proper async/await usage
- [ ] Mock objects properly configured
- [ ] Tests are isolated and don't depend on each other
- [ ] Performance tests for critical paths
- [ ] Accessibility considerations included

---

This test suite ensures the Couleur app maintains high quality through comprehensive automated testing at all levels of the application architecture.