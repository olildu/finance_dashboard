from fastapi import APIRouter
from datetime import datetime
from services.db_config import connection

router = APIRouter()

@router.get("/credit")
async def debit(amount: str, reason: str, category: str, area: str):
    current_date = datetime.now()
    current_month_string = current_date.strftime("%B")
    current_month_int = current_date.month
    current_year = str(current_date.year)

    balanceMap = {
        "variable-expense-transactions" :  "variable_expense",
        "savings-expense-transactions" : "savings",
        "monthly-transactions" : "monthly_expense_left",
        "mutual-funds-transactions" : "mutual_funds"
    }

    connection.reconnect()
    cursor = connection.cursor()

    # Month Data Update
    cursor.execute(
        "INSERT IGNORE INTO months_table (id, month_year) VALUES (%s, %s)", 
        (f"{current_month_int}{current_year}", f"{current_month_string} {current_year}")
    )

    # Transaction Data Update
    cursor.execute(
        """
        INSERT INTO transactions_table (m_id, reason, amount, category, method, bracket, date)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        """,
        (f"{current_month_int}{current_year}", reason, amount, category, "credit", area, current_date)
    )

    # Account Data Update
    cursor.execute(f"SELECT {balanceMap[area]} FROM account_details WHERE m_id = '{current_month_int}{current_year}'")
    balance = cursor.fetchone()[0]
    balance += int(amount)
    
    cursor.execute(f'UPDATE account_details SET {balanceMap[area]} = {balance} WHERE m_id = "{current_month_int}{current_year}"')

    connection.commit()