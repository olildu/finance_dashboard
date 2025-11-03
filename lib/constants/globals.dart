import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorkey = GlobalKey<NavigatorState>();

List categories = ["Food & Drinks", "Gums", "Travel", "Shopping", "Bill"];

Map<String, IconData> categoriesIcon = {
  "Food & Drinks": Icons.lunch_dining_rounded,
  "Cigarettes": Icons.smoking_rooms_rounded,
  "Travel": Icons.flight,
  "Shopping": Icons.shopping_bag,
  "Bill": Icons.payments_rounded,
  "debit": Icons.arrow_outward_rounded,
  "credit": Icons.arrow_outward_rounded,
  "Monthly Expense": Icons.calendar_month_rounded,
  "Savings Expense": Icons.savings_rounded,
  "Variable Expense": Icons.credit_card_rounded,
  "Laundry": Icons.checkroom_rounded,
  "Others": Icons.auto_graph_rounded,
};

Map<String, String> backendAreaRoute = {"0": "monthly-transactions", "1": "variable-expense-transactions", "2": "savings-expense-transactions", "3": "mutual-funds-transactions"};

List<String> months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

String month = months[DateTime.now().month - 1];

int monthlyExpenseLeft = 0;
int mutualFundsTotal = 0;
int variableExpense = 0;
int savings = 0;

bool fetchedData = false;
