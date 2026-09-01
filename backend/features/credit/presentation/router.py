"""
Credit API endpoints.

Provides GET /balance and GET /history endpoints for retrieving credit ledger
information (balance owed and transaction history).
"""

from fastapi import APIRouter, Depends

from core.db import get_db
from features.auth.presentation.router import get_current_user
from features.credit.data.repository import CreditRepository
from features.credit.presentation.schemas import (
    CreditBalanceResponse,
    CreditHistoryResponse,
)

router = APIRouter(tags=["credit"])


def get_credit_repository(db=Depends(get_db)) -> CreditRepository:
    """Dependency: credit repository with database cursor."""
    return CreditRepository(db)


@router.get("/balance", response_model=CreditBalanceResponse)
def get_balance(
    current_user_id: int = Depends(get_current_user),
    repository: CreditRepository = Depends(get_credit_repository),
):
    """
    Get the current credit balance owed by the authenticated user.

    Requires authentication via Bearer token in Authorization header.

    Returns the current balance owed to the credit ledger.
    """
    balance = repository.sum_balance(current_user_id)
    return CreditBalanceResponse(balance=balance)


@router.get("/history", response_model=CreditHistoryResponse)
def get_history(
    current_user_id: int = Depends(get_current_user),
    repository: CreditRepository = Depends(get_credit_repository),
):
    """
    Get the credit ledger transaction history for the authenticated user.

    Requires authentication via Bearer token in Authorization header.

    Returns a list of credit ledger entries with amounts, types, and timestamps.
    """
    entries = repository.get_history(current_user_id)
    return CreditHistoryResponse(entries=entries)
