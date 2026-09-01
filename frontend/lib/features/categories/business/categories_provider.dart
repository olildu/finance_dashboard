import 'package:flutter/material.dart';
import 'package:finance_dashboard/features/categories/data/categories_api.dart';

/// CategoriesProvider handles all category state and logic
class CategoriesProvider extends ChangeNotifier {
  final CategoriesApi _categoriesApi;

  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCached = false;
  Future<void>? _inFlightFuture;

  CategoriesProvider({required CategoriesApi categoriesApi})
      : _categoriesApi = categoriesApi;

  /// List of all categories with envelope information
  List<Map<String, dynamic>> get categories => _categories;

  /// Whether data is currently being loaded
  bool get isLoading => _isLoading;

  /// Error message if any operation failed
  String? get errorMessage => _errorMessage;

  /// Load categories from the API
  /// If [forceRefresh] is true, bypasses cache and fetches fresh data
  /// Otherwise uses cached data if available
  /// Concurrent load() calls while one is in progress will await the same Future
  Future<void> load({bool forceRefresh = false}) async {
    try {
      // If we have cached data and not forcing refresh, return cached data
      if (_isCached && !forceRefresh) {
        return;
      }

      // If a load is already in progress, await the same Future
      if (_inFlightFuture != null && !forceRefresh) {
        return _inFlightFuture!;
      }

      // Set loading state
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create the in-flight future for this load operation
      _inFlightFuture = _performLoad();
      await _inFlightFuture;
    } catch (e) {
      // Handle errors
      _isLoading = false;
      _errorMessage = _extractErrorMessage(e);
      notifyListeners();
    } finally {
      // Clear in-flight future only if not forcing refresh
      if (!forceRefresh) {
        _inFlightFuture = null;
      }
    }
  }

  /// Perform the actual load operation
  Future<void> _performLoad() async {
    try {
      // Fetch categories from API
      final categoriesData = await _categoriesApi.getCategories();

      // Update state with fetched data
      _categories = categoriesData;
      _isCached = true;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      // Handle errors
      _isLoading = false;
      _errorMessage = _extractErrorMessage(e);
      notifyListeners();
      rethrow;
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
