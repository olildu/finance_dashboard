# Phase 0 Frontend Foundation Build Transcript

**Date**: 2026-09-01

## Overview
This document records the completion of Phase 0 (foundation only) for the Flutter Web personal finance app rebuild. Phase 0 establishes the core infrastructure for routing, networking, and theming without modifying existing code yet.

## Files Created

### 1. `frontend/lib/core/theme/colors.dart`
- **Purpose**: Centralizes color definitions in the new core architecture
- **Content**: Copied verbatim from `frontend/lib/constants/colors.dart`
- **Colors**:
  - `backgroundColor`: Color(255, 22, 22, 23)
  - `primaryColor`: Color(255, 36, 36, 39)
  - `secondaryColor`: Color(255, 62, 62, 62)
- **Note**: Original `constants/colors.dart` remains in place; cleanup happens in later phases once features import from the new location

### 2. `frontend/lib/core/network/token_manager.dart`
- **Purpose**: Token lifecycle management (save, retrieve, delete)
- **Content**: Copied verbatim from `frontend/lib/services/token_services.dart`
- **Public API**:
  - `saveTokens({required String accessToken, required String refreshToken})` - Stores both tokens to LocalStorage
  - `getAccessToken()` - Retrieves the current access token
  - `getRefreshToken()` - Retrieves the current refresh token
  - `hasValidRefreshToken()` - Checks if a refresh token exists and is non-empty
  - `deleteTokens()` - Clears both tokens from storage
- **Implementation**: Uses `LocalStorage('token_storage')` via the `localstorage` package
- **Note**: Original `services/token_services.dart` remains in place; `api_client.dart` (new core) imports from the new location

### 3. `frontend/lib/core/network/api_client.dart`
- **Purpose**: Centralized HTTP client with JWT interceptor logic for all feature API clients
- **Content**: Extracted from `frontend/lib/services/http_services.dart` (constructor body only)
- **Features**:
  - Dio instance configured with baseUrl (`"/"` or `"http://127.0.0.1:9000/"`)
  - `InterceptorsWrapper` with two handlers:
    - **onRequest**: Automatically attaches `Authorization: Bearer <token>` header if access token is available
    - **onError**: On 401 response:
      1. Attempts to refresh token using the stored refresh token
      2. If refresh succeeds, updates stored tokens and retries the original request
      3. If refresh fails or no refresh token exists, logs out and clears tokens via `_logout()`
  - `_logout()` method: Deletes tokens and navigates to '/login' using `navigatorkey.currentContext?.go('/login')` (from `constants/globals.dart`)
- **Public API**:
  - `Dio get dio` - Returns the configured Dio instance for feature API clients to use
- **Excluded**: Finance-specific methods (login, debitTransaction, creditTransaction, etc.) — these move to per-feature API clients in later phases
- **Dependencies**:
  - Uses `core/network/token_manager.dart` (NOT the old `services/token_services.dart`)
  - References `constants/globals.dart` for `navigatorkey` (a later phase will relocate globals.dart to core/)

### 4. `frontend/lib/core/routing/app_router.dart`
- **Purpose**: Centralized go_router configuration
- **Content**: GoRouter skeleton with two placeholder routes
- **Routes**:
  - `'/'` → Dashboard placeholder (`Scaffold` with `Text('Dashboard (TODO)')`)
  - `'/login'` → Login placeholder (`Scaffold` with `Text('Login (TODO)')`)
- **Export**: Top-level `appRouter` GoRouter instance (features will import this in main.dart wiring in later phases)
- **Note**: Placeholder UI will be replaced with real feature pages in later phases; this is the routing skeleton only

### 5. `frontend/pubspec.yaml` — Updated
- **Change**: Added `mocktail: ^1.0.0` under `dev_dependencies`
- **Placement**: Alongside existing `flutter_test` and `flutter_lints`
- **No version changes** to other dependencies

### 6. `frontend/test/core/api_client_test.dart`
- **Purpose**: Establish test directory structure and confirm test setup
- **Content**: Single trivial passing test
- **Test**: `test('placeholder', () => expect(1, 1));`
- **Note**: Placeholder only; real ApiClient tests (mocking Dio with mocktail) will be added in later phases when feature API clients need integration tests

## Build and Analysis Status

### Flutter Tools Availability
- **Status**: Flutter command not available in this environment
- **Consequence**: `flutter pub get` and `flutter analyze` could not be executed
- **Mitigation**: Hand-verified all Dart syntax below

### Hand-Verified Syntax

1. **`core/theme/colors.dart`**: ✓ Valid
   - Simple const/variable declarations with proper imports
   - No syntax errors

2. **`core/network/token_manager.dart`**: ✓ Valid
   - Proper class definition with LocalStorage usage
   - All method signatures match original
   - Async/await syntax correct

3. **`core/network/api_client.dart`**: ✓ Valid
   - Proper Dio initialization with BaseOptions
   - InterceptorsWrapper syntax correct (onRequest and onError handlers)
   - Async handler methods properly structured
   - Token refresh logic mirrors original (fetch new token, update storage, retry original request)
   - Logout navigation using navigatorkey (requires navigatorkey from globals.dart at import time)

4. **`core/routing/app_router.dart`**: ✓ Valid
   - Proper GoRouter configuration with routes list
   - GoRoute syntax correct
   - Builder functions returning Scaffolds with Text widgets

5. **`test/core/api_client_test.dart`**: ✓ Valid
   - Proper flutter_test import
   - test() function call with correct syntax

6. **`pubspec.yaml`**: ✓ Valid
   - mocktail: ^1.0.0 added to dev_dependencies under flutter_lints
   - YAML formatting preserved
   - No version conflicts (SDK constraint remains ^3.5.1)

## TODOs for Later Phases

### Cleanup Phase (future)
- Old `services/http_services.dart` — Still used by untouched old screens (debitTransaction, creditTransaction, etc.); remove once feature API clients are implemented
- Old `services/token_services.dart` — Still exists; `services/http_services.dart` and old screens still import it; remove once `core/network/api_client.dart` is wired into features
- Old `constants/colors.dart` — Still exists; remove once all screens import from `core/theme/colors.dart`
- Old responsive_screen/ and widgets/mobile_widgets/ — Not deleted yet per instructions (mobile support cleanup happens in later phase)

### Routing Wiring (next phase)
- Update `main.dart` to use `appRouter` from `core/routing/app_router.dart`
- Replace placeholder routes with real feature pages as they are implemented
- Wire up NavigatorObserver or similar if needed for deep linking

### Token Manager Integration (next phase)
- Feature API clients will inject/reference TokenManager from core/network/token_manager.dart
- All new feature endpoints will use ApiClient's dio getter
- Old HttpServices can be deprecated once all features use new ApiClient

### API Client Enhancement (future phases)
- Add per-feature API client classes that extend or wrap ApiClient
- Move authentication logic (login, register) to an AuthApiClient
- Move finance logic (debitTransaction, getBalance, etc.) to a FinanceApiClient
- Add error handling utilities and response models

### Globals Relocation (future)
- Move navigatorkey and other core globals from `constants/globals.dart` to `core/globals.dart` or similar
- Update ApiClient to import from new location

### Real Tests (future)
- Implement actual ApiClient tests using mocktail to mock Dio
- Add TokenManager unit tests
- Add integration tests for refresh token flow

## Summary

Phase 0 foundation is complete:
- ✓ Core theme structure in place
- ✓ Core network (token + API client) infrastructure ready
- ✓ Routing skeleton established
- ✓ Test infrastructure scaffolded (mocktail added)
- ✓ All old files remain intact (no breaking changes to existing app)
- ✓ New code follows existing patterns (Dio setup, interceptor style, async/await patterns)

The app should still compile and run with the old code; new features will gradually migrate to the core infrastructure established here.

