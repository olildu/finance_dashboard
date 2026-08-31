import 'package:flutter/material.dart';
import 'package:finance_dashboard/features/accounts/business/accounts_provider.dart';
import 'package:finance_dashboard/features/budgets/business/budgets_provider.dart';
import 'package:finance_dashboard/features/credit/business/credit_provider.dart';
import 'package:finance_dashboard/features/transactions/business/transactions_provider.dart';

/// DashboardProvider composes data from multiple feature providers
/// and presents a unified dashboard state
class DashboardProvider extends ChangeNotifier {
  final AccountsProvider _accountsProvider;
  final BudgetsProvider _budgetsProvider;
  final CreditProvider _creditProvider;
  final TransactionsProvider _transactionsProvider;

  bool _isLoading = false;
  String? _errorMessage;

  DashboardProvider({
    required AccountsProvider accountsProvider,
    required BudgetsProvider budgetsProvider,
    required CreditProvider creditProvider,
    required TransactionsProvider transactionsProvider,
  })  : _accountsProvider = accountsProvider,
        _budgetsProvider = budgetsProvider,
        _creditProvider = creditProvider,
        _transactionsProvider = transactionsProvider;

  /// Whether any data is currently being loaded
  bool get isLoading => _isLoading;

  /// Error message if any operation failed
  String? get errorMessage => _errorMessage;

  /// Month-end check data from AccountsProvider
  Map<String, dynamic>? get monthEndCheck => _accountsProvider.monthEndCheck;

  /// Budget statuses (categories) from BudgetsProvider
  List<Map<String, dynamic>> get budgetStatuses => _budgetsProvider.categories;

  /// Credit balance from CreditProvider
  dynamic get creditBalance => _creditProvider.balance;

  /// Recent transactions from TransactionsProvider
  List<Map<String, dynamic>> get transactions => _transactionsProvider.transactions;

  /// Load all dashboard data in parallel from all providers
  Future<void> load() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Load all provider data in parallel
      await Future.wait([
        _accountsProvider.load(),
        _budgetsProvider.load(),
        _creditProvider.load(),
        _transactionsProvider.load(),
      ]);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _extractErrorMessage(e);
      notifyListeners();
    }
  }

  /// Extract error message from exception
  String _extractErrorMessage(Object? error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.startsWith('Exception: ')) {
        return message.substring('Exception: '.length);
      }
      return message;
    }
    return 'An unknown error occurred';
  }
}
