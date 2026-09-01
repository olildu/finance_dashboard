from contextlib import asynccontextmanager
from decimal import Decimal
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from psycopg2.extras import RealDictCursor

# Feature routers will be imported and registered here in later phases:
from features.auth.presentation.router import router as auth_router
from features.accounts.presentation.router import router as accounts_router
from features.categories.presentation.router import router as categories_router
from features.transactions.presentation.router import router as transactions_router
from features.budgets.presentation.router import router as budgets_router
from features.credit.presentation.router import router as credit_router
from features.dashboard.presentation.router import router as dashboard_router
from features.rollover.presentation.router import router as rollover_router, SLICE_ACCOUNT_CODE
from features.rollover.business.scheduler import setup_rollover_scheduler, shutdown_scheduler
from features.rollover.business.engine import RolloverEngine
from features.rollover.data.repository import RolloverRepository
from features.transactions.data.repository import TransactionsRepository
from features.accounts.data.repository import AccountsRepository
from features.auth.data.repository import AuthRepository
from features.credit.business.service import CreditService
from features.credit.data.repository import CreditRepository
from core.config import settings
from core.clock import Clock
from core.db import get_conn

# etc.

logger = logging.getLogger(__name__)


async def run_rollover_check_all_users() -> None:
    """
    Run the rollover check for every user, once per scheduler tick.

    Opens its own short-lived DB connection per run (never a connection held
    for the app's whole lifetime) so the transaction commits cleanly via
    get_conn()'s commit-on-success and doesn't hold locks indefinitely.
    A failure for one user is logged and does not stop the others.
    """
    clock = Clock()
    with get_conn() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        auth_repo = AuthRepository(cursor)
        rollover_repo = RolloverRepository(cursor, clock)
        transactions_repo = TransactionsRepository(cursor)
        accounts_repo = AccountsRepository(cursor)
        credit_service = CreditService(CreditRepository(cursor))
        slice_account_id = transactions_repo.get_account_id_by_code(SLICE_ACCOUNT_CODE)

        engine = RolloverEngine(
            rollover_repository=rollover_repo,
            transactions_repository=transactions_repo,
            budget_envelopes_lookup=accounts_repo.get_all_budget_envelopes,
            credit_ledger_interface=credit_service,
            clock=clock,
            salary_total=Decimal(str(settings.SALARY_TOTAL)),
            slice_account_id=slice_account_id,
        )

        for user_id in auth_repo.list_all_user_ids():
            try:
                closed = engine.run_rollover_check(user_id)
                if closed:
                    logger.info("Rollover closed %d month(s) for user %d", len(closed), user_id)
            except Exception:
                logger.exception("Rollover check failed for user %d", user_id)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application startup and shutdown."""
    logger.info("Starting rollover scheduler...")
    await setup_rollover_scheduler(run_rollover_check_all_users)

    yield

    logger.info("Shutting down rollover scheduler...")
    await shutdown_scheduler()


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(title="Finance Dashboard API", lifespan=lifespan)

    # Add CORS middleware (permissive for now, restrict in production)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Feature routers will be registered here in later phases:
    app.include_router(auth_router, prefix="/auth")
    app.include_router(accounts_router)
    app.include_router(categories_router)
    app.include_router(transactions_router)
    app.include_router(budgets_router, prefix="/budgets")
    app.include_router(credit_router, prefix="/credit")
    app.include_router(dashboard_router, prefix="/dashboard")
    app.include_router(rollover_router, prefix="/rollover")
    # etc.

    # Mount static files (frontend build) as the last statement
    # This serves the frontend SPA with fallback to index.html
    app.mount("/", StaticFiles(directory="static", html=True), name="static")

    return app


app = create_app()
