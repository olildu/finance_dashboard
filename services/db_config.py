import mysql.connector
from mftool import Mftool

connection = mysql.connector.connect(
    host="localhost",
    user="root",
    password="MYSQLmyrefc/12",
    database="finance_dashboard"
)

mf = Mftool()
