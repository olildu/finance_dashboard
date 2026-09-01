# Phase 1: Categories Feature - Backend Tests

## Overview

This document describes the test suite for the categories feature, implementing TDD for GET /categories endpoint.

## Architecture

Categories feature follows feature-sliced architecture:
- **presentation/**: Router and Pydantic schemas for API requests/responses
- **business/**: Service layer (not needed for categories - pure reference reads)
- **data/**: Repository layer with database queries

No business logic layer is needed for categories since this is purely a reference data read operation.

## Test Files Created

### 1. Presentation Layer Tests
**File**: `backend/features/categories/tests/presentation/test_router.py`

#### Purpose
Tests the FastAPI router endpoint GET /categories with:
- Authentication validation (Bearer token required)
- Response shape and structure
- Budget envelope joins
- All 7 categories present with correct data

#### Test Structure
- Uses mock dependencies (MockTokenService, MockCategoriesRepository, MockCategoriesService)
- FastAPI TestClient for HTTP testing
- 31 test cases covering:
  - **Authentication** (6 tests)
    - Missing token → 401
    - Invalid Bearer format → 401
    - Invalid token → 401
    - Valid token → 200
  - **Response Structure** (4 tests)
    - Returns all 7 categories
    - Each category has code, display_name, envelope fields
    - Each envelope has name, monthly_amount, account_code
    - Response is valid JSON with categories array
  - **Individual Category Validation** (19 tests)
    - Each of 7 categories (food, rent, electricity, phone_internet, travel, party_outside, misc) verified with correct:
      - Display name
      - Envelope name
      - Monthly amount
      - Funding account code
  - **Shared Envelope Verification** (2 tests)
    - Travel and party_outside both appear as separate categories
    - Both map to the same PartyOutsideTravel envelope
    - Both have identical envelope data (name, amount, account)

#### Key Assertions
- All 7 categories present: food, rent, electricity, phone_internet, travel, party_outside, misc
- Travel and party_outside are separate category entries but share envelope:
  - Envelope name: "PartyOutsideTravel"
  - Monthly amount: 4000.00
  - Funding account: "SBI"
- Monetary values (monthly_amount) are floats, not strings

### 2. Data Layer Tests
**File**: `backend/features/categories/tests/data/test_repository.py`

#### Purpose
Integration tests against real seeded database data using db_conn fixture.
Tests the repository layer's database query logic for categories with envelope joins.

#### Test Structure
- Uses CategoriesRepository inline implementation (following accounts feature pattern)
- db_conn fixture for real database access
- 3 test classes with 39 test cases:

**Class 1: TestGetAllActiveCategoriesWithEnvelopes** (19 tests)
- Verifies all 7 active categories returned
- Checks each category has required fields (id, code, display_name, is_active, envelope info, account info)
- Verifies each category's envelope join:
  - Food → Food envelope (6000, ICICI)
  - Rent → Rent envelope (17000, SLICE)
  - Electricity → Electricity envelope (100, SLICE)
  - Phone & Internet → PhoneInternet envelope (300, SLICE)
  - Travel → PartyOutsideTravel envelope (4000, SBI)
  - Party/Dining Out → PartyOutsideTravel envelope (4000, SBI)
  - Misc → Misc envelope (5000, ICICI)
- Confirms travel and party_outside share the same envelope_id
- Tests results ordered by category id
- Verifies monthly_amount values are Decimal type

**Class 2: TestGetCategoryByCode** (8 tests)
- Tests single category lookup by code
- Verifies envelope joins for individual lookups
- Tests nonexistent category returns None
- Verifies travel and party_outside both map correctly

**Class 3: TestGetCategoriesByEnvelopeId** (12 tests)
- Tests querying categories by envelope_id
- PartyOutsideTravel envelope (id=2) should return 2 categories (travel, party_outside)
- All other envelopes should return 1 category each
- Non-existent envelope returns empty list
- Verifies categories ordered by id

#### SQL Query Pattern
```sql
SELECT
    c.id, c.code, c.display_name, c.is_active, c.envelope_id,
    be.id as envelope_id, be.name as envelope_name, be.monthly_amount,
    be.account_id,
    a.code as account_code, a.display_name as account_display_name
FROM categories c
JOIN budget_envelopes be ON c.envelope_id = be.id
JOIN accounts a ON be.account_id = a.id
WHERE c.is_active = true
ORDER BY c.id
```

## Seeded Test Data Reference

### Accounts (5 total)
- ICICI (id=1, bank)
- SBI (id=2, bank)
- SLICE (id=3, bank)
- HDFC (id=4, fixed, 2500.00)
- CREDIT (id=5, pseudo_credit)

### Budget Envelopes (6 total)
1. Food → ICICI, 6000.00
2. PartyOutsideTravel → SBI, 4000.00
3. Rent → SLICE, 17000.00
4. Electricity → SLICE, 100.00
5. PhoneInternet → SLICE, 300.00
6. Misc → ICICI, 5000.00

### Categories (7 total)
1. food → Food envelope
2. rent → Rent envelope
3. electricity → Electricity envelope
4. phone_internet → PhoneInternet envelope
5. travel → PartyOutsideTravel envelope
6. party_outside → PartyOutsideTravel envelope (SAME ENVELOPE AS travel)
7. misc → Misc envelope

## API Response Schema (Expected)

```json
{
  "categories": [
    {
      "code": "food",
      "display_name": "Food",
      "envelope": {
        "name": "Food",
        "monthly_amount": 6000.00,
        "account_code": "ICICI"
      }
    },
    {
      "code": "travel",
      "display_name": "Travel",
      "envelope": {
        "name": "PartyOutsideTravel",
        "monthly_amount": 4000.00,
        "account_code": "SBI"
      }
    },
    {
      "code": "party_outside",
      "display_name": "Party/Dining Out",
      "envelope": {
        "name": "PartyOutsideTravel",
        "monthly_amount": 4000.00,
        "account_code": "SBI"
      }
    }
    // ... remaining 4 categories
  ]
}
```

## Key Testing Insights

### Shared Envelope Pattern
The critical insight tested extensively is that **travel** and **party_outside** are two distinct categories but both map to the same budget envelope. The tests verify:
1. Both appear as separate entries in the response
2. Each has its own category code and display_name
3. But they share identical envelope data (name, amount, account)
4. The database query correctly handles this via envelope_id foreign key

### Test-Driven Development
- Tests written first with no implementation
- All tests follow "Arrange-Act-Assert" pattern
- Mock implementations included for presentation layer
- Repository class defined inline in test file (following existing pattern)
- db_conn fixture from conftest.py handles real database setup/teardown

### Database Setup
- Tests use ephemeral PostgreSQL from docker-compose.ci.yml
- conftest.py provides db_conn fixture that:
  - Yields RealDictCursor for dict-like row access
  - Truncates transactional tables after each test
  - Persists reference data (accounts, budget_envelopes, categories)

## Running Tests

### Run all tests
```bash
pytest backend/features/categories/tests/
```

### Run only presentation tests
```bash
pytest backend/features/categories/tests/presentation/test_router.py
```

### Run only data tests
```bash
pytest backend/features/categories/tests/data/test_repository.py
```

### Run with verbose output
```bash
pytest -v backend/features/categories/tests/
```

### Run specific test class
```bash
pytest -v backend/features/categories/tests/presentation/test_router.py::TestListCategoriesEndpoint
```

### Run specific test
```bash
pytest -v backend/features/categories/tests/presentation/test_router.py::TestListCategoriesEndpoint::test_list_categories_returns_all_seven_categories
```

## Test Data Summary

### Total Test Coverage
- **Presentation Layer**: 31 tests covering 7 categories, auth, response shape, joins
- **Data Layer**: 39 tests covering query patterns, joins, envelope relationships
- **Total**: 70 tests

### Coverage Areas
- ✅ Authentication validation
- ✅ All 7 categories present
- ✅ Budget envelope joins (6 envelopes)
- ✅ Account funding joins (3 funding accounts: ICICI, SBI, SLICE)
- ✅ Shared envelope pattern (travel + party_outside both → PartyOutsideTravel)
- ✅ Query patterns: get_all, get_by_code, get_by_envelope_id
- ✅ Response shape and structure
- ✅ Data types (Decimal for amounts, strings for codes)

## Implementation Notes

### Ready for Implementation
These tests are TDD-ready. Implementation should:

1. Create `backend/features/categories/presentation/schemas.py`:
   - Pydantic models for CategoryResponse with nested BudgetEnvelopeSchema

2. Create `backend/features/categories/presentation/router.py`:
   - GET /categories endpoint
   - Depends on get_current_user (auth)
   - Depends on CategoriesRepository (data)
   - Returns list of categories with envelope joins

3. Create `backend/features/categories/data/repository.py`:
   - Implement CategoriesRepository with db_conn cursor
   - Implement the three query methods tested here

4. Register router in `backend/main.py`:
   ```python
   from features.categories.presentation.router import router as categories_router
   app.include_router(categories_router)
   ```

## Future Enhancements

Potential features for later phases:
- Filter categories by account_code
- Search categories by display_name
- Get category summary with current month spending
- Archive/deactivate categories (test uses is_active flag)
