import 'package:flutter/material.dart';
import 'package:finance_dashboard/features/budgets/data/budgets_api.dart';

/// BudgetsProvider handles all budgets state and logic
class BudgetsProvider extends ChangeNotifier {
  final BudgetsApi _budgetsApi;

  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCached = false;
  Future<void>? _inFlightFuture;

  BudgetsProvider({required BudgetsApi budgetsApi}) : _budgetsApi = budgetsApi;

  /// List of category budget status entries
  List<Map<String, dynamic>> get categories => _categories;

  /// Whether data is currently being loaded
  bool get isLoading => _isLoading;

  /// Error message if any operation failed
  String? get errorMessage => _errorMessage;

  /// Load budget data (category statuses) from the API
  /// If [forceRefresh] is true, bypasses cache and fetches fresh data
  /// Otherwise uses cached data if available
  /// Concurrent load() calls while one is in progress will await the same Future
  Future<void> load({bool forceRefresh = false}) async {
    try {
      // If data is cached and we're not forcing a refresh, return early
      if (_isCached && !forceRefresh) {
        return;
      }

      // If a load is already in progress, await the same future
      if (_inFlightFuture != null && !forceRefresh) {
        return _inFlightFuture!;
      }

      // Create a new load future
      _inFlightFuture = _performLoad();
      await _inFlightFuture;
    } catch (e) {
      // Handle errors - exception is already set in _performLoad
      // but we catch here to prevent propagation up the call stack
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
      final response = await _budgetsApi.getStatus();

      _categories = List<Map<String, dynamic>>.from(response['categories'] ?? []);
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
