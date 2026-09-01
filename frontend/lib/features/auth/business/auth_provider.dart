import 'package:flutter/material.dart';
import 'package:finance_dashboard/core/network/token_manager.dart';
import 'package:finance_dashboard/features/auth/data/auth_api.dart';

/// AuthProvider handles all authentication state and logic
class AuthProvider extends ChangeNotifier {
  final AuthApi _authApi;
  final TokenManager _tokenManager;

  bool _isLoggedIn = false;
  String? _currentError;

  AuthProvider({
    required AuthApi authApi,
    required TokenManager tokenManager,
  })  : _authApi = authApi,
        _tokenManager = tokenManager;

  /// Whether the user is currently logged in
  bool get isLoggedIn => _isLoggedIn;

  /// The current error message, if any
  String? get currentError => _currentError;

  /// Login with username and password
  Future<void> login(String username, String password) async {
    try {
      // Call the API to login
      final response = await _authApi.login(username, password);

      // Extract tokens from response
      final accessToken = response['access_token'] as String?;
      final refreshToken = response['refresh_token'] as String?;

      if (accessToken == null || refreshToken == null) {
        throw Exception('Missing tokens in response');
      }

      // Save tokens to storage
      await _tokenManager.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // Update state
      _isLoggedIn = true;
      _currentError = null;
      notifyListeners();
    } catch (e) {
      _currentError = _extractErrorMessage(e);
      _isLoggedIn = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Register a new user
  Future<void> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      // Call the API to register
      await _authApi.register(username, email, password);

      // Backend returns user data without tokens on register
      // Now login with the same credentials to get tokens
      await login(username, password);
    } catch (e) {
      _currentError = _extractErrorMessage(e);
      _isLoggedIn = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      await _tokenManager.deleteTokens();
      _isLoggedIn = false;
      _currentError = null;
      notifyListeners();
    } catch (e) {
      _currentError = _extractErrorMessage(e);
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
