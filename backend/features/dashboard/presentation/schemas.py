"""
Pydantic schemas for dashboard API endpoints.

DashboardOverviewResponse composes response shapes from accounts,
budgets, credit, and transactions features.
"""

from pydantic import BaseModel, Field

from features.accounts.presentation.schemas import MonthEndCheckResponse
from features.budgets.presentation.schemas import CategoryStatus
from features.credit.presentation.schemas import CreditBalanceResponse
from features.transactions.presentation.schemas import TransactionResponse


class DashboardOverviewResponse(BaseModel):
    """Complete dashboard overview response composing all four features."""

    month_end_check: MonthEndCheckResponse = Field(
        ...,
        description="Month-end check data: expected balances for bank accounts, HDFC reserve, and total net worth",
    )
    budget_statuses: list[CategoryStatus] = Field(
        ...,
        description="Budget pace and burn-rate metrics for all active categories in the current month",
    )
    credit_balance: CreditBalanceResponse = Field(
        ...,
        description="Current balance owed to the credit ledger",
    )
    recent_transactions: list[TransactionResponse] = Field(
        ...,
        description="Recent transactions for the current month",
    )

    class Config:
        """Pydantic config for decimal and datetime serialization."""

        from_attributes = True
