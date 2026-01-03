from mftool import Mftool
import psycopg2
import psycopg2.extras  

connection = psycopg2.connect(
    host="localhost",
    user="ebinsanthosh", 
    password="root", 
    database="finance_dashboard"
)

mf = Mftool()

def get_db():
    cursor = connection.cursor()
    try:
        yield cursor
        connection.commit()
    except (Exception, psycopg2.Error) as error:
        print(f"Rolling back transaction due to: {error}")
        connection.rollback()
        raise  
    finally:
        cursor.close()

def get_db_dict():
    cursor = connection.cursor(cursor_factory=psycopg2.extras.DictCursor)
    try:
        yield cursor
        connection.commit()
    except (Exception, psycopg2.Error) as error:
        print(f"Rolling back transaction due to: {error}")
        connection.rollback()
        raise
    finally:
        cursor.close()