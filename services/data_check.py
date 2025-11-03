from datetime import datetime
from services.db_config import connection

def go_back_month(month: int, year: int):
    if month == 1:
        return f"12{year-1}"
    else:
        return f"{month-1}{year}"


def data_check(current_date: datetime, user_id: int):
    cursor = connection.cursor()
    current_year = current_date.year
    current_month = current_date.month
    current_month_name = current_date.strftime("%B")

    combined_id = f"{current_month}{current_year}"

    cursor.execute(
        "SELECT 1 FROM months_table WHERE id = %s",
        (combined_id,)
    )
    month_exists = cursor.fetchone()

    if not month_exists:
        print(f"Creating global month record {combined_id}...")
        cursor.execute(
            "INSERT INTO months_table (id, month_year) VALUES (%s, %s)",
            (combined_id, f"{current_month_name} {current_year}")
        )
        connection.commit()

    cursor.execute(
        "SELECT 1 FROM account_details WHERE m_id = %s AND user_id = %s",
        (combined_id, user_id)
    )
    account_exists = cursor.fetchone()

    if not account_exists:
        print(f"Creating account_details for user {user_id} for month {combined_id}...")

        try:
            prev_id = go_back_month(current_month, current_year)
            cursor.execute(
                "SELECT savings, mutual_funds, variable_expense, monthly_expense_left "
                "FROM account_details WHERE m_id = %s AND user_id = %s",
                (prev_id, user_id)
            )
            prev_data = cursor.fetchone()

            if prev_data:
                prev_savings, prev_mutual, prev_variable, prev_left = prev_data
                savings = prev_savings + prev_variable + prev_left
                mutual_funds = prev_mutual
            else:
                savings = 0
                mutual_funds = 0

        except Exception as e:
            print(f"Error fetching previous month data: {e}")
            savings = 0
            mutual_funds = 0

        cursor.execute(
            """
            INSERT INTO account_details (m_id, user_id, savings, mutual_funds, variable_expense, monthly_expense_left)
            VALUES (%s, %s, %s, %s, 4000.00, 4000.00)
            """,
            (combined_id, user_id, savings, mutual_funds)
        )

        connection.commit()

    cursor.close()