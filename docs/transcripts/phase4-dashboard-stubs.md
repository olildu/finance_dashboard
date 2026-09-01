# Phase 4: Dashboard Feature Stubs

**Date:** 2026-09-01  
**Status:** Stubs created (no tests, no real logic)

## Overview

Created minimal dashboard feature stubs for both backend and frontend. The dashboard is a thin **composition layer** that delegates to four existing features:

1. **Accounts** (month-end check: expected balances, HDFC reserve, net worth)
2. **Budgets** (category pace and burn-rate metrics)
3. **Credit** (current balance owed)
4. **Transactions** (recent transaction list)

No real business logic yet—all implementation methods raise `NotImplementedError`.

## Backend Structure

### Backend Directory Layout

```
backend/features/dashboard/
├── __init__.py
├── business/
│   ├── __init__.py
│   └── overview_service.py
└── presentation/
    ├── __init__.py
    ├── schemas.py
    └── router.py
```

### Backend Files Created

#### 1. `backend/features/dashboard/business/overview_service.py`

**Class:** `OverviewService`

**Constructor:**
```python
def __init__(
    self,
    accounts_service,              # AccountsService
    budgets_pace_service,          # BudgetsPaceService
    credit_service,                # CreditService
    transactions_repository,       # TransactionsRepository
)
```

**Stub Method:**
```python
def get_overview(self, user_id: int, month_id: int) -> dict:
    """
    Get complete dashboard overview.
    
    Composes data from four existing services and returns:
    {
        "month_end_check": {...},   # from AccountsService
        "budget_statuses": [...],   # from BudgetsPaceService
        "credit_balance": {...},    # from CreditService
        "transactions": [...]       # from TransactionsRepository
    }
    
    Raises:
        NotImplementedError: Stub implementation TBD
    """
    raise NotImplementedError("Dashboard overview not yet implemented")
```

**Key Design:**
- Composes but does NOT reimplement any existing logic
- Calls each service/repository and merges results
- No database access—delegation only

#### 2. `backend/features/dashboard/presentation/schemas.py`

**Class:** `DashboardOverviewResponse`

Reuses existing Pydantic schemas as nested fields:

```python
class DashboardOverviewResponse(BaseModel):
    month_end_check: MonthEndCheckResponse      # from accounts
    budget_statuses: list[CategoryStatus]       # from budgets
    credit_balance: CreditBalanceResponse       # from credit
    recent_transactions: list[TransactionResponse]  # from transactions
```

**Rationale:** Reuses exact response shapes from each feature instead of redefining fields. This ensures schema consistency and makes composition straightforward.

#### 3. `backend/features/dashboard/presentation/router.py`

**Endpoint:** `GET /overview` (auth-protected)

**Dependencies:**
- All four repositories (created via dependency injection)
- All four services (created via dependency injection)
- `OverviewService` (orchestrator)
- `get_current_user` (authentication)

**Stub Endpoint:**
```python
@router.get("/overview", response_model=DashboardOverviewResponse)
def get_overview(
    current_user_id: int = Depends(get_current_user),
    service: OverviewService = Depends(get_overview_service),
    accounts_repo: AccountsRepository = Depends(get_accounts_repository),
    clock=Depends(get_clock),
):
    """Get complete dashboard overview for authenticated user."""
    now = clock.now()
    month_id = accounts_repo.get_month_id(now.year, now.month)
    if month_id is None:
        month_id = accounts_repo.create_month(now.year, now.month)
    
    result = service.get_overview(
        user_id=current_user_id,
        month_id=month_id,
    )
    return DashboardOverviewResponse(**result)
```

**Current Behavior:** Raises `NotImplementedError` when `service.get_overview()` is called.

---

## Frontend Structure

### Frontend Directory Layout

```
frontend/lib/features/dashboard/
├── __init__.dart
├── business/
│   ├── __init__.dart
│   └── dashboard_provider.dart
└── presentation/
    ├── __init__.dart
    └── home_page.dart
```

### Frontend Files Created

#### 1. `frontend/lib/features/dashboard/business/dashboard_provider.dart`

**Class:** `DashboardProvider extends ChangeNotifier`

**Constructor:**
```dart
DashboardProvider({
  required AccountsProvider accountsProvider,
  required BudgetsProvider budgetsProvider,
  required CreditProvider creditProvider,
  required TransactionsProvider transactionsProvider,
})
```

**Stub Method:**
```dart
Future<void> load() async {
  // Calls load() on all four sub-providers in parallel
  await Future.wait([
    _accountsProvider.load(),
    _budgetsProvider.load(),
    _creditProvider.load(),
    _transactionsProvider.load(),
  ]);
}
```

**Design Choice:** Composition via sub-providers  
Rather than calling a single `GET /overview` backend endpoint, the provider loads all four existing providers in parallel. This:
- Reuses existing provider logic (caching, error handling, state management)
- Allows partial loads if one provider fails
- Keeps provider responsibilities isolated
- Mirrors the backend composition pattern

**Properties:** Exposes composed getters:
- `monthEndCheck` → from AccountsProvider
- `budgetStatuses` → from BudgetsProvider
- `creditBalance` → from CreditProvider
- `transactions` → from TransactionsProvider
- `isLoading`, `errorMessage` (aggregate state across all four)

#### 2. `frontend/lib/features/dashboard/presentation/home_page.dart`

**Widget:** `HomePage extends StatelessWidget`

**Current Rendering:**
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Dashboard')),
    body: const Center(child: Text('TODO: Dashboard home screen')),
  );
}
```

**Purpose:** Placeholder for the main app home screen, replacing old `responsive_screen/` home pages. Real UI (composed account balances, budget cards, credit info, transactions list) to follow in next phase.

---

## Implementation Notes

### Backend

1. **No Tests Yet:** Test suite will be added in phase 5.
2. **Service Constructor Signatures Verified:**
   - `AccountsService(repository, clock)`
   - `BudgetsPaceService(categories_repo, transactions_repo, clock)`
   - `CreditService(repository)`
   - `TransactionsRepository(cursor)`
3. **Response Shapes Verified:** Imported all existing Pydantic schemas (MonthEndCheckResponse, CategoryStatus, CreditBalanceResponse, TransactionResponse).
4. **Dependency Injection:** Follows existing FastAPI patterns (Depends, nested service dependencies).
5. **Authentication:** GET /overview is protected with `get_current_user`.

### Frontend

1. **No Tests Yet:** Test suite will be added in phase 5.
2. **Provider Architecture:**
   - Composes four existing providers (no new API client needed yet)
   - Parallel loading via `Future.wait()`
   - Aggregate loading state and error handling
   - Public getters expose composed data
3. **State Management:** Uses `ChangeNotifier` pattern consistent with existing providers.
4. **Widget Placeholder:** HomePage is a minimal StatelessWidget with TODO text.

---

## Next Steps

### Phase 5: Dashboard Tests & Implementation

1. **Backend Tests:**
   - Test `OverviewService.get_overview()` with mock services
   - Test `GET /overview` endpoint with auth
   - Verify response schema composition

2. **Backend Implementation:**
   - Implement `OverviewService.get_overview()` to call all four services and merge results
   - Ensure error handling across service calls

3. **Frontend Tests:**
   - Test `DashboardProvider.load()` with mock sub-providers
   - Test concurrent provider calls and state aggregation
   - Test error scenarios (one or more providers fail)

4. **Frontend UI:**
   - Implement HomePage with real composed dashboard layout
   - Display month-end check data (account balances, net worth)
   - Display budget cards (category pace, burn rate, runout date)
   - Display credit balance
   - Display recent transactions (scrollable list)

---

## Files Changed/Created

### Backend
- ✅ `backend/features/dashboard/__init__.py`
- ✅ `backend/features/dashboard/business/__init__.py`
- ✅ `backend/features/dashboard/business/overview_service.py`
- ✅ `backend/features/dashboard/presentation/__init__.py`
- ✅ `backend/features/dashboard/presentation/schemas.py`
- ✅ `backend/features/dashboard/presentation/router.py`

### Frontend
- ✅ `frontend/lib/features/dashboard/__init__.dart`
- ✅ `frontend/lib/features/dashboard/business/__init__.dart`
- ✅ `frontend/lib/features/dashboard/business/dashboard_provider.dart`
- ✅ `frontend/lib/features/dashboard/presentation/__init__.dart`
- ✅ `frontend/lib/features/dashboard/presentation/home_page.dart`

---

## Verification Checklist

- ✅ Backend OverviewService composes four real services/repos
- ✅ Backend schemas reuse existing Pydantic models
- ✅ Backend router is auth-protected
- ✅ Frontend DashboardProvider composes four existing providers
- ✅ Frontend HomePage is a placeholder widget
- ✅ No tests added (stub phase only)
- ✅ No real logic implemented (all methods raise NotImplementedError)
- ✅ Directory structure matches existing feature layout
- ✅ No circular imports
- ✅ Import statements reference real production classes
