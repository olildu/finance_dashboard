"""
Accounts API endpoints: list accounts and month-end check.

Requires authentication (valid Bearer token).
Depends on backend/features/auth's get_current_user dependency.
"""

from fastapi import APIRouter, Depends

from core.clock import get_clock
from core.db import get_db
from features.auth.presentation.router import get_current_user
from features.accounts.business.service import AccountsService
from features.accounts.data.repository import AccountsRepository
from features.accounts.presentation.schemas import AccountSchema, MonthEndCheckResponse

router = APIRouter(prefix="/accounts", tags=["accounts"])


def get_accounts_repository(db=Depends(get_db)) -> AccountsRepository:
    """Dependency: accounts repository with database cursor."""
    return AccountsRepository(db)


def get_accounts_service(
    repository: AccountsRepository = Depends(get_accounts_repository),
    clock=Depends(get_clock),
) -> AccountsService:
    """Dependency: accounts service with repository and clock."""
    return AccountsService(repository, clock)


@router.get("", response_model=list[AccountSchema])
def list_accounts(
    current_user_id: int = Depends(get_current_user),
    service: AccountsService = Depends(get_accounts_service),
):
    """
    Get all accounts for the current user.

    Requires Bearer token authentication.

    Returns:
        List of all accounts: [{"id": int, "code": str, "display_name": str, "kind": str, "fixed_amount": float|None}, ...]
    """
    accounts = service.get_all_accounts()
    return [
        AccountSchema(
            id=acc["id"],
            code=acc["code"],
            display_name=acc["display_name"],
            kind=acc["kind"],
            fixed_amount=acc["fixed_amount"],
        )
        for acc in accounts
    ]


@router.get("/month-end-check", response_model=MonthEndCheckResponse)
def month_end_check(
    current_user_id: int = Depends(get_current_user),
    service: AccountsService = Depends(get_accounts_service),
):
    """
    Get expected balances for current month.

    Calculates expected balance for each bank account (ICICI/SBI/SLICE) based on:
    - Envelope funding amounts
    - Expense transactions
    - Transfers/rollover sweeps

    HDFC reserve is read from accounts.fixed_amount.

    Requires Bearer token authentication.

    Returns:
        {
            "ICICI": {"expected_balance": float},
            "SBI": {"expected_balance": float},
            "SLICE": {"expected_balance": float},
            "hdfc_reserve": float,
            "total_net_worth": float
        }
    """
    now = service.clock.now()
    result = service.calculate_month_end_check(
        user_id=current_user_id,
        year=now.year,
        month=now.month,
    )
    return MonthEndCheckResponse(**result)
