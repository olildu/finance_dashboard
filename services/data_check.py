from datetime import datetime
import json
from services.db_config import connection

def go_back_month(
    month : int,
    year : int
):
    if month == 1:
        return f"{12}{year-1}" 
    else:
        return f"{month-1}{year}" 

def data_check(current_date):
    cursor = connection.cursor()
    current_day = str(current_date.day)
    current_year = str(current_date.year)
    current_month_str = current_date.strftime("%B")

    combined_id = f"{current_date.month}{current_year}"
    cursor.execute(f"SELECT 1 FROM months_table WHERE id = {combined_id}")
    result = cursor.fetchone()
    
    if result:
        print(f"ID {combined_id} exists in the table.")
    else: 
        print(f"ID {combined_id} does not exist in the table.")

        try:
            month_to_check = go_back_month(
                month = current_date.month,
                year = current_year
            )

            cursor.execute(f"SELECT * FROM ACCOUNT_DETAILS WHERE M_ID = {month_to_check};")
            account_details = cursor.fetchone()

            mutual_funds = account_details[3]
            savings = account_details[2] + account_details[5] + account_details[4]

            cursor.execute(f"INSERT INTO months_table (id, month_year) VALUES ({combined_id}, '{current_month_str} {current_year}');")
            cursor.execute(f"INSERT INTO account_details (m_id, savings, mutual_funds, variable_expense, monthly_expense_left) VALUES ({combined_id}, {savings}, {mutual_funds}, 4000.00, 4000.00);")
            
        
        except:
            cursor.execute(f"INSERT INTO months_table (id, month_year) VALUES ({combined_id}, '{current_month_str} {current_year}');")
            cursor.execute(f"INSERT INTO account_details (m_id, savings, mutual_funds, variable_expense, monthly_expense_left) VALUES ({combined_id}, 0, 0, 4000.00, 4000.00);")
            

        connection.commit()