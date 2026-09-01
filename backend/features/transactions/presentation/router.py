"""
Transactions API endpoints.

Provides endpoints for creating, listing, and deleting transactions.
All endpoints require authentication via Bearer token in Authorization header.
"""

from fastapi import APIRouter, Depends, HTTPException, status

from core.db import get_db
from core.clock import get_clock
from features.auth.presentation.router import get_current_user
from features.transactions.data.repository import TransactionsRepository
from features.transactions.business.service import TransactionsService
from features.categories.data.repository import CategoriesRepository
from features.credit.business.interface import CreditLedgerInterface
from features.transactions.presentation.schemas import (
    CreateTransactionRequest,
    TransactionResponse,
    TransactionListResponse,
)

router = APIRouter(prefix="/transactions", tags=["transactions"])


def get_transactions_repository(db=Depends(get_db)) -> TransactionsRepository:
    """Dependency: transactions repository with database cursor."""
    return TransactionsRepository(db)


def get_categories_repository(db=Depends(get_db)) -> CategoriesRepository:
    """Dependency: categories repository with database cursor."""
    return CategoriesRepository(db)


def get_credit_interface(db=Depends(get_db)) -> CreditLedgerInterface:
    """Dependency: credit ledger interface implementation."""
    # Importing here to avoid circular imports
    from features.credit.business.service import CreditService
    from features.credit.data.repository import CreditRepository
    credit_repo = CreditRepository(db)
    return CreditService(credit_repo)


def get_transactions_service(
    repository: TransactionsRepository = Depends(get_transactions_repository),
    categories_repo: CategoriesRepository = Depends(get_categories_repository),
    credit_interface: CreditLedgerInterface = Depends(get_credit_interface),
) -> TransactionsService:
    """Dependency: transactions service with all dependencies."""
    return TransactionsService(repository, categories_repo, credit_interface)


def get_current_month_id(db=Depends(get_db), clock=Depends(get_clock)) -> int:
    """Get or create the month_id for the current month."""
    from features.accounts.data.repository import AccountsRepository
    accounts_repo = AccountsRepository(db)
    now = clock.now()
    month_id = accounts_repo.get_month_id(now.year, now.month)
    if not month_id:
        month_id = accounts_repo.create_month(now.year, now.month)
    return month_id


@router.post("", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def create_transaction(
    request: CreateTransactionRequest,
    current_user_id: int = Depends(get_current_user),
    service: TransactionsService = Depends(get_transactions_service),
    month_id: int = Depends(get_current_month_id),
):
    """
    Create a new transaction.

    Requires authentication. The transaction is processed with automatic overage
    handling based on the category's envelope budget.

    Returns the created transaction details.
    """
    result = service.record_expense(
        user_id=current_user_id,
        month_id=month_id,
        category_code=request.category_code,
        amount=request.amount,
        reason=request.reason,
        date=request.date.isoformat(),
    )
    return TransactionResponse(**result)


@router.get("", response_model=TransactionListResponse)
def list_transactions(
    current_user_id: int = Depends(get_current_user),
    repository: TransactionsRepository = Depends(get_transactions_repository),
    month_id: int = Depends(get_current_month_id),
):
    """
    List all transactions for the current month.

    Requires authentication. Returns transactions for the current budget month.
    """
    transactions = repository.list_for_month(current_user_id, month_id)
    # Convert to TransactionResponse format
    transaction_responses = []
    for txn in transactions:
        transaction_responses.append(
            TransactionResponse(
                id=txn["id"],
                category_code=txn["category_code"] or "",
                funding_account_code=txn["funding_account_code"],
                amount=txn["amount"],
                type=txn["type"],
                is_overage=txn["is_overage"],
                reason=txn["reason"],
                date=txn["date"],
            )
        )
    return TransactionListResponse(transactions=transaction_responses)


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(
    transaction_id: int,
    current_user_id: int = Depends(get_current_user),
    repository: TransactionsRepository = Depends(get_transactions_repository),
):
    """
    Delete a transaction by ID.

    Requires authentication. Only the transaction owner (current user) can delete it.

    Returns 204 No Content. DELETE is idempotent - returns success even if transaction not found.
    """
    repository.delete(current_user_id, transaction_id)
    return None
