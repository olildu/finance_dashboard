import 'package:flutter/material.dart';
import 'package:finance_dashboard/features/transactions/data/transactions_api.dart';

/// TransactionsProvider handles all transaction state and logic
class TransactionsProvider extends ChangeNotifier {
  final TransactionsApi _transactionsApi;

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  TransactionsProvider({required TransactionsApi transactionsApi})
      : _transactionsApi = transactionsApi;

  /// List of all transactions
  List<Map<String, dynamic>> get transactions => _transactions;

  /// Whether data is currently being loaded
  bool get isLoading => _isLoading;

  /// Error message if any operation failed
  String? get errorMessage => _errorMessage;

  /// Load transactions from the API
  Future<void> load() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final transactionData = await _transactionsApi.getTransactions();
      _transactions = transactionData;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Add a new transaction
  /// [categoryCode] - The category code
  /// [amount] - Transaction amount
  /// [reason] - Optional reason
  /// [date] - Date of the transaction
  Future<void> addTransaction({
    required String categoryCode,
    required num amount,
    String? reason,
    required DateTime date,
  }) async {
    try {
      final createdTransaction = await _transactionsApi.createTransaction(
        categoryCode: categoryCode,
        amount: amount,
        reason: reason,
        date: date,
      );
      _transactions.add(createdTransaction);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a transaction
  /// [transactionId] - The ID of the transaction to delete
  Future<void> deleteTransaction(int transactionId) async {
    try {
      await _transactionsApi.deleteTransaction(transactionId);
      _transactions.removeWhere((t) => t['id'] == transactionId);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
