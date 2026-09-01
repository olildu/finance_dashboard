import 'package:flutter/material.dart';
import 'package:finance_dashboard/features/accounts/data/accounts_api.dart';

/// AccountsProvider handles all account state and logic
class AccountsProvider extends ChangeNotifier {
  final AccountsApi _accountsApi;

  List<Map<String, dynamic>> _accounts = [];
  Map<String, dynamic>? _monthEndCheck;
  bool _isLoading = false;
  String? _errorMessage;

  AccountsProvider({required AccountsApi accountsApi}) : _accountsApi = accountsApi;

  /// List of all accounts
  List<Map<String, dynamic>> get accounts => _accounts;

  /// Month-end check data with hdfc_reserve, total_net_worth, and accounts
  Map<String, dynamic>? get monthEndCheck => _monthEndCheck;

  /// Whether data is currently being loaded
  bool get isLoading => _isLoading;

  /// Error message if any operation failed
  String? get errorMessage => _errorMessage;

  /// Load accounts and month-end check data from the API
  Future<void> load() async {
    try {
      // Set loading state
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Fetch both accounts and month-end check data in parallel
      final results = await Future.wait([
        _accountsApi.getAccounts(),
        _accountsApi.getMonthEndCheck(),
      ]);

      final accountsData = results[0] as List<Map<String, dynamic>>;
      final monthEndData = results[1] as Map<String, dynamic>;

      // Update state with fetched data
      _accounts = accountsData;
      _monthEndCheck = monthEndData;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      // Handle errors
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
