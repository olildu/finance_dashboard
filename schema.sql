-- Table to store user login information.
-- Passwords should always be securely hashed before storing.
CREATE TABLE
  users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );

-- Modified months_table to include a reference to the user.
CREATE TABLE months_table (
  id VARCHAR(255) PRIMARY KEY,
  month_year VARCHAR(255) NOT NULL
);

-- This table is implicitly linked to a user via its m_id relationship
-- with months_table. No changes are needed here.
CREATE TABLE account_details (
  m_id VARCHAR(255),
  category_id INT,
  savings DECIMAL(10, 2) NOT NULL,
  mutual_funds DECIMAL(10, 2) NOT NULL,
  variable_expense DECIMAL(10, 2) NOT NULL,
  monthly_expense_left DECIMAL(10, 2) NOT NULL,
  PRIMARY KEY (m_id, category_id),
  FOREIGN KEY (m_id) REFERENCES months_table (id)
);

-- This table is also implicitly linked to a user via its m_id relationship.
-- No changes are needed here.
CREATE TABLE
  transactions_table (
    id SERIAL PRIMARY KEY,
    m_id VARCHAR(255) NOT NULL,
    reason VARCHAR(255),
    amount DECIMAL(10, 2) NOT NULL,
    category VARCHAR(255),
    method VARCHAR(50),
    bracket VARCHAR(255),
    date TIMESTAMP,
    FOREIGN KEY (m_id) REFERENCES months_table (id)
  );

-- Modified mutual_funds table to be user-specific.
-- Each user will have their own list of funds.
CREATE TABLE
  mutual_funds (
    user_id INT NOT NULL,
    fund_name VARCHAR(255) NOT NULL,
    units DECIMAL(10, 2) NOT NULL,
    buy_price DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users (user_id),
    -- A user can only have one entry per fund name.
    PRIMARY KEY (user_id, fund_name)
  );
