"""
Integration tests for rollover API endpoints.

Uses FastAPI TestClient with dependency_overrides against the REAL router,
overriding only the auth dependency and the get_rollover_engine dependency
(which builds a real DB-backed engine per request in production — here we
override it with a mock engine so these are pure route/wiring tests, not
integration tests of the engine itself, which is covered in test_engine.py).
"""

from datetime import timedelta
from decimal import Decimal
from unittest.mock import Mock

import jwt
import pytest
from fastapi import FastAPI, HTTPException, Header
from fastapi.testclient import TestClient

from core.config import settings
from core.clock import Clock
from features.auth.presentation.router import get_current_user
from features.rollover.presentation.router import router, get_rollover_engine


class MockTokenService:
    """Mock JWT token service for testing."""

    def __init__(self, secret: str, algorithm: str, clock: Clock):
        self.secret = secret
        self.algorithm = algorithm
        self.clock = clock

    def create_access_token(self, user_id: int, expires_in_minutes: int) -> str:
        now = self.clock.now()
        expiry = now + timedelta(minutes=expires_in_minutes)
        payload = {"sub": str(user_id), "exp": expiry, "iat": now, "token_type": "access"}
        return jwt.encode(payload, self.secret, algorithm=self.algorithm)

    def get_user_id_from_token(self, token: str) -> int:
        payload = jwt.decode(token, self.secret, algorithms=[self.algorithm])
        return int(payload["sub"])


@pytest.fixture
def mock_clock():
    return Clock()


@pytest.fixture
def mock_token_service(mock_clock):
    return MockTokenService(settings.JWT_SECRET, settings.JWT_ALGORITHM, mock_clock)


@pytest.fixture
def mock_rollover_engine():
    engine = Mock()
    engine.run_rollover_check = Mock(return_value=[])
    return engine


@pytest.fixture
def client(mock_token_service, mock_rollover_engine):
    """Real router, real /run-check prefix, mocked auth + mocked engine."""
    app = FastAPI()
    app.include_router(router, prefix="/rollover")

    def mock_get_current_user(authorization: str = Header(None)) -> int:
        if not authorization:
            raise HTTPException(status_code=401, detail="Missing authorization header")
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header format")
        try:
            return mock_token_service.get_user_id_from_token(authorization[7:])
        except jwt.InvalidTokenError:
            raise HTTPException(status_code=401, detail="Invalid or expired token")

    app.dependency_overrides[get_current_user] = mock_get_current_user
    app.dependency_overrides[get_rollover_engine] = lambda: mock_rollover_engine

    return TestClient(app)


def auth_header(mock_token_service, user_id=1):
    token = mock_token_service.create_access_token(user_id=user_id, expires_in_minutes=30)
    return {"Authorization": f"Bearer {token}"}


class TestRunCheckAuthenticationRequired:
    def test_run_check_without_token_returns_401(self, client):
        response = client.post("/rollover/run-check")
        assert response.status_code == 401
        assert "Missing authorization header" in response.json()["detail"]

    def test_run_check_with_invalid_bearer_format_returns_401(self, client):
        response = client.post(
            "/rollover/run-check", headers={"Authorization": "InvalidBearer sometoken"}
        )
        assert response.status_code == 401

    def test_run_check_with_invalid_token_returns_401(self, client):
        response = client.post(
            "/rollover/run-check", headers={"Authorization": "Bearer invalid.token.here"}
        )
        assert response.status_code == 401

    def test_run_check_with_valid_token_returns_200(self, client, mock_token_service):
        response = client.post("/rollover/run-check", headers=auth_header(mock_token_service))
        assert response.status_code == 200


class TestRunCheckResponseFormat:
    def test_run_check_returns_rollover_run_result_shape(self, client, mock_token_service):
        response = client.post("/rollover/run-check", headers=auth_header(mock_token_service))
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["months_closed"], list)
        assert isinstance(data["credit_settled_amounts"], list)
        assert isinstance(data["sweep_amounts"], list)

    def test_run_check_returns_empty_lists_when_no_months_closed(
        self, client, mock_token_service, mock_rollover_engine
    ):
        mock_rollover_engine.run_rollover_check.return_value = []
        response = client.post("/rollover/run-check", headers=auth_header(mock_token_service))
        assert response.status_code == 200
        data = response.json()
        assert data["months_closed"] == []
        assert data["credit_settled_amounts"] == []
        assert data["sweep_amounts"] == []

    def test_run_check_lists_are_same_length(self, client, mock_token_service, mock_rollover_engine):
        mock_rollover_engine.run_rollover_check.return_value = [
            {"month_id": 6, "credit_settled_amount": Decimal("500.00"), "sweep_amount": Decimal("13800.00")},
            {"month_id": 7, "credit_settled_amount": Decimal("0.00"), "sweep_amount": Decimal("15800.00")},
        ]
        response = client.post("/rollover/run-check", headers=auth_header(mock_token_service))
        assert response.status_code == 200
        data = response.json()
        num_closed = len(data["months_closed"])
        assert num_closed == 2
        assert len(data["credit_settled_amounts"]) == num_closed
        assert len(data["sweep_amounts"]) == num_closed

    def test_run_check_returns_correct_month_ids(self, client, mock_token_service, mock_rollover_engine):
        mock_rollover_engine.run_rollover_check.return_value = [
            {"month_id": 6, "credit_settled_amount": Decimal("100"), "sweep_amount": Decimal("14000")},
            {"month_id": 7, "credit_settled_amount": Decimal("200"), "sweep_amount": Decimal("14100")},
            {"month_id": 8, "credit_settled_amount": Decimal("0"), "sweep_amount": Decimal("14200")},
        ]
        response = client.post("/rollover/run-check", headers=auth_header(mock_token_service))
        assert response.status_code == 200
        assert response.json()["months_closed"] == [6, 7, 8]

    def test_run_check_returns_decimal_amounts(self, client, mock_token_service, mock_rollover_engine):
        mock_rollover_engine.run_rollover_check.return_value = [
            {"month_id": 6, "credit_settled_amount": Decimal("250.75"), "sweep_amount": Decimal("13800.50")},
        ]
        response = client.post("/rollover/run-check", headers=auth_header(mock_token_service))
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["credit_settled_amounts"][0], (int, float, str))
        assert isinstance(data["sweep_amounts"][0], (int, float, str))
        assert float(data["credit_settled_amounts"][0]) == 250.75
        assert float(data["sweep_amounts"][0]) == 13800.50


class TestRunCheckEngineIntegration:
    def test_run_check_calls_engine_with_correct_user_id(self, client, mock_token_service, mock_rollover_engine):
        response = client.post("/rollover/run-check", headers=auth_header(mock_token_service, user_id=42))
        assert response.status_code == 200
        mock_rollover_engine.run_rollover_check.assert_called_once_with(user_id=42)

    def test_run_check_different_users_get_different_results(self, client, mock_token_service, mock_rollover_engine):
        mock_rollover_engine.run_rollover_check.side_effect = [
            [{"month_id": 6, "credit_settled_amount": Decimal("100"), "sweep_amount": Decimal("14000")}],
            [{"month_id": 7, "credit_settled_amount": Decimal("200"), "sweep_amount": Decimal("14100")}],
        ]

        response1 = client.post("/rollover/run-check", headers=auth_header(mock_token_service, user_id=1))
        response2 = client.post("/rollover/run-check", headers=auth_header(mock_token_service, user_id=2))

        assert response1.status_code == 200
        assert response2.status_code == 200
        assert response1.json()["months_closed"] == [6]
        assert response2.json()["months_closed"] == [7]


class TestRunCheckContentType:
    def test_run_check_returns_json_response(self, client, mock_token_service):
        response = client.post("/rollover/run-check", headers=auth_header(mock_token_service))
        assert response.status_code == 200
        assert response.headers["content-type"] == "application/json"
