"""
Pydantic schemas for credit API endpoints.

Response models for credit balance and history information.
"""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field, field_serializer


class CreditBalanceResponse(BaseModel):
    """Response schema for GET /balance."""

    balance: Decimal = Field(..., description="Current balance owed to the credit ledger")

    @field_serializer("balance", when_used="json")
    def serialize_balance(self, value: Decimal) -> float:
        """Serialize Decimal balance as float for JSON."""
        return float(value)


class CreditHistoryEntry(BaseModel):
    """A single credit ledger history entry."""

    id: int = Field(..., description="Entry id")
    month: int = Field(..., description="Month id for this entry")
    category_code: str | None = Field(
        None, description="Category code (e.g., 'food', 'rent'); null for payoff entries"
    )
    amount: Decimal = Field(..., description="Amount for this entry")
    entry_type: str = Field(..., description="Type of entry (e.g., 'overage', 'settlement')")
    created_at: datetime = Field(..., description="Timestamp when entry was created")

    @field_serializer("amount", when_used="json")
    def serialize_amount(self, value: Decimal) -> float:
        """Serialize Decimal amount as float for JSON."""
        return float(value)


class CreditHistoryResponse(BaseModel):
    """Response schema for GET /history."""

    entries: list[CreditHistoryEntry] = Field(..., description="List of credit ledger history entries")
