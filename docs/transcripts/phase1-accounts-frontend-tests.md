# Phase 1: Accounts Feature Frontend Tests

**Date:** 2026-09-01
**Status:** Test Contracts Written (TDD - Implementation to follow)
**Scope:** Flutter frontend tests for the accounts feature using TDD approach

---

## Overview

This phase established comprehensive test contracts for the accounts feature following TDD principles. Three test files were created covering the data, business logic, and presentation layers of the feature:

- **Data Layer Tests:** AccountsApi contract tests
- **Business Logic Tests:** AccountsProvider state management tests
- **Presentation Layer Tests:** MonthEndCheckPage widget tests

All tests use mocktail for mocking and follow the existing project testing patterns established in the auth feature.

---

## Test Files Created

### 1. Data Layer: `test/features/accounts/data/accounts_api_test.dart`

**Purpose:** Contract tests for the AccountsApi data layer

**Mock Setup:**
- `MockDio`: Mocks the Dio HTTP client

**Test Groups:**

#### `getAccounts()` Tests

1. **Basic Functionality**
   - Should call GET `/accounts` endpoint
   - Should return list of accounts with correct structure
   - Should parse numeric values correctly (preserve decimals)

2. **Happy Path**
   - Returns array of account objects with id, name, balance, expected_balance
   - Handles multiple accounts (2+ items)

3. **Edge Cases**
   - Returns empty list when no accounts exist
   - Handles accounts with null optional fields

4. **Error Handling**
   - Throws exception on network errors (connection timeout)
   - Throws exception on 401 unauthorized
   - Throws exception on 500 server error

**Expected Account Structure:**
```json
{
  "id": "acc_1",
  "name": "Checking Account",
  "balance": 5000.0,
  "expected_balance": 5000.0
}
```

#### `getMonthEndCheck()` Tests

1. **Basic Functionality**
   - Should call GET `/accounts/month-end-check` endpoint
   - Should return month-end check data with correct structure

2. **Happy Path**
   - Returns object with hdfc_reserve, total_net_worth, and accounts list
   - Each account contains id, name, expected_balance

3. **Edge Cases**
   - Handles zero hdfc_reserve (0.0)
   - Handles negative hdfc_reserve (overdraft scenarios like -500.0)
   - Handles large numbers in total_net_worth (9999999.99)
   - Preserves decimal precision

4. **Error Handling**
   - Throws exception on network errors
   - Throws exception on 401 unauthorized
   - Throws exception on 500 server error

**Expected Month-End Check Structure:**
```json
{
  "hdfc_reserve": 1000.0,
  "total_net_worth": 50000.0,
  "accounts": [
    {
      "id": "acc_1",
      "name": "Checking",
      "expected_balance": 5000.0
    }
  ]
}
```

---

### 2. Business Layer: `test/features/accounts/business/accounts_provider_test.dart`

**Purpose:** State management tests for the AccountsProvider using ChangeNotifier + Provider pattern

**Mock Setup:**
- `MockAccountsApi`: Mocks the data layer API calls

**State Properties to Manage:**
- `accounts`: List<Map<String, dynamic>> - loaded accounts
- `monthEndCheck`: Map<String, dynamic>? - month-end check data
- `isLoading`: bool - loading state during API calls
- `errorMessage`: String? - error message when operations fail

**Test Groups:**

#### Initialization Tests

1. Accounts list initialized as empty
2. isLoading initialized as false
3. errorMessage initialized as null
4. monthEndCheck initialized as null

#### `load()` Method Tests

1. **Happy Path**
   - Successfully loads both accounts and month-end check data
   - Sets accounts list with returned data
   - Sets monthEndCheck with returned data
   - Clears errorMessage on success
   - Sets isLoading to false after completion
   - Calls notifyListeners()

2. **State Transitions**
   - Sets isLoading to true at start of load
   - Sets isLoading to false at end of load (success or failure)
   - Clears errorMessage on successful load

3. **Error Scenarios**
   - Handles getAccounts() failure gracefully
   - Handles getMonthEndCheck() failure gracefully
   - Sets errorMessage when errors occur
   - Keeps accounts list empty on error
   - Calls notifyListeners() even on failure

4. **Edge Cases**
   - Handles empty accounts list
   - Handles concurrent load() calls gracefully
   - Calls both getAccounts() and getMonthEndCheck()

5. **Data Preservation**
   - Preserves data across multiple loads
   - Fully replaces accounts on each load

#### Error Handling Tests

1. Network timeout errors
2. Unauthorized (401) errors
3. Server (500) errors
4. Invalid response data handling

---

### 3. Presentation Layer: `test/features/accounts/presentation/month_end_check_page_test.dart`

**Purpose:** Widget tests for the MonthEndCheckPage displaying month-end account summary

**Mock Setup:**
- `MockAccountsProvider`: Mocks the business logic provider with:
  - `accounts`: Test data list
  - `monthEndCheck`: Test summary data
  - `isLoading`: Loading state
  - `errorMessage`: Error display state
  - `load()`: Async method to reload data

**Test Groups:**

#### UI Elements Tests

1. **Layout & Display**
   - Page displays title (e.g., "Month End Check")
   - HDFC reserve amount displayed with label
   - Total net worth amount displayed with label
   - List of accounts displayed

2. **Account Display**
   - Each account name displayed
   - Each account's expected_balance amount displayed
   - All accounts in the list rendered

3. **Currency Formatting**
   - Amounts formatted with thousand separators (1,234.56)
   - Amounts shown with 2 decimal places
   - Values like 1234.56 → "1,234.56", 50000.00 → "50,000.00"

4. **Loading State**
   - CircularProgressIndicator shown when isLoading is true
   - No loading indicator when isLoading is false
   - Page responsive during loading

5. **Error State**
   - Error message displayed when errorMessage is set
   - No error message when errorMessage is null

#### Data Rendering Tests

1. **Accuracy**
   - All account data rendered correctly
   - Multiple accounts (2, 3+) all displayed
   - HDFC reserve shows correct value
   - Total net worth shows correct value

2. **Precision**
   - Decimal precision preserved in display
   - 1234.56 not truncated to 1234.5
   - 50000.99 not rounded to 50001

3. **Special Values**
   - Zero balances displayed correctly (0.00)
   - Negative balances displayed correctly (-500.0)
   - Large numbers formatted with separators
   - Edge case values preserved

#### Interaction Tests

1. **Initialization**
   - load() called on page initialization
   - Data fetched when page first appears

2. **Refresh Functionality**
   - Refresh button available (IconButton or RefreshIndicator)
   - load() called when refresh is triggered
   - UI updates after refresh completes

#### State Transitions Tests

1. Updates when isLoading changes
2. Updates when errorMessage changes
3. Updates when monthEndCheck data changes
4. Updates when accounts list changes

#### Error Handling Tests

1. **Error Messages Display**
   - Network error message displayed
   - Authorization error message displayed
   - Server error message displayed

2. **Error Recovery**
   - Retry button/functionality available on error
   - load() called when retry is triggered
   - Data reloaded successfully after retry

---

## Testing Patterns Used

### Mock Setup Pattern

```dart
class MockAccountsApi extends Mock {
  Future<List<Map<String, dynamic>>> getAccounts() => Future.value([]);
  Future<Map<String, dynamic>> getMonthEndCheck() => Future.value({});
}
```

### When/Then Pattern for Mocking

```dart
when(() => mockApi.method()).thenAnswer((_) async => data);
when(() => mockApi.method()).thenThrow(Exception('error'));
```

### Widget Test Wrapper Pattern

```dart
Widget createWidgetUnderTest() {
  return MaterialApp(
    home: ChangeNotifierProvider<Provider>.value(
      value: mockProvider,
      child: const PageUnderTest(),
    ),
  );
}
```

### Verification Pattern

```dart
verify(() => mockApi.method()).called(1);
verify(() => mockApi.method()).called(atLeast(1));
```

---

## Implementation Guidelines

When implementing the actual feature, follow these contracts:

### AccountsApi Implementation

The data layer should:
- Inject Dio via constructor
- Call `ApiClient.dio` to get configured Dio instance
- Handle HTTP errors and throw appropriate exceptions
- Parse response data into expected structures
- Return Future-based async methods

### AccountsProvider Implementation

The business logic should:
- Extend ChangeNotifier from provider package
- Inject AccountsApi via constructor
- Implement all state properties (accounts, monthEndCheck, isLoading, errorMessage)
- Implement load() method that:
  - Sets isLoading = true at start
  - Clears errorMessage before loading
  - Calls both API methods
  - Updates state with returned data
  - Sets isLoading = false
  - Calls notifyListeners() after state changes
  - Catches exceptions and sets errorMessage

### MonthEndCheckPage Implementation

The presentation layer should:
- Consume AccountsProvider with context.watch()
- Call provider.load() in initState or lifecycle hook
- Display loading indicator when isLoading is true
- Display error message when errorMessage is not null
- Display formatted account data when available
- Format currency values with thousand separators
- Provide refresh button to reload data
- Update UI reactively as provider state changes

---

## Dependencies

All tests use existing project dependencies:
- `flutter_test` - Flutter test framework
- `mocktail` - Mocking library (>= 1.0.0)
- `provider` - State management (>= 6.1.2)
- `dio` - HTTP client (>= 5.9.0)

---

## File Locations

Test files created:
- `/frontend/test/features/accounts/data/accounts_api_test.dart`
- `/frontend/test/features/accounts/business/accounts_provider_test.dart`
- `/frontend/test/features/accounts/presentation/month_end_check_page_test.dart`

Implementation files to create:
- `/frontend/lib/features/accounts/data/accounts_api.dart`
- `/frontend/lib/features/accounts/business/accounts_provider.dart`
- `/frontend/lib/features/accounts/presentation/month_end_check_page.dart`

---

## Next Steps

1. Implement AccountsApi following the test contracts
2. Implement AccountsProvider following the test contracts
3. Implement MonthEndCheckPage following the test contracts
4. Run all tests: `flutter test test/features/accounts/`
5. Verify all tests pass
6. Wire MonthEndCheckPage route into app_router.dart
7. Integration testing with actual backend

---

## Test Execution

To run all accounts feature tests:

```bash
cd frontend
flutter test test/features/accounts/
```

To run specific test file:

```bash
flutter test test/features/accounts/data/accounts_api_test.dart
flutter test test/features/accounts/business/accounts_provider_test.dart
flutter test test/features/accounts/presentation/month_end_check_page_test.dart
```

To run with coverage:

```bash
flutter test --coverage test/features/accounts/
```

---

## Summary

This TDD phase established 60+ comprehensive test cases covering:
- 17 tests for AccountsApi data layer
- 30+ tests for AccountsProvider business logic
- 40+ tests for MonthEndCheckPage widget

The tests define clear contracts for:
- API request/response handling
- State management and transitions
- UI rendering and interactions
- Error handling and recovery
- Data formatting and precision

All tests follow the existing project patterns and use the established testing infrastructure (mocktail, provider, flutter_test).
