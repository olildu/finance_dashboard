-- Accounts
INSERT INTO accounts (code, display_name, kind, fixed_amount) VALUES
  ('ICICI', 'ICICI Bank', 'bank', NULL),
  ('SBI', 'SBI Bank', 'bank', NULL),
  ('SLICE', 'Slice', 'bank', NULL),
  ('HDFC', 'HDFC (Fixed)', 'fixed', 2500.00),
  ('CREDIT', 'Credit Ledger', 'pseudo_credit', NULL);

-- Budget Envelopes
INSERT INTO budget_envelopes (name, monthly_amount, account_id) VALUES
  ('Food', 6000.00, 1),
  ('PartyOutsideTravel', 4000.00, 2),
  ('Rent', 17000.00, 3),
  ('Electricity', 100.00, 3),
  ('PhoneInternet', 300.00, 3),
  ('Misc', 5000.00, 3),
  ('Savings', 13800.00, 3);

-- Categories
INSERT INTO categories (code, display_name, envelope_id, is_active) VALUES
  ('food', 'Food', 1, true),
  ('rent', 'Rent', 3, true),
  ('electricity', 'Electricity', 4, true),
  ('phone_internet', 'Phone & Internet', 5, true),
  ('travel', 'Travel', 2, true),
  ('party_outside', 'Party/Dining Out', 2, true),
  ('misc', 'Miscellaneous', 6, true),
  ('savings', 'Savings', 7, true);
