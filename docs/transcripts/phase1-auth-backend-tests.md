# Phase 1: Auth Backend Tests

**Date:** 2026-09-01  
**Status:** Tests written (TDD phase)  
**Objective:** Write comprehensive pytest tests for the auth feature before implementation.

## Overview

This phase implements a Test-Driven Development (TDD) workflow for the auth feature. Three comprehensive test suites were written covering:

1. **Service layer** (business logic): password hashing/verification and JWT encoding/decoding
2. **Router layer** (API endpoints): HTTP status codes, request validation, response shapes
3. **Repository layer** (data access): database constraints, user lookups, error handling

All tests are written **before implementation** — they define the contract that the implementation must satisfy.

## Architecture

The auth feature follows the feature-sliced design established in the codebase:

```
backend/features/auth/
├── tests/
│   ├── __init__.py
│   ├── test_service.py       # Unit tests: password hashing + JWT
│   ├── test_router.py        # Integration tests: FastAPI endpoints
│   └── test_repository.py    # Integration tests: database operations
├── business/                 # (NOT YET WRITTEN — to be implemented)
│   ├── service.py           # Password hasher, token service
│   └── __init__.py
├── data/                    # (NOT YET WRITTEN — to be implemented)
│   ├── repository.py        # User CRUD operations
│   └── __init__.py
├── presentation/            # (NOT YET WRITTEN — to be implemented)
│   ├── router.py            # FastAPI endpoints
│   ├── schemas.py           # Pydantic request/response models
│   └── __init__.py
└── __init__.py
```

## Database Schema

The auth feature uses the `users` table from `backend/db/schema.sql`:

```sql
CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

Key constraints:
- **user_id**: Auto-incrementing primary key
- **username**: Unique, case-sensitive, required
- **email**: Unique, case-sensitive, required (255 chars to support long email addresses)
- **password_hash**: Required, supports bcrypt hashes (60+ chars)
- **created_at**: Automatically set to current timestamp on insert

## Test Suites

### 1. Service Layer Tests (`test_service.py`)

**Scope:** Unit tests for business logic — password hashing, JWT encoding/decoding, token expiration.  
**Mocking:** Repository is mocked; only core cryptographic operations are tested.  
**Execution:** No database required.

#### Password Hashing Tests

- ✓ `hash_password()` returns a non-empty bcrypt hash string
- ✓ Hash produces different output each time (due to random salt)
- ✓ `verify_password()` succeeds with correct plain password
- ✓ `verify_password()` fails with incorrect password
- ✓ Password verification is case-sensitive
- ✓ `verify_password()` fails with empty password

#### JWT Token Creation Tests

- ✓ `create_access_token()` returns a valid JWT string with three parts (header.payload.signature)
- ✓ Access token payload includes user_id in `sub` claim
- ✓ Access token has `token_type="access"` claim
- ✓ `create_refresh_token()` returns a valid JWT string
- ✓ Refresh token payload includes user_id in `sub` claim
- ✓ Refresh token has `token_type="refresh"` claim

#### JWT Token Decoding Tests

- ✓ `decode_token()` returns payload dict for valid token
- ✓ `decode_token()` raises `jwt.InvalidTokenError` for tampered signature
- ✓ `decode_token()` raises `jwt.InvalidTokenError` for malformed tokens
- ✓ `decode_token()` raises `jwt.InvalidTokenError` for empty tokens
- ✓ `get_user_id_from_token()` extracts and returns user_id as int
- ✓ `get_user_id_from_token()` raises for invalid tokens

#### Token Expiration Tests

- ✓ Access token expires after configured minutes (default: 30)
- ✓ Refresh token expires after configured days (default: 7)
- ✓ Expired token raises `jwt.ExpiredSignatureError` on decode
- ✓ Token is valid at exact moment of expiration

### 2. Router Layer Tests (`test_router.py`)

**Scope:** Integration tests for API endpoints using FastAPI TestClient.  
**Mocking:** Repository is mocked; tests focus on HTTP routing, validation, and response structure.  
**Execution:** No database required; FastAPI dependency injection allows repository mocking.

#### POST /auth/register Endpoint

- ✓ Valid registration returns 201 Created
- ✓ Response includes user_id, username, email
- ✓ Duplicate username returns 409 Conflict
- ✓ Duplicate email returns 409 Conflict
- ✓ Missing username returns 422 Unprocessable Entity
- ✓ Missing email returns 422
- ✓ Missing password returns 422
- ✓ Empty username returns 422
- ✓ Empty password returns 422

#### POST /auth/login Endpoint

- ✓ Valid credentials return 200 OK
- ✓ Response includes access_token string
- ✓ Response includes refresh_token string
- ✓ Returned tokens are valid JWTs decodable with settings.JWT_SECRET
- ✓ Nonexistent user returns 401 Unauthorized
- ✓ Wrong password returns 401
- ✓ Missing username returns 422
- ✓ Missing password returns 422
- ✓ Response includes `token_type="bearer"`

#### POST /auth/refresh Endpoint

- ✓ Valid refresh_token returns 200 OK
- ✓ Returns a new access_token different from original
- ✓ Returned access_token is valid JWT
- ✓ Invalid refresh_token returns 401
- ✓ Using access_token instead of refresh_token returns 401 (token_type validation)
- ✓ Missing refresh_token returns 422
- ✓ Response includes `token_type="bearer"`

#### get_current_user Dependency

- ✓ Valid Bearer token returns user_id
- ✓ Missing Authorization header returns 401
- ✓ Malformed Bearer header format returns 401

### 3. Repository Layer Tests (`test_repository.py`)

**Scope:** Integration tests against real database using `db_conn` fixture.  
**Mocking:** None — tests directly execute SQL and validate database constraints.  
**Execution:** Requires ephemeral test Postgres (docker-compose.ci.yml, port 5433).

#### User Insertion Tests

- ✓ Insert creates record with username, email, password_hash
- ✓ Inserted user has auto-incremented user_id
- ✓ Inserted user has created_at timestamp
- ✓ Multiple users can be inserted with different usernames

#### Username Uniqueness Tests

- ✓ Duplicate username raises `psycopg2.IntegrityError`
- ✓ Username comparison is case-sensitive (TestUser ≠ testuser)

#### Email Uniqueness Tests

- ✓ Duplicate email raises `psycopg2.IntegrityError`
- ✓ Email comparison is case-sensitive (Test@Example.com ≠ test@example.com)

#### User Lookup by Username Tests

- ✓ Lookup existing user returns record with correct fields
- ✓ Lookup nonexistent user returns None
- ✓ Username lookup is case-sensitive
- ✓ Lookup works with special characters in username (e.g., user_123-test)

#### User Lookup by Email Tests

- ✓ Lookup existing user returns record with correct fields
- ✓ Lookup nonexistent user returns None
- ✓ Email lookup is case-sensitive
- ✓ Lookup works with complex email formats (e.g., user+tag@sub.example.co.uk)

#### Password Hash Storage Tests

- ✓ Password hash is stored and retrieved exactly as provided
- ✓ Long bcrypt hashes (60+ chars) are supported
- ✓ NULL password_hash is rejected (NOT NULL constraint)

#### Constraint Interaction Tests

- ✓ Second insert with same username and email fails on username uniqueness
- ✓ Failed insert doesn't break transaction (subsequent queries still work)

## Configuration

All tests use configuration from `backend/core/config.py`:

- **JWT_SECRET:** Environment variable `JWT_SECRET`, default: `"your-secret-key-change-in-production"`
- **JWT_ALGORITHM:** `HS256` (hardcoded)
- **ACCESS_TOKEN_EXPIRE_MINUTES:** Environment variable, default: `30`
- **REFRESH_TOKEN_EXPIRE_DAYS:** Environment variable, default: `7`

## Test Execution

Tests use pytest fixtures from `backend/tests/conftest.py`:

### db_conn Fixture
- **Scope:** Per-test
- **Setup:** Schema and seed data created in session-scoped `db_setup` fixture
- **Teardown:** Truncates `users`, `months`, `user_month_state`, `credit_ledger`, `transactions` tables; seed data (accounts, budget_envelopes, categories) persist

### frozen_clock Fixture
- **Scope:** Per-test
- **Type:** Returns a `FrozenClock` instance for time mocking
- **Usage:** For testing token expiration with controlled time

### Running Tests

```bash
# All auth tests
pytest backend/features/auth/tests/ -v

# Specific test file
pytest backend/features/auth/tests/test_service.py -v

# Specific test class
pytest backend/features/auth/tests/test_router.py::TestRegisterEndpoint -v

# Specific test
pytest backend/features/auth/tests/test_service.py::TestPasswordHashing::test_verify_password_fails_with_incorrect_password -v
```

**Prerequisite:** Test database must be running (docker-compose.ci.yml):
```bash
docker-compose -f docker-compose.ci.yml up -d postgres
```

## Next Phase: Implementation

The implementation phase will write the following files:

### `backend/features/auth/business/service.py`
- `PasswordHasher` class with `hash_password()` and `verify_password()` methods
- `TokenService` class with JWT encoding/decoding methods
- Dependencies: `get_password_hasher()`, `get_token_service()` for FastAPI injection

### `backend/features/auth/data/repository.py`
- `AuthRepository` class with methods:
  - `insert_user(username, email, password_hash) -> user_id`
  - `get_user_by_username(username) -> dict | None`
  - `get_user_by_email(email) -> dict | None`
- Handles database-level duplicate constraint errors gracefully

### `backend/features/auth/presentation/router.py`
- FastAPI APIRouter at `/auth` prefix
- Endpoints: POST `/register`, POST `/login`, POST `/refresh`
- Dependency: `get_current_user` for authenticated endpoints

### `backend/features/auth/presentation/schemas.py`
- Pydantic models:
  - `RegisterRequest`, `LoginRequest`, `RefreshRequest`
  - `TokenResponse`, `UserResponse`

### `backend/main.py`
- Register auth router with app

All implementations will be validated against these test suites using:
```bash
pytest backend/features/auth/tests/ -v
```

## Notes

- **No real passwords stored:** Tests use plain "test_password_123" and hashed variants; implementation will use actual bcrypt hashing
- **Mock repository pattern:** `test_router.py` mocks repository to isolate endpoint logic; `test_repository.py` tests DB access directly
- **JWT validation:** Tests verify token structure, expiration, and type discrimination (access vs refresh)
- **Constraint testing:** `test_repository.py` validates database-level uniqueness constraints
- **Error handling:** Tests verify HTTP status codes (401, 409, 422) for all error scenarios

## References

- Feature structure: `backend/features/auth/`
- Existing fixtures: `backend/tests/conftest.py`
- Configuration: `backend/core/config.py`
- Database schema: `backend/db/schema.sql`
- Main app factory: `backend/main.py`
