import 'package:flutter/material.dart';
import 'package:finance_dashboard/features/rollover/data/rollover_api.dart';

/// RolloverProvider handles rollover state and logic
/// Manages state for manual rollover trigger with loading/error/result tracking
class RolloverProvider extends ChangeNotifier {
  final RolloverApi _rolloverApi;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _lastResult;
  Future<void>? _inFlightFuture;

  RolloverProvider({required RolloverApi rolloverApi})
      : _rolloverApi = rolloverApi;

  /// Whether a rollover trigger is currently in progress
  bool get isLoading => _isLoading;

  /// Error message if the last trigger failed
  String? get errorMessage => _errorMessage;

  /// Result of the last successful trigger
  Map<String, dynamic>? get lastResult => _lastResult;

  /// Trigger a manual rollover check on the server
  /// Concurrent trigger() calls while one is in progress will await the same Future
  /// Throws an exception on failure
  Future<void> trigger() async {
    // If a trigger is already in progress, await the same future
    if (_inFlightFuture != null) {
      return _inFlightFuture!;
    }

    // Create a new trigger future
    _inFlightFuture = _performTrigger();
    try {
      await _inFlightFuture;
    } finally {
      // Must clear even when _performTrigger rethrows, or every subsequent
      // trigger() call would return the same stale failed future forever.
      _inFlightFuture = null;
    }
  }

  Future<void> _performTrigger() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _rolloverApi.triggerCheck();
      _lastResult = result;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
