CREATE TABLE accounts (
  id SERIAL PRIMARY KEY,
  code VARCHAR(20) UNIQUE NOT NULL,
  display_name VARCHAR(50) NOT NULL,
  kind VARCHAR(20) NOT NULL CHECK (kind IN ('bank','pseudo_credit','fixed')),
  fixed_amount DECIMAL(10,2)
);

CREATE TABLE budget_envelopes (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,
  monthly_amount DECIMAL(10,2) NOT NULL,
  account_id INT NOT NULL REFERENCES accounts(id)
);

CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  code VARCHAR(30) UNIQUE NOT NULL,
  display_name VARCHAR(50) NOT NULL,
  envelope_id INT NOT NULL REFERENCES budget_envelopes(id),
  is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE months (
  id SERIAL PRIMARY KEY,
  year INT NOT NULL,
  month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  UNIQUE (year, month)
);

CREATE TABLE transactions (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  month_id INT NOT NULL REFERENCES months(id),
  category_id INT REFERENCES categories(id),
  funding_account_id INT NOT NULL REFERENCES accounts(id),
  amount DECIMAL(10,2) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('expense','transfer','rollover_sweep','credit_payoff')),
  is_overage BOOLEAN NOT NULL DEFAULT false,
  reason VARCHAR(255),
  date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_txn_user_month_cat ON transactions (user_id, month_id, category_id);
CREATE INDEX idx_txn_user_month_account ON transactions (user_id, month_id, funding_account_id);

CREATE TABLE credit_ledger (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  month_id INT NOT NULL REFERENCES months(id),
  category_id INT REFERENCES categories(id),
  transaction_id INT REFERENCES transactions(id),
  amount DECIMAL(10,2) NOT NULL,
  entry_type VARCHAR(20) NOT NULL CHECK (entry_type IN ('overage','payoff')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_credit_ledger_user_month ON credit_ledger (user_id, month_id);

CREATE TABLE user_month_state (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  month_id INT NOT NULL REFERENCES months(id),
  status VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open','rolled_over')),
  credit_settled_amount DECIMAL(10,2) DEFAULT 0,
  sweep_amount DECIMAL(10,2) DEFAULT 0,
  rolled_over_at TIMESTAMP WITH TIME ZONE,
  UNIQUE (user_id, month_id)
);
