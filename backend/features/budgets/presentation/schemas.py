"""
Pydantic schemas for budgets API endpoints.

Response models for category budget status including pace and burn-rate metrics.
"""

from datetime import date
from decimal import Decimal

from pydantic import BaseModel, Field, field_serializer


class CategoryStatus(BaseModel):
    """Budget status for a single category in the current month."""

    category_code: str = Field(
        ..., description="Category code (e.g., 'food', 'rent', 'travel')"
    )
    display_name: str = Field(..., description="Human-readable category name")
    budget: Decimal = Field(..., description="Monthly budget allocation in rupees")
    spent: Decimal = Field(
        ..., description="Amount spent (non-overage only) in rupees"
    )
    remaining: Decimal = Field(
        ..., description="Remaining budget (budget - spent, clamped >= 0) in rupees"
    )
    days_left: int = Field(..., description="Days remaining in the month (including today)")
    allowance_per_day: Decimal = Field(
        ...,
        description="Daily allowance based on remaining budget and days left in rupees",
    )
    burn_rate_per_day: Decimal = Field(
        ..., description="Average daily burn rate based on days elapsed in rupees"
    )
    projected_runout_date: date | None = Field(
        default=None,
        description="Projected date when budget will run out (if burn rate continues); None if burn_rate is 0",
    )

    @field_serializer(
        "budget", "spent", "remaining", "allowance_per_day", "burn_rate_per_day", when_used="json"
    )
    def serialize_decimal(self, value: Decimal) -> float:
        """Serialize Decimal fields as float for JSON."""
        return float(value)


class BudgetsStatusResponse(BaseModel):
    """Response schema for GET /status."""

    categories: list[CategoryStatus] = Field(
        ..., description="Budget status for all active categories"
    )
