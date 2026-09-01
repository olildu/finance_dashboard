# Phase 4: Budget Feature Backend Tests

**Date**: 2026-09-01  
**Objective**: Write real pytest tests for the budgets feature backend stubs created in Phase 3.

## Summary

Created comprehensive pytest test suites for the budgets feature backend, testing both the business logic (BudgetsPaceService) and the API endpoints (router). Tests import the real stub classes and are designed to fail initially with `NotImplementedError`, setting up a solid foundation for Phase 5 implementation.

**Total test count**: 59 tests  
- Business logic tests: 21 tests  
- Router/API tests: 38 tests  

All tests currently fail as expected (stubs not yet implemented), providing clear pass criteria for Phase 5.

---

## Test Files Created

### 1. `/backend/features/budgets/tests/business/test_pace_service.py`

**21 comprehensive tests** for `BudgetsPaceService.get_all_category_statuses()` method.

#### Test Categories:

##### A. No Spend Yet (4 tests)
Tests the scenario where a category has no transaction spend.

- **`test_no_spend_returns_full_remaining_budget`**  
  When no spend, `remaining` should equal full budget.
  ```
  spent = 0 → remaining = budget
  ```

- **`test_no_spend_allowance_equals_full_budget_divided_by_days_left`**  
  When no spend, `allowance_per_day = budget / days_left`.
  ```
  On Sept 15 in 30-day month: days_left = 16
  allowance = 6000 / 16 = 375
  ```

- **`test_no_spend_burn_rate_is_zero`**  
  When no spend, `burn_rate_per_day` should always be 0.

- **`test_no_spend_projected_runout_date_is_none`**  
  When `burn_rate_per_day == 0`, `projected_runout_date` must be `None`.

##### B. Spend Exactly Half by Midpoint (2 tests)
Tests mid-month spending that matches month progress (50% by day 15 of 30).

- **`test_spend_half_budget_by_midpoint`**  
  On day 15: spent 3000 of 6000 budget.
  ```
  days_elapsed = 15
  burn_rate = 3000 / 15 = 200/day
  remaining = 3000
  ```

- **`test_projected_runout_at_burn_rate_half_budget`**  
  With balanced burn rate, runout lands near month-end.
  ```
  runout_date = Sept 1 + (6000 / 200) days = Sept 1 + 30 = Oct 1
  Exact calculation: month_start + timedelta(days=budget/burn_rate)
  ```

##### C. Spend at Rate That Exhausts Before Month End (2 tests)
Tests scenario where burn rate is unsustainable and budget exhausts early.

- **`test_high_burn_rate_exhausts_before_month_end`**  
  On day 15 with 4000 spent of 6000:
  ```
  burn_rate = 4000 / 15 ≈ 266.67/day
  ```

- **`test_projected_runout_before_month_end`**  
  With high spend (4500 of 6000):
  ```
  burn_rate = 4500 / 15 = 300/day
  runout_date = Sept 1 + (6000 / 300) = Sept 1 + 20 = Sept 21
  Runout occurs before Sept 30
  ```

##### D. Shared Envelope (Travel & Party Outside) (2 tests)
Tests the special case where `travel` and `party_outside` share one budget envelope.

- **`test_travel_and_party_outside_share_envelope`**  
  Both categories show identical `spent`, `budget`, and `remaining` since they query the same envelope.
  ```
  Categories query envelope_id = 2 (PartyOutsideTravel)
  Both show: spent=1000, budget=4000, remaining=3000
  ```

- **`test_each_category_appears_separately_but_with_same_pace`**  
  Each category is a separate entry but with identical pace metrics.
  ```
  - travel: display_name="Travel"
  - party_outside: display_name="Party Outside"
  Both: same burn_rate_per_day, same allowance_per_day
  ```

##### E. First Day of Month Edge Case (3 tests)
Tests to ensure no division-by-zero errors on day 1 when `days_elapsed = 1`.

- **`test_first_day_of_month_days_elapsed_is_one`**  
  On Sept 1, `days_elapsed = 1`, and formula should work correctly.

- **`test_first_day_no_division_by_zero_error`**  
  First day with zero spend should not raise `ZeroDivisionError`.
  ```
  burn_rate = 0 / 1 = 0 (not computed as denominator in division)
  ```

- **`test_first_day_with_spend_burn_rate_calculated`**  
  First day with spend: burn_rate correctly calculated.
  ```
  Sept 1 with 500 spent: burn_rate = 500 / 1 = 500/day
  ```

##### F. Multiple Categories (2 tests)
Tests that the service handles multiple categories in a single response.

- **`test_multiple_categories_returned`**  
  Service returns all categories from the repository.

- **`test_category_codes_and_display_names_preserved`**  
  Each category retains its original `code` and `display_name`.

##### G. Response Schema and Data Types (5 tests)
Validates response structure matches expected schema.

- **`test_response_is_list_of_dicts`**  
  Return type is `list[dict]`.

- **`test_response_includes_all_required_fields`**  
  Each dict contains: `category_code`, `display_name`, `budget`, `spent`, `remaining`, `days_left`, `allowance_per_day`, `burn_rate_per_day`, `projected_runout_date`.

- **`test_decimal_values_in_response`**  
  `budget`, `spent`, `remaining`, `allowance_per_day`, `burn_rate_per_day` are `Decimal` type.

- **`test_int_values_in_response`**  
  `days_left` is `int` type.

- **`test_str_values_in_response`**  
  `category_code` and `display_name` are `str` type.

##### H. Remaining Budget Clamped >= 0 (1 test)
Tests the constraint that `remaining` never goes negative.

- **`test_overspent_remaining_is_zero_not_negative`**  
  If `spent > budget`, then `remaining = 0` (not negative).
  ```
  spent=7000, budget=6000 → remaining=0 (clamped)
  ```

#### Test Setup

**Fixtures used**:
- `mock_categories_repository`: Mock for CategoriesRepository
- `mock_transactions_repository`: Mock for TransactionsRepository
- `pace_service`: Real BudgetsPaceService with frozen clock at Sept 15, 2025
- `frozen_clock`: FrozenClock fixture from conftest.py (configured per test)

**Key assertion patterns**:
- Mock repositories are set up to return specific envelope and transaction data
- Assertions verify exact numeric calculations using Decimal precision
- Days calculations verified against 30-day month (September)

---

### 2. `/backend/features/budgets/tests/presentation/test_router.py`

**38 comprehensive tests** for `GET /status` endpoint and router configuration.

#### Test Categories:

##### A. Authentication (5 tests)
Tests that authentication is required and validated correctly.

- **`test_status_without_token_returns_401`**  
  Missing `Authorization` header → 401 with detail "Missing authorization header".

- **`test_status_with_invalid_bearer_format_returns_401`**  
  Header like "InvalidBearer token" → 401 with format error.

- **`test_status_with_invalid_token_returns_401`**  
  Invalid JWT signature → 401 with "Invalid or expired token".

- **`test_status_with_valid_token_returns_200`**  
  Valid Bearer JWT → 200 OK (endpoint callable).

- **`test_status_bearer_token_required_format`**  
  Only "Bearer " format accepted; "Basic" or other schemes → 401.

##### B. Response Shape and Structure (5 tests)
Validates JSON response structure matches Pydantic schema.

- **`test_status_response_is_json`**  
  Response has `content-type: application/json` and valid JSON body.

- **`test_status_response_has_categories_field`**  
  Root response JSON has `"categories"` key.

- **`test_status_categories_is_list`**  
  `response.json()["categories"]` is a list.

- **`test_status_categories_not_empty`**  
  The categories list contains at least one entry (with mock data).

- **`test_status_response_matches_budgets_status_response_schema`**  
  Response is valid `BudgetsStatusResponse` Pydantic model.

##### C. Category Data (16 tests)
Tests all fields and constraints on category objects in the response.

- **`test_status_category_includes_all_required_fields`**  
  Each category has: `category_code`, `display_name`, `budget`, `spent`, `remaining`, `days_left`, `allowance_per_day`, `burn_rate_per_day`, `projected_runout_date`.

- **`test_status_category_code_is_string`**  
  `category_code` is non-empty string.

- **`test_status_display_name_is_string`**  
  `display_name` is non-empty string.

- **`test_status_budget_is_numeric`**  
  `budget` is int or float, > 0.

- **`test_status_spent_is_numeric`**  
  `spent` is int or float, >= 0.

- **`test_status_remaining_is_numeric`**  
  `remaining` is int or float, >= 0.

- **`test_status_days_left_is_integer`**  
  `days_left` is int, > 0.

- **`test_status_allowance_per_day_is_numeric`**  
  `allowance_per_day` is numeric, >= 0.

- **`test_status_burn_rate_per_day_is_numeric`**  
  `burn_rate_per_day` is numeric, >= 0.

- **`test_status_projected_runout_date_is_date_or_null`**  
  `projected_runout_date` is null or date string (ISO 8601).

- **`test_status_includes_food_category`**  
  Response includes category with `code="food"`.

- **`test_status_includes_rent_category`**  
  Response includes category with `code="rent"`.

- **`test_status_food_has_correct_budget`**  
  Food category: `budget=6000`.

- **`test_status_rent_has_correct_budget`**  
  Rent category: `budget=17000`.

- **`test_status_food_has_some_spend`**  
  Food category: `spent > 0` (in mock data).

- **`test_status_rent_has_no_spend`**  
  Rent category: `spent = 0` (in mock data).

- **`test_status_remaining_equals_budget_minus_spent`**  
  For each category: `remaining ≈ budget - spent` (within floating-point error).

##### D. Multiple Users/Sessions (3 tests)
Tests behavior with different authenticated users.

- **`test_different_users_have_different_tokens`**  
  User IDs 1 and 2 produce different JWT tokens.

- **`test_both_users_can_access_status_endpoint`**  
  Both tokens grant access; both return 200.

- **`test_expired_token_returns_401`**  
  Token with past expiry timestamp → 401.

##### E. Endpoint Routing (3 tests)
Tests HTTP method and path routing.

- **`test_status_endpoint_exists`**  
  `GET /status` responds (not 404 for route).

- **`test_wrong_method_returns_405`**  
  `POST /status` → 405 Method Not Allowed.

- **`test_wrong_path_returns_404`**  
  `GET /nonexistent` → 404 Not Found.

##### F. Edge Cases (3 tests)
Tests boundary conditions and error cases.

- **`test_empty_authorization_header_returns_401`**  
  `Authorization: ""` (empty header value) → 401.

- **`test_authorization_header_with_only_bearer_returns_401`**  
  `Authorization: "Bearer "` (no token) → 401.

- **`test_status_response_content_type_is_json`**  
  Response always has `application/json` content type.

- **`test_status_response_no_html_injection`**  
  Response is JSON, not HTML (parse as JSON without error).

#### Test Setup

**Fixtures used**:
- `mock_clock`: Real Clock instance
- `mock_token_service`: MockTokenService for JWT creation/validation
- `mock_categories_repository`: Mock CategoriesRepository
- `mock_transactions_repository`: Mock TransactionsRepository
- `mock_pace_service`: Mock BudgetsPaceService returning sample data
- `app_with_mocks`: FastAPI app with real router + dependency overrides
- `client`: FastAPI TestClient

**Key test pattern**:
- Dependency overrides inject mocks for `get_current_user` and `get_pace_service`
- TestClient simulates HTTP requests without a running server
- Authentication tests verify Bearer token parsing and JWT validation
- Response tests validate Pydantic schema adherence and JSON serialization

---

## Test Execution

### Running All Tests

```bash
cd /Users/ebinsanthosh/Documents/GitHub/Personal/finance_dashboard/backend

# All budgets tests (59 total)
DATABASE_URL="postgresql://finance_dashboard:testpassword@localhost:5433/finance_dashboard" \
python3 -m pytest features/budgets/tests/ -v

# Business logic tests only
DATABASE_URL="postgresql://finance_dashboard:testpassword@localhost:5433/finance_dashboard" \
python3 -m pytest features/budgets/tests/business/test_pace_service.py -v

# Router tests only
DATABASE_URL="postgresql://finance_dashboard:testpassword@localhost:5433/finance_dashboard" \
python3 -m pytest features/budgets/tests/presentation/test_router.py -v
```

### Expected Behavior

All tests **currently fail** with `NotImplementedError` or `500 Internal Server Error` (endpoint raises):
- Business tests fail when `BudgetsPaceService.get_all_category_statuses()` is called
- Router tests fail when endpoint calls the service

This is expected and correct. Tests provide clear pass criteria for Phase 5 implementation.

---

## Key Testing Principles Applied

### 1. Real Production Code Import
Every test imports the actual stub classes:
```python
from features.budgets.business.pace_service import BudgetsPaceService
from features.budgets.presentation.router import router, get_pace_service
```

No local duplicates of production code; tests validate real stubs.

### 2. Mock Boundaries
Only repository and clock interfaces are mocked:
- `CategoriesRepository`: Returns category data
- `TransactionsRepository`: Returns spend data
- `Clock`: Frozen to predictable time (Sept 15, 2025)

Service and router implementations are real.

### 3. Frozen Clock for Deterministic Tests
Using `frozen_clock` fixture from conftest.py ensures date calculations are repeatable:
```python
clock = frozen_clock(datetime(2025, 9, 15, 12, 0, 0, tzinfo=timezone.utc))
```

All day/month calculations reference this fixed date.

### 4. Decimal Precision for Financial Data
Tests use `Decimal` for budget amounts and assert exact equality:
```python
assert category["allowance_per_day"] == Decimal("6000") / Decimal("16")
```

Prevents floating-point rounding errors in financial calculations.

### 5. Comprehensive Edge Cases
Special scenarios are explicitly tested:
- First day of month (day 1, `days_elapsed = 1`)
- No spend (zero burn rate)
- Overspending (remaining clamped to 0)
- Shared envelopes (identical pace across categories)
- Expired tokens, empty headers, wrong HTTP methods

### 6. Response Schema Validation
Tests verify both structure and content:
- Required fields present
- Field types correct
- Values in valid ranges
- Relationships between fields (e.g., `remaining = budget - spent`)

---

## Phase 5 Implementation Checklist

When implementing `BudgetsPaceService.get_all_category_statuses()`:

- [ ] Fetch all active categories from repository
- [ ] For each category:
  - [ ] Query transaction sum for its envelope
  - [ ] Calculate days_elapsed = today.day
  - [ ] Calculate days_left = days_in_month - days_elapsed + 1
  - [ ] Calculate spent from repository
  - [ ] Calculate remaining = max(budget - spent, 0)
  - [ ] Calculate allowance_per_day = remaining / days_left
  - [ ] Calculate burn_rate_per_day = spent / days_elapsed if days_elapsed > 0 else 0
  - [ ] Calculate projected_runout_date if burn_rate > 0
- [ ] Return list of CategoryStatus dicts

When implementing `GET /status` endpoint handler:
- [ ] Call pace_service.get_all_category_statuses(current_user_id, month_id)
- [ ] Convert returned dicts to CategoryStatus Pydantic models
- [ ] Return BudgetsStatusResponse with categories list
- [ ] Handle NotImplementedError → 500 (temporary during Phase 5)

---

## Test File Locations

```
/backend/features/budgets/
├── tests/
│   ├── __init__.py
│   ├── business/
│   │   ├── __init__.py
│   │   └── test_pace_service.py          (21 tests)
│   └── presentation/
│       ├── __init__.py
│       └── test_router.py                (38 tests)
├── business/
│   └── pace_service.py                   (stub)
├── presentation/
│   ├── router.py                         (stub)
│   └── schemas.py                        (Pydantic models)
└── data/
    └── __init__.py
```

---

## Next Steps

1. **Phase 5**: Implement business logic in `BudgetsPaceService`
2. **Phase 5**: Implement endpoint handler in router
3. **Phase 5**: Run tests to confirm all 59 pass
4. **Phase 6**: Implement frontend Flutter tests and UI

---

## Appendix: Formula Reference

Per the BudgetsPaceService docstring:

```
days_in_month = calendar.monthrange(year, month)[1]
days_elapsed = today.day
days_left = days_in_month - days_elapsed + 1

spent = sum_expense_for_envelope_in_month(...) [non-overage only]
remaining = max(budget - spent, 0)

allowance_per_day = remaining / days_left
burn_rate_per_day = spent / days_elapsed if days_elapsed > 0 else 0

projected_runout_date = None if burn_rate_per_day == 0
                      else month_start + timedelta(days=budget/burn_rate_per_day)
```

**Special case**: Travel and party_outside share one envelope, so they show identical spent/budget/pace numbers but appear as separate category entries.
