from mftool import Mftool
import psycopg2

connection = psycopg2.connect(
    host="localhost",
    user="postgres", 
    password="9612", 
    database="finance_dashboard"
)

mf = Mftool()
