# Phase 2: Transactions Feature Stubs

## Overview
Created stub implementations for the transactions feature across both backend and frontend. All method bodies raise `NotImplementedError` (Python) or `UnimplementedError()` (Dart). No real logic or tests were implemented—this phase establishes the interface and dependency structure.

## Backend Implementation

### Directory Structure
```
backend/features/transactions/
├── __init__.py
├── data/
│   ├── __init__.py
│   └── repository.py
├── business/
│   ├── __init__.py
│   └── service.py
└── presentation/
    ├── __init__.py
    ├── schemas.py
    └── router.py
```

### 1. Data Layer: `repository.py`
**Class: `TransactionsRepository`**

Stub methods:
- `insert(user_id, month_id, category_id, funding_account_id, amount, type, is_overage, reason, date) -> int`
  - Returns the inserted transaction ID
- `list_for_month(user_id, month_id) -> list`
  - Returns a list of transaction dicts for the user in a specific month
- `delete(user_id, transaction_id) -> bool`
  - Returns True if deleted, False if not found
- `sum_expense_for_envelope_in_month(user_id, month_id, envelope_id) -> Decimal`
  - Returns the sum of non-overage expenses for an envelope in a month

### 2. Business Layer: `service.py`
**Class: `TransactionsService`**

Constructor dependencies:
- `TransactionsRepository` - for data access
- `CategoriesRepository` - imported from `features.categories.data.repository` (read from real file)
- `CreditLedgerInterface` - imported from `features.credit.business.interface` (abstract interface for credit ledger)

Stub method:
- `record_expense(user_id, month_id, category_code, amount, reason, date) -> dict`

**Overage Rule Documentation:**
The docstring documents the overage logic (not yet implemented):
1. Look up the category by code to get its envelope and budget
2. Sum all existing non-overage expense transactions for that envelope in this month
3. If (existing_sum + new_amount) > envelope.monthly_amount:
   - The ENTIRE new transaction is marked as `is_overage=True`
   - The funding_account is set to CREDIT (via `credit_interface.record_overage`)
4. Otherwise:
   - `is_overage=False` and funding_account is the envelope's real account

### 3. Presentation Layer: `schemas.py`
**Pydantic Models:**
- `CreateTransactionRequest`: category_code (str), amount (Decimal), reason (str | None), date (datetime)
- `TransactionResponse`: id, category_code, funding_account_code, amount, type, is_overage, reason, date
- `TransactionListResponse`: transactions (list[TransactionResponse])

### 4. Presentation Layer: `router.py`
**APIRouter (no prefix)**

Auth-protected endpoints (all raise NotImplementedError):
- `POST /`: Create a new transaction
  - Takes CreateTransactionRequest, returns TransactionResponse
- `GET /`: List transactions for current month
  - Returns TransactionListResponse
- `DELETE /{transaction_id}`: Delete a transaction
  - Returns 204 No Content on success

Dependency injection:
- `get_transactions_repository(db)` - provides TransactionsRepository
- `get_transactions_service(repository)` - provides TransactionsService (currently raises NotImplementedError, awaits credit interface implementation)

All endpoints depend on `get_current_user` from auth module.

## Frontend Implementation

### Directory Structure
```
frontend/lib/features/transactions/
├── data/
│   └── transactions_api.dart
├── business/
│   └── transactions_provider.dart
└── presentation/
    ├── transaction_entry_page.dart
    └── transaction_list_page.dart
```

### 1. Data Layer: `transactions_api.dart`
**Class: `TransactionsApi`**

Stub methods (all throw UnimplementedError):
- `createTransaction({categoryCode, amount, reason, date}) -> Future<Map<String, dynamic>>`
  - Creates a new transaction via API
- `getTransactions() -> Future<List<Map<String, dynamic>>>`
  - Fetches all transactions for the current month
- `deleteTransaction(transactionId) -> Future<bool>`
  - Deletes a transaction by ID

### 2. Business Layer: `transactions_provider.dart`
**Class: `TransactionsProvider extends ChangeNotifier`**

State:
- `_transactions` - list of transaction maps
- `_isLoading` - boolean
- `_errorMessage` - optional error string

Getter properties:
- `transactions`, `isLoading`, `errorMessage`

Stub methods (all throw UnimplementedError):
- `load() -> Future<void>`
  - Loads transactions from API
- `addTransaction({categoryCode, amount, reason, date}) -> Future<void>`
  - Creates and adds a new transaction
- `deleteTransaction(transactionId) -> Future<void>`
  - Deletes a transaction

### 3. Presentation: `transaction_entry_page.dart`
**Class: `TransactionEntryPage extends StatelessWidget`**

Placeholder page returning `Scaffold` with AppBar ("New Transaction") and `Text('TODO')` in body.

### 4. Presentation: `transaction_list_page.dart`
**Class: `TransactionListPage extends StatefulWidget`**

Placeholder page returning `Scaffold` with AppBar ("Transactions") and `Text('TODO')` in body.

## Dependencies & Imports

### Backend
- **TransactionsService** correctly imports from:
  - `features.categories.data.repository.CategoriesRepository` (real production code)
  - `features.credit.business.interface.CreditLedgerInterface` (abstract interface only)
- Ensures no duplicate class definitions; all imports are from real production modules
- CategoriesRepository provides: `get_category_by_code()`, `get_all_active_categories_with_envelopes()`, `get_categories_by_envelope_id()`
- CreditLedgerInterface provides abstract methods: `current_balance()`, `record_overage()`, `settle()`

### Frontend
- **TransactionsProvider** imports `TransactionsApi` from data layer
- **TransactionsApi** imports only `dio/dio.dart` (standard HTTP client)

## Testing Notes
- No tests written in this phase
- All method bodies raise exceptions to fail fast if accidentally called
- Backend tests will use `pytest` with database fixtures from `conftest.py`
- Frontend tests will use `fvm flutter test` with real package imports

## Next Phase Preparation
- Credit feature must complete its `CreditLedgerInterface` implementation before transactions service can be fully implemented
- Categories repository is complete and ready to be used
- Database schema must include transactions table with columns: id, user_id, month_id, category_id, funding_account_id, amount, type, is_overage, reason, date
- API response structure follows established patterns from categories and auth features
