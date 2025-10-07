from services.db_config import connection, mf

def calculateFunds(x):
    cursor = connection.cursor()
    cursor.execute("SELECT fund_name, units, buy_price FROM mutual_funds")
    funds_data = cursor.fetchall()

    invested_mid_cap = 0
    invested_large_cap = 0

    current_units_mid_cap = 0
    current_units_large_cap = 0

    profit_mid_cap = 0
    profit_large_cap = 0

    for x in funds_data:
        if x[0] == "Motilal Oswal Midcap Fund":
            current_units_mid_cap += x[1]
            invested_mid_cap += x[2]

        if x[0] == "ICICI Prudential Bluechip Fund":
            current_units_large_cap += x[1]
            invested_large_cap += x[2]

    f = mf.get_scheme_quote(120586)["nav"]
    e = mf.get_scheme_quote(127042)["nav"]

    current_price_mid_cap = round(float(current_units_mid_cap) * float(e), 2)
    current_price_large_cap = round(float(current_units_large_cap) * float(f), 2)

    profit_mid_cap = round(float(current_price_mid_cap) - float(invested_mid_cap), 2)
    profit_large_cap = round(float(current_price_large_cap) - float(invested_large_cap), 2)

    return {
        "large_cap": {
            "invested": invested_large_cap,
            "current": current_price_large_cap,
            "turnover": profit_large_cap
        },
        "mid_cap": {
            "invested": invested_mid_cap,
            "current": current_price_mid_cap,
            "turnover": profit_mid_cap
        },
        "total" : {
            "invested": invested_large_cap + invested_mid_cap,
            "current": current_price_large_cap + current_price_mid_cap,
            "turnover": profit_large_cap + profit_mid_cap
        }
    }