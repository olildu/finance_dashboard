"""
Pydantic schemas for rollover API endpoints.

Response models for rollover run results and closed-month details.
"""

from decimal import Decimal
from pydantic import BaseModel, Field


class RolloverRunResult(BaseModel):
    """
    Result of a rollover run (POST /run-check).

    Captures the outcome of rolling over unclosed months: which months were closed,
    and the settlement/sweep amounts for each.
    """

    months_closed: list[int] = Field(
        ...,
        description="List of month IDs that were rolled over (closed) in this run",
    )
    credit_settled_amounts: list[Decimal] = Field(
        ...,
        description="List of credit settlement amounts for each closed month, in the same order as months_closed",
    )
    sweep_amounts: list[Decimal] = Field(
        ...,
        description="List of sweep amounts (leftover + fixed allocation) for each closed month, in the same order as months_closed",
    )
