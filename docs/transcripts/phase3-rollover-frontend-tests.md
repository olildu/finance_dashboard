# Phase 3: Rollover Feature - Frontend Tests

**Date:** 2026-09-01  
**Task:** Create real Flutter tests for the rollover feature frontend  
**Status:** Complete

## Overview

The rollover feature is primarily backend-driven (APScheduler cron), but a small frontend surface was created to support manual triggering for debugging and testing. This transcript documents the creation of stub files and comprehensive test suites for:

1. `RolloverApi` - Data layer for API communication
2. `RolloverProvider` - Business logic layer for state management

The frontend surface is intentionally minimal since rollover is fundamentally a background job, not a user-facing UI feature.

## Stub Files Created

### 1. Data Layer: RolloverApi
**File:** `/Users/ebinsanthosh/Documents/GitHub/Personal/finance_dashboard/frontend/lib/features/rollover/data/rollover_api.dart`

```dart
class RolloverApi {
  final Dio dio;

  RolloverApi(this.dio);

  /// Trigger a manual rollover check on the server
  /// Returns: {'status': string, 'message': string}
  /// Throws: Exception on failure
  Future<Map<String, dynamic>> triggerCheck() async { ... }
}
```

**Responsibility:**
- Calls `POST /rollover/run-check` endpoint
- Returns response data (status, message)
- Propagates exceptions to caller

**Design Notes:**
- Uses Dio for HTTP communication
- Minimal method surface - only one endpoint needed
- Auth handled by Dio interceptors at app level

### 2. Business Logic: RolloverProvider
**File:** `/Users/ebinsanthosh/Documents/GitHub/Personal/finance_dashboard/frontend/lib/features/rollover/business/rollover_provider.dart`

```dart
class RolloverProvider extends ChangeNotifier {
  final RolloverApi _rolloverApi;

  bool _isLoading = false;
  String? _errorMessage = null;
  Map<String, dynamic>? _lastResult = null;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get lastResult => _lastResult;

  Future<void> trigger() async { ... }
}
```

**Responsibility:**
- State management for manual trigger operations
- Loading state tracking (isLoading)
- Error tracking (errorMessage)
- Result caching (lastResult)
- Request coalescing - concurrent calls await same Future

**Design Decisions:**

1. **Request Coalescing:** If `trigger()` is called while one is already in progress, new calls await the same Future. This prevents duplicate API requests during rapid user interactions.

2. **State Clearing:** The `_inFlightFuture` is cleared in a `finally` block, even when `_performTrigger()` throws. This ensures subsequent calls don't return a stale failed Future.

3. **Result Preservation:** On failure, `lastResult` is not cleared - it retains the previous successful result. This allows UI to show "last known state" when an error occurs.

4. **Error Message:** Overwritten on each trigger attempt. New successful trigger clears it; new failure sets it.

## Test Suites

### 1. RolloverApi Tests
**File:** `/Users/ebinsanthosh/Documents/GitHub/Personal/finance_dashboard/frontend/test/features/rollover/data/rollover_api_test.dart`

**Test Count:** 11 tests, all passing

**Coverage:**
- ✓ Correct endpoint (`POST /rollover/run-check`)
- ✓ Response parsing (status, message fields)
- ✓ Additional response fields handling
- ✓ Empty/edge case messages
- ✓ Auth errors (401, 403)
- ✓ Network errors (timeout, connection refused)
- ✓ Server errors (500)

**Key Test Examples:**

```dart
test('should return status from response', () async {
  // Verifies status field is correctly extracted from response
  final result = await rolloverApi.triggerCheck();
  expect(result['status'], equals(expectedStatus));
});

test('should throw exception on network error', () async {
  // Verifies network errors propagate
  expect(
    () => rolloverApi.triggerCheck(),
    throwsA(isA<DioException>()),
  );
});

test('should handle success response with additional fields', () async {
  // Verifies robustness when backend adds extra fields
  final result = await rolloverApi.triggerCheck();
  expect(result.containsKey('months_processed'), true);
  expect(result['months_processed'], equals(2));
});
```

### 2. RolloverProvider Tests
**File:** `/Users/ebinsanthosh/Documents/GitHub/Personal/finance_dashboard/frontend/test/features/rollover/business/rollover_provider_test.dart`

**Test Count:** 23 tests, all passing

**Test Groups:**

#### Initialization (4 tests)
- ✓ Starts with isLoading = false
- ✓ Starts with errorMessage = null
- ✓ Starts with lastResult = null
- ✓ No pending trigger on init

#### Trigger Operations (14 tests)
- ✓ Calls triggerCheck() API method
- ✓ Sets isLoading = true during trigger
- ✓ Sets isLoading = false after trigger
- ✓ Stores result in lastResult
- ✓ Clears errorMessage on success
- ✓ Sets errorMessage on failure
- ✓ Maintains lastResult on failure
- ✓ Handles server errors (500)
- ✓ Rethrows API exceptions
- ✓ **Coalesces concurrent triggers** (calls API only once)
- ✓ Handles concurrent triggers on failure
- ✓ Allows new trigger after previous completes

#### State Transitions (3 tests)
- ✓ Loading → Loaded
- ✓ Loaded → Error (on failure)
- ✓ Error → Success (retry succeeds)

#### Notification Behavior (2 tests)
- ✓ Notifies listeners when trigger starts
- ✓ Notifies listeners on error

**Key Test Examples:**

```dart
test('should handle multiple concurrent triggers', () async {
  // Verifies request coalescing - API called only once
  // even though trigger() is called 3 times concurrently
  await Future.wait([
    provider.trigger(),
    provider.trigger(),
    provider.trigger(),
  ]);

  // API should be called only once due to coalescing
  verify(() => mockRolloverApi.triggerCheck()).called(1);
  expect(provider.lastResult, equals(response));
});

test('should transition from error to success on retry', () async {
  // Verifies error recovery path
  // First trigger fails
  try { await provider.trigger(); } catch (_) {}
  expect(provider.errorMessage, isNotNull);

  // Setup success response
  when(() => mockRolloverApi.triggerCheck()).thenAnswer(...);

  // Retry succeeds
  await provider.trigger();
  expect(provider.errorMessage, isNull);
  expect(provider.lastResult, isNotNull);
});

test('should maintain previous lastResult on trigger failure', () async {
  // Verifies we preserve last known state when error occurs
  // First trigger succeeds
  await provider.trigger();
  final previousResult = provider.lastResult;

  // Second trigger fails
  when(() => mockRolloverApi.triggerCheck()).thenThrow(...);
  try { await provider.trigger(); } catch (_) {}

  // lastResult should still have previous success
  expect(provider.lastResult, equals(previousResult));
});
```

## Test Statistics

| Category | Count | Status |
|----------|-------|--------|
| RolloverApi tests | 11 | ✓ All passing |
| RolloverProvider tests | 23 | ✓ All passing |
| **Total tests** | **34** | **✓ All passing** |

**Runtime:**
- API tests: ~778ms
- Provider tests: ~1,129ms
- Total: ~1.9 seconds

## Design Rationale

### Why Minimal Frontend?
Rollover is fundamentally a background job orchestrated by the backend cron scheduler. The only reason for a frontend component is:
1. **Manual trigger for testing** - Developers can manually kick off a rollover check
2. **Status visibility** - Show if a trigger is in progress, any errors
3. **Debugging** - Quick manual retry capability

A full UI (showing month states, rollover progress, etc.) would be over-engineering since the real work happens automatically in the scheduler.

### Request Coalescing Pattern
The provider implements request coalescing following the credit_provider pattern:
- Concurrent calls to `trigger()` while one is in progress return the same Future
- Prevents duplicate API requests during rapid interactions
- Essential for manual trigger button - user might click multiple times

### Error Handling Philosophy
- **API errors propagate** - Caller can handle/display errors
- **lastResult preserved on error** - UI can show "last known state" with error message
- **errorMessage cleared on success** - Clean state after recovery
- **Exception rethrown** - Allows caller-specific error handling

## Integration Points

### How This Connects to Backend
```
Frontend (RolloverProvider.trigger())
  ↓
POST /rollover/run-check (requires auth)
  ↓
Backend (RolloverRouter.run_check())
  ↓
RolloverEngine.execute_check()
  ↓
Database updates (month states, credit settlement, envelope sweeps)
```

The backend router ensures:
1. User is authenticated
2. Validates request format
3. Returns `{'status': str, 'message': str}` response

### How This Connects to Scheduler
The manual trigger (`/rollover/run-check`) runs the same logic as the hourly scheduler, but on-demand. Both use `RolloverEngine.execute_check()`.

## Files Created Summary

```
frontend/
├── lib/
│   └── features/
│       └── rollover/
│           ├── __init__.dart
│           ├── data/
│           │   └── rollover_api.dart (19 lines)
│           └── business/
│               └── rollover_provider.dart (60 lines)
└── test/
    └── features/
        └── rollover/
            ├── data/
            │   └── rollover_api_test.dart (223 lines)
            └── business/
                └── rollover_provider_test.dart (316 lines)
```

**Code Metrics:**
- Stub files: 79 lines of production code
- Test files: 539 lines of test code
- Test-to-code ratio: 6.8:1 (high coverage)

## Next Steps

When backend stub implementation is completed, these tests will:
1. Run against real backend endpoints
2. Verify API contract matches (response format)
3. Test integration with authentication/authorization
4. Validate error scenarios from actual server

For now, tests use mocks to ensure:
- Data layer correctly formats requests
- Business layer manages state correctly
- Error handling is robust
- Concurrent request handling works

## Verification

All tests run successfully:
```bash
cd frontend
fvm flutter test test/features/rollover/

# API tests
fvm flutter test test/features/rollover/data/rollover_api_test.dart -v
# ✓ 11 tests passed

# Provider tests  
fvm flutter test test/features/rollover/business/rollover_provider_test.dart -v
# ✓ 23 tests passed
```

## Related Documentation

- Backend stub implementation: `/docs/transcripts/phase3-rollover-stubs.md`
- Rollover algorithm design: Documented in backend `RolloverEngine` class docstring
- Feature architecture: Follows same pattern as `credit` feature
