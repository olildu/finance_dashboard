"""
Pydantic schemas for transaction API requests and responses.
"""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, condecimal, field_serializer


class CreateTransactionRequest(BaseModel):
    """Schema for creating a transaction."""

    category_code: str
    amount: condecimal(gt=Decimal("0"))
    reason: str | None = None
    date: datetime


class TransactionResponse(BaseModel):
    """Schema for a transaction response."""

    model_config = ConfigDict(json_encoders={Decimal: float})

    id: int
    category_code: str
    funding_account_code: str
    amount: Decimal
    type: str
    is_overage: bool
    reason: str | None
    date: datetime

    @field_serializer("amount", when_used="json")
    def serialize_amount(self, value: Decimal) -> float:
        """Serialize Decimal amount as float for JSON."""
        return float(value)


class TransactionListResponse(BaseModel):
    """Schema for listing transactions."""

    transactions: list[TransactionResponse]
