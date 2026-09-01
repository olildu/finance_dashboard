# Phase 1: Auth Frontend Tests - TDD Workflow

**Date Created:** 2026-09-01  
**Status:** Test Contracts Written (TDD Phase 1)  
**Next Phase:** Implementation of auth feature based on test contracts

## Overview

This document describes the comprehensive test suite written for the authentication feature of the Flutter Web finance dashboard. Following Test-Driven Development (TDD) principles, the tests are written first, serving as specifications for the implementation that will follow.

The auth feature is structured using feature-sliced architecture with three layers:
- **Data Layer** (`data/auth_api.dart`): HTTP API communication with the backend
- **Business Layer** (`business/auth_provider.dart`): State management and business logic
- **Presentation Layer** (`presentation/login_register_page.dart`): UI components and user interactions

## Test Files Created

### 1. Data Layer Test: `test/features/auth/data/auth_api_test.dart`

**Purpose:** Verify that AuthApi correctly communicates with backend endpoints and handles responses/errors.

**Testing Strategy:** Mock Dio HTTP client at the lowest level to ensure no actual network calls are made.

#### Login Tests (7 tests)
- **successful login**: Verifies AuthApi.login() calls POST /auth/login with username and password
- **successful login response**: Confirms response parsing returns access_token and refresh_token
- **401 error handling**: Ensures DioException with 401 status is caught and thrown appropriately
- **network error handling**: Tests connection timeout and other network errors
- **500 error handling**: Verifies server error responses are handled

#### Register Tests (7 tests)
- **successful register**: Verifies AuthApi.register() calls POST /auth/register with username, email, password
- **successful register response**: Confirms token response parsing on successful registration (201 status)
- **400 validation error**: Tests handling of duplicate username/email errors
- **network error handling**: Tests connection errors during registration
- **500 server error**: Verifies server error handling

#### Refresh Token Tests (5 tests)
- **successful refresh**: Verifies AuthApi.refresh() calls POST /auth/refresh with refresh_token
- **new token response**: Confirms new access_token is returned
- **401 invalid token**: Tests invalid/expired refresh token handling
- **network error**: Tests connection errors during token refresh

**Mocking Pattern:**
```dart
late MockDio mockDio;

when(() => mockDio.post(
  '/auth/login',
  data: {'username': username, 'password': password},
)).thenAnswer((_) async => Response(...));
```

**Key Assertions:**
- Endpoint URLs are correct
- Request parameters are properly formatted
- Response data is correctly parsed
- Errors are thrown with appropriate context

### 2. Business Layer Test: `test/features/auth/business/auth_provider_test.dart`

**Purpose:** Verify that AuthProvider correctly manages authentication state and coordinates between data layer and token storage.

**Testing Strategy:** Mock AuthApi and TokenManager, verify state transitions and listener notifications.

#### Initialization Tests (2 tests)
- **default state**: Confirms isLoggedIn=false and currentError=null on initialization
- **provider dependency injection**: Verifies AuthApi and TokenManager are properly injected

#### Login Flow Tests (7 tests)
- **successful login**: Verifies state changes to isLoggedIn=true and tokens are saved
- **error cleared**: Confirms currentError is set to null after successful login
- **login failure**: Verifies error message is captured and isLoggedIn stays false
- **network error**: Tests handling of network errors with appropriate error messages
- **server error**: Tests 500 error scenarios
- **listener notification**: Confirms notifyListeners() is called on success
- **listener notification on failure**: Confirms notifyListeners() is called on error

#### Register Flow Tests (8 tests)
- **successful register**: Verifies state changes to isLoggedIn=true and tokens are saved
- **error cleared**: Confirms currentError is null after successful register
- **register failure**: Verifies error message on duplicate username/email
- **duplicate username error**: Tests specific error handling
- **duplicate email error**: Tests specific error handling
- **network error**: Tests connection timeout scenarios
- **listener notification**: Confirms notifyListeners() called on success
- **listener notification on failure**: Confirms notifyListeners() called on error

#### Logout Flow Tests (5 tests)
- **logout state change**: Verifies isLoggedIn becomes false
- **token deletion**: Confirms TokenManager.deleteTokens() is called
- **error cleared**: Verifies currentError is cleared on logout
- **listener notification**: Confirms notifyListeners() called
- **error handling**: Tests graceful handling if token deletion fails

#### State Management Tests (2 tests)
- **state persistence**: Verifies isLoggedIn state is maintained across multiple operations
- **error accumulation**: Confirms errors are only set on failures and cleared on success

**Mocking Pattern:**
```dart
late MockAuthApi mockAuthApi;
late MockTokenManager mockTokenManager;

when(() => mockAuthApi.login(username, password))
  .thenAnswer((_) async => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
  });
```

**Key Assertions:**
- State transitions are correct
- TokenManager methods are called with correct parameters
- AuthApi is called with correct parameters
- Listeners are notified of state changes
- Errors are properly captured and cleared

### 3. Presentation Layer Test: `test/features/auth/presentation/login_register_page_test.dart`

**Purpose:** Verify the UI correctly displays fields, handles user input, and communicates with AuthProvider.

**Testing Strategy:** Widget tests using flutter_test with Provider for dependency injection.

#### UI Elements Tests (6 tests)
- **username field**: Confirms TextField for username input is present
- **email field**: Confirms TextField for email input is present
- **password field**: Confirms password TextField is obscured (obscureText: true)
- **login button**: Confirms ElevatedButton for login is present and pressable
- **register button**: Confirms ElevatedButton for register is present and pressable
- **error message display**: Verifies error messages are shown when AuthProvider.currentError is not null
- **no error initially**: Confirms error message is not displayed initially

#### Login Functionality Tests (7 tests)
- **login button calls provider**: Verifies AuthProvider.login() is called with entered values
- **clears error on success**: Confirms error message disappears after successful login
- **displays error on failure**: Verifies error message is shown after failed login
- **disables button while loading**: Tests button is disabled during async operation
- **clears fields on success**: Confirms input fields are cleared after successful login
- **preserves fields on failure**: Verifies input fields retain values after failed login for correction

#### Register Functionality Tests (6 tests)
- **register button calls provider**: Verifies AuthProvider.register() is called with all three fields
- **clears error on success**: Confirms error message disappears after successful register
- **displays error on failure**: Verifies error message is shown after failed register
- **disables button while loading**: Tests button is disabled during async operation
- **clears fields on success**: Confirms input fields are cleared after successful register
- **preserves fields on failure**: Verifies input fields retain values after failed register

#### Input Validation Tests (6 tests)
- **empty username validation**: Confirms login validation error and provider not called
- **empty password validation**: Confirms login validation error and provider not called
- **empty username in register**: Confirms register validation error
- **empty email validation**: Confirms register validation error
- **empty password in register**: Confirms register validation error
- **email format validation**: Confirms invalid email format is rejected with error message

#### UI Responsiveness Tests (3 tests)
- **state changes update UI**: Verifies UI reflects AuthProvider.isLoggedIn changes
- **login loading state**: Confirms loading indicator shown during login request
- **register loading state**: Confirms loading indicator shown during register request

**Testing Pattern:**
```dart
Widget createWidgetUnderTest() {
  return MaterialApp(
    home: ChangeNotifierProvider<MockAuthProvider>.value(
      value: mockAuthProvider,
      child: const LoginRegisterPage(),
    ),
  );
}

await tester.pumpWidget(createWidgetUnderTest());
await tester.enterText(find.byType(TextField).first, 'username');
await tester.tap(find.byType(ElevatedButton).first);
await tester.pumpAndSettle();

verify(() => mockAuthProvider.login('username', 'password')).called(1);
```

**Key Assertions:**
- AuthProvider methods are called with correct parameters
- Input fields contain expected values
- Error messages are displayed/hidden correctly
- UI state responds to provider state changes
- Validation prevents invalid submissions

## Test Architecture

### Layered Testing Approach

```
┌─────────────────────────────────────────────────────────────┐
│ Presentation Layer (Widget Tests)                           │
│ - Mock AuthProvider                                         │
│ - Test user interactions                                    │
│ - Verify UI state management                               │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│ Business Layer (Unit Tests)                                 │
│ - Mock AuthApi + TokenManager                              │
│ - Test state transitions                                    │
│ - Verify method calls and error handling                   │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│ Data Layer (Unit Tests)                                     │
│ - Mock Dio HTTP client                                     │
│ - Test endpoint communication                              │
│ - Verify request/response handling                         │
└─────────────────────────────────────────────────────────────┘
```

### Mocking Strategy

1. **Data Layer**: Mock Dio to simulate HTTP responses and errors without network calls
2. **Business Layer**: Mock AuthApi and TokenManager to test logic in isolation
3. **Presentation Layer**: Mock AuthProvider to test UI without business logic

This isolation ensures:
- Tests are fast (no network calls)
- Tests are reliable (no external dependencies)
- Tests are focused (each layer tests one responsibility)
- Tests are independent (can run in any order)

## Test Execution

### Running Tests

```bash
# Run all auth feature tests
flutter test test/features/auth/

# Run specific test file
flutter test test/features/auth/data/auth_api_test.dart
flutter test test/features/auth/business/auth_provider_test.dart
flutter test test/features/auth/presentation/login_register_page_test.dart

# Run with coverage
flutter test --coverage test/features/auth/
```

### Expected Test Results (When Implemented)

- **Data Layer Tests**: ~19 tests
- **Business Layer Tests**: ~22 tests
- **Presentation Layer Tests**: ~28 tests
- **Total**: ~69 test cases

All tests are designed to pass when implementation correctly follows the test contracts.

## Test Dependencies

The tests use the following packages already present in pubspec.yaml:
- `flutter_test`: Flutter testing framework
- `mocktail`: Mocking library for Dart (more lightweight than mockito)
- `provider`: State management for dependency injection
- `go_router`: Routing (used by AuthProvider for redirects on logout)

No additional dependencies are required.

## Implementation Guidelines

### AuthApi Implementation Requirements

Based on the data layer tests, AuthApi must:

1. **Login Method**
   - Call `dio.post('/auth/login', data: {'username': username, 'password': password})`
   - Return `Map<String, dynamic>` with 'access_token' and 'refresh_token'
   - Throw exceptions on network or HTTP errors

2. **Register Method**
   - Call `dio.post('/auth/register', data: {'username': username, 'email': email, 'password': password})`
   - Return tokens on success (201 status expected)
   - Throw exceptions on validation or server errors

3. **Refresh Method**
   - Call `dio.post('/auth/refresh', data: {'refresh_token': refreshToken})`
   - Return new 'access_token'
   - Throw on invalid/expired refresh tokens

### AuthProvider Implementation Requirements

Based on the business layer tests, AuthProvider must:

1. **Extend ChangeNotifier**
   - Maintain `isLoggedIn` (bool) state
   - Maintain `currentError` (String?) state
   - Call `notifyListeners()` on state changes

2. **Login Method**
   - Call authApi.login() with credentials
   - On success: save tokens, set isLoggedIn=true, clear error, notify
   - On error: capture error message, keep isLoggedIn=false, notify

3. **Register Method**
   - Call authApi.register() with username, email, password
   - On success: save tokens, set isLoggedIn=true, clear error, notify
   - On error: capture error message, keep isLoggedIn=false, notify

4. **Logout Method**
   - Call tokenManager.deleteTokens()
   - Set isLoggedIn=false
   - Clear currentError
   - Notify listeners
   - Optionally redirect to /login via go_router

### LoginRegisterPage Implementation Requirements

Based on the presentation layer tests, LoginRegisterPage must:

1. **UI Components**
   - TextField for username input
   - TextField for email input (register mode)
   - TextField for password input (with obscureText: true)
   - ElevatedButton for login
   - ElevatedButton for register
   - Error message display (when currentError is not null)

2. **Login Flow**
   - Validate username and password are not empty
   - Extract values from TextFields
   - Call authProvider.login(username, password)
   - Show loading indicator while awaiting response
   - Display error message if login fails
   - Clear fields if login succeeds
   - Disable button during loading

3. **Register Flow**
   - Validate username, email, and password are not empty
   - Validate email format
   - Extract values from TextFields
   - Call authProvider.register(username, email, password)
   - Show loading indicator while awaiting response
   - Display error message if register fails
   - Clear fields if register succeeds
   - Disable button during loading

4. **State Management**
   - Listen to authProvider changes via Consumer or similar
   - Update UI when provider states change
   - Handle navigation on successful login (via go_router or callback)

## Test-Driven Development (TDD) Workflow

This phase follows the "Red-Green-Refactor" cycle:

### Phase 1: RED (Current) ✓ COMPLETED
- Write comprehensive test specifications
- Tests fail because implementation doesn't exist
- Tests define the contract that implementation must fulfill

### Phase 2: GREEN (Next)
- Implement AuthApi, AuthProvider, and LoginRegisterPage
- Each implementation follows the test contracts exactly
- All tests should pass when implementation is complete
- Focus on making tests pass, not on perfection

### Phase 3: REFACTOR (Future)
- Review implementation for:
  - Code duplication
  - Performance improvements
  - Readability enhancements
  - Design pattern adherence
- Add integration tests if needed
- Refactor while keeping all tests passing

## Test Naming Conventions

All tests follow the pattern: `should [expected behavior]`

**Examples:**
- `should call POST /auth/login with username and password`
- `should return access_token and refresh_token on successful login`
- `should throw exception on login failure with 401 status`
- `should set isLoggedIn to true after successful login`
- `should display error message when AuthProvider.currentError is not null`

This naming convention makes tests self-documenting and readable as specifications.

## Coverage Expectations

The test suite aims for high coverage of the auth feature:

- **Data Layer**: 100% of AuthApi methods
- **Business Layer**: 100% of AuthProvider public interface
- **Presentation Layer**: 100% of user interactions and UI states

Expected overall coverage: 95%+ of auth feature code

## Known Limitations

1. **No Backend Integration**: Tests use mocked HTTP responses. Integration with actual backend will be tested separately.

2. **No Navigation Testing**: Tests don't verify navigation to dashboard after login (that's handled by app_router). The provider sets state correctly; routing is tested separately.

3. **No Local Storage Testing**: TokenManager uses localstorage package. Token persistence is tested at the provider level through token manager mocks.

4. **No Animation Testing**: Loading indicators and transitions are verified conceptually; detailed animation testing would require additional snapshot tests.

## Next Steps

1. **Code Review**: Review these test specifications with team
2. **Implementation**: Follow tests to implement auth feature
3. **Run Tests**: Execute `flutter test test/features/auth/` to verify implementation
4. **Code Coverage**: Generate coverage report: `flutter test --coverage`
5. **Integration Tests**: After all unit tests pass, add integration tests with backend

## Document Version

- **Version**: 1.0
- **Created**: 2026-09-01
- **Last Updated**: 2026-09-01
- **Status**: Ready for Implementation
