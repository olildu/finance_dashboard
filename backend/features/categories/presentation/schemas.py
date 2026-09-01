"""
Pydantic schemas for categories API endpoints.

Response models for category listing with budget_envelope information.
"""

from pydantic import BaseModel, Field


class BudgetEnvelopeSchema(BaseModel):
    """Budget envelope info in category response."""

    name: str = Field(..., description="Name of the budget envelope (e.g., 'Food', 'Rent')")
    monthly_amount: float = Field(..., description="Monthly allocation amount in rupees")
    account_code: str = Field(..., description="Code of the funding account (e.g., 'ICICI', 'SBI')")


class CategorySchema(BaseModel):
    """Response schema for a single category."""

    code: str = Field(..., description="Category code (e.g., 'food', 'rent', 'travel')")
    display_name: str = Field(..., description="Human-readable category name (e.g., 'Food', 'Rent')")
    envelope: BudgetEnvelopeSchema = Field(..., description="Associated budget envelope")


class CategoriesListResponse(BaseModel):
    """Response schema for GET /categories."""

    categories: list[CategorySchema] = Field(..., description="List of all active categories")
