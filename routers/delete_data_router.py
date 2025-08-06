from fastapi import APIRouter
from datetime import datetime   

from services.db_config import connection

router = APIRouter()

@router.get("/deleteTransaction")
async def get_transactions(
    id: str,
    amount: str,
    bracket : str,
    method : str
):
    current_date = datetime.now()
    
    combined_id = f"{current_date.month}{current_date.year}"

    cursor = connection.cursor()
    balanceMap = {
        "variable-expense-transactions" :  "variable_expense",
        "savings-expense-transactions" : "savings",
        "monthly-transactions" : "monthly_expense_left",
        "debit" : "+",
        "credit" : "-"
    }

    cursor.execute(f'delete from transactions_table where id = {id}')
    cursor.execute(f'UPDATE account_details SET {balanceMap[bracket]} = {balanceMap[bracket]} {balanceMap[method]} {amount} WHERE m_id = {combined_id}')

    connection.commit()

    return {"server_response": "Transaction deleted successfully"}
