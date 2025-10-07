import psycopg2
import psycopg2.extras
from fastapi import APIRouter, Depends
from datetime import datetime

from services.data_check import data_check
from services.db_config import connection
from services.mf_data_calculator import calculateFunds
from services.autofill import get_top_suggestions
from services.auth import get_current_user

router = APIRouter()

@router.get("/getData")
async def get_data(user_id: int = Depends(get_current_user)):
    current_date = datetime.now()
    current_date_sql = current_date.strftime('%Y-%m-%d')
    current_month_int = current_date.month
    current_year = current_date.year
    combined_id = f"{current_month_int}{current_year}"

    data_check(current_date, user_id)
    
    cursor = connection.cursor()

    category_totals = {}
    spent_today = 0

    cursor.execute(
        "SELECT * FROM transactions_table WHERE bracket = %s AND m_id = %s",
        ('monthly-transactions', combined_id)
    )
    monthlyTransactions = cursor.fetchall()

    for transaction in monthlyTransactions:
        amount = transaction[3]
        category = transaction[4]
        category_totals[category] = category_totals.get(category, 0) + amount

    cursor.execute(
        "SELECT * FROM transactions_table WHERE bracket = %s AND m_id = %s AND DATE(date) = %s",
        ('monthly-transactions', combined_id, current_date_sql)
    )
    todayData = cursor.fetchall()

    for x in todayData:
        spent_today += x[3]

    total_expense = sum(category_totals.values())

    category_percentages = {}
    for category, total in category_totals.items():
        if total_expense != 0:
            category_percentages[category] = round((total / total_expense) * 100, 2)
        else:
            category_percentages[category] = 0.0

    cursor.execute("SELECT mutual_funds, variable_expense, savings, monthly_expense_left FROM account_details WHERE m_id = %s", (combined_id,))
    account_details = cursor.fetchone()
    
    if not account_details:
        cursor.close()
        return {"error": f"No account details found for month_id: {combined_id}"}

    mutual_funds_performance = calculateFunds(user_id)
    cursor.close()

    return {
        "monthly_expense_left": account_details[3],
        "mutual_funds_total" : account_details[0],
        "variable_expense" : account_details[1],
        "savings" : account_details[2],
        "category_totals": category_totals,
        "total_expense": total_expense,
        "category_percentages": category_percentages,
        "spent_today" : spent_today,
        "mutual_funds_performance" : mutual_funds_performance
    }

@router.get("/getTransactions")
async def get_transactions(month: str, year: str, user_id: int = Depends(get_current_user)):
    cursor = connection.cursor()
    
    cursor.execute('SELECT id FROM months_table WHERE month_year = %s AND user_id = %s', (f"{month} {year}", user_id))
    result = cursor.fetchone()

    if not result:
        cursor.close()
        return {"month": f"{month} {year}", "transactions": []}
        
    m_id = result[0]

    cursor.execute('SELECT * FROM transactions_table WHERE m_id = %s', (m_id,))
    transactions = cursor.fetchall()
    cursor.close()
 
    transactions_list = [
        {   
            "id" : t[0], "m_id" : t[1], "reason" : t[2], "amount" : t[3],
            "category" : t[4], "method" : t[5], "bracket" : t[6], "date" : t[7],
        } for t in transactions
    ]

    return {"month": f"{month} {year}", "transactions": transactions_list}

@router.get("/getChoices")
async def get_choices(amount: str, user_id: int = Depends(get_current_user)):
    cursor = connection.cursor(cursor_factory=psycopg2.extras.DictCursor) 
    
    # This query might be more useful if it's user-specific. 
    # For now, it searches all transactions as per the original logic.
    cursor.execute("SELECT reason FROM transactions_table WHERE amount = %s AND method = 'debit' AND reason != ''", (amount,))
    transactions_db = cursor.fetchall()
    cursor.close()

    transcation_reasons = [t["reason"] for t in transactions_db]
    suggested_captions = get_top_suggestions(transcation_reasons)

    return suggested_captions