# Phase 1: Accounts Feature - Backend Test Suite

**Date**: September 1, 2025

**Objective**: Write comprehensive pytest test suite for the accounts feature (test-driven development).

## Overview

This phase focuses on creating a complete test suite for the accounts feature across three layers:

1. **Business Logic Tests** (unit tests) - Tests for expected-balance calculations
2. **Presentation Layer Tests** (integration tests) - Tests for API endpoints
3. **Data Layer Tests** (integration tests) - Tests for repository queries against seeded data

No implementation is written in this phase; only tests are created following TDD principles.

## Architecture Overview

The accounts feature follows the feature-sliced architecture pattern:

```
backend/features/accounts/
├── business/           # Use-case logic (service.py)
│   └── service.py     # AccountsService for balance calculations
├── data/              # Database access (repository.py)
│   └── repository.py  # AccountsRepository for queries
├── presentation/      # API endpoints (router.py + schemas.py)
│   ├── router.py      # FastAPI endpoints
│   └── schemas.py     # Pydantic request/response models
└── tests/
    ├── business/test_service.py      # Unit tests for AccountsService
    ├── presentation/test_router.py   # Integration tests for endpoints
    └── data/test_repository.py       # Integration tests for repository
```

## Test Files Created

### 1. backend/features/accounts/tests/business/test_service.py

**Purpose**: Unit tests for AccountsService expected-balance calculation logic.

**Dependencies**: Mocked repository and clock (no database access).

**Mock Repository Fixtures**:
- `mock_repository`: Returns seeded account/envelope data
- `frozen_clock`: Time is fixed at 2025-09-01 12:00:00 UTC
- `service`: AccountsService instance with mocked dependencies

**Test Classes**:

#### TestExpectedBalanceNoSpend
Tests expected-balance calculation when no transactions exist.

- `test_no_spend_balance_equals_envelope_totals`: Balance equals sum of monthly_amounts for envelopes funded by account
- `test_no_spend_all_envelopes_funded_correctly`: Verifies all envelopes allocated to correct accounts

Expected results (seeded data):
- ICICI: Food (6000) + Misc (5000) = 11000
- SBI: PartyOutsideTravel (4000)
- SLICE: Rent (17000) + Electricity (100) + PhoneInternet (300) = 17400
- HDFC: Fixed 2500
- Total: 34900

#### TestExpectedBalanceWithSpend
Tests expected-balance with expense transactions (is_overage=false).

- `test_spend_within_budget_reduces_balance`: Single expense reduces balance
- `test_multiple_expenses_on_same_account`: Multiple expenses sum correctly
- `test_expenses_on_different_accounts`: Expenses on different accounts only affect those accounts

#### TestExpectedBalanceWithRolloverSweep
Tests expected-balance with rollover_sweep transactions.

- `test_rollover_sweep_into_slice_increases_balance`: Rollover sweep increases balance
- `test_multiple_rollover_sweeps`: Multiple sweeps sum correctly
- `test_rollover_sweep_combined_with_expenses`: Both expenses and sweeps accounted for

#### TestHDFCFixedReserve
Tests that HDFC reserve is always 2500 regardless of transactions.

- `test_hdfc_reserve_is_always_2500`: Fixed reserve value
- `test_hdfc_reserve_with_transactions`: Not affected by other accounts' transactions

#### TestTotalNetWorth
Tests total_net_worth calculation.

- `test_total_net_worth_no_spend`: Equals sum of all balances
- `test_total_net_worth_with_spend`: Decreases with expenses
- `test_total_net_worth_with_rollover_sweep`: Increases with rollovers
- `test_total_net_worth_complex_transactions`: Handles multiple transactions correctly

**Total: 20 unit tests**

---

### 2. backend/features/accounts/tests/presentation/test_router.py

**Purpose**: Integration tests for FastAPI endpoints with mocked dependencies.

**Dependencies**: Mocked service, repository, token service, and password hasher.

**Mock Classes**:
- `MockPasswordHasher`: Simulates password hashing
- `MockTokenService`: Generates and validates JWT tokens
- `MockAccountsRepository`: Returns seeded account data
- `MockAccountsService`: Computes month-end check

**Fixtures**:
- `mock_token_service`: TokenService for generating test tokens
- `mock_accounts_repository`: Repository with seeded data
- `mock_accounts_service`: Service for balance calculations
- `app_with_mocks`: FastAPI app with mocked dependencies
- `client`: TestClient for making HTTP requests

**Test Classes**:

#### TestListAccountsEndpoint
Tests GET /accounts endpoint.

Authentication tests:
- `test_list_accounts_without_token_returns_401`: Missing auth header
- `test_list_accounts_with_invalid_bearer_format_returns_401`: Malformed header
- `test_list_accounts_with_invalid_token_returns_401`: Invalid token
- `test_list_accounts_with_valid_token_returns_200`: Valid token succeeds

Response shape tests:
- `test_list_accounts_returns_all_accounts`: Returns 5 accounts
- `test_list_accounts_returns_correct_account_fields`: Response includes id/code/display_name/kind/fixed_amount
- `test_list_accounts_includes_icici`: ICICI in response
- `test_list_accounts_includes_sbi`: SBI in response
- `test_list_accounts_includes_slice`: SLICE in response

Account data tests:
- `test_list_accounts_icici_account_has_correct_kind`: ICICI kind='bank', fixed_amount=null
- `test_list_accounts_hdfc_account_has_fixed_amount`: HDFC kind='fixed', fixed_amount=2500
- `test_list_accounts_response_is_json_array`: Response is JSON array

#### TestMonthEndCheckEndpoint
Tests GET /accounts/month-end-check endpoint.

Authentication tests:
- `test_month_end_check_without_token_returns_401`: Missing auth header
- `test_month_end_check_with_invalid_token_returns_401`: Invalid token
- `test_month_end_check_with_valid_token_returns_200`: Valid token succeeds

Response structure tests:
- `test_month_end_check_returns_icici_balance`: Response includes ICICI with expected_balance
- `test_month_end_check_returns_sbi_balance`: Response includes SBI with expected_balance
- `test_month_end_check_returns_slice_balance`: Response includes SLICE with expected_balance
- `test_month_end_check_returns_hdfc_reserve`: Response includes hdfc_reserve (2500.00)
- `test_month_end_check_returns_total_net_worth`: Response includes total_net_worth

Validation tests:
- `test_month_end_check_total_equals_sum_of_balances`: total_net_worth = sum of account balances
- `test_month_end_check_response_shape`: Verifies complete response structure and types
- `test_month_end_check_hdfc_not_in_per_account_list`: HDFC only as hdfc_reserve, not account entry
- `test_month_end_check_credit_not_in_response`: CREDIT pseudo-account excluded

**Total: 23 integration tests**

---

### 3. backend/features/accounts/tests/data/test_repository.py

**Purpose**: Integration tests for AccountsRepository against real database with db_conn fixture.

**Database Fixture**: `db_conn` from conftest.py - provides RealDictCursor with seeded data.

**Repository Methods Tested**:
- `get_all_accounts()` - List all accounts
- `get_all_budget_envelopes()` - List all budget envelopes
- `get_month_id(year, month)` - Lookup month by year/month
- `create_month(year, month)` - Create month entry
- `get_transactions_for_month(user_id, month_id)` - List transactions
- `sum_expenses_for_account_in_month()` - Sum of expenses by account
- `sum_non_expense_transactions_for_account_in_month()` - Sum of transfers/sweeps/payoffs
- `sum_monthly_amounts_for_account_envelopes()` - Sum of envelope amounts by account

**Test Classes**:

#### TestGetAllAccounts
Tests `get_all_accounts()` query.

- `test_get_all_accounts_returns_list`: Query returns list
- `test_get_all_accounts_returns_five_accounts`: Seeded data has 5 accounts
- `test_get_all_accounts_includes_icici`: ICICI present
- `test_get_all_accounts_includes_sbi`: SBI present
- `test_get_all_accounts_includes_slice`: SLICE present
- `test_get_all_accounts_includes_hdfc`: HDFC present
- `test_get_all_accounts_includes_credit`: CREDIT present
- `test_get_all_accounts_icici_correct_kind`: ICICI kind='bank'
- `test_get_all_accounts_hdfc_correct_kind_and_amount`: HDFC kind='fixed', amount=2500
- `test_get_all_accounts_credit_correct_kind`: CREDIT kind='pseudo_credit'
- `test_get_all_accounts_has_required_fields`: All required fields present
- `test_get_all_accounts_ordered_by_id`: Results ordered by id

#### TestGetAllBudgetEnvelopes
Tests `get_all_budget_envelopes()` query.

- `test_get_all_budget_envelopes_returns_list`: Query returns list
- `test_get_all_budget_envelopes_returns_six_envelopes`: Seeded data has 6 envelopes
- `test_get_all_budget_envelopes_includes_food`: Food envelope present
- `test_get_all_budget_envelopes_includes_rent`: Rent envelope present
- `test_get_all_budget_envelopes_food_amount_is_6000`: Food monthly_amount=6000
- `test_get_all_budget_envelopes_rent_amount_is_17000`: Rent monthly_amount=17000
- `test_get_all_budget_envelopes_food_funded_by_icici`: Food funded by ICICI (account_id=1)
- `test_get_all_budget_envelopes_rent_funded_by_slice`: Rent funded by SLICE (account_id=3)

#### TestMonthQueries
Tests month-related queries.

- `test_get_month_id_returns_none_for_nonexistent_month`: Nonexistent month returns None
- `test_create_month_creates_and_returns_id`: Create month returns id
- `test_get_month_id_finds_created_month`: After create, get_month_id finds it
- `test_create_month_unique_constraint`: Duplicate month raises error

#### TestTransactionSumQueries
Tests transaction aggregation queries.

**Expense sum tests**:
- `test_sum_expenses_for_account_returns_decimal`: Returns Decimal
- `test_sum_expenses_for_account_no_transactions_returns_zero`: No transactions = 0
- `test_sum_expenses_for_account_with_single_expense`: Single expense sums correctly
- `test_sum_expenses_excludes_non_expense_transactions`: Only counts type='expense'
- `test_sum_expenses_excludes_overage_transactions`: Only counts is_overage=false
- `test_sum_expenses_multiple_transactions`: Multiple expenses sum correctly

**Non-expense sum tests**:
- `test_sum_non_expense_transactions_returns_decimal`: Returns Decimal
- `test_sum_non_expense_transactions_includes_rollover_sweep`: Includes rollover_sweep

**Envelope amount sum tests**:
- `test_sum_envelope_amounts_for_account_returns_decimal`: Returns Decimal
- `test_sum_envelope_amounts_icici_is_11000`: ICICI envelopes total 11000
- `test_sum_envelope_amounts_sbi_is_4000`: SBI envelopes total 4000
- `test_sum_envelope_amounts_slice_is_17400`: SLICE envelopes total 17400
- `test_sum_envelope_amounts_hdfc_is_zero`: HDFC envelopes total 0 (fixed account)

#### TestGetTransactionsForMonth
Tests `get_transactions_for_month()` query.

- `test_get_transactions_for_month_returns_list`: Query returns list
- `test_get_transactions_for_month_no_transactions_returns_empty`: No transactions = empty list
- `test_get_transactions_for_month_with_transaction`: Returns inserted transaction
- `test_get_transactions_for_month_excludes_other_months`: Only returns specified month

**Total: 41 integration tests**

---

## Test Summary

| Layer | File | Test Count | Type |
|-------|------|-----------|------|
| Business | test_service.py | 20 | Unit tests (mocked deps) |
| Presentation | test_router.py | 23 | Integration tests (mocked service) |
| Data | test_repository.py | 41 | Integration tests (real DB) |
| **Total** | | **84** | |

## Key Testing Patterns

### 1. Mocking Strategy

**Business Layer**: 
- Mock `AccountsRepository` returning seeded data
- Mock `Clock` returning fixed time
- No database access

**Presentation Layer**:
- Mock entire `AccountsService` 
- Mock `TokenService` for JWT generation
- Mock `AccountsRepository`
- Use FastAPI TestClient with mocked dependencies
- No database access

**Data Layer**:
- Use real database via `db_conn` fixture
- Create temporary test data (users, months, transactions)
- Verify queries against seeded reference data (accounts, envelopes, categories)
- Fixture cleanup truncates only transactional tables

### 2. Authentication Testing

All endpoints requiring auth test three scenarios:
1. Missing Authorization header → 401
2. Invalid/malformed token → 401
3. Valid token → 200 with correct response

### 3. Decimal Handling

Repository methods return `Decimal` for financial amounts to maintain precision:
```python
result = Decimal(str(row["total"]))  # Avoids float rounding errors
```

### 4. Seeded Data Assumptions

Tests assume these 5 seeded accounts:
- ICICI (bank) funding Food (6000) + Misc (5000)
- SBI (bank) funding PartyOutsideTravel (4000)
- SLICE (bank) funding Rent (17000) + Electricity (100) + PhoneInternet (300)
- HDFC (fixed) with fixed_amount=2500 (funds no envelopes)
- CREDIT (pseudo_credit) for overage tracking

## Implementation Checklist

When implementing the actual feature code, ensure:

### Business Layer (service.py)
- [ ] `AccountsService` class with repository and clock dependencies
- [ ] `calculate_month_end_check()` method implementing expected-balance logic
- [ ] Correct envelope totals per account
- [ ] Expense deduction (is_overage=false only)
- [ ] Rollover/transfer/payoff additions
- [ ] HDFC fixed reserve handling
- [ ] Total net worth calculation

### Data Layer (repository.py)
- [ ] `get_all_accounts()` query
- [ ] `get_all_budget_envelopes()` query
- [ ] `get_month_id()` and `create_month()` for month lookup/creation
- [ ] `get_transactions_for_month()` with all required fields
- [ ] `sum_expenses_for_account_in_month()` aggregation query
- [ ] `sum_non_expense_transactions_for_account_in_month()` aggregation query
- [ ] `sum_monthly_amounts_for_account_envelopes()` aggregation query

### Presentation Layer (router.py + schemas.py)
- [ ] `AccountSchema` with id/code/display_name/kind/fixed_amount
- [ ] `MonthEndCheckResponse` schema
- [ ] `GET /accounts` endpoint with auth protection
- [ ] `GET /accounts/month-end-check` endpoint with auth protection
- [ ] Import and register router in backend/main.py

## Running the Tests

Once implementation is complete:

```bash
# Run all accounts tests
pytest backend/features/accounts/tests/

# Run specific layer
pytest backend/features/accounts/tests/business/test_service.py
pytest backend/features/accounts/tests/presentation/test_router.py
pytest backend/features/accounts/tests/data/test_repository.py

# With coverage
pytest --cov=backend/features/accounts backend/features/accounts/tests/

# Verbose output
pytest -v backend/features/accounts/tests/
```

**Note**: Data layer tests require a live test database (docker-compose.ci.yml on port 5433).

## Design Decisions

### 1. Expected Balance Calculation

Formula per bank account:
```
expected_balance = sum(envelope_amounts) - sum(expenses) + sum(non_expense_transactions)
```

Where:
- `sum(envelope_amounts)`: Monthly allocations for envelopes funded by account
- `sum(expenses)`: Transaction amount where type='expense' AND is_overage=false
- `sum(non_expense_transactions)`: Type IN ('transfer', 'rollover_sweep', 'credit_payoff')

### 2. HDFC Special Handling

HDFC is a fixed reserve account:
- Kind: 'fixed'
- fixed_amount: 2500.00
- Funds zero envelopes
- Returned as separate `hdfc_reserve` field, not per-account balance
- Always 2500, never calculated

### 3. Month Lookup

Months must be explicitly created in the database:
- `get_month_id()` returns None if not found
- `create_month()` inserts new month and returns id
- Unique constraint on (year, month)

### 4. Transaction Filtering

Expected-balance calculation must distinguish:
- Expenses (type='expense', is_overage=false) → subtract
- Overages (type='expense', is_overage=true) → exclude from expected balance
- Transfers/sweeps (type IN (...), no is_overage check) → add/subtract

## Future Considerations

1. **Pagination**: Accounts list might need pagination for large account sets
2. **Filtering**: Month-end check could support date range queries
3. **Caching**: Balance calculations could be cached if computed frequently
4. **Validation**: Consider envelope consistency checks (no gaps/overlaps)
5. **Auditing**: Add transaction reason/notes field for transparency
6. **Rollover Logic**: Implement automatic month-to-month rollover sweep logic

## References

- Schema: `backend/db/schema.sql`
- Seed data: `backend/db/seed.sql`
- Test fixtures: `backend/tests/conftest.py`
- Feature slice guide: Documentation in project README
- Auth pattern: `backend/features/auth/tests/`
