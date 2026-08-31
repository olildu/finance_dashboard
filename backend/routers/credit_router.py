from fastapi import APIRouter, Depends
from datetime import datetime
from services.db_config import get_db
from services.auth import get_current_user
from decimal import Decimal # Import Decimal

router = APIRouter()

@router.get("/credit")
async def credit(amount: float, reason: str, category: str, area: str, 
                 user_id: int = Depends(get_current_user),
                 cursor=Depends(get_db)):
    
    current_date = datetime.now()
    current_month_int = current_date.month
    current_year = str(current_date.year)
    combined_id = f"{current_month_int}{current_year}"

    balanceMap = {
        "variable-expense-transactions": "variable_expense",
        "savings-expense-transactions": "savings",
        "monthly-transactions": "monthly_expense_left",
        "mutual-funds-transactions": "mutual_funds"
    }

    cursor.execute(
        """
        INSERT INTO transactions_table (m_id, reason, amount, category, method, bracket, date, user_id)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """,
        (combined_id, reason, amount, category, "credit", area, current_date, user_id)
    )

    column_to_update = balanceMap[area]

    cursor.execute(f"SELECT {column_to_update} FROM account_details WHERE m_id = %s AND user_id = %s", (combined_id, user_id))

    result = cursor.fetchone()
    if result:
        balance = result[0] # This is a Decimal
        balance += Decimal(amount) # Convert amount to Decimal
        
        cursor.execute(f"UPDATE account_details SET {column_to_update} = %s WHERE m_id = %s AND user_id = %s", (balance, combined_id, user_id))

    return {"message": "Credit successful"}