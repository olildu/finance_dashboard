from fastapi import APIRouter, Depends
from datetime import datetime
from services.db_config import connection
from services.auth import get_current_user

router = APIRouter()

@router.get("/debit")
async def debit(amount: str, reason: str, category: str, area: str, user_id: int = Depends(get_current_user)):
    current_date = datetime.now()
    current_month_string = current_date.strftime("%B")
    current_month_int = current_date.month
    current_year = str(current_date.year)
    combined_id = f"{current_month_int}{current_year}"

    balanceMap = {
        "variable-expense-transactions": "variable_expense",
        "savings-expense-transactions": "savings",
        "monthly-transactions": "monthly_expense_left",
        "mutual-funds-transactions": "mutual_funds"
    }

    cursor = connection.cursor()

    cursor.execute(
        """
        INSERT INTO transactions_table (m_id, reason, amount, category, method, bracket, date)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        """,
        (combined_id, reason, amount, category, "debit", area, current_date)
    )

    column_to_update = balanceMap[area]
    cursor.execute(f"SELECT {column_to_update} FROM account_details WHERE m_id = %s", (combined_id,))
    
    result = cursor.fetchone()
    if result:
        balance = result[0]
        balance -= int(amount)
        
        cursor.execute(f"UPDATE account_details SET {column_to_update} = %s WHERE m_id = %s", (balance, combined_id))

    connection.commit()
    cursor.close()