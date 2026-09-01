# Phase 0: Backend Foundation Build

## Overview
This document describes the Phase 0 foundation build for the finance dashboard backend. This phase establishes the plumbing and structure that later feature work (auth, transactions, credit management, etc.) will build on top of.

## Deletions
The following old files/directories were completely removed (git history preserves them):
- `backend/routers/` — deprecated router modules (auth, credit, debit, delete, get_data, mf_transaction)
- `backend/models/` — deprecated SQLAlchemy/Pydantic models
- `backend/services/` — deprecated service layer
- `backend/storage/` — deprecated storage utilities
- `backend/main.py.bak` — backup file
- `backend/schema.sql` — old schema file (replaced by `backend/db/schema.sql`)

## Files Created

### Database Layer
1. **backend/db/schema.sql**
   - Defines 8 core tables: `accounts`, `budget_envelopes`, `categories`, `users`, `months`, `transactions`, `credit_ledger`, `user_month_state`
   - Includes CHECK constraints for enum-like fields (e.g., account kind, transaction type)
   - Includes indexes on commonly queried transaction combinations (user_id, month_id, category_id and user_id, month_id, funding_account_id)
   - Foreign key relationships maintain referential integrity

2. **backend/db/seed.sql**
   - Seed data for accounts: ICICI (bank), SBI (bank), SLICE (bank), HDFC (fixed, 2500), CREDIT (pseudo_credit)
   - Seed data for budget envelopes: Food (6000, ICICI), PartyOutsideTravel (4000, SBI), Rent (17000, SLICE), Electricity (100, SLICE), PhoneInternet (300, SLICE), Misc (5000, ICICI)
   - Seed data for categories: food, rent, electricity, phone_internet, travel, party_outside, misc

### Core Configuration
3. **backend/core/__init__.py**
   - Empty init file for the core package

4. **backend/core/config.py**
   - `Settings` class loads configuration from environment variables
   - Defaults: DATABASE_URL (postgresql://finance_dashboard:...), JWT_SECRET, JWT_ALGORITHM (HS256), SALARY_TOTAL (46200), ACCESS_TOKEN_EXPIRE_MINUTES (30), REFRESH_TOKEN_EXPIRE_DAYS (7)
   - Exports singleton `settings` instance

5. **backend/core/db.py**
   - `SimpleConnectionPool` from psycopg2 for connection pooling (min=2, max=20)
   - `get_conn()` context manager: acquires connection, commits on success, rolls back on exception, always releases to pool
   - `get_db()` FastAPI dependency: yields a RealDictCursor for dict-like row access

6. **backend/core/clock.py**
   - `Clock` class with `now()` method returning `datetime.now(timezone.utc)`
   - `get_clock()` FastAPI dependency returns module-level singleton
   - Convention comment: never call `datetime.now()` directly; always use the injected dependency
   - Allows tests to monkeypatch/override time via dependency injection

### Features Layer
7. **backend/features/__init__.py**
   - Empty init file for the features package

8. **backend/features/credit/__init__.py**
   - Empty init file for the credit feature package

9. **backend/features/credit/business/__init__.py**
   - Empty init file for the business logic package

10. **backend/features/credit/business/interface.py**
    - `CreditLedgerInterface` abstract base class (ABC) defining the credit ledger interface
    - Three abstract methods (raise NotImplementedError):
      - `current_balance(user_id: int) -> Decimal` — returns balance owed to credit ledger
      - `record_overage(user_id: int, month_id: int, category_id: int, amount: Decimal, transaction_id: int) -> None` — records overage transaction
      - `settle(user_id: int, month_id: int, amount: Decimal, transaction_id: int) -> Decimal` — settles amount and returns remaining balance
    - One-line docstrings document intent only; implementations deferred to later phases

### Application Entry Point
11. **backend/main.py**
    - `create_app()` factory function creates and configures the FastAPI app
    - Adds CORSMiddleware (allow_origins=["*"] for now; restrict in production)
    - Registers startup event (currently a no-op TODO comment for rollover catch-up check)
    - Comments noting where feature routers will be registered in later phases
    - Mounts StaticFiles at "/" from "static" directory with html=True for SPA serving
    - StaticFiles mount is the last statement (critical for router precedence)
    - Exports `app = create_app()`

### Dependencies
12. **backend/req.txt**
    - Rewritten to include: fastapi, uvicorn, psycopg2-binary, python-jose[cryptography], passlib[bcrypt], bcrypt==4.0.1, pydantic[email], rapidfuzz, apscheduler, pytest, pytest-asyncio, httpx
    - Dropped: mftool (mutual funds feature out of scope)

### Testing Infrastructure
13. **backend/tests/__init__.py**
    - Empty init file for the tests package

14. **backend/tests/conftest.py**
    - `db_setup` fixture (session scope): drops and recreates the public schema, applies schema.sql and seed.sql once per test session
    - `db_conn` fixture: connects to test database, yields RealDictCursor, truncates (not drops) tables after each test to preserve schema/seed
    - `FrozenClock` class: extends Clock to return a fixed time
    - `frozen_clock` fixture: provides a callable to create FrozenClock instances for tests
    - Important comment: tests expect DATABASE_URL to point at a scratch/test database (from docker-compose.ci.yml), never the dev DB

15. **backend/pytest.ini**
    - testpaths = features tests (pytest discovers tests in these directories)
    - rootdir = . (rootdir is backend/)

### Docker & Deployment
16. **backend/Dockerfile**
    - Multi-stage build:
      - Stage 1 (frontend-build): ghcr.io/cirruslabs/flutter:stable, checks out frontend, builds web release
      - Stage 2 (backend): python:3.11-slim, installs Python dependencies, copies backend code, copies frontend build to ./static
      - Entrypoint: uvicorn main:app --host 0.0.0.0 --port 8000
    - Important comment: build context is REPO ROOT (not backend/), so COPY paths are relative to repo root

17. **/docker-compose.yml** (repo root)
    - `db` service: postgres:16, sets POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD (from env), mounts schema.sql and seed.sql for initialization, health check via pg_isready
    - `backend` service: builds from current Dockerfile, depends on db (service_healthy condition), mounts DATABASE_URL and JWT_SECRET from env, exposes port 8000
    - Named volume `db_data` for persistent database storage

18. **/docker-compose.ci.yml** (repo root)
    - `db` service only (no backend; CI runs pytest against this)
    - postgres:16 with tmpfs mount (/dev/shm) instead of named volume for ephemeral storage
    - Exposed on port 5433:5432 to avoid collision with dev compose
    - Health check and environment variables same as docker-compose.yml

### Configuration Examples
19. **/.env.example** (repo root)
    - POSTGRES_PASSWORD=changeme
    - JWT_SECRET=changeme-generate-a-real-secret
    - Users copy this to .env and populate with real secrets

### Transcript & Documentation
20. **docs/transcripts/phase0-backend.md** (this file)
    - Documents the complete Phase 0 build: deletions, file purposes, structure

## Summary of Architecture

### Directory Structure
```
finance_dashboard/
  backend/
    core/
      __init__.py
      config.py        # Settings singleton
      db.py            # Connection pool & FastAPI dependency
      clock.py         # Clock singleton for time injection
    db/
      schema.sql       # Database schema
      seed.sql         # Initial data
    features/
      __init__.py
      credit/
        __init__.py
        business/
          __init__.py
          interface.py # Abstract credit ledger interface
    tests/
      __init__.py
      conftest.py      # Pytest fixtures
    Dockerfile
    main.py            # FastAPI app factory
    pytest.ini         # Pytest configuration
    req.txt            # Python dependencies
  docker-compose.yml
  docker-compose.ci.yml
  .env.example
  docs/
    transcripts/
      phase0-backend.md
```

### Key Design Decisions

1. **Dependency Injection via FastAPI Dependencies**: The `get_db()` and `get_clock()` dependencies allow:
   - Easy connection management with automatic cleanup
   - Time-mockable behavior in tests (frozen_clock fixture)
   - Future feature implementations to inject these without coupling to implementation details

2. **Abstract Interface for Credit Logic**: `CreditLedgerInterface` defines the contract for credit ledger operations without implementation. This allows multiple implementations (in-memory, database-backed, etc.) in later phases without changing the interface.

3. **Connection Pooling**: `SimpleConnectionPool` reduces connection churn; configured with safe min/max bounds.

4. **Schema as Code**: SQL schema and seed data are version-controlled and automatically applied via docker-entrypoint-initdb.d scripts.

5. **Multi-stage Docker Build**: Separates frontend build (Flutter web) from backend (Python), keeps final image small by not including Flutter SDK.

6. **StaticFiles Mount as Last Router**: FastAPI must mount static files last to ensure API routes take precedence.

7. **Test Isolation via Truncation**: Tests truncate (not drop) tables after each run, preserving schema and allowing quick re-setup via seed reinsertion in future phases.

## TODOs for Later Phases

1. **Authentication & Authorization (Phase 1?)**
   - Implement `features/auth/` routers and services
   - Wire JWT token generation/validation
   - Include auth routers in main.py

2. **Transaction Management (Phase 1?)**
   - Implement `features/transactions/` routers and services
   - Wire transaction creation, querying, editing
   - Use db dependency for cursor-based queries

3. **Credit Ledger Implementation**
   - Implement `CreditLedgerInterface` with concrete logic
   - Register in feature router(s)
   - Add transaction handling for overage/payoff flows

4. **Rollover Logic**
   - Implement the startup event in main.py that performs rollover catch-up checks
   - Use APScheduler (already in req.txt) for scheduled rollover tasks if needed

5. **Error Handling & Logging**
   - Add structured logging (e.g., Python logging with JSON formatters)
   - Add global exception handlers in FastAPI

6. **Database Migrations**
   - Consider Alembic for schema versioning as the app grows beyond Phase 0

7. **Environment-Specific Configuration**
   - Load ALLOWED_ORIGINS from config for non-dev environments
   - Add separate production/staging configs

8. **Comprehensive Test Suite**
   - Add tests for core modules (db connection, clock injection, config loading)
   - Add integration tests using the db_conn fixture
   - Add endpoint tests once routers are implemented

9. **Frontend Static Files**
   - Ensure flutter build web output lands in backend/static/ (or create empty static/ for now)
   - Set up CI/CD to build frontend and copy artifacts before backend build

10. **Performance & Monitoring**
    - Add query logging/profiling
    - Add health check endpoint
    - Add metrics collection (e.g., Prometheus)

## Notes on Deviations

- No deviations from the provided specification.
- All syntax checks (via `python3 -m py_compile`) passed successfully.

## Database Setup & First Run

To get started:

1. Copy `.env.example` to `.env` and populate with real secrets:
   ```bash
   cp .env.example .env
   # Edit .env and set POSTGRES_PASSWORD and JWT_SECRET
   ```

2. Start the stack with docker-compose:
   ```bash
   docker-compose up -d
   ```

   This will:
   - Start PostgreSQL 16 container
   - Run schema.sql and seed.sql on initialization
   - Build the backend Docker image (will fail frontend build on first run if Flutter not available)
   - Start the backend on port 8000

3. For testing, run against docker-compose.ci.yml:
   ```bash
   docker-compose -f docker-compose.ci.yml up -d
   export DATABASE_URL=postgresql://finance_dashboard:testpassword@localhost:5433/finance_dashboard
   pytest
   ```

4. Once feature routers are implemented, include them in `main.py` and they will be served at their registered prefixes.
