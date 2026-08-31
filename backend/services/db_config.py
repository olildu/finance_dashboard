import psycopg2
import psycopg2.extras
from psycopg2 import pool
from mftool import Mftool

# Initialize Mftool
mf = Mftool()

# Create a ThreadedConnectionPool
# This will maintain between 1 and 20 connections to be shared across your FastAPI requests
try:
    db_pool = psycopg2.pool.ThreadedConnectionPool(
        1, 20,
        host="localhost",
        user="ebinsanthosh", 
        password="root", 
        database="finance_dashboard"
    )
    if db_pool:
        print("Connection pool created successfully")
except (Exception, psycopg2.DatabaseError) as error:
    print("Error while connecting to PostgreSQL", error)

def get_db():
    """Yields a standard database cursor using a connection from the pool."""
    # Fetch a connection from the pool
    connection = db_pool.getconn()
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
        # Return the connection back to the pool so other requests can use it
        db_pool.putconn(connection)

def get_db_dict():
    """Yields a dictionary-like database cursor using a connection from the pool."""
    # Fetch a connection from the pool
    connection = db_pool.getconn()
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
        # Return the connection back to the pool so other requests can use it
        db_pool.putconn(connection)
