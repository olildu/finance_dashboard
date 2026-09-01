from abc import ABC, abstractmethod
from decimal import Decimal


class CreditLedgerInterface(ABC):
    """Abstract interface for credit ledger business logic. Implementations provided in later phases."""

    @abstractmethod
    def current_balance(self, user_id: int) -> Decimal:
        """Return the current balance owed to the credit ledger."""
        raise NotImplementedError

    @abstractmethod
    def record_overage(self, user_id: int, month_id: int, category_id: int, amount: Decimal, transaction_id: int) -> None:
        """Record an overage transaction against the credit ledger."""
        raise NotImplementedError

    @abstractmethod
    def settle(self, user_id: int, month_id: int, amount: Decimal, transaction_id: int) -> Decimal:
        """Settle a credit ledger amount and return remaining balance."""
        raise NotImplementedError
