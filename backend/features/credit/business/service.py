"""
Credit ledger business logic service.

Implements the CreditLedgerInterface with database-backed operations
for managing credit balances, overages, and settlements.
"""

from decimal import Decimal

from features.credit.business.interface import CreditLedgerInterface
from features.credit.data.repository import CreditRepository


class CreditService(CreditLedgerInterface):
    """Service implementing credit ledger business logic."""

    def __init__(self, repository: CreditRepository):
        """
        Initialize with a credit repository.

        Args:
            repository: The CreditRepository instance for database access.
        """
        self.repository = repository

    def current_balance(self, user_id: int) -> Decimal:
        """
        Return the current balance owed to the credit ledger.

        Args:
            user_id: The user id.

        Returns:
            The current balance as a Decimal.

        Raises:
            NotImplementedError: This is a stub implementation.
        """
        return self.repository.sum_balance(user_id)

    def record_overage(
        self,
        user_id: int,
        month_id: int,
        category_id: int,
        amount: Decimal,
        transaction_id: int,
    ) -> None:
        """
        Record an overage transaction against the credit ledger.

        Args:
            user_id: The user id.
            month_id: The month id.
            category_id: The category id.
            amount: The overage amount.
            transaction_id: The transaction id.

        Raises:
            NotImplementedError: This is a stub implementation.
        """
        self.repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=category_id,
            transaction_id=transaction_id,
            amount=amount,
            entry_type="overage",
        )

    def settle(
        self,
        user_id: int,
        month_id: int,
        amount: Decimal,
        transaction_id: int,
    ) -> Decimal:
        """
        Settle a credit ledger amount and return remaining balance.

        Args:
            user_id: The user id.
            month_id: The month id.
            amount: The settlement amount.
            transaction_id: The transaction id.

        Returns:
            The remaining balance after settlement as a Decimal.

        Raises:
            NotImplementedError: This is a stub implementation.
        """
        # Record the payoff as a negative amount
        self.repository.insert_ledger_entry(
            user_id=user_id,
            month_id=month_id,
            category_id=None,
            transaction_id=transaction_id,
            amount=-amount,
            entry_type="payoff",
        )
        # Return the new balance
        return self.repository.sum_balance(user_id)
