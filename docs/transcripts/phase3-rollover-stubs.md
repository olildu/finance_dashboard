# Phase 3: Rollover Feature Stubs

**Date:** 2025-09-01  
**Status:** Stub implementation (all bodies raise NotImplementedError)

## Summary

Created the complete stub structure for the rollover feature—the monthly settle, refill, and sweep engine. This phase establishes the API contracts, data layer interfaces, and business logic skeleton without implementing real database queries or transaction processing.

## Files Created

### 1. Data Layer: `backend/features/rollover/data/repository.py`

**RolloverRepository** class with four stub methods:

- **`get_or_create_month(year: int, month: int) -> int`**
  - Fetches or creates a month record.
  - Returns the month_id.

- **`get_unclosed_months_before(user_id: int, current_month_id: int) -> list[dict]`**
  - Retrieves all months that have no 'rolled_over' status in `user_month_state` for this user, strictly before the current month.
  - Returns in chronological order: `[{id, year, month}, ...]`

- **`get_or_create_month_state_locked(user_id: int, month_id: int) -> dict`**
  - Fetches or creates a `user_month_state` row with **row-level locking** (SELECT...FOR UPDATE or INSERT...ON CONFLICT).
  - Returns: `{id, user_id, month_id, status, credit_settled_amount, sweep_amount}`
  - **Design note:** Uses atomic locking to prevent concurrent rollover attempts on the same month.

- **`mark_rolled_over(state_id: int, credit_settled_amount: Decimal, sweep_amount: Decimal) -> None`**
  - Marks a month_state row as 'rolled_over' and records settlement/sweep amounts.
  - Sets `status = 'rolled_over'`, `credit_settled_amount`, `sweep_amount`, and `rolled_over_at = current_timestamp`.

### 2. Business Logic: `backend/features/rollover/business/engine.py`

**RolloverEngine** class encapsulating the monthly rollover algorithm.

**Constructor parameters:**
- `rollover_repository`: RolloverRepository
- `transactions_repository`: TransactionsRepository (for inserting payoff/sweep)
- `budget_envelopes_lookup`: Method or repository to fetch all envelopes with `monthly_amount` and account info
- `credit_ledger_interface`: CreditLedgerInterface (for settling credit debt)
- `clock`: Clock (for getting current month)
- `slice_account_id`: Account ID for the Slice (pseudo-credit) account
- `credit_account_id`: Account ID for the Credit account

**Stub method:**
- **`run_rollover_check(user_id: int) -> list[dict]`**
  - Returns: `[{month_id, credit_settled_amount, sweep_amount}, ...]` for all closed months.

**Embedded Algorithm Documentation:**

The engine implements a three-step rollover per unclosed month:

1. **Find Current Month**
   - Query the clock for the current month.

2. **For Each Unclosed Month (Chronological Order)**

   a. **Settle Credit Debt (from Slice)**
      - Query the credit ledger for this month's outstanding balance.
      - Insert a `credit_payoff` transaction funded from Slice.
      - Call `credit_interface.settle(user_id, month_id, amount, transaction_id)`.

   b. **Refill (No-op)**
      - Spend is always derived fresh from transactions; no refill action needed.

   c. **Sweep Leftovers + Fixed Allocation**
      - Calculate per-envelope leftover: `monthly_amount - spend_this_month`.
      - Never go negative; negative overage is already in the credit ledger.
      - Sum all leftover amounts.
      - Add the fixed amount: `SALARY_TOTAL - sum(all envelope monthly_amounts)`.
      - Insert a `rollover_sweep` transaction funded into Slice.

   d. **Mark Rolled Over**
      - Record settlement and sweep amounts in `user_month_state`.

### 3. Presentation Schemas: `backend/features/rollover/presentation/schemas.py`

**RolloverRunResult** Pydantic model:
- `months_closed: list[int]` — Month IDs that were rolled over.
- `credit_settled_amounts: list[Decimal]` — Settlement amounts (parallel to `months_closed`).
- `sweep_amounts: list[Decimal]` — Sweep amounts (parallel to `months_closed`).

### 4. API Router: `backend/features/rollover/presentation/router.py`

**Endpoint:** `POST /run-check`
- **Auth:** Requires Bearer token (current_user_id from token).
- **Response:** RolloverRunResult
- **Purpose:** Manual/debug trigger for rollover checks. Automatic triggering is managed by the scheduler.
- **Body:** NotImplementedError stub.

### 5. Scheduler: `backend/features/rollover/business/scheduler.py`

**Function:** `setup_scheduler(app_lifespan_context, run_check_fn) -> None`

**Behavior (documented in docstring):**
- Initializes an APScheduler AsyncIOScheduler.
- Runs `run_check_fn()` **immediately on startup** (catch-up after server restart).
- Runs `run_check_fn()` **every hour** thereafter.
- Attaches scheduler lifecycle to the FastAPI app lifespan.

**Stub body:** NotImplementedError

## Directory Structure

```
backend/features/rollover/
├── __init__.py
├── data/
│   ├── __init__.py
│   └── repository.py
├── business/
│   ├── __init__.py
│   ├── engine.py
│   └── scheduler.py
└── presentation/
    ├── __init__.py
    ├── schemas.py
    └── router.py
```

## Integration Points (Not Yet Implemented)

1. **Main app (`backend/main.py`)**
   - Need to import and register the rollover router.
   - Need to set up the scheduler in the lifespan.

2. **Database initialization**
   - Tables (`months`, `user_month_state`) are defined in `schema.sql`.
   - Accounts for SLICE and CREDIT are assumed to exist.

3. **Dependencies**
   - RolloverEngine constructor requires:
     - An envelopes lookup (can reuse CategoriesRepository or add a small method).
     - SLICE and CREDIT account IDs (hardcode in config or fetch on startup).

## Next Phase

- Implement real SQL queries in RolloverRepository.
- Implement the rollover algorithm in RolloverEngine.run_rollover_check().
- Implement the scheduler startup/shutdown hooks.
- Integrate router into main.py.
- Add integration and unit tests.

## Testing Reminders

- All database queries and transactions must use the real database (per project guidelines).
- No local class definitions duplicating production classes (boundary mocks only).
- Must write REAL assertions; no "isNotNull"-only tests.
- Frozen clock fixtures should be used from backend/conftest.py.
