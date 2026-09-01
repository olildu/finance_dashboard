# Phase 1: Categories Frontend Tests

## Summary

This document describes the test-driven development (TDD) phase for the categories feature in the finance dashboard frontend. The tests define the contract that the implementation must satisfy, covering both the API data layer and the business logic (state management) layer.

## Architecture Overview

The categories feature follows the established feature-sliced architecture:

```
frontend/lib/features/categories/
├── data/
│   └── categories_api.dart         (to be implemented)
├── business/
│   └── categories_provider.dart    (to be implemented)
└── presentation/
    └── (pages/widgets - not covered in this phase)
```

The tests are located in:

```
frontend/test/features/categories/
├── data/
│   └── categories_api_test.dart     (API contract tests)
└── business/
    └── categories_provider_test.dart (Provider contract tests)
```

## Test Structure

### 1. CategoriesApi Tests (`categories_api_test.dart`)

**Purpose**: Define the contract for the data layer API client.

**Key Responsibilities**:
- Call the backend GET `/categories` endpoint
- Parse the response as a list of category objects
- Include envelope information with each category (allocated, spent, remaining)
- Handle various HTTP status codes and network errors

**Test Groups**:

#### getCategories()

The main method that fetches categories from the backend.

**Happy Path Tests**:
- `should call GET /categories endpoint`: Verifies the correct endpoint is called
- `should return list of categories with correct structure`: Validates response structure with id, name, color, icon, and envelope data
- `should return empty list when no categories exist`: Handles empty responses
- `should handle single category in response`: Works with single-item lists
- `should preserve envelope data with category`: Full envelope info (allocated, spent, remaining) is maintained

**Edge Cases**:
- `should handle categories with zero envelope balance`: Spent = 0
- `should handle categories with spent exceeding allocation`: Overspent envelopes
- `should parse numeric values correctly`: Decimal precision (1234.56 stays as 1234.56, not 1234 or 1235)
- `should handle categories with null envelope gracefully`: Envelope can be null
- `should handle large number of categories`: Efficient parsing of 50+ categories
- `should handle response parsing with extra fields`: Ignores metadata, descriptions, timestamps

**Network/Error Tests**:
- `should throw exception on network error`: Connection timeout
- `should throw exception on 401 unauthorized`: Auth failure
- `should throw exception on 403 forbidden`: Permission denied
- `should throw exception on 500 server error`: Server error
- `should throw exception on 503 service unavailable`: Service down

**Concurrency**:
- `should handle concurrent getCategories calls`: Multiple simultaneous requests work correctly

**Expected Category Response Structure**:
```dart
{
  'id': 'cat_1',
  'name': 'Food & Dining',
  'color': '#FF5722',
  'icon': 'restaurant',
  'envelope': {
    'id': 'env_1',
    'name': 'Monthly Food Budget',
    'allocated': 5000.0,
    'spent': 2500.0,
    'remaining': 2500.0,  // optional
  },
}
```

### 2. CategoriesProvider Tests (`categories_provider_test.dart`)

**Purpose**: Define the contract for the business logic layer (state management).

**Key Responsibilities**:
- Manage categories state (list, loading status, errors)
- Cache fetched categories to avoid redundant API calls
- Implement lazy loading: API only called when `load()` is explicitly invoked
- Support force refresh to bypass cache
- Extend ChangeNotifier for reactive updates
- Expose cached categories for use by transactions and budget features

**Test Groups**:

#### Initialization

- `should initialize with empty categories list`: Start with []
- `should initialize isLoading as false`: Not loading on creation
- `should initialize errorMessage as null`: No error on creation
- `should not call API on initialization`: Lazy loading - no API call until load() is invoked

#### load()

Standard data loading with error handling.

**Happy Path**:
- `should successfully load categories`: Complete flow with notification
- `should set isLoading to true during load`: Proper loading state management
- `should clear error message on successful load`: Error cleared on success
- `should populate categories list on successful load`: Categories populated with full data
- `should handle empty categories list`: Works when API returns []
- `should notify listeners on successful load`: ChangeNotifier pattern

**Error Handling**:
- `should set errorMessage and keep isLoading false on API failure`: Graceful failure
- `should handle network timeout errors gracefully`: Connection errors
- `should handle 401 unauthorized errors`: Auth failures
- `should handle server (500) errors gracefully`: Server issues
- `should handle null response data gracefully`: Malformed responses
- `should notify listeners on load failure`: Notify even on failure

**State Management**:
- `should set isLoading to false on load completion`: Cleanup after load

#### Caching Behavior (Critical)

This is the most important test group - categories cache must be reusable by other features.

**Caching Contract**:
- `should cache categories and not call API twice on consecutive loads`: Calling `load()` twice only calls API once
  - First `load()` → API call (hits backend)
  - Second `load()` → no API call (returns cached data)
  - Verify: `mockCategoriesApi.getCategories()` called exactly once

- `should return cached categories on second load without API call`: Explicit cache verification
  - Cache is returned with original data intact

- `should use cache across multiple sequential loads`: Three `load()` calls → API called once

**Force Refresh**:
- `should bypass cache when forceRefresh is true`: Calling `load(forceRefresh: true)` forces API call
  - First `load()` → API call
  - Second `load(forceRefresh: true)` → API call (force)
  - Verify: API called twice

- `should refetch data when forceRefresh is true`: Updated data replaces cached data
  - First load returns v1 data
  - Second load with forceRefresh returns v2 data
  - Categories updated to v2

**Cache Edge Cases**:
- `should cache empty categories list`: Empty list is cached (don't retry on empty)
- `should not cache data when load fails`: Failed load doesn't cache (retry on next load)
- `should not cache categories when API returns null`: Invalid data not cached

**Cache Performance**:
- `should handle cache with large category lists`: 100+ categories cached efficiently

#### State Management

Cross-feature concerns for cache reusability.

- `should maintain categories across multiple operations`: Cached state available for transactions/budgets features
- `should clear error on successful retry after failure`: Proper error recovery
- `should preserve envelope info in cached categories`: Envelope data survives caching for other features
  - Contains: id, name, allocated, spent, remaining, account_id
- `should handle error message updates correctly`: Error state transitions

#### Concurrent Operations

Thread-safety and race condition handling.

- `should handle concurrent load calls gracefully`: Multiple simultaneous `load()` calls
- `should handle load and forceRefresh concurrently`: Mix of cached and refresh calls

#### Provider Integration

Integration with the provider package and UI consumption.

- `should expose categories getter for other features`: Public `categories` property readable by transactions/budget providers
- `should expose load method for manual refresh`: Public `load()` method callable by UI
- `should work with ChangeNotifier provider pattern`: Extends ChangeNotifier, calls notifyListeners()

## Expected Implementation Contracts

### CategoriesApi

**Location**: `frontend/lib/features/categories/data/categories_api.dart`

**Class Signature**:
```dart
class CategoriesApi {
  final ApiClient _apiClient;
  
  CategoriesApi(this._apiClient);
  
  /// Fetches all categories from the backend.
  /// Returns a list of categories with envelope information.
  /// Throws DioException on network/server errors.
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _apiClient.dio.get('/categories');
    return List<Map<String, dynamic>>.from(response.data as List);
  }
}
```

**Key Points**:
- Uses injected ApiClient (with JWT + 401-refresh interceptor)
- Calls GET `/categories`
- Returns raw response data as list of maps
- Does NOT cache (caching is provider's responsibility)
- Lets DioException propagate to caller

### CategoriesProvider

**Location**: `frontend/lib/features/categories/business/categories_provider.dart`

**Class Signature**:
```dart
class CategoriesProvider extends ChangeNotifier {
  final CategoriesApi _api;
  
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  CategoriesProvider(this._api);
  
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  /// Load categories from API with optional force refresh.
  /// First call fetches from API and caches.
  /// Subsequent calls return cached data unless forceRefresh is true.
  /// forceRefresh = true bypasses cache and refetches from API.
  Future<void> load({bool forceRefresh = false}) async {
    // If already cached and not forcing refresh, return cached data
    if (_categories.isNotEmpty && !forceRefresh) {
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _categories = await _api.getCategories();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

**Key Implementation Details**:

1. **Lazy Loading**: No API call until `load()` is invoked
2. **Caching Logic**:
   - If `_categories` is not empty and `forceRefresh` is false → return (use cache)
   - Otherwise → make API call
3. **State Management**:
   - `_isLoading`: true during API call, false when done
   - `_errorMessage`: Set on error, cleared on success
   - `_categories`: Replaced with new data on successful load
4. **Notification**:
   - Call `notifyListeners()` before and after API call
   - Call `notifyListeners()` even on errors
5. **Error Handling**:
   - Catch any exception from API
   - Set `_errorMessage` with exception details
   - Clear categories on error (don't leave stale data)
6. **Cache Reusability**:
   - Envelope information is preserved in cached categories
   - Other features (transactions, budgets) read from this cache
   - Data integrity maintained across feature boundaries

## Testing Patterns Used

### 1. Mocking Pattern

Following the project's mocktail conventions:

```dart
class MockDio extends Mock implements Dio {}
class MockCategoriesApi extends Mock {
  Future<List<Map<String, dynamic>>> getCategories() => Future.value([]);
}
```

### 2. Arrange-Act-Assert (AAA) Pattern

All tests follow standard AAA structure:

```dart
test('description', () async {
  // Arrange: Set up mocks and test data
  when(() => mockApi.method()).thenAnswer((_) async => data);
  
  // Act: Execute the code under test
  await provider.load();
  
  // Assert: Verify expected behavior
  expect(provider.categories, equals(expectedData));
});
```

### 3. ChangeNotifier Testing

Provider tests don't require Flutter widget testing:

```dart
// setUp creates a new provider instance for each test
setUp(() {
  mockApi = MockCategoriesApi();
  provider = CategoriesProvider(mockApi);
});

// Tests verify public getters and public methods
test('should populate categories on load', () async {
  when(() => mockApi.getCategories()).thenAnswer((_) async => data);
  
  await provider.load();
  
  expect(provider.categories, isNotEmpty);
});
```

## Data Flow Diagram

```
UI / Other Features
    ↓
CategoriesProvider (state management)
    ├─ categories: List<Map> (cached)
    ├─ isLoading: bool
    ├─ errorMessage: String?
    └─ load({forceRefresh}): Future<void>
    ↓
CategoriesApi (API layer)
    ├─ getCategories(): Future<List<Map>>
    ↓
    → GET /categories (backend)
    ↓
    ← Response: [{id, name, color, icon, envelope: {...}}, ...]
```

## Cache Lifecycle Example

```
State: Empty cache

(1) await provider.load()
    → Calls API: GET /categories
    ← Response: [cat_1, cat_2, cat_3]
    → Cache: [cat_1, cat_2, cat_3]
    → isLoading: false, errorMessage: null

(2) await provider.load()
    → Cache exists and forceRefresh=false
    → Skip API call, return cached data
    → NO API call

(3) await provider.load(forceRefresh: true)
    → forceRefresh=true, bypass cache
    → Calls API: GET /categories
    ← Response: [cat_1, cat_2, cat_3, cat_4] (updated)
    → Cache: [cat_1, cat_2, cat_3, cat_4]

(4) await provider.load()
    → Cache exists with 4 items
    → Skip API call, return cached data
    → NO API call
```

## Cross-Feature Cache Usage

The categories cache includes envelope information and is designed to be consumed by other features:

### Transactions Feature

```dart
class TransactionsProvider extends ChangeNotifier {
  final CategoriesProvider categoriesProvider;
  
  Future<void> createTransaction(transactionData) async {
    // Read from cached categories
    final categories = categoriesProvider.categories;
    final category = categories.firstWhere((c) => c['id'] == transactionData.categoryId);
    final envelope = category['envelope'];
    
    // Use envelope info to validate transaction
    if (envelope != null) {
      final spent = envelope['spent'];
      final allocated = envelope['allocated'];
      // Validate transaction against budget
    }
  }
}
```

### Budgets Feature

```dart
class BudgetsProvider extends ChangeNotifier {
  final CategoriesProvider categoriesProvider;
  
  Map<String, dynamic> getBudgetSummary() {
    final categories = categoriesProvider.categories;
    
    // Aggregate envelope data across categories
    final totalAllocated = categories
        .map((c) => (c['envelope'] as Map?)['allocated'] as double? ?? 0)
        .fold(0.0, (sum, a) => sum + a);
    
    return {'total_allocated': totalAllocated};
  }
}
```

## Running the Tests

From the `frontend` directory:

```bash
# Run all categories tests
flutter test test/features/categories/

# Run only API tests
flutter test test/features/categories/data/

# Run only provider tests
flutter test test/features/categories/business/

# Run with verbose output
flutter test test/features/categories/ -v

# Run specific test
flutter test test/features/categories/business/categories_provider_test.dart \
  -k "should cache categories and not call API twice"
```

## Implementation Checklist

When implementing the feature, ensure:

- [ ] CategoriesApi created with getCategories() method
- [ ] CategoriesProvider extends ChangeNotifier
- [ ] Lazy loading: no API call until load() invoked
- [ ] Caching: second load() uses cache, no API call
- [ ] Force refresh: load(forceRefresh: true) bypasses cache
- [ ] Error handling: set errorMessage and clear categories on error
- [ ] State management: isLoading and errorMessage updated correctly
- [ ] Notification: notifyListeners() called on state changes
- [ ] Envelope preservation: cached categories retain full envelope data
- [ ] All tests passing: `flutter test test/features/categories/`

## Notes on Test Design

1. **No Implementation Code**: Tests define the contract only; implementation comes next
2. **TDD Approach**: Tests drive the implementation design
3. **Mocking Strategy**: Mock only the data layer (CategoriesApi); test providers with mocked API
4. **Cache Centrality**: Caching is a core concern - extensive tests ensure it works correctly
5. **Reusability**: Cache includes envelope data so transactions/budgets can read it without making their own API calls
6. **Error Recovery**: Caching doesn't prevent retries on errors - only successful loads are cached

## Related Documentation

- Backend Categories API: `docs/api/categories.md`
- Feature-Sliced Architecture: `docs/architecture.md`
- Provider Pattern Guide: `docs/state-management.md`
- Test Conventions: `docs/testing.md`
