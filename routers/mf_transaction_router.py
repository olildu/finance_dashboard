from fastapi import APIRouter
from datetime import datetime
from services.db_config import connection

router = APIRouter()

@router.get("/mf-transaction")
async def debit(amount: str, fund_name: str, method: str, units: str):
    print(method)

    amount = "-" + amount if method == "debit" else amount

    cursor = connection.cursor()

    print(f"INSERT INTO mutual_funds (units, buy_price, fund_name) VALUES ({units}, {amount}, '{fund_name}');")

    cursor.execute(
        f"INSERT INTO mutual_funds (units, buy_price, fund_name) VALUES ({units}, {amount}, '{fund_name}');"
    )

    connection.commit() 