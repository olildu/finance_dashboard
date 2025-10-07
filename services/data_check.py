from datetime import datetime
from services.db_config import connection

def go_back_month(month: int, year: int):
    if month == 1:
        return f"{12}{year-1}"
    else:
        return f"{month-1}{year}"

def data_check(current_date, user_id: int): 
    cursor = connection.cursor()
    current_year = str(current_date.year)
    current_month_str = current_date.strftime("%B")
    combined_id = f"{current_date.month}{current_year}"

    cursor.execute("SELECT 1 FROM months_table WHERE id = %s AND user_id = %s", (combined_id, user_id))
    result = cursor.fetchone()

    if not result:
        print(f"ID {combined_id} for user {user_id} does not exist. Creating...")

        try:
            month_to_check = go_back_month(month=current_date.month, year=current_date.year)
            cursor.execute("SELECT * FROM account_details WHERE m_id = %s", (month_to_check,))
            account_details = cursor.fetchone()
            
            # Assuming account_details schema aligns with indices
            if account_details:
                mutual_funds = account_details[2] 
                savings = account_details[1] + account_details[4] + account_details[3]
            else:
                raise ValueError("No previous month's data found.")

            cursor.execute(
                "INSERT INTO months_table (id, user_id, month_year) VALUES (%s, %s, %s)",
                (combined_id, user_id, f"{current_month_str} {current_year}")
            )
            cursor.execute(
                """
                INSERT INTO account_details (m_id, savings, mutual_funds, variable_expense, monthly_expense_left) 
                VALUES (%s, %s, %s, 4000.00, 4000.00)
                """,
                (combined_id, savings, mutual_funds)
            )

        except (Exception,):
            cursor.execute(
                "INSERT INTO months_table (id, user_id, month_year) VALUES (%s, %s, %s)",
                (combined_id, user_id, f"{current_month_str} {current_year}")
            )
            cursor.execute(
                """
                INSERT INTO account_details (m_id, savings, mutual_funds, variable_expense, monthly_expense_left) 
                VALUES (%s, 0, 0, 4000.00, 4000.00)
                """,
                (combined_id,)
            )

        connection.commit()
    
    cursor.close()