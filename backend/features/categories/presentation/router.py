"""
Categories API endpoints.

Provides GET /categories endpoint for listing all active budget categories
with their associated envelope and funding account information.
"""

from fastapi import APIRouter, Depends

from core.db import get_db
from features.auth.presentation.router import get_current_user
from features.categories.data.repository import CategoriesRepository
from features.categories.presentation.schemas import (
    CategoriesListResponse,
    CategorySchema,
    BudgetEnvelopeSchema,
)

router = APIRouter(prefix="/categories", tags=["categories"])


def get_categories_repository(db=Depends(get_db)) -> CategoriesRepository:
    """Dependency: categories repository with database cursor."""
    return CategoriesRepository(db)


@router.get("", response_model=CategoriesListResponse)
def list_categories(
    current_user_id: int = Depends(get_current_user),
    repository: CategoriesRepository = Depends(get_categories_repository),
):
    """
    Get all active categories with their budget_envelope and funding account info.

    Requires authentication via Bearer token in Authorization header.

    Returns a list of all active categories with associated envelope allocation
    amounts and funding account codes.
    """
    # Query all active categories with envelope and account joins
    all_categories = repository.get_all_active_categories_with_envelopes()

    # Transform database rows into response schema
    categories = []
    for cat in all_categories:
        envelope = BudgetEnvelopeSchema(
            name=cat["envelope_name"],
            monthly_amount=float(cat["monthly_amount"]),
            account_code=cat["account_code"],
        )
        category = CategorySchema(
            code=cat["code"],
            display_name=cat["display_name"],
            envelope=envelope,
        )
        categories.append(category)

    return CategoriesListResponse(categories=categories)
