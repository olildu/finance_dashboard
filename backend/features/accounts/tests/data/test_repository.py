"""
Integration tests for accounts data layer (repository).

Tests database access patterns against real seeded data using db_conn fixture.
Verifies accounts list query and transaction-sum queries.
"""

from datetime import datetime, timezone
from decimal import Decimal

import pytest

from features.accounts.data.repository import AccountsRepository


# ============================================================================
# Fixtures
# ============================================================================


@pytest.fixture
def repository(db_conn):
    """Provide an AccountsRepository with a database connection."""
    return AccountsRepository(db_conn)


# ============================================================================
# Tests: Accounts list query
# ============================================================================


class TestGetAllAccounts:
    """Test get_all_accounts query against seeded data."""

    def test_get_all_accounts_returns_list(self, repository):
        """get_all_accounts should return a list."""
        accounts = repository.get_all_accounts()
        assert isinstance(accounts, list)

    def test_get_all_accounts_returns_five_accounts(self, repository):
        """Seeded data includes 5 accounts: ICICI, SBI, SLICE, HDFC, CREDIT."""
        accounts = repository.get_all_accounts()
        assert len(accounts) == 5

    def test_get_all_accounts_includes_icici(self, repository):
        """Seeded accounts include ICICI."""
        accounts = repository.get_all_accounts()
        codes = [acc["code"] for acc in accounts]
        assert "ICICI" in codes

    def test_get_all_accounts_includes_sbi(self, repository):
        """Seeded accounts include SBI."""
        accounts = repository.get_all_accounts()
        codes = [acc["code"] for acc in accounts]
        assert "SBI" in codes

    def test_get_all_accounts_includes_slice(self, repository):
        """Seeded accounts include SLICE."""
        accounts = repository.get_all_accounts()
        codes = [acc["code"] for acc in accounts]
        assert "SLICE" in codes

    def test_get_all_accounts_includes_hdfc(self, repository):
        """Seeded accounts include HDFC."""
        accounts = repository.get_all_accounts()
        codes = [acc["code"] for acc in accounts]
        assert "HDFC" in codes

    def test_get_all_accounts_includes_credit(self, repository):
        """Seeded accounts include CREDIT pseudo-account."""
        accounts = repository.get_all_accounts()
        codes = [acc["code"] for acc in accounts]
        assert "CREDIT" in codes

    def test_get_all_accounts_icici_correct_kind(self, repository):
        """ICICI should have kind='bank'."""
        accounts = repository.get_all_accounts()
        icici = next(acc for acc in accounts if acc["code"] == "ICICI")
        assert icici["kind"] == "bank"

    def test_get_all_accounts_hdfc_correct_kind_and_amount(self, repository):
        """HDFC should have kind='fixed' and fixed_amount=2500."""
        accounts = repository.get_all_accounts()
        hdfc = next(acc for acc in accounts if acc["code"] == "HDFC")
        assert hdfc["kind"] == "fixed"
        assert hdfc["fixed_amount"] == 2500.00

    def test_get_all_accounts_credit_correct_kind(self, repository):
        """CREDIT should have kind='pseudo_credit'."""
        accounts = repository.get_all_accounts()
        credit = next(acc for acc in accounts if acc["code"] == "CREDIT")
        assert credit["kind"] == "pseudo_credit"

    def test_get_all_accounts_has_required_fields(self, repository):
        """Each account should have id, code, display_name, kind, fixed_amount."""
        accounts = repository.get_all_accounts()
        for acc in accounts:
            assert "id" in acc
            assert "code" in acc
            assert "display_name" in acc
            assert "kind" in acc
            assert "fixed_amount" in acc

    def test_get_all_accounts_ordered_by_id(self, repository):
        """Accounts should be returned in order by id."""
        accounts = repository.get_all_accounts()
        ids = [acc["id"] for acc in accounts]
        assert ids == sorted(ids)


# ============================================================================
# Tests: Budget envelopes query
# ============================================================================


class TestGetAllBudgetEnvelopes:
    """Test get_all_budget_envelopes query against seeded data."""

    def test_get_all_budget_envelopes_returns_list(self, repository):
        """get_all_budget_envelopes should return a list."""
        envelopes = repository.get_all_budget_envelopes()
        assert isinstance(envelopes, list)

    def test_get_all_budget_envelopes_returns_six_envelopes(self, repository):
        """Seeded data includes 6 budget envelopes."""
        envelopes = repository.get_all_budget_envelopes()
        assert len(envelopes) == 6

    def test_get_all_budget_envelopes_includes_food(self, repository):
        """Seeded envelopes include Food."""
        envelopes = repository.get_all_budget_envelopes()
        names = [env["name"] for env in envelopes]
        assert "Food" in names

    def test_get_all_budget_envelopes_includes_rent(self, repository):
        """Seeded envelopes include Rent."""
        envelopes = repository.get_all_budget_envelopes()
        names = [env["name"] for env in envelopes]
        assert "Rent" in names

    def test_get_all_budget_envelopes_food_amount_is_6000(self, repository):
        """Food envelope should have monthly_amount=6000."""
        envelopes = repository.get_all_budget_envelopes()
        food = next(env for env in envelopes if env["name"] == "Food")
        assert food["monthly_amount"] == 6000.00

    def test_get_all_budget_envelopes_rent_amount_is_17000(self, repository):
        """Rent envelope should have monthly_amount=17000."""
        envelopes = repository.get_all_budget_envelopes()
        rent = next(env for env in envelopes if env["name"] == "Rent")
        assert rent["monthly_amount"] == 17000.00

    def test_get_all_budget_envelopes_food_funded_by_icici(self, repository):
        """Food should be funded by ICICI (account_id=1)."""
        envelopes = repository.get_all_budget_envelopes()
        food = next(env for env in envelopes if env["name"] == "Food")
        assert food["account_id"] == 1

    def test_get_all_budget_envelopes_rent_funded_by_slice(self, repository):
        """Rent should be funded by SLICE (account_id=3)."""
        envelopes = repository.get_all_budget_envelopes()
        rent = next(env for env in envelopes if env["name"] == "Rent")
        assert rent["account_id"] == 3


# ============================================================================
# Tests: Month queries
# ============================================================================


class TestMonthQueries:
    """Test month-related database queries."""

    def test_get_month_id_returns_none_for_nonexistent_month(self, repository):
        """get_month_id should return None for month that doesn't exist."""
        month_id = repository.get_month_id(2025, 1)
        assert month_id is None

    def test_create_month_creates_and_returns_id(self, repository):
        """create_month should create month entry and return month_id."""
        month_id = repository.create_month(2025, 9)
        assert isinstance(month_id, int)
        assert month_id > 0

    def test_get_month_id_finds_created_month(self, repository):
        """After create_month, get_month_id should find it."""
        created_id = repository.create_month(2025, 8)
        found_id = repository.get_month_id(2025, 8)
        assert found_id == created_id

    def test_create_month_duplicate_returns_same_id(self, repository):
        """Creating duplicate month should return the same month_id (handled via ON CONFLICT)."""
        month_id_1 = repository.create_month(2025, 7)
        # Try to create same month again
        month_id_2 = repository.create_month(2025, 7)
        # Should return the same month_id due to ON CONFLICT
        assert month_id_1 == month_id_2




# ============================================================================
# Tests: Transactions query
# ============================================================================


class TestGetTransactionsForMonth:
    """Test get_transactions_for_month query."""

    def test_get_transactions_for_month_returns_list(self, repository, db_conn):
        """get_transactions_for_month should return a list."""
        month_id = repository.create_month(2025, 9)
        db_conn.execute(
            "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s) RETURNING user_id",
            ("testuser", "test@example.com", "hash"),
        )
        user_id = db_conn.fetchone()["user_id"]

        transactions = repository.get_transactions_for_month(user_id, month_id)
        assert isinstance(transactions, list)

    def test_get_transactions_for_month_no_transactions_returns_empty(self, repository, db_conn):
        """With no transactions, should return empty list."""
        month_id = repository.create_month(2025, 9)
        db_conn.execute(
            "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s) RETURNING user_id",
            ("testuser", "test@example.com", "hash"),
        )
        user_id = db_conn.fetchone()["user_id"]

        transactions = repository.get_transactions_for_month(user_id, month_id)
        assert len(transactions) == 0

    def test_get_transactions_for_month_with_transaction(self, repository, db_conn):
        """Should return transactions for the given month."""
        month_id = repository.create_month(2025, 9)
        db_conn.execute(
            "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s) RETURNING user_id",
            ("testuser", "test@example.com", "hash"),
        )
        user_id = db_conn.fetchone()["user_id"]

        # Insert transaction
        db_conn.execute(
            """
            INSERT INTO transactions
            (user_id, month_id, category_id, funding_account_id, amount, type, is_overage, date)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (user_id, month_id, 1, 1, 500.00, "expense", False, datetime.now(timezone.utc)),
        )

        transactions = repository.get_transactions_for_month(user_id, month_id)
        assert len(transactions) == 1
        assert transactions[0]["amount"] == 500.00

    def test_get_transactions_for_month_excludes_other_months(self, repository, db_conn):
        """Should only return transactions for the specified month."""
        month_id_sept = repository.create_month(2025, 9)
        month_id_oct = repository.create_month(2025, 10)

        db_conn.execute(
            "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s) RETURNING user_id",
            ("testuser", "test@example.com", "hash"),
        )
        user_id = db_conn.fetchone()["user_id"]

        # Insert in September
        db_conn.execute(
            """
            INSERT INTO transactions
            (user_id, month_id, category_id, funding_account_id, amount, type, is_overage, date)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (user_id, month_id_sept, 1, 1, 500.00, "expense", False, datetime.now(timezone.utc)),
        )

        # Insert in October
        db_conn.execute(
            """
            INSERT INTO transactions
            (user_id, month_id, category_id, funding_account_id, amount, type, is_overage, date)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (user_id, month_id_oct, 1, 1, 300.00, "expense", False, datetime.now(timezone.utc)),
        )

        # Query September
        transactions = repository.get_transactions_for_month(user_id, month_id_sept)
        assert len(transactions) == 1
        assert transactions[0]["amount"] == 500.00
