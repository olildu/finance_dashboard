from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime
from services.db_config import get_db
from services.auth import get_current_user

router = APIRouter()

@router.get("/deleteTransaction")
async def delete_transaction(id: int, amount: float, bracket: str, method: str, 
                             user_id: int = Depends(get_current_user),
                             cursor=Depends(get_db)):
    
    current_date = datetime.now()
    combined_id = f"{current_date.month}{current_date.year}"

    cursor.execute("SELECT m_id, user_id FROM transactions_table WHERE id = %s", (id,))
    transaction = cursor.fetchone()

    if not transaction:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transaction not found")
    
    m_id = transaction[0]
    owner_id = transaction[1]
    
    if owner_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to delete this transaction")

    balanceMap = {
        "variable-expense-transactions": "variable_expense",
        "savings-expense-transactions": "savings",
        "monthly-transactions": "monthly_expense_left",
        "debit": "+",
        "credit": "-"
    }

    cursor.execute("DELETE FROM transactions_table WHERE id = %s AND user_id = %s", (id, user_id))

    column_to_update = balanceMap[bracket]
    operator = balanceMap[method]

    sql_query = f"UPDATE account_details SET {column_to_update} = {column_to_update} {operator} %s WHERE m_id = %s AND user_id = %s"
    
    cursor.execute(sql_query, (amount, combined_id, user_id))

    return {"server_response": "Transaction deleted successfully"}