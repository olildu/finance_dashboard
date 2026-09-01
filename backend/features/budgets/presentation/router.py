"""
Budgets API endpoints.

Provides GET /status endpoint for querying per-category budget pace and burn-rate
metrics for the current month.
"""

from fastapi import APIRouter, Depends

from core.clock import get_clock
from core.db import get_db
from features.accounts.data.repository import AccountsRepository
from features.auth.presentation.router import get_current_user
from features.budgets.business.pace_service import BudgetsPaceService
from features.budgets.presentation.schemas import BudgetsStatusResponse
from features.categories.data.repository import CategoriesRepository
from features.transactions.data.repository import TransactionsRepository

router = APIRouter(tags=["budgets"])


def get_accounts_repository(db=Depends(get_db)) -> AccountsRepository:
    """Dependency: accounts repository, reused here only for its month lookup/creation."""
    return AccountsRepository(db)


def get_categories_repository(db=Depends(get_db)) -> CategoriesRepository:
    """Dependency: categories repository with database cursor."""
    return CategoriesRepository(db)


def get_transactions_repository(db=Depends(get_db)) -> TransactionsRepository:
    """Dependency: transactions repository with database cursor."""
    return TransactionsRepository(db)


def get_pace_service(
    categories_repo: CategoriesRepository = Depends(get_categories_repository),
    transactions_repo: TransactionsRepository = Depends(get_transactions_repository),
    clock=Depends(get_clock),
) -> BudgetsPaceService:
    """Dependency: budget pace service with all required repositories."""
    return BudgetsPaceService(categories_repo, transactions_repo, clock)


@router.get("/status", response_model=BudgetsStatusResponse)
def get_budget_status(
    current_user_id: int = Depends(get_current_user),
    pace_service: BudgetsPaceService = Depends(get_pace_service),
    accounts_repo: AccountsRepository = Depends(get_accounts_repository),
    clock=Depends(get_clock),
):
    """
    Get budget status for all categories in the current month.

    Requires authentication via Bearer token in Authorization header.

    Returns per-category metrics including:
    - Budget allocation and amount spent
    - Remaining budget and days left in month
    - Daily allowance pace and burn rate
    - Projected runout date if spending continues at current rate
    """
    now = clock.now()
    month_id = accounts_repo.get_month_id(now.year, now.month)
    if month_id is None:
        month_id = accounts_repo.create_month(now.year, now.month)

    # Get category statuses from the pace service
    category_statuses = pace_service.get_all_category_statuses(
        user_id=current_user_id,
        month_id=month_id,
    )

    # Convert each status dict to CategoryStatus object
    categories = [
        {
            "category_code": status["category_code"],
            "display_name": status["display_name"],
            "budget": status["budget"],
            "spent": status["spent"],
            "remaining": status["remaining"],
            "days_left": status["days_left"],
            "allowance_per_day": status["allowance_per_day"],
            "burn_rate_per_day": status["burn_rate_per_day"],
            "projected_runout_date": status["projected_runout_date"],
        }
        for status in category_statuses
    ]

    return BudgetsStatusResponse(categories=categories)
