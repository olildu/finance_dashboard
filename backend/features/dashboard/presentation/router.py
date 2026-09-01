"""
Dashboard API endpoints.

Provides GET /overview endpoint for retrieving the complete dashboard
composition of accounts, budgets, credit, and transactions data.
"""

from fastapi import APIRouter, Depends

from core.clock import get_clock
from core.db import get_db
from features.accounts.business.service import AccountsService
from features.accounts.data.repository import AccountsRepository
from features.auth.presentation.router import get_current_user
from features.budgets.business.pace_service import BudgetsPaceService
from features.categories.data.repository import CategoriesRepository
from features.credit.business.service import CreditService
from features.credit.data.repository import CreditRepository
from features.dashboard.business.overview_service import OverviewService
from features.dashboard.presentation.schemas import DashboardOverviewResponse
from features.transactions.data.repository import TransactionsRepository

router = APIRouter(tags=["dashboard"])


def get_accounts_repository(db=Depends(get_db)) -> AccountsRepository:
    """Dependency: accounts repository with database cursor."""
    return AccountsRepository(db)


def get_categories_repository(db=Depends(get_db)) -> CategoriesRepository:
    """Dependency: categories repository with database cursor."""
    return CategoriesRepository(db)


def get_transactions_repository(db=Depends(get_db)) -> TransactionsRepository:
    """Dependency: transactions repository with database cursor."""
    return TransactionsRepository(db)


def get_credit_repository(db=Depends(get_db)) -> CreditRepository:
    """Dependency: credit repository with database cursor."""
    return CreditRepository(db)


def get_accounts_service(
    repository: AccountsRepository = Depends(get_accounts_repository),
    clock=Depends(get_clock),
) -> AccountsService:
    """Dependency: accounts service with repository and clock."""
    return AccountsService(repository, clock)


def get_budgets_pace_service(
    categories_repo: CategoriesRepository = Depends(get_categories_repository),
    transactions_repo: TransactionsRepository = Depends(get_transactions_repository),
    clock=Depends(get_clock),
) -> BudgetsPaceService:
    """Dependency: budgets pace service with all required repositories."""
    return BudgetsPaceService(categories_repo, transactions_repo, clock)


def get_credit_service(
    repository: CreditRepository = Depends(get_credit_repository),
) -> CreditService:
    """Dependency: credit service with repository."""
    return CreditService(repository)


def get_overview_service(
    accounts_service: AccountsService = Depends(get_accounts_service),
    budgets_pace_service: BudgetsPaceService = Depends(get_budgets_pace_service),
    credit_service: CreditService = Depends(get_credit_service),
    transactions_repo: TransactionsRepository = Depends(get_transactions_repository),
    clock=Depends(get_clock),
) -> OverviewService:
    """Dependency: overview service composing all four feature services."""
    return OverviewService(
        accounts_service,
        budgets_pace_service,
        credit_service,
        transactions_repo,
        clock=clock,
    )


@router.get("/overview", response_model=DashboardOverviewResponse)
def get_overview(
    current_user_id: int = Depends(get_current_user),
    service: OverviewService = Depends(get_overview_service),
    accounts_repo: AccountsRepository = Depends(get_accounts_repository),
    clock=Depends(get_clock),
):
    """
    Get the complete dashboard overview for the authenticated user.

    Requires authentication via Bearer token in Authorization header.

    Composes data from four features:
    1. Month-end check (expected balances for bank accounts)
    2. Budget status (category pace and burn-rate metrics)
    3. Credit balance (current balance owed)
    4. Recent transactions (transactions for current month)

    Returns:
        {
            "month_end_check": {...},     # MonthEndCheckResponse
            "budget_statuses": [...],    # [CategoryStatus]
            "credit_balance": {...},     # CreditBalanceResponse
            "recent_transactions": [...]  # [TransactionResponse]
        }
    """
    now = clock.now()
    month_id = accounts_repo.get_month_id(now.year, now.month)
    if month_id is None:
        month_id = accounts_repo.create_month(now.year, now.month)

    result = service.get_overview(
        user_id=current_user_id,
        month_id=month_id,
    )
    return DashboardOverviewResponse(**result)
