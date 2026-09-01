# Phase 2: Credit Feature Stubs

## Summary
Created empty-but-real-signature stub files for the credit feature across both backend and frontend. All methods raise `NotImplementedError` or `UnimplementedError`, following the architecture established by the project.

## Backend Stubs

### 1. backend/features/credit/data/repository.py
Created `CreditRepository` class with stub methods:
- `insert_ledger_entry(user_id, month_id, category_id, transaction_id, amount, entry_type)` → raises NotImplementedError
- `sum_balance(user_id)` → raises NotImplementedError, returns Decimal
- `get_history(user_id, month_id=None)` → raises NotImplementedError, returns list

### 2. backend/features/credit/business/service.py
Created `CreditService` class implementing `CreditLedgerInterface` with stub methods:
- `current_balance(user_id)` → raises NotImplementedError, returns Decimal
- `record_overage(user_id, month_id, category_id, amount, transaction_id)` → raises NotImplementedError
- `settle(user_id, month_id, amount, transaction_id)` → raises NotImplementedError, returns Decimal

Constructor accepts `CreditRepository` dependency.

### 3. backend/features/credit/presentation/schemas.py
Created Pydantic response models:
- `CreditBalanceResponse`: contains `balance: Decimal`
- `CreditHistoryEntry`: contains `id, month, category_code, amount, entry_type, created_at`
- `CreditHistoryResponse`: contains `entries: list[CreditHistoryEntry]`

### 4. backend/features/credit/presentation/router.py
Created APIRouter with auth-protected stub endpoints:
- `GET /balance` → returns CreditBalanceResponse, raises NotImplementedError
- `GET /history` → returns CreditHistoryResponse, raises NotImplementedError

Both endpoints use `get_current_user` from `features.auth.presentation.router` for authentication.

### 5. backend/features/credit/presentation/__init__.py
Created empty init file.

### 6. backend/features/credit/data/__init__.py
Created empty init file.

## Frontend Stubs

### 1. frontend/lib/features/credit/data/credit_api.dart
Created `CreditApi` class with stub methods:
- `getBalance()` → throws UnimplementedError, returns `Future<Map<String, dynamic>>`
- `getHistory()` → throws UnimplementedError, returns `Future<Map<String, dynamic>>`

Constructor accepts `Dio` instance for HTTP client.

### 2. frontend/lib/features/credit/business/credit_provider.dart
Created `CreditProvider` class extending `ChangeNotifier` with:
- Fields: `_balance`, `_history` (list), `_isLoading`, `_errorMessage`, `_isCached`, `_inFlightFuture`
- Getters: `balance`, `history`, `isLoading`, `errorMessage`
- Method: `load(forceRefresh)` → throws UnimplementedError

Constructor accepts `CreditApi` dependency.

### 3. frontend/lib/features/credit/presentation/credit_balance_widget.dart
Created `CreditBalanceWidget` as a StatelessWidget:
- `build()` method returns `Text('TODO')` placeholder

## Notes
- All stub files follow the project's existing architectural patterns
- No test files were created in this phase
- No real logic implemented - only interface/contract definitions
- All files are ready for implementation in subsequent phases
- Backend router endpoints have no prefix; prefix should be added in main.py's `include_router()`
