"""
Rollover API endpoints.

Provides POST /run-check for manually triggering a rollover check for the
current user. The automatic trigger is the scheduler (business/scheduler.py),
which builds its own engine per run across all users — this endpoint is a
debug/manual escape hatch, built fresh per request via dependency injection
(never a long-lived global engine, which was the source of a serious
commit/idempotency bug in an earlier version of this feature).
"""

from decimal import Decimal

from fastapi import APIRouter, Depends

from core.clock import get_clock
from core.config import settings
from core.db import get_db
from features.accounts.data.repository import AccountsRepository
from features.auth.presentation.router import get_current_user
from features.credit.business.service import CreditService
from features.credit.data.repository import CreditRepository
from features.rollover.business.engine import RolloverEngine
from features.rollover.data.repository import RolloverRepository
from features.rollover.presentation.schemas import RolloverRunResult
from features.transactions.data.repository import TransactionsRepository

router = APIRouter()

SLICE_ACCOUNT_CODE = "SLICE"


def get_rollover_engine(db=Depends(get_db), clock=Depends(get_clock)) -> RolloverEngine:
    """
    Build a RolloverEngine for this request, sharing one DB cursor/connection
    across every repository so the whole rollover run commits atomically when
    the request completes (via core.db.get_conn()'s commit-on-success).
    """
    rollover_repo = RolloverRepository(db, clock)
    transactions_repo = TransactionsRepository(db)
    accounts_repo = AccountsRepository(db)
    credit_service = CreditService(CreditRepository(db))

    slice_account_id = transactions_repo.get_account_id_by_code(SLICE_ACCOUNT_CODE)

    return RolloverEngine(
        rollover_repository=rollover_repo,
        transactions_repository=transactions_repo,
        budget_envelopes_lookup=accounts_repo.get_all_budget_envelopes,
        credit_ledger_interface=credit_service,
        clock=clock,
        salary_total=Decimal(str(settings.SALARY_TOTAL)),
        slice_account_id=slice_account_id,
    )


@router.post("/run-check", response_model=RolloverRunResult)
def run_rollover_check(
    current_user_id: int = Depends(get_current_user),
    engine: RolloverEngine = Depends(get_rollover_engine),
):
    """
    Manually trigger a rollover check for the current user.

    Requires authentication via Bearer token in Authorization header.
    """
    results = engine.run_rollover_check(user_id=current_user_id)

    return RolloverRunResult(
        months_closed=[r["month_id"] for r in results],
        credit_settled_amounts=[Decimal(str(r["credit_settled_amount"])) for r in results],
        sweep_amounts=[Decimal(str(r["sweep_amount"])) for r in results],
    )
