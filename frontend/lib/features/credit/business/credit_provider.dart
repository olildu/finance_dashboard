import 'package:flutter/material.dart';
import 'package:finance_dashboard/features/credit/data/credit_api.dart';

/// CreditProvider handles all credit state and logic
class CreditProvider extends ChangeNotifier {
  final CreditApi _creditApi;

  dynamic _balance;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCached = false;
  Future<void>? _inFlightFuture;

  CreditProvider({required CreditApi creditApi}) : _creditApi = creditApi;

  /// Current credit balance owed
  dynamic get balance => _balance;

  /// List of credit ledger history entries
  List<Map<String, dynamic>> get history => _history;

  /// Whether data is currently being loaded
  bool get isLoading => _isLoading;

  /// Error message if any operation failed
  String? get errorMessage => _errorMessage;

  /// Load credit data (balance and history) from the API
  /// If [forceRefresh] is true, bypasses cache and fetches fresh data
  /// Otherwise uses cached data if available
  /// Concurrent load() calls while one is in progress will await the same Future
  Future<void> load({bool forceRefresh = false}) async {
    // If data is cached and we're not forcing a refresh, return early
    if (_isCached && !forceRefresh) {
      return;
    }

    // If a load is already in progress, await the same future
    if (_inFlightFuture != null) {
      return _inFlightFuture!;
    }

    // Create a new load future
    _inFlightFuture = _performLoad();
    try {
      await _inFlightFuture;
    } finally {
      // Must clear even when _performLoad rethrows, or every subsequent
      // load() call would return the same stale failed future forever.
      _inFlightFuture = null;
    }
  }

  Future<void> _performLoad() async {
    _isLoading = true;
    notifyListeners();

    try {
      final balanceResponse = await _creditApi.getBalance();
      final historyResponse = await _creditApi.getHistory();

      _balance = balanceResponse['balance'];
      _history = List<Map<String, dynamic>>.from(historyResponse['entries'] ?? []);
      _errorMessage = null;
      _isCached = true;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
