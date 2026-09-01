# Phase 3: Budgets Feature Stubs

## Overview

Created backend and frontend stubs for the budgets feature. This feature computes, per category, an allowance-pace and a burn-rate projection for the current month.

## Backend Implementation

### Structure

Created the following backend files under `backend/features/budgets/`:

```
backend/features/budgets/
├── __init__.py
├── business/
│   ├── __init__.py
│   └── pace_service.py          # BudgetsPaceService class
├── data/
│   └── __init__.py
└── presentation/
    ├── __init__.py
    ├── schemas.py               # CategoryStatus, BudgetsStatusResponse
    └── router.py                # APIRouter with GET /status endpoint
```

### pace_service.py

**Class:** `BudgetsPaceService`

Constructor dependencies:
- `CategoriesRepository`: Fetches categories with envelope/budget/account info
- `TransactionsRepository`: Fetches transaction amounts for calculations
- `Clock`: Gets current date (uses `get_clock()`, never `datetime.now()` directly)

**Stub Method:** `get_all_category_statuses(user_id: int, month_id: int) -> list[dict]`

This method will compute the following metrics per category:

```
days_in_month = calendar.monthrange(year, month)[1]
days_elapsed = today.day
days_left = days_in_month - days_elapsed + 1

spent = sum_expense_for_envelope_in_month(...)  # non-overage only
remaining = max(budget - spent, 0)

allowance_per_day = remaining / days_left
burn_rate_per_day = spent / days_elapsed if days_elapsed > 0 else 0

projected_runout_date = None if burn_rate_per_day == 0 
                         else month_start + timedelta(days=budget/burn_rate_per_day)
```

**Design Note:** Travel and party_outside categories share one envelope, so their spent/budget/pace numbers will be identical to each other, but each still appears as its own category entry in the response.

### schemas.py

**Class:** `CategoryStatus`

Pydantic model with the following fields:
- `category_code: str` - Category code (e.g., 'food', 'rent', 'travel')
- `display_name: str` - Human-readable category name
- `budget: Decimal` - Monthly budget allocation in rupees
- `spent: Decimal` - Amount spent (non-overage only) in rupees
- `remaining: Decimal` - Remaining budget (budget - spent, clamped >= 0) in rupees
- `days_left: int` - Days remaining in the month (including today)
- `allowance_per_day: Decimal` - Daily allowance based on remaining budget and days left in rupees
- `burn_rate_per_day: Decimal` - Average daily burn rate based on days elapsed in rupees
- `projected_runout_date: date | None` - Projected date when budget will run out if spending continues at current rate

**Class:** `BudgetsStatusResponse`

Pydantic model containing:
- `categories: list[CategoryStatus]` - Budget status for all active categories

Decimal fields are serialized to float in JSON responses.

### router.py

**APIRouter:** No prefix (endpoints are at `/status`, not `/budgets/status`)

**Dependencies:**
- `get_categories_repository()`: Provides CategoriesRepository from DB cursor
- `get_transactions_repository()`: Provides TransactionsRepository from DB cursor
- `get_pace_service()`: Wires together all repositories and Clock

**Endpoint:** `GET /status`

- Response model: `BudgetsStatusResponse`
- Auth: Protected with `Depends(get_current_user)` from auth feature
- Currently raises `NotImplementedError` (stub)

## Frontend Implementation

### Structure

Created the following frontend files under `frontend/lib/features/budgets/`:

```
frontend/lib/features/budgets/
├── data/
│   └── budgets_api.dart              # BudgetsApi class
├── business/
│   └── budgets_provider.dart         # BudgetsProvider (ChangeNotifier)
└── presentation/
    └── category_pace_card.dart       # CategoryPaceCard widget (placeholder)
```

### budgets_api.dart

**Class:** `BudgetsApi`

Constructor:
- `final Dio dio;`

**Method:** `getStatus() -> Future<Map<String, dynamic>>`

Currently throws `UnimplementedError` with message "getStatus() is not yet implemented".

Response structure (when implemented):
```json
{
  "categories": [
    {
      "category_code": "food",
      "display_name": "Food",
      "budget": 5000.00,
      "spent": 1200.50,
      "remaining": 3799.50,
      "days_left": 10,
      "allowance_per_day": 379.95,
      "burn_rate_per_day": 171.50,
      "projected_runout_date": "2025-09-20"
    },
    ...
  ]
}
```

### budgets_provider.dart

**Class:** `BudgetsProvider extends ChangeNotifier`

Constructor:
- `required BudgetsApi budgetsApi` (named parameter)

**State:**
- `_categories: List<Map<String, dynamic>>` - List of category statuses
- `_isLoading: bool` - Whether data is currently being loaded
- `_errorMessage: String?` - Error message if any operation failed
- `_isCached: bool` - Whether data has been successfully loaded once
- `_inFlightFuture: Future<void>?` - Tracks in-flight load requests for deduplication

**Getters:**
- `categories: List<Map<String, dynamic>>` - Current list of category statuses
- `isLoading: bool` - Loading state
- `errorMessage: String?` - Error message

**Method:** `load({bool forceRefresh = false}) -> Future<void>`

- If cached and not forcing refresh, returns immediately
- If load is already in progress, awaits the same future (deduplication)
- Calls `_performLoad()` which calls `_budgetsApi.getStatus()`
- Updates `_categories`, `_errorMessage`, `_isCached` state
- Notifies listeners on state changes
- Currently `_performLoad()` will throw `UnimplementedError` from the API

### category_pace_card.dart

**Class:** `CategoryPaceCard extends StatelessWidget`

Constructor:
- `required this.status: Map<String, dynamic>` - Single category status entry

Currently a placeholder returning `Text('TODO')`.

Will eventually display:
- Category name and code
- Budget allocation, spent amount, remaining budget
- Days left in month
- Daily allowance pace
- Burn rate and projected runout date

## Integration Notes

### Backend Integration Points

1. **Database:** Uses existing tables:
   - `categories` (with `envelope_id`)
   - `budget_envelopes` (with `monthly_amount`, `account_id`)
   - `accounts`
   - `months` (for year/month lookup)
   - `transactions` (with `is_overage` flag)
   - `users`

2. **Dependencies:**
   - `CategoriesRepository.get_all_active_categories_with_envelopes()` - Fetch all active categories
   - `TransactionsRepository.sum_expense_for_envelope_in_month(user_id, month_id, envelope_id)` - Fetch non-overage expenses per envelope
   - `Clock.now()` - Get current date (via `get_clock()` dependency)

3. **Auth:** Uses `get_current_user` dependency from auth feature (extracts user_id from Bearer token)

### Frontend Integration Points

1. **API:** Connects to backend `GET /status` endpoint (once router is registered in main app)

2. **Dependencies:**
   - `Dio` instance for HTTP calls
   - Provider pattern for state management

3. **Widget Tree:** `CategoryPaceCard` will be used by parent widgets to display budget status (to be built in later phases)

## No Tests or Real Logic

As per requirements:
- No tests written yet
- All methods raise `NotImplementedError` (stubs only)
- Ready for real implementation in next phase

## Files Created

Backend:
- `/backend/features/budgets/__init__.py`
- `/backend/features/budgets/business/__init__.py`
- `/backend/features/budgets/business/pace_service.py`
- `/backend/features/budgets/data/__init__.py`
- `/backend/features/budgets/presentation/__init__.py`
- `/backend/features/budgets/presentation/schemas.py`
- `/backend/features/budgets/presentation/router.py`

Frontend:
- `/frontend/lib/features/budgets/data/budgets_api.dart`
- `/frontend/lib/features/budgets/business/budgets_provider.dart`
- `/frontend/lib/features/budgets/presentation/category_pace_card.dart`

Documentation:
- `/docs/transcripts/phase3-budgets-stubs.md` (this file)

## Next Steps

Phase 4 (to be scheduled):
1. Implement `BudgetsPaceService.get_all_category_statuses()` with real calculations
2. Implement backend router endpoint to call the service and return response
3. Implement `BudgetsApi.getStatus()` with real HTTP calls
4. Implement `BudgetsProvider._performLoad()` to handle API calls
5. Implement `CategoryPaceCard` widget with real UI
6. Write integration and unit tests for all layers
7. Register budgets router in main FastAPI app
8. Integrate widgets into dashboard UI
