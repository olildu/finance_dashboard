import 'package:dio/dio.dart';

/// AuthApi handles all authentication-related API calls
class AuthApi {
  final Dio dio;

  AuthApi(this.dio);

  /// Login with username and password
  /// Returns a map containing 'access_token' and 'refresh_token'
  /// Throws an exception on failure
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  /// Register a new user with username, email, and password
  /// Returns a map containing 'access_token' and 'refresh_token'
  /// Throws an exception on failure
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  /// Refresh the access token using the refresh token
  /// Returns a map containing the new 'access_token'
  /// Throws an exception on failure
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  /// Handle DioException and convert to meaningful error messages
  void _handleDioException(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      String message = 'An error occurred';

      // Try to extract error message from response
      final responseData = e.response!.data;
      if (responseData is Map<String, dynamic>) {
        // FastAPI uses 'detail' field for error messages
        message = responseData['detail'] ??
                  responseData['message'] ??
                  'An error occurred';
      }

      throw Exception('$message (HTTP $statusCode)');
    } else if (e.type == DioExceptionType.connectionTimeout) {
      throw Exception('Connection timeout. Please check your internet connection.');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      throw Exception('Server took too long to respond. Please try again.');
    } else if (e.type == DioExceptionType.sendTimeout) {
      throw Exception('Request timeout. Please try again.');
    } else {
      throw Exception('Network error: ${e.message ?? "Unknown error"}');
    }
  }
}
