import json
from fastapi import APIRouter
from datetime import datetime   

from services.data_check import data_check
from services.db_config import connection
from services.mf_data_calculator import calculateFunds
from services.autofill import get_top_suggestions

router = APIRouter()

@router.get("/getData")
async def get_data():
    current_date = datetime.now()
    current_date_sql = datetime.now().strftime('%Y-%m-%d')
    current_month = current_date.strftime("%B")
    current_month_int = current_date.month
    current_year = current_date.year
    
    connection.reconnect()
    cursor = connection.cursor()

    data_check(current_date)

    category_totals = {}
    spent_today = 0 

    cursor.execute(f"select * from transactions_table where bracket='monthly-transactions' and m_id='{current_month_int}{current_year}'")
    monthlyTransactions = cursor.fetchall()

    for transaction in monthlyTransactions:
        amount = transaction[3]
        category = transaction[4]
        if category in category_totals:
            category_totals[category] += amount
        else:
            category_totals[category] = amount

    cursor.execute(f"SELECT * FROM transactions_table WHERE bracket = 'monthly-transactions' AND m_id = {current_month_int}{current_year} AND DATE(date) = '{current_date_sql}';")
    todayData = cursor.fetchall()

    for x in todayData:
        spent_today += x[3]

    total_expense = sum(category_totals.values())

    category_percentages = {}
    for category, total in category_totals.items():
        if total_expense != 0:
            category_percentages[category] = round((total / total_expense) * 1, 2) 
        else:
            category_percentages[category] = 0.0  

    cursor.execute(f"SELECT mutual_funds FROM account_details WHERE m_id = '{current_month_int}{current_year}'")
    mutual_funds_total = cursor.fetchone()[0]

    cursor.execute(f"SELECT variable_expense FROM account_details WHERE m_id = '{current_month_int}{current_year}'")
    variable_expense = cursor.fetchone()[0]
    
    cursor.execute(f"SELECT savings FROM account_details WHERE m_id = '{current_month_int}{current_year}'")
    savings = cursor.fetchone()[0]
    
    cursor.execute(f"SELECT monthly_expense_left FROM account_details WHERE m_id = '{current_month_int}{current_year}'")
    balance = cursor.fetchone()[0]

    return {
        "monthly_expense_left": balance,
        "mutual_funds_total" : mutual_funds_total,
        "variable_expense" : variable_expense,
        "savings" : savings,
        "category_totals": category_totals,
        "total_expense": total_expense,
        "category_percentages": category_percentages,
        "spent_today" : spent_today,
        "mutual_funds_performance" : calculateFunds()
    }

@router.get("/getTransactions")
async def get_transactions(
    month: str,
    year: str
):
    connection.reconnect()
    cursor = connection.cursor()
    
    cursor.execute(f'SELECT id FROM months_table WHERE month_year = "{month} {year}";')
    m_id = cursor.fetchone()[0]

    cursor.execute(f'SELECT * FROM TRANSACTIONS_TABLE WHERE M_ID = {m_id}')
    transactions = cursor.fetchall()
 
    transactions_list = []

    for transaction in transactions:
        transactions_list.append(
            {   
                "id" : transaction[0],
                "m_id" : transaction[1],
                "reason" : transaction[2], 
                "amount" : transaction[3],
                "category" : transaction[4],
                "method" : transaction[5],
                "bracket" : transaction[6],
                "date" : transaction[7],
            }
        )

    return {"month": f"{month} {year}", "transactions": transactions_list}  

@router.get("/getChoices")
async def get_choices(
    amount: str,
):
    transcation_reason = []
    connection.reconnect()
    cursor = connection.cursor(dictionary=True) 

    cursor.execute(f"SELECT * FROM transactions_table where amount = {amount} and method = 'debit' and reason != ''")

    transactions_db = cursor.fetchall()

    for transaction in transactions_db:
        transcation_reason.append(transaction["reason"])

    suggested_captions = get_top_suggestions(transcation_reason)

    return suggested_captions