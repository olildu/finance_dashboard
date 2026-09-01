"""
Business logic for transactions.

Handles recording expenses, applying overage rules, and managing transaction state.
"""

from decimal import Decimal

from features.categories.data.repository import CategoriesRepository
from features.credit.business.interface import CreditLedgerInterface
from features.transactions.data.repository import TransactionsRepository


class TransactionsService:
    """Service for transaction business logic."""

    def __init__(
        self,
        transactions_repository: TransactionsRepository,
        categories_repository: CategoriesRepository,
        credit_interface: CreditLedgerInterface,
    ):
        """
        Initialize the TransactionsService.

        Args:
            transactions_repository: Repository for transaction data access.
            categories_repository: Repository for category data access.
            credit_interface: Interface to the credit ledger (abstract interface).
        """
        self.transactions_repository = transactions_repository
        self.categories_repository = categories_repository
        self.credit_interface = credit_interface

    def record_expense(
        self,
        user_id: int,
        month_id: int,
        category_code: str,
        amount: Decimal,
        reason: str | None,
        date: str,
    ) -> dict:
        """
        Record an expense transaction with automatic overage handling.

        Overage Rule:
        1. Look up the category by code to get its envelope and budget.
        2. Sum all existing non-overage expense transactions for that envelope in this month.
        3. If (existing_sum + new_amount) > envelope.monthly_amount:
           - The ENTIRE new transaction is marked as is_overage=True.
           - The funding_account is set to CREDIT (using credit_interface.record_overage).
        4. Otherwise:
           - is_overage=False and funding_account is the envelope's real account.

        Args:
            user_id: ID of the user.
            month_id: ID of the budget month.
            category_code: Category code (e.g., 'food', 'rent').
            amount: Transaction amount.
            reason: Optional reason for the transaction.
            date: Date of the transaction (ISO format string).

        Returns:
            A dict with transaction details (id, category_code, funding_account_code,
            amount, type, is_overage, reason, date).
        """
        # 1. Look up category by code
        category = self.categories_repository.get_category_by_code(category_code)
        if not category:
            raise ValueError(f"Category '{category_code}' not found")

        category_id = category["id"]
        envelope_id = category["envelope_id"]
        monthly_budget = Decimal(str(category["monthly_amount"]))
        account_code = category["account_code"]

        # 2. Sum existing non-overage expenses for this envelope
        existing_sum = self.transactions_repository.sum_expense_for_envelope_in_month(
            user_id, month_id, envelope_id
        )

        # 3. Determine if this transaction is an overage
        total_with_new = existing_sum + amount
        is_overage = total_with_new > monthly_budget
        funding_account_code = "CREDIT" if is_overage else account_code

        # Look up the funding account's real id (never assume seed insertion order).
        funding_account_id = self.transactions_repository.get_account_id_by_code(
            funding_account_code
        )

        # 4. Insert the transaction
        transaction_id = self.transactions_repository.insert(
            user_id=user_id,
            month_id=month_id,
            category_id=category_id,
            funding_account_id=funding_account_id,
            amount=amount,
            type="expense",
            is_overage=is_overage,
            reason=reason,
            date=date,
        )

        # 5. If overage, call credit interface
        if is_overage:
            self.credit_interface.record_overage(
                user_id=user_id,
                month_id=month_id,
                category_id=category_id,
                amount=amount,
                transaction_id=transaction_id,
            )

        # 6. Return response
        return {
            "id": transaction_id,
            "category_code": category_code,
            "funding_account_code": funding_account_code,
            "amount": amount,
            "type": "expense",
            "is_overage": is_overage,
            "reason": reason,
            "date": date,
        }
