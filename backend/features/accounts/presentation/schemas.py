"""
Pydantic schemas for accounts feature API requests and responses.
"""

from typing import Optional

from pydantic import BaseModel


class AccountSchema(BaseModel):
    """Response schema for a single account."""

    id: int
    code: str
    display_name: str
    kind: str
    fixed_amount: Optional[float] = None

    class Config:
        from_attributes = True


class AccountBalanceSchema(BaseModel):
    """Account balance info in month-end check."""

    expected_balance: float


class MonthEndCheckResponse(BaseModel):
    """Response schema for month-end check endpoint."""

    ICICI: AccountBalanceSchema
    SBI: AccountBalanceSchema
    SLICE: AccountBalanceSchema
    hdfc_reserve: float
    total_net_worth: float

    class Config:
        from_attributes = True
