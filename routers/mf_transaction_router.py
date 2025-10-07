from fastapi import APIRouter, Depends, HTTPException
from services.db_config import connection
from services.auth import get_current_user

router = APIRouter()

@router.get("/mf-transaction")
async def mf_transaction(amount: str, fund_name: str, method: str, units: str, user_id: int = Depends(get_current_user)):
    cursor = connection.cursor()
    try: 
        amount_value = float(amount)
        if method == "debit":
            amount_value = -amount_value


        cursor.execute(
            """
            INSERT INTO mutual_funds (user_id, fund_name, units, buy_price) 
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (user_id, fund_name) 
            DO UPDATE SET units = mutual_funds.units + EXCLUDED.units, 
                        buy_price = mutual_funds.buy_price + EXCLUDED.buy_price;
            """,
            (user_id, fund_name, units, amount_value)
        )

        connection.commit()
        cursor.close()
    except Exception as e:
        connection.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
        